"""
CogniGuide student check ("assessment") - agent plan, Phase 2

Before the tutor replies, it looks at the student's NEWEST message and fills in a short form:
what the student is doing, whether it is right, which common mistake it shows, and so on.

    1. Gemini fills in the form (socratic_agent.generate_json, a JSON schema, low temperature).
    2. Python checks every value. Anything unknown becomes a safe value ("unclear", "none").
    3. For a bank problem, Python's answer checker (answer_check.py) has the last word on
       "solved": Gemini cannot declare a problem solved when the real answer is not there,
       and a message with the whole right answer is solved even if Gemini missed it.
    4. If Gemini fails (busy, bad JSON...), the simple word rules of adaptive.py fill in the
       form instead (source = "fallback"). The chat never breaks because of this step.

Never trust the form blindly: the values are evidence for policy.py, not facts.
The form holds labels and one short quote at most; it is never shown to the student.
"""

import logging

from app import adaptive, answer_check
from app.models.socratic_agent import TutorUnavailable, generate_json

log = logging.getLogger(__name__)

INTENTS = ("answer_attempt", "step_attempt", "explanation", "question", "confused",
           "asks_for_answer", "off_topic", "other")
CORRECTNESS = ("correct", "partially_correct", "incorrect", "not_applicable", "unclear")
REASONING = ("none", "partial", "clear")

# How many earlier chat items Gemini sees (enough for the current step, keeps the call small).
CONTEXT_ITEMS = 10
MAX_EVIDENCE = 160

SCHEMA = {
    "type": "object",
    "properties": {
        "intent": {"type": "string", "enum": list(INTENTS),
                   "description": "What the newest student message mainly does."},
        "correctness": {"type": "string", "enum": list(CORRECTNESS),
                        "description": "Is the maths in the newest student message right?"},
        "current_step": {"type": "integer",
                         "description": "Which key step (1, 2, ...) the student is working on; 0 if unknown."},
        "final_answer_given": {"type": "boolean",
                               "description": "Did the student state a final answer to the whole problem?"},
        "solved": {"type": "boolean",
                   "description": "Has the student now given the complete, correct final answer?"},
        "mistake_id": {"type": "string",
                       "description": "The id of the common mistake shown, 'other' for a different mistake, or 'none'."},
        "mistake_confidence": {"type": "number", "description": "0 to 1: how sure you are about mistake_id."},
        "self_corrected": {"type": "boolean",
                           "description": "Did the student notice and fix their OWN earlier mistake?"},
        "reasoning_shown": {"type": "string", "enum": list(REASONING),
                            "description": "Did the student explain how or why, not just give a number?"},
        "evidence": {"type": "string", "description": "A very short quote from the student's message."},
    },
    "required": ["intent", "correctness", "current_step", "final_answer_given", "solved",
                 "mistake_id", "mistake_confidence", "self_corrected", "reasoning_shown"],
}

SYSTEM_INSTRUCTION = (
    "You are checking a teenager's maths work for a tutor. You do NOT talk to the student. "
    "Judge ONLY the student's newest message, using the problem, the answer sheet and the chat. "
    "Be strict and honest: if the maths is wrong, say incorrect; if you cannot tell, say unclear. "
    "A message that only repeats numbers from the problem is not a correct step. "
    "'solved' is true only when the student has given the complete, correct final answer. "
    "Fill in every field of the form."
)


def _transcript(history):
    lines = []
    for turn in history[-CONTEXT_ITEMS:]:
        speaker = "Tutor" if turn.get("role") == "teacher" else "Student"
        lines.append(f"{speaker}: {turn.get('content', '').strip()}")
    return "\n".join(lines)


def build_prompt(problem_text, problem, history):
    """The question for Gemini. The answer sheet is included for bank problems (never shown to students)."""
    parts = [f"Problem: {problem_text}"]
    if problem:
        parts.append(f"Answer sheet (secret): {problem['answer']}")
        parts.append("Key steps:\n" + "\n".join(f"{i}. {s}" for i, s in enumerate(problem["steps"], 1)))
        if problem.get("mistakes"):
            parts.append("Common mistakes (use these ids for mistake_id):\n" + "\n".join(
                f"- {m['id']}: {m['description']}" for m in problem["mistakes"]))
    else:
        parts.append("There is no answer sheet: the student typed this problem in. Work out the answer yourself carefully.")
    parts.append("Chat so far:\n" + _transcript(history))
    parts.append("Fill in the form about the student's NEWEST message.")
    return "\n\n".join(parts)


