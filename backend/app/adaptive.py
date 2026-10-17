"""
CogniGuide adaptive reasoning support - Phase 2, Stages 4 and 5

Looks at the student's recent messages and decides a HINT LEVEL (1, 2 or 3).
It uses simple word rules. It does NOT call the AI, so it is free, fast,
and gives the same answer every time for the same chat.

    Level 1 = student is doing fine      -> only a guiding question, no hint
    Level 2 = student is a little stuck  -> point to the part of the problem to look at
    Level 3 = student is struggling      -> a small, concrete hint (never the answer)

Known limit (to improve later): these rules cannot tell if a number the
student gave is right or wrong. They only read signs like "I don't know",
"just tell me the answer", or "oops, let me try again".
"""

import re

# How many of the student's latest messages we look at.
WINDOW = 3

ASKED_FOR_ANSWER_PATTERNS = [
    r"\bjust tell me\b",
    r"\btell me the answer\b",
    r"\bgive me the answer\b",
    r"\bwhat'?s the answer\b",
    r"\bwhat is the answer\b",
    r"\bsolve it for me\b",
    r"\bdo it for me\b",
]

STUCK_PATTERNS = [
    r"\bi don'?t know\b",
    r"\bidk\b",
    r"\bno idea\b",
    r"\bconfused\b",
    r"\bdon'?t understand\b",
    r"\bstuck\b",
    r"\bnot sure\b",
    r"\bhelp\b",
    r"\bi give up\b",
]

SELF_CORRECT_PATTERNS = [
    r"\boops\b",
    r"\bwait\b",
    r"\bmy mistake\b",
    r"\bi made a mistake\b",
    r"\blet me try again\b",
    r"\bthat'?s wrong\b",
    r"\bthat'?s not right\b",
    r"\bi mean\b",
    r"\bactually\b",
]

HINT_INSTRUCTIONS = {
    1: (
        "HINT LEVEL 1 (the student is doing fine): Ask ONE open guiding question. "
        "Do not give any hint. Let the student do the thinking."
    ),
    2: (
        "HINT LEVEL 2 (the student is a little stuck): Point to the part of the problem "
        "to look at, or name the idea to use, then ask a question. "
        "Do not give a calculated number or the final answer."
    ),
    3: (
        "HINT LEVEL 3 (the student is struggling): Give a small, concrete hint. "
        "Break the next step into a very easy question, or show a tiny example with "
        "different numbers. Be extra warm and encouraging. "
        "Still do NOT give the final answer."
    ),
}

ASKED_FOR_ANSWER_EXTRA = (
    "The student asked you to just give the answer. Kindly say you will not do that "
    "because working it out themselves is how they get stronger, and then help with the next small step."
)

SELF_CORRECT_EXTRA = (
    "The student just noticed and fixed their own mistake. Praise that specific habit "
    "(checking and correcting yourself) in a few words, then ask the next question."
)


def _matches(text, patterns):
    text = text.lower()
    return any(re.search(p, text) for p in patterns)


def classify_message(text):
    """Return a dict of True/False signs for ONE student message."""
    return {
        "asked_for_answer": _matches(text, ASKED_FOR_ANSWER_PATTERNS),
        "stuck": _matches(text, STUCK_PATTERNS),
        "self_correct": _matches(text, SELF_CORRECT_PATTERNS),
    }


def analyze_history(history):
    """Look at the chat so far and decide the hint level for the NEXT tutor reply.

    history: list of {"role": "teacher" | "student", "content": "..."}
    """
    student_messages = [t["content"] for t in history if t.get("role") == "student"]
    recent = student_messages[-WINDOW:]
    signs = [classify_message(m) for m in recent]

    struggle_count = sum(1 for s in signs if s["asked_for_answer"] or s["stuck"])

    if struggle_count == 0:
        level = 1
    elif struggle_count == 1:
        level = 2
    else:
        level = 3

    latest = signs[-1] if signs else {"asked_for_answer": False, "stuck": False, "self_correct": False}
    latest_struggling = latest["asked_for_answer"] or latest["stuck"]

    # If the student struggled before but their newest message is fine, ease off by one level.
    if struggle_count > 0 and not latest_struggling:
        level = max(1, level - 1)

    return {
        "hint_level": level,
        # What the student needs. Stage 5 (scaffolding.py) may lower "hint_level" but never this number.
        "needed_level": level,
        "struggle_count": struggle_count,
        "latest": latest,
        # True only when the chat ends with a student message (a NEW message to learn from).
        "new_student_message": bool(history) and history[-1].get("role") == "student",
    }


def build_instruction(analysis):
    """Turn the analysis into extra text that is added to the tutor's instructions."""
    parts = [HINT_INSTRUCTIONS[analysis["hint_level"]]]
    if analysis["latest"]["asked_for_answer"]:
        parts.append(ASKED_FOR_ANSWER_EXTRA)
    if analysis["latest"]["self_correct"]:
        parts.append(SELF_CORRECT_EXTRA)
    return "\n".join(parts)


def indicator_rows(analysis):
    """List of (indicator_type, value) to save in the indicators table.

    Only for a NEW student message, so nothing is saved twice.
    """
    if not analysis["new_student_message"]:
        return []
    # Save the level the student NEEDS (Stage 5 may use a lower level, but the data must show real need).
    rows = [("hint_level", analysis.get("needed_level", analysis["hint_level"]))]
    latest = analysis["latest"]
    if latest["self_correct"]:
        rows.append(("self_correction", 1))
    if latest["asked_for_answer"]:
        rows.append(("asked_for_answer", 1))
    if latest["stuck"]:
        rows.append(("stuck", 1))
    return rows
