"""
CogniGuide database helper - Phase 2, Stages 2, 3, 4, 5, 6 and 7

All Supabase code lives here, so api.py stays short.
Every function raises an exception if the database call fails;
api.py catches it so a database problem never breaks the chat.

Needs two secrets in .env (never commit them):
    SUPABASE_URL=...
    SUPABASE_SERVICE_KEY=...
"""

import os

from dotenv import find_dotenv, load_dotenv

load_dotenv(find_dotenv())

_client = None


def is_configured():
    """True only if both Supabase secrets are present."""
    return bool(os.getenv("SUPABASE_URL", "").strip() and os.getenv("SUPABASE_SERVICE_KEY", "").strip())


def _get_client():
    """Create the Supabase client once, the first time it is needed."""
    global _client
    if _client is None:
        from supabase import create_client  # imported here so the server starts even without the library

        _client = create_client(
            os.getenv("SUPABASE_URL", "").strip(),
            os.getenv("SUPABASE_SERVICE_KEY", "").strip(),
        )
    return _client


def get_or_create_student(anon_code):
    """Return the student's database id, creating the student on first sight."""
    res = (
        _get_client()
        .table("students")
        .upsert({"anon_code": anon_code}, on_conflict="anon_code")
        .execute()
    )
    return res.data[0]["id"]


def create_session(student_id, problem):
    """Start a new session and return its id."""
    res = _get_client().table("sessions").insert({"student_id": student_id, "problem": problem}).execute()
    return res.data[0]["id"]


def session_belongs_to(session_id, student_id):
    """True if this session exists and belongs to this student."""
    res = (
        _get_client()
        .table("sessions")
        .select("id")
        .eq("id", session_id)
        .eq("student_id", student_id)
        .limit(1)
        .execute()
    )
    return bool(res.data)


def save_messages(session_id, messages):
    """Save a list of (role, content) pairs in order, in one database call."""
    rows = [{"session_id": session_id, "role": role, "content": content} for role, content in messages]
    _get_client().table("messages").insert(rows).execute()


def save_indicators(student_id, session_id, indicators):
    """Stage 4: save a list of (indicator_type, value) pairs, in one database call.

    Example: [("hint_level", 2), ("self_correction", 1)]
    """
    if not indicators:
        return
    rows = [
        {"student_id": student_id, "session_id": session_id, "indicator_type": kind, "value": value}
        for kind, value in indicators
    ]
    _get_client().table("indicators").insert(rows).execute()


def find_student(anon_code):
    """Stage 5: return the student's database id, or None if we have never seen this code.

    Unlike get_or_create_student, this does NOT create anything.
    """
    res = (
        _get_client()
        .table("students")
        .select("id")
        .eq("anon_code", anon_code)
        .limit(1)
        .execute()
    )
    return res.data[0]["id"] if res.data else None


def get_recent_session_levels(student_id, exclude_session_id=None, max_sessions=3):
    """Stage 5: average hint level of this student's newest EARLIER sessions, newest first.

    Example result: [1.0, 1.33, 2.67]  (one number per earlier session)
    The session in progress (exclude_session_id) is left out.
    """
    res = (
        _get_client()
        .table("indicators")
        .select("session_id, value")
        .eq("student_id", student_id)
        .eq("indicator_type", "hint_level")
        .order("created_at", desc=True)
        .order("id", desc=True)
        .limit(300)
        .execute()
    )

    per_session = {}  # session_id -> list of levels; dict keeps the newest-first order
    for row in res.data or []:
        sid = row.get("session_id")
        if sid is None or sid == exclude_session_id or row.get("value") is None:
            continue
        per_session.setdefault(sid, []).append(float(row["value"]))

    averages = [sum(levels) / len(levels) for levels in per_session.values()]
    return averages[:max_sessions]


# The indicator types that describe how a student worked in an earlier session.
HISTORY_INDICATORS = ["hint_level", "stuck", "asked_for_answer", "self_correction"]


def get_history_summary(student_id, exclude_session_id=None, max_sessions=3):
    """Stage 6: a short summary of this student's newest EARLIER sessions (numbers only).

    Reads only this student's own indicator rows. It never reads message text.
    Example result:
        {"sessions": 3, "averages": [1.0, 1.5, 3.0],      # average hint level, newest session first
         "stuck": 4, "asked_for_answer": 1, "self_correction": 2}   # totals over those sessions
    The session in progress (exclude_session_id) is left out.
    """
    res = (
        _get_client()
        .table("indicators")
        .select("session_id, indicator_type, value")
        .eq("student_id", student_id)
        .in_("indicator_type", HISTORY_INDICATORS)
        .order("created_at", desc=True)
        .order("id", desc=True)
        .limit(600)
        .execute()
    )

    per_session = {}  # session_id -> list of rows; dict keeps the newest-first order
    for row in res.data or []:
        sid = row.get("session_id")
        if sid is None or sid == exclude_session_id or row.get("value") is None:
            continue
        per_session.setdefault(sid, []).append(row)

    newest = list(per_session.values())[:max_sessions]
    summary = {"sessions": len(newest), "averages": [], "stuck": 0, "asked_for_answer": 0, "self_correction": 0}
    for rows in newest:
        levels = [float(r["value"]) for r in rows if r.get("indicator_type") == "hint_level"]
        if levels:
            summary["averages"].append(sum(levels) / len(levels))
        for kind in ("stuck", "asked_for_answer", "self_correction"):
            summary[kind] += sum(1 for r in rows if r.get("indicator_type") == kind)
    return summary


def session_has_reflection(session_id):
    """Stage 6: True if a reflection question was already asked in this session.

    Every reflection that is asked is saved as an indicator whose type starts with "reflection_".
    """
    res = (
        _get_client()
        .table("indicators")
        .select("id")
        .eq("session_id", session_id)
        .like("indicator_type", "reflection_%")
        .limit(1)
        .execute()
    )
    return bool(res.data)


# Stage 7: how many of the newest sessions the progress dashboard shows.
PROGRESS_MAX_SESSIONS = 10
# Supabase gives at most 1000 rows per call, so we read the indicator rows page by page.
_PAGE_SIZE = 1000
_MAX_PAGES = 5


def get_progress_rows(student_id, max_sessions=PROGRESS_MAX_SESSIONS):
    """Stage 7: the raw rows the progress dashboard needs, for THIS student only.

    Returns (sessions, indicators):
        sessions   - the student's newest sessions, NEWEST first: [{"id": ..., "started_at": ...}, ...]
        indicators - the indicator rows of those sessions, oldest first:
                     [{"session_id": ..., "indicator_type": ..., "value": ...}, ...]
    Numbers only: it never reads message text.
    """
    client = _get_client()
    res = (
        client.table("sessions")
        .select("id, started_at")
        .eq("student_id", student_id)
        .order("started_at", desc=True)
        .limit(max_sessions)
        .execute()
    )
    sessions = res.data or []
    if not sessions:
        return [], []

    session_ids = [s["id"] for s in sessions]
    indicators = []
    for page in range(_MAX_PAGES):
        start = page * _PAGE_SIZE
        res = (
            client.table("indicators")
            .select("session_id, indicator_type, value")
            .eq("student_id", student_id)
            .in_("session_id", session_ids)
            .order("id")
            .range(start, start + _PAGE_SIZE - 1)
            .execute()
        )
        batch = res.data or []
        indicators.extend(batch)
        if len(batch) < _PAGE_SIZE:
            break
    return sessions, indicators