def _pick(value, allowed, default):
    return value if value in allowed else default


def validate(raw, problem):
    """Turn Gemini's answer into a safe form: every value checked, unknown values replaced."""
    mistake_ids = {m["id"] for m in (problem or {}).get("mistakes", [])}
    steps = len((problem or {}).get("steps", [])) or 6

    mistake = raw.get("mistake_id") if isinstance(raw.get("mistake_id"), str) else "none"
    if mistake not in mistake_ids and mistake != "none":
        mistake = "other"
    try:
        confidence = min(1.0, max(0.0, float(raw.get("mistake_confidence", 0))))
    except (TypeError, ValueError):
        confidence = 0.0
    step = raw.get("current_step")
    step = step if isinstance(step, int) and not isinstance(step, bool) and 0 <= step <= steps else 0

    return {
        "intent": _pick(raw.get("intent"), INTENTS, "other"),
        "correctness": _pick(raw.get("correctness"), CORRECTNESS, "unclear"),
        "current_step": step,
        "final_answer_given": raw.get("final_answer_given") is True,
        "solved": raw.get("solved") is True,
        "mistake_id": mistake,
        "mistake_confidence": confidence if mistake != "none" else 0.0,
        "self_corrected": raw.get("self_corrected") is True,
        "reasoning_shown": _pick(raw.get("reasoning_shown"), REASONING, "none"),
        "evidence": str(raw.get("evidence", ""))[:MAX_EVIDENCE],
        "source": "llm",
        "answer_check": None,
    }


def fallback(history):
    """The form filled in by the old word rules, when Gemini cannot help."""
    student = [t["content"] for t in history if t.get("role") == "student"]
    signs = adaptive.classify_message(student[-1]) if student else {
        "asked_for_answer": False, "stuck": False, "self_correct": False}
    if signs["asked_for_answer"]:
        intent = "asks_for_answer"
    elif signs["stuck"]:
        intent = "confused"
    else:
        intent = "other"
    return {
        "intent": intent, "correctness": "unclear", "current_step": 0, "final_answer_given": False,
        "solved": False, "mistake_id": "none", "mistake_confidence": 0.0,
        "self_corrected": signs["self_correct"], "reasoning_shown": "none", "evidence": "",
        "source": "fallback", "answer_check": None,
    }


def apply_answer_check(form, newest_message, problem):
    """Python's answer checker has the last word on 'solved' for a bank problem."""
    if not problem:
        return form
    check = answer_check.check_final_answer(newest_message, problem)
    form = dict(form)
    form["answer_check"] = "correct" if check["all_correct"] else (
        "partial" if check["parts_found"] else "not_found")
    if check["all_correct"]:
        form["solved"] = True
        form["final_answer_given"] = True
        form["correctness"] = "correct"
        if form["intent"] in ("other", "question", "confused", "asks_for_answer"):
            form["intent"] = "answer_attempt"
    elif form["solved"]:
        # Gemini thinks it is solved, but the real answer is not in the message: do not believe it.
        form["solved"] = False
        if form["correctness"] == "correct":
            form["correctness"] = "partially_correct" if check["parts_found"] else "unclear"
    return form


def assess(problem_text, problem, history):
    """Fill in the form for the student's newest message (the last item of history).

    problem: the FULL bank problem, or None for a problem the student typed in.
    Never raises: when Gemini fails, the word rules fill in the form.
    """
    newest = history[-1]["content"] if history and history[-1].get("role") == "student" else ""
    try:
        raw = generate_json(build_prompt(problem_text, problem, history), SCHEMA,
                            system_instruction=SYSTEM_INSTRUCTION)
        form = validate(raw, problem)
    except TutorUnavailable as err:  # busy, quota, bad JSON (InvalidModelOutput)...
        log.warning("Student check by Gemini failed, using the word rules: %s", err)
        form = fallback(history)
    except Exception as err:  # e.g. no GEMINI_API_KEY: the reply step will report it
        log.warning("Student check could not run, using the word rules: %s", err)
        form = fallback(history)
    return apply_answer_check(form, newest, problem)
