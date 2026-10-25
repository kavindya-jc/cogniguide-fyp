"""
Tests for the tutor agent controller (tutor_agent.py) - agent plan, Phase 1 (Step 1.3).

Offline: Gemini and Supabase are replaced by small fakes, so the tests are free and fast.
They check that moving the chat logic out of api.py changed nothing: the same hint
levels, the same instructions for the tutor, the same saved rows and the same errors.

Run from the backend/ folder:   python -m pytest tests/test_tutor_agent.py
"""

import pytest

from app import adaptive, auth, db, tutor_agent
from app.api import app
from app.models.socratic_agent import TutorUnavailable

PROBLEM = "Natalia sold clips to 48 of her friends in April, and then she sold half as many clips in May. How many clips did Natalia sell altogether in April and May?"

# The scripted students of the Stage 8 live test (experiments/phase2_adaptive_agent/test_stage8_live.py)
# and the hint levels that run recorded in stage8_results.md.
STRUGGLING = ["I don't know how to start.", "I'm confused, I don't understand.", "Just tell me the answer.",
              "Ok, I think the first number is 48."]
STRONG = ["She sold 48 clips in April.", "In May she sold half of 48, so 24 clips.",
          "So I add 48 and 24 together.", "48 plus 24 is 72 clips altogether."]


class FakeTutor:
    """Stands in for Gemini: remembers what it was asked and gives a fixed reply."""

    def __init__(self, fail=False):
        self.fail = fail
        self.calls = []

    def __call__(self, problem, history, extra_instruction="", raise_on_error=False):
        self.calls.append({"problem": problem, "history": list(history), "extra": extra_instruction,
                           "raise_on_error": raise_on_error})
        if self.fail:
            raise TutorUnavailable("pretend 503")
        return "What do you notice?"


class FakeDb:
    """Stands in for Supabase: keeps sessions, messages and indicators in lists."""

    def __init__(self, broken=False):
        self.broken = broken
        self.sessions, self.messages, self.indicators = {}, [], []

    def install(self, monkeypatch):
        monkeypatch.setattr(db, "is_configured", lambda: True)
        monkeypatch.setattr(db, "find_student", lambda code: None)  # new student: full support, no reflection
        monkeypatch.setattr(db, "get_or_create_student", self.get_or_create_student)
        monkeypatch.setattr(db, "create_session", self.create_session)
        monkeypatch.setattr(db, "session_belongs_to", lambda sid, student: self.sessions.get(sid) == student)
        monkeypatch.setattr(db, "save_messages", lambda sid, msgs: self.messages.extend((sid, r, c) for r, c in msgs))
        monkeypatch.setattr(db, "save_indicators", lambda student, sid, rows: self.indicators.extend(rows))

    def get_or_create_student(self, code):
        if self.broken:
            raise RuntimeError("database is down")
        return "uuid-" + code

    def create_session(self, student, problem):
        sid = f"session-{len(self.sessions) + 1}"
        self.sessions[sid] = student
        return sid


@pytest.fixture
def tutor(monkeypatch):
    fake = FakeTutor()
    monkeypatch.setattr(tutor_agent, "socratic_response", fake)
    return fake


def play(code, messages):
    """Play a whole chat through run_turn, like the app does. Returns the list of results."""
    history, results, session_id = [], [], None
    result = tutor_agent.run_turn(code, PROBLEM, history, session_id)  # the tutor opens the chat
    for message in [None] + messages:
        if message is not None:
            history.append({"role": "student", "content": message})
            result = tutor_agent.run_turn(code, PROBLEM, history, session_id)
            results.append(result)
        session_id = result["session_id"]
        history.append({"role": "teacher", "content": result["reply"]})
    return results


# ---- Same decisions as before ----

def test_reply_has_the_same_fields_as_before(tutor):
    result = tutor_agent.run_turn(None, PROBLEM, [])
    assert set(result) == {"reply", "session_id", "hint_level", "scaffold_level", "reflection_type"}
    assert result["reply"] == "What do you notice?"
    assert tutor.calls[0]["raise_on_error"] is True


