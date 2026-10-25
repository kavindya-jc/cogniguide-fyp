"""
CogniGuide progress dashboard logic - Phase 2, Stage 7

Turns the NUMBERS that Stages 4 to 6 already saved (the indicators table) into a short
progress summary for ONE student. It is used by GET /progress in api.py.

Simple rules only. There is no AI call here and no database call here (db.py reads the rows,
this file only sums them up), so it is free, fast and easy to test.

Privacy: it works with numbers only. It never reads or returns any message text, and the
reply has no session ids, names or emails.

The growth sentence:
  - We need at least 2 sessions with data (MIN_SESSIONS).
  - We look at the newest 3 of them (WINDOW) and compare the OLDEST with the NEWEST.
  - The average "help needed" level (1 = little, 3 = a lot) fell by 0.5 or more -> less_help
    rose by 0.5 or more -> more_help; otherwise -> steady. (Same 0.5 rule as Stage 6.)

Known limits (first version): the numbers come from word rules (see adaptive.py), which cannot
tell if an answer is right or wrong, so "growth" is a rough guide, not a grade. The 0.5 rule
and the 3-session window are first guesses, not tested with real teenagers (Phase 3).
"""

from app import reflection

# How many sessions we need before we say anything about growth.
MIN_SESSIONS = 2
# How many of the newest sessions we compare (oldest of these against newest of these).
WINDOW = 3
# The change in the average help level that counts as real change.
CHANGE_AT = 0.5

TREND_LESS_HELP = "less_help"
TREND_MORE_HELP = "more_help"
TREND_STEADY = "steady"
TREND_NOT_ENOUGH = "not_enough_data"

GROWTH_MESSAGES = {
    # Phase 4: the words describe what the student DID (used less help), not a claim about
    # their thinking - needing fewer hints can also come from easier problems.
    TREND_LESS_HELP: (
        "In your recent sessions you used less help than at the start. "
        "Keep saying your steps in your own words."
    ),
    TREND_MORE_HELP: (
        "Lately you have used a bit more help than before. That is normal when the problems get harder, "
        "and asking for a hint is part of learning."
    ),
    TREND_STEADY: (
        "You are working at a steady level. A good next step: say your plan in your own words before each step."
    ),
    TREND_NOT_ENOUGH: (
        "Not enough sessions yet. Come back after a couple more sessions to see how you are working."
    ),
}


def _count(rows, kind):
    return sum(1 for r in rows if r.get("indicator_type") == kind)


def _reflection_type(rows):
    """The reflection type asked in this session (a short word like 'improving'), or None."""
    prefix = "reflection_"
    for r in rows:
        kind = str(r.get("indicator_type", ""))
        if kind.startswith(prefix) and kind[len(prefix):] in reflection.REFLECTION_TYPES:
            return kind[len(prefix):]
    return None


def summarize_sessions(sessions, indicators):
    """One dictionary per session, OLDEST first. Sessions with no hint_level rows are left out.

    sessions   - list of {"id": ..., "started_at": ...}, NEWEST first (as db.get_progress_rows gives them)
    indicators - list of {"session_id", "indicator_type", "value"} rows, oldest first
    """
    by_session = {}
    for row in indicators or []:
        by_session.setdefault(row.get("session_id"), []).append(row)

    summary = []
    for session in reversed(sessions or []):
        rows = by_session.get(session.get("id"), [])
        levels = [float(r["value"]) for r in rows if r.get("indicator_type") == "hint_level" and r.get("value") is not None]
        if not levels:
            continue  # nothing from the student in this session (for example only the tutor's opening)
        allowed = [float(r["value"]) for r in rows if r.get("indicator_type") == "scaffold_level" and r.get("value") is not None]
        summary.append(
            {
                "started_at": session.get("started_at"),
                "needed_level": round(sum(levels) / len(levels), 2),
                "allowed_level": int(allowed[-1]) if allowed else None,
                "stuck": _count(rows, "stuck"),
                "asked_for_answer": _count(rows, "asked_for_answer"),
                "self_corrections": _count(rows, "self_correction"),
                "reflection_type": _reflection_type(rows),
                # Phase 2-3: from the answer checker and the tutor's decisions.
                "solved": _count(rows, "solved") > 0,
                "wrong_attempts": _count(rows, "wrong_attempt"),
            }
        )
    return summary


def growth(sessions):
    """The growth trend and the plain sentence for the student. sessions = summarize_sessions(...)."""
    recent = sessions[-WINDOW:]
    if len(recent) < MIN_SESSIONS:
        trend = TREND_NOT_ENOUGH
    else:
        change = recent[-1]["needed_level"] - recent[0]["needed_level"]
        if change <= -CHANGE_AT:
            trend = TREND_LESS_HELP
        elif change >= CHANGE_AT:
            trend = TREND_MORE_HELP
        else:
            trend = TREND_STEADY
    return {"trend": trend, "message": GROWTH_MESSAGES[trend]}


def build_progress(student_code, sessions, indicators):
    """The full /progress reply for one student. A new student (no rows) gives empty lists."""
    shown = summarize_sessions(sessions, indicators)
    totals = {
        "sessions": len(shown),
        "stuck": sum(s["stuck"] for s in shown),
        "asked_for_answer": sum(s["asked_for_answer"] for s in shown),
        "self_corrections": sum(s["self_corrections"] for s in shown),
        "reflections": sum(1 for s in shown if s["reflection_type"]),
        "solved": sum(1 for s in shown if s["solved"]),
    }
    return {"student_id": student_code, "sessions": shown, "totals": totals, "growth": growth(shown)}
