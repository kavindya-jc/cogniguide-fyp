"""
CogniGuide tutor agent controller - agent plan, Phases 1 and 2

ONE place that runs a tutoring turn. api.py checks the request and who the student is,
then calls run_turn(). Each turn follows the same cycle:

    RECEIVE  the problem (with its answer sheet, for a bank problem), the chat and the
             session memory (sessions.state)
    ASSESS   assessment.py   - Gemini fills in a form about the student's newest message;
                               Python checks it, and answer_check.py has the last word on "solved"
    DECIDE   policy.py       - plain rules choose ONE action (hint ladder, mistakes, confirm...),
                               limited by the Stage 5 scaffold level (scaffolding.py)
    ACT      socratic_agent  - Gemini writes the reply for that action (+ a Stage 6 reflection
                               question at a calm moment, reflection.py)
    CHECK    answer_check.py - the reply must not give away the answer and must be short;
                               otherwise it is written again once, then a safe reply is used
    UPDATE   db.py           - save the turn, the indicators and the new session memory
                               (never breaks the reply)

The next message starts the cycle again with the updated memory: that is the feedback loop.
Gemini is called twice per student message (check + reply); the opening turn needs only the reply.
"""

import logging

from app import adaptive, answer_check, assessment, db, policy, problems, reflection, scaffolding
from app.models.socratic_agent import TutorUnavailable, socratic_response  # noqa: F401 (TutorUnavailable is raised to api.py)

# The longest reply that passes the safety check (the tutor is asked for at most three short sentences).
MAX_REPLY_CHARS = 700

log = logging.getLogger(__name__)

assess = assessment.assess


def load_scaffold_level(student_code, session_id):
    """Stage 5: choose the scaffold level (1-3) from the student's earlier sessions.

    Never raises. Any problem (no student_id, new student, no database, database error)
    gives 3 = full support, which is the Stage 4 behaviour.
    """
    if not student_code or not db.is_configured():
        return scaffolding.MAX_SCAFFOLD
    try:
        student_uuid = db.find_student(student_code)
        if student_uuid is None:
            return scaffolding.MAX_SCAFFOLD
        averages = db.get_recent_session_levels(student_uuid, exclude_session_id=session_id)
        return scaffolding.compute_scaffold_level(averages)
    except Exception as err:
        log.error("Reading earlier sessions failed (using full support): %s", err)
        return scaffolding.MAX_SCAFFOLD


def load_reflection_type(student_code, session_id, history, analysis):
    """Stage 6: choose a reflection type for this reply, or None for no reflection question.

    Never raises. No student_id, no session_id, no database, a database error, a bad moment,
    a new student, or a reflection already asked in this session all give None.
    """
    if not student_code or not session_id or not db.is_configured():
        return None
    # Cheap checks first, so most turns do not touch the database at all.
    if not reflection.is_good_moment(analysis, reflection.count_student_messages(history)):
        return None
    try:
        student_uuid = db.find_student(student_code)
        if student_uuid is None:
            return None
        if not db.session_belongs_to(session_id, student_uuid):
            return None  # never use another student's session
        if db.session_has_reflection(session_id):
            return None  # at most once per session
        summary = db.get_history_summary(student_uuid, exclude_session_id=session_id)
        return reflection.choose_reflection_type(summary)
    except Exception as err:
        log.error("Reading history for reflection failed (no reflection): %s", err)
        return None


def log_turn(student_code, session_id, problem, history, reply, analysis,
             scaffold_level=scaffolding.MAX_SCAFFOLD, reflection_type=None, problem_id=None, rows=None):
    """Save this turn to the database and return the session id.

    Saves the student's newest message (if the history ends with one), the tutor's reply,
    and the indicators (Stage 4 + the Stage 5 scaffold level + the Stage 6 reflection type, if one was asked). Raises an exception if anything fails; the caller handles it.
    A new session also remembers problem_id (Step 1.4) when the problem came from the bank.
    rows (Phase 2): the indicator rows of this turn (indicator_rows); without them the old
    Stage 4 word-rule rows are saved.
    """
    if not db.is_configured():
        log.warning("Supabase is not configured; chat not saved.")
        return session_id

    student_uuid = db.get_or_create_student(student_code)

    if session_id:
        if not db.session_belongs_to(session_id, student_uuid):
            raise ValueError("session_id does not exist or belongs to another student")
    else:
        session_id = db.create_session(student_uuid, problem, problem_id=problem_id)

    messages = []
    if history and history[-1]["role"] == "student":
        messages.append(("student", history[-1]["content"]))
    messages.append(("teacher", reply))
    db.save_messages(session_id, messages)

    # Indicators are extra: if they fail, the messages above are already safe.
    try:
        if rows is None:
            rows = adaptive.indicator_rows(analysis)  # empty unless there is a NEW student message
        rows = list(rows)
        if rows:
            rows.append(("scaffold_level", scaffold_level))
            if reflection_type:
                rows.append((reflection.indicator_name(reflection_type), 1))
        db.save_indicators(student_uuid, session_id, rows)
    except Exception as err:
        log.error("Saving indicators failed: %s", err)

    return session_id


def load_state(student_code, session_id, history):
    """The session memory to start this turn from. Never raises.

    A logged-in student's session: the memory saved last turn (sessions.state).
    Otherwise (no login, a new session, or the database cannot be read) a fresh memory, with
    the struggle count guessed from the earlier messages by the Stage 4 word rules, so the help
    can still go up within the chat.
    """
    if student_code and session_id and db.is_configured():
        try:
            student_uuid = db.find_student(student_code)
            if student_uuid is not None and db.session_belongs_to(session_id, student_uuid):
                return policy.clean_state(db.get_session_state(session_id)), True
        except Exception as err:
            log.error("Reading the session memory failed (starting fresh): %s", err)
    state = policy.new_state()
    earlier = history[:-1] if history and history[-1].get("role") == "student" else history
    state["struggle"] = adaptive.analyze_history(earlier)["struggle_count"]
    return state, False


