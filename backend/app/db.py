"""
CogniGuide database helper - Phase 2, Stages 2 and 3

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
