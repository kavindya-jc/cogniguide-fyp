"""
pytest settings for the backend tests.

The Stage 4-7c test files are plain scripts: they run their checks when they are
started and stop with sys.exit(). pytest must not import them directly (the
sys.exit would stop pytest), so they are skipped here and test_check_scripts.py
runs each one on its own instead. New tests are normal pytest files.
"""

# The older check scripts, run by test_check_scripts.py.
CHECK_SCRIPTS = [
    "test_adaptive.py",
    "test_auth.py",
    "test_progress.py",
    "test_reflection.py",
    "test_scaffolding.py",
]

collect_ignore = CHECK_SCRIPTS


import pytest  # noqa: E402

from app import db  # noqa: E402
from app.models import socratic_agent  # noqa: E402


@pytest.fixture(autouse=True)
def no_real_gemini_or_supabase(monkeypatch):
    """Safety net for every pytest test: never call the real Gemini or the real Supabase.

    The project's .env has real keys, so without this a test that forgets a fake would spend
    the Gemini quota or write to the real database. With no key, Gemini calls stop at once
    (EnvironmentError); the database counts as "not set up", and any real database call fails
    loudly unless the test installs a fake.
    """
    monkeypatch.setattr(socratic_agent, "API_KEY", "")
    monkeypatch.setattr(socratic_agent, "_client", None)
    monkeypatch.setattr(db, "is_configured", lambda: False)

    def no_real_database():
        raise RuntimeError("A test tried to use the real Supabase. Give it a fake database.")

    monkeypatch.setattr(db, "_get_client", no_real_database)