@pytest.mark.parametrize("messages, levels", [(STRUGGLING, [2, 3, 3, 2]), (STRONG, [1, 1, 1, 1])])
def test_hint_levels_match_the_stage8_run(tutor, messages, levels):
    assert [r["hint_level"] for r in play(None, messages)] == levels


def test_tutor_gets_the_same_instruction_as_adaptive_builds(tutor):
    history = [{"role": "teacher", "content": "Where do you start?"},
               {"role": "student", "content": "Just tell me the answer."}]
    tutor_agent.run_turn(None, PROBLEM, history)
    expected = adaptive.build_instruction(adaptive.analyze_history(history))
    assert tutor.calls[0]["extra"] == expected
    assert "HINT LEVEL 2" in expected and "asked you to just give the answer" in expected


def test_full_support_for_an_anonymous_chat(tutor):
    result = tutor_agent.run_turn(None, PROBLEM, [{"role": "student", "content": "48 clips."}])
    assert result["scaffold_level"] == 3 and result["reflection_type"] is None


# ---- Saving ----

def test_anonymous_chat_saves_nothing(tutor, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    result = tutor_agent.run_turn(None, PROBLEM, [])
    assert result["session_id"] is None
    assert store.messages == [] and store.indicators == []


def test_logged_in_chat_is_saved_like_before(tutor, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    play("P001", ["I don't know how to start."])
    assert list(store.sessions) == ["session-1"]  # one chat = one session
    assert [(r, c) for _, r, c in store.messages] == [
        ("teacher", "What do you notice?"),           # the opening
        ("student", "I don't know how to start."),
        ("teacher", "What do you notice?"),
    ]
    assert ("hint_level", 2) in store.indicators and ("stuck", 1) in store.indicators
    assert ("scaffold_level", 3) in store.indicators


def test_database_failure_still_gives_the_reply(tutor, monkeypatch):
    FakeDb(broken=True).install(monkeypatch)
    result = tutor_agent.run_turn("P001", PROBLEM, [])
    assert result["reply"] == "What do you notice?"
    assert result["session_id"] is None


def test_gemini_failure_saves_nothing(monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    monkeypatch.setattr(tutor_agent, "socratic_response", FakeTutor(fail=True))
    with pytest.raises(TutorUnavailable):
        tutor_agent.run_turn("P001", PROBLEM, [])
    assert store.sessions == {} and store.messages == []


# ---- /chat still works the same through the controller ----

@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("AUTH_SECRET", "test-secret-for-the-tutor-agent-tests-0123456789")
    return app.test_client()


def test_chat_endpoint_uses_the_controller(tutor, client, monkeypatch):
    FakeDb().install(monkeypatch)
    r = client.post("/chat", json={"problem": PROBLEM, "history": []},
                    headers={"Authorization": "Bearer " + auth.make_token("P001")})
    assert r.status_code == 200
    body = r.get_json()
    assert body["reply"] == "What do you notice?" and body["session_id"] == "session-1"


def test_chat_endpoint_busy_tutor_gives_503(client, monkeypatch):
    monkeypatch.setattr(tutor_agent, "socratic_response", FakeTutor(fail=True))
    r = client.post("/chat", json={"problem": PROBLEM, "history": []})
    assert r.status_code == 503
    assert r.get_json()["error"]["code"] == "tutor_unavailable"


def test_chat_endpoint_other_error_gives_500(client, monkeypatch):
    def no_key(*args, **kwargs):
        raise EnvironmentError("GEMINI_API_KEY environment variable not found")

    monkeypatch.setattr(tutor_agent, "socratic_response", no_key)
    r = client.post("/chat", json={"problem": PROBLEM, "history": []})
    assert r.status_code == 500
    assert "GEMINI_API_KEY" not in r.get_data(as_text=True)
