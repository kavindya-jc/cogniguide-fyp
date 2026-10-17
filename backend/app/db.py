"""
CogniGuide database helper - Phase 2, Stages 2, 3, 4 and 5

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
