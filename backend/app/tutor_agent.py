"""
CogniGuide tutor agent controller - agent plan, Phase 1 (Step 1.3)

ONE place that runs a tutoring turn. api.py checks the request and who the student is,
then calls run_turn(). This file decides and acts:

    1. Stage 4  adaptive.py     - hint level (1-3) from the student's recent messages
    2. Stage 5  scaffolding.py  - limit the hint level using the student's earlier sessions
    3. Stage 6  reflection.py   - maybe one reflection question about how they work
    4.          socratic_agent  - Gemini writes the reply with those extra instructions
    5. Stage 3  db.py           - save the turn and the indicators (never breaks the reply)

Step 1.3 only MOVED this code here from api.py. The behaviour is exactly the same as
before (same order, same rules, same saved rows). Later phases change the steps inside
run_turn (assess the student's reasoning, choose an action, check the reply), so api.py
does not need to change again.
"""

import logging

from app import adaptive, db, reflection, scaffolding
from app.models.socratic_agent import TutorUnavailable, socratic_response  # noqa: F401 (TutorUnavailable is raised to api.py)

log = logging.getLogger(__name__)


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
             scaffold_level=scaffolding.MAX_SCAFFOLD, reflection_type=None, problem_id=None):
    """Save this turn to the database and return the session id.

    Saves the student's newest message (if the history ends with one), the tutor's reply,
    and the indicators (Stage 4 + the Stage 5 scaffold level + the Stage 6 reflection type, if one was asked). Raises an exception if anything fails; the caller handles it.
    A new session also remembers problem_id (Step 1.4) when the problem came from the bank.
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
        rows = adaptive.indicator_rows(analysis)  # empty unless there is a NEW student message
        if rows:
            rows.append(("scaffold_level", scaffold_level))
            if reflection_type:
                rows.append((reflection.indicator_name(reflection_type), 1))
        db.save_indicators(student_uuid, session_id, rows)
    except Exception as err:
        log.error("Saving indicators failed: %s", err)

    return session_id


def run_turn(student_code, problem, history, session_id=None, problem_id=None):
    """Run one tutoring turn and return the result for api.py.

    student_code: the code from the login token, or None (an anonymous chat that is not saved).
    problem_id: the bank id (for example "alg-9-1") when the problem came from GET /problems,
                or None for a problem the student typed in. Step 1.4 only saves it with the
                session; later steps use it to check the student's answer.
    Returns {"reply", "session_id", "hint_level", "scaffold_level", "reflection_type"}.
    Raises TutorUnavailable when Gemini cannot give a real reply (nothing is saved then).
    Any other exception (for example no GEMINI_API_KEY) is raised to api.py too.
    """
    # Stage 4: decide the hint level from the student's recent messages.
    analysis = adaptive.analyze_history(history)

    # Stage 5: fade the help if earlier sessions show the student needs less of it.
    scaffold_level = load_scaffold_level(student_code, session_id)
    analysis = scaffolding.apply_scaffold(analysis, scaffold_level)

    # Stage 6: maybe ask one reflection question about the student's own way of working.
    reflection_type = load_reflection_type(student_code, session_id, history, analysis)

    extra_instruction = adaptive.build_instruction(analysis)
    scaffold_note = scaffolding.build_scaffold_instruction(scaffold_level, analysis)
    if scaffold_note:
        extra_instruction += "\n" + scaffold_note
    if reflection_type:
        extra_instruction += "\n" + reflection.build_reflection_instruction(reflection_type)

    reply = socratic_response(problem, history, extra_instruction=extra_instruction, raise_on_error=True)

    # Stage 3: save the chat. Never let a database problem break the reply.
    if student_code:
        try:
            session_id = log_turn(
                student_code, session_id, problem, history, reply, analysis, scaffold_level, reflection_type,
                problem_id=problem_id,
            )
        except Exception as err:
            log.error("Saving chat to database failed: %s", err)

    return {
        "reply": reply,
        "session_id": session_id,
        "hint_level": analysis["hint_level"],
        "scaffold_level": scaffold_level,
        "reflection_type": reflection_type,
    }
