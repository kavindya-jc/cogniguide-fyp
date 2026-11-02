"""
Team request: "Recent chats", so a student can carry on an old chat.

  - GET /sessions: the student's own newest chats, newest first.
  - GET /sessions/<id>/messages: one of their own chats with its messages in order.
  - Both need the login token, and nobody can read another student's chat.

The database is a fake (conftest.py blocks the real Supabase).
"""

import pytest

from app import auth, db
from app.api import app

MINE = "11111111-1111-4111-8111-111111111111"
THEIRS = "22222222-2222-4222-8222-222222222222"

SESSIONS = {
    MINE: {
        "id": MINE,
        "student": "uuid-p001",
        "problem": "Solve: 3x − 5 = 2x + 7",
        "problem_id": "alg-01",
        "status": "solved",
        "started_at": "2026-10-30T10:00:00+00:00",
        "messages": [
            {"role": "teacher", "content": "Hello! What do you notice?"},
            {"role": "student", "content": "x = 12"},
            {"role": "teacher", "content": "How can you check it?"},
        ],
    },
    THEIRS: {
        "id": THEIRS,
        "student": "uuid-p002",
        "problem": "Find 20% of 350.",
        "problem_id": None,
        "status": None,
        "started_at": "2026-10-30T11:00:00+00:00",
        "messages": [{"role": "student", "content": "secret"}],
    },
}


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("AUTH_SECRET", "test-secret-for-the-recent-chats-tests-0123456789")
    monkeypatch.setattr(db, "is_configured", lambda: True)
    monkeypatch.setattr(db, "find_student", lambda code: {"P001": "uuid-p001", "P002": "uuid-p002"}.get(code))

    def recent(student_id, limit=db.RECENT_CHATS_LIMIT):
        rows = [s for s in SESSIONS.values() if s["student"] == student_id]
        return sorted(rows, key=lambda s: s["started_at"], reverse=True)[:limit]

    def one(session_id, student_id):
        s = SESSIONS.get(session_id)
        return s if s and s["student"] == student_id else None

    monkeypatch.setattr(db, "get_recent_chats", recent)
    monkeypatch.setattr(db, "get_chat_for_student", one)
    return app.test_client()


def login(code="P001"):
    return {"Authorization": "Bearer " + auth.make_token(code)}


def test_the_list_has_only_my_chats(client):
    r = client.get("/sessions", headers=login())
    assert r.status_code == 200
    chats = r.get_json()["sessions"]
    assert [c["session_id"] for c in chats] == [MINE]
    assert chats[0] == {
        "session_id": MINE,
        "problem": "Solve: 3x − 5 = 2x + 7",
        "problem_id": "alg-01",
        "status": "solved",
        "started_at": "2026-10-30T10:00:00+00:00",
    }
    assert r.headers["Cache-Control"] == "no-store"


def test_a_chat_with_no_status_counts_as_active(client):
    chats = client.get("/sessions", headers=login("P002")).get_json()["sessions"]
    assert chats[0]["status"] == "active"


def test_a_new_student_has_no_chats(client):
    r = client.get("/sessions", headers=login("NEW1"))
    assert r.status_code == 200
    assert r.get_json() == {"sessions": []}


def test_my_chat_comes_back_with_its_messages_in_order(client):
    r = client.get(f"/sessions/{MINE}/messages", headers=login())
    assert r.status_code == 200
    body = r.get_json()
    assert body["problem"] == "Solve: 3x − 5 = 2x + 7"
    assert body["problem_id"] == "alg-01"
    assert [m["content"] for m in body["messages"]] == [
        "Hello! What do you notice?",
        "x = 12",
        "How can you check it?",
    ]
    assert set(body["messages"][0]) == {"role", "content"}


def test_another_students_chat_is_not_found(client):
    r = client.get(f"/sessions/{THEIRS}/messages", headers=login())
    assert r.status_code == 404
    assert "secret" not in r.get_data(as_text=True)


@pytest.mark.parametrize("path", ["/sessions", f"/sessions/{MINE}/messages"])
def test_login_is_needed(client, path):
    assert client.get(path).status_code == 401
    assert client.get(path, headers={"Authorization": "Bearer not-a-token"}).status_code == 401


def test_a_bad_id_is_not_found(client):
    assert client.get("/sessions/not-a-uuid/messages", headers=login()).status_code == 404


def test_database_trouble_gives_a_calm_503(client, monkeypatch):
    def broken(*args, **kwargs):
        raise RuntimeError("database is down")

    monkeypatch.setattr(db, "get_recent_chats", broken)
    r = client.get("/sessions", headers=login())
    assert r.status_code == 503
    assert r.get_json()["error"]["code"] == "chats_unavailable"