def check_reply(reply, problem, decision, state):
    """The reply safety check. Returns why the reply is not allowed, or None if it is fine."""
    if len(reply) > MAX_REPLY_CHARS:
        return "it is too long"
    already_solved = state["solved"] or decision["action"] == policy.CONFIRM_AND_REFLECT
    if problem and not already_solved and answer_check.reply_leaks_answer(reply, problem):
        return "it gives away (part of) the final answer"
    return None


def indicator_rows(form, decision, analysis):
    """The numbers saved for this turn (the indicators table). Only for a NEW student message.

    The same kinds as before (so progress.py keeps working) plus: wrong_attempt, solved, misconception.
    hint_level is the help the student NEEDED (before the scaffold limit), as before.
    """
    if form is None or not analysis["new_student_message"]:
        return []
    latest = analysis["latest"]
    rows = [("hint_level", decision["needed_level"])]
    if form["self_corrected"]:
        rows.append(("self_correction", 1))
    if decision["asked_for_answer"] or latest["asked_for_answer"]:
        rows.append(("asked_for_answer", 1))
    if form["intent"] == "confused" or latest["stuck"]:
        rows.append(("stuck", 1))
    if form["correctness"] == "incorrect":
        rows.append(("wrong_attempt", 1))
    if form["solved"]:
        rows.append(("solved", 1))
    if decision["mistake_id"]:
        rows.append(("misconception", 1))
    return rows


def _bank_problem(problem_id):
    if not problem_id:
        return None
    try:
        return problems.find(problem_id)
    except problems.ProblemBankError as err:
        log.error("Problem bank cannot be read (no answer sheet this turn): %s", err)
        return None


def run_turn(student_code, problem, history, session_id=None, problem_id=None):
    """Run one tutoring turn and return the result for api.py.

    student_code: the code from the login token, or None (an anonymous chat that is not saved).
    problem: the problem text. problem_id: the bank id (for example "alg-9-1") when the problem
             came from GET /problems, or None for a problem the student typed in (no answer sheet).
    Returns {"reply", "session_id", "hint_level", "scaffold_level", "reflection_type"}.
    Raises TutorUnavailable when Gemini cannot write the reply (nothing is saved then).
    Any other exception (for example no GEMINI_API_KEY) is raised to api.py too.
    """
    # RECEIVE
    analysis = adaptive.analyze_history(history)  # word rules: backup signals and reflection timing
    bank = _bank_problem(problem_id)
    state, _saved = load_state(student_code, session_id, history)
    scaffold_level = load_scaffold_level(student_code, session_id)

    # ASSESS (only when the student wrote something new)
    form = assess(problem, bank, history) if analysis["new_student_message"] else None

    # DECIDE
    decision = policy.choose_action(form, state, scaffold_level, bank)

    # ACT
    reflection_type = None
    if decision["action"] in policy.CALM_ACTIONS:
        reflection_type = load_reflection_type(student_code, session_id, history, analysis)
    instruction = policy.build_instruction(decision, form, bank, state)
    if decision["action"] not in (policy.CONFIRM_AND_REFLECT, policy.REDIRECT, policy.EXPLAIN_STEP_CLEARLY):
        scaffold_note = scaffolding.build_scaffold_instruction(scaffold_level, {"struggle_count": decision["struggle"]})
        if scaffold_note:
            instruction += "\n" + scaffold_note
    if reflection_type:
        instruction += "\n" + reflection.build_reflection_instruction(reflection_type)

    reply = socratic_response(problem, history, extra_instruction=instruction, raise_on_error=True)

    # CHECK the reply: one more try, then a safe reply
    guard = "ok"
    why = check_reply(reply, bank, decision, state)
    if why:
        log.warning("Reply not allowed (%s); asking again.", why)
        try:
            second = socratic_response(
                problem, history,
                extra_instruction=instruction + f"\nYOUR LAST REPLY WAS NOT ALLOWED because {why}. Write a new one that follows every rule.",
                raise_on_error=True,
            )
        except TutorUnavailable:
            second = None
        if second and not check_reply(second, bank, decision, state):
            reply, guard = second, "rewritten"
        else:
            reply, guard = policy.SAFE_REPLIES[decision["action"]], "safe_reply"

    # UPDATE the memory and save. Never let a database problem break the reply.
    new_state = policy.update_state(state, form, decision)
    new_state["last_reason"] = decision["reason"]
    new_state["last_guard"] = guard
    if student_code:
        turn_saved = False
        try:
            session_id = log_turn(
                student_code, session_id, problem, history, reply, analysis, scaffold_level, reflection_type,
                problem_id=problem_id, rows=indicator_rows(form, decision, analysis),
            )
            turn_saved = True
        except Exception as err:
            log.error("Saving chat to database failed: %s", err)
        # Only after log_turn worked: it checked that this session belongs to this student.
        if turn_saved and session_id and db.is_configured():
            try:
                db.save_session_state(session_id, new_state, solved=new_state["solved"] and not state["solved"])
            except Exception as err:
                log.error("Saving the session memory failed: %s", err)

    return {
        "reply": reply,
        "session_id": session_id,
        "hint_level": decision["hint_level"],
        "scaffold_level": scaffold_level,
        "reflection_type": reflection_type,
    }
