"""
Tests for the research data - agent plan, Phases 3 and 4.

  - every tutor reply is logged in agent_turns (labels only, never message text)
  - POST /session/end: "I worked it out!" is checked against the server's own memory
  - hints fade per maths area (Stage 5 + Phase 4)
  - progress shows solved problems and uses behaviour words, not claims about thinking

Offline: Gemini and Supabase are fakes. Run from backend/:   python -m pytest tests/test_research_data.py
"""

import pytest

from app import auth, db, progress, tutor_agent
from app.api import app

from test_tutor_agent import ALG, FakeDb, FakeTutor, check_says, play  # noqa: F401 (fixtures below)
from test_tutor_agent import gemini_check, tutor  # noqa: F401  (pytest fixtures)


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("AUTH_SECRET", "test-secret-for-the-research-data-tests-0123456789")
    return app.test_client()


def login(code="P001"):
    return {"Authorization": "Bearer " + auth.make_token(code)}


# ---- The decision log ----

def test_every_reply_is_logged(tutor, gemini_check, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    gemini_check(check_says(correctness="incorrect", mistake_id="other", evidence="x = 3 secret words"))
    play("P001", ["x = 3"], problem=ALG, problem_id="alg-9-1")
    opening, answer = store.agent_turns
    assert opening["action"] == "ASK_GUIDING_QUESTION" and opening["intent"] is None
    assert answer["action"] == "ENCOURAGE_SELF_CORRECTION" and answer["correctness"] == "incorrect"
    assert answer["problem_id"] == "alg-9-1" and answer["check_source"] == "llm" and answer["guard"] == "ok"
    assert answer["needed_level"] == 1 and answer["hint_level"] == 1 and isinstance(answer["latency_ms"], int)
    assert "secret words" not in str(store.agent_turns)  # never message text


def test_anonymous_chats_are_not_logged(tutor, gemini_check, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    gemini_check(check_says())
    play(None, ["x?"], problem=ALG, problem_id="alg-9-1")
    assert store.agent_turns == []


def test_log_failure_does_not_break_the_chat(tutor, gemini_check, monkeypatch):
    FakeDb().install(monkeypatch)

    def table_missing(row):
        raise RuntimeError("relation agent_turns does not exist")

    monkeypatch.setattr(db, "save_agent_turn", table_missing)
    gemini_check(check_says())
    results = play("P001", ["x?"], problem=ALG, problem_id="alg-9-1")
    assert results[0]["reply"] == "What do you notice?"


# ---- "I worked it out!" ----

def solved_session(store, monkeypatch, gemini_check, answer):
    gemini_check(check_says(correctness="unclear"))
    play("P001", [answer], problem=ALG, problem_id="alg-9-1")
    return "session-1"


def test_worked_it_out_is_verified(tutor, gemini_check, client, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    sid = solved_session(store, monkeypatch, gemini_check, "x = 12")
    # the fake session ids are not real uuids, so the endpoint gets a real-looking one mapped to it
    real = "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b"
    store.sessions[real] = store.sessions[sid]
    store.states[real] = store.states[sid]
    r = client.post("/session/end", json={"session_id": real, "reason": "worked_it_out"}, headers=login())
    assert r.status_code == 200 and r.get_json() == {"status": "solved", "verified": True}
    assert (real, "solved") in store.ended and ("claimed_solved", 1) in store.indicators


def test_worked_it_out_without_the_answer_is_not_verified(tutor, gemini_check, client, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    sid = solved_session(store, monkeypatch, gemini_check, "I think I get it")
    real = "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b"
    store.sessions[real] = store.sessions[sid]
    store.states[real] = store.states[sid]
    r = client.post("/session/end", json={"session_id": real, "reason": "worked_it_out"}, headers=login())
    assert r.get_json() == {"status": "ended", "verified": False}
    assert ("claimed_solved", 0) in store.indicators


def test_leaving_records_no_claim(client, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    real = "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b"
    store.sessions[real] = "uuid-P001"
    r = client.post("/session/end", json={"session_id": real, "reason": "left"}, headers=login())
    assert r.get_json() == {"status": "ended", "verified": False}
    assert store.indicators == []


@pytest.mark.parametrize("body, headers, status", [
    ({"session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b", "reason": "worked_it_out"}, {}, 401),  # no login
    ({"session_id": "not-a-session", "reason": "left"}, None, 400),
    ({"session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b", "reason": "bored"}, None, 400),
    ({"session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b", "reason": "left"}, None, 404),  # not this student's
])
def test_session_end_errors(client, monkeypatch, body, headers, status):
    FakeDb().install(monkeypatch)
    r = client.post("/session/end", json=body, headers=login() if headers is None else headers)
    assert r.status_code == status


# ---- Hints fade per maths area ----

def test_scaffold_uses_only_the_same_area(monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    store.sessions.update({"s-alg": "uuid-P001", "s-geo": "uuid-P001", "s-own": "uuid-P001"})
    store.created[:] = [{"problem": "", "problem_id": "alg-10-1"}, {"problem": "", "problem_id": "geo-8-1"},
                        {"problem": "", "problem_id": None}]
    asked = {}

    def levels(student, ids, exclude_session_id=None, max_sessions=3):
        asked["ids"] = ids
        return [1.0, 1.0, 1.0]

    monkeypatch.setattr(db, "get_area_session_levels", levels)
    assert tutor_agent.load_scaffold_level("P001", None, "algebra") == 1
    assert asked["ids"] == ["s-alg"]  # not the geometry one, not the typed-in one


def test_typed_in_problem_uses_all_sessions(monkeypatch):
    FakeDb().install(monkeypatch)
    monkeypatch.setattr(db, "get_recent_session_levels", lambda s, exclude_session_id=None: [3.0, 3.0])
    assert tutor_agent.load_scaffold_level("P001", None, None) == 3


# ---- Progress ----

def rows(session, *kinds):
    return [{"session_id": session, "indicator_type": k, "value": v} for k, v in kinds]


def test_progress_counts_solved_and_wrong_tries():
    sessions = [{"id": "b", "started_at": "2026-10-02"}, {"id": "a", "started_at": "2026-10-01"}]
    indicators = rows("a", ("hint_level", 2), ("wrong_attempt", 1), ("wrong_attempt", 1)) + \
        rows("b", ("hint_level", 1), ("solved", 1))
    body = progress.build_progress("P001", sessions, indicators)
    assert [s["solved"] for s in body["sessions"]] == [False, True]
    assert [s["wrong_attempts"] for s in body["sessions"]] == [2, 0]
    assert body["totals"]["solved"] == 1


def test_growth_words_describe_behaviour_not_thinking():
    for message in progress.GROWTH_MESSAGES.values():
        assert "thinker" not in message and "thinking is growing" not in message
