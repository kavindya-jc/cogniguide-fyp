"""
Tests for the tutor agent controller (tutor_agent.py) - agent plan, Phases 1 and 2.

Offline: Gemini and Supabase are replaced by small fakes, so the tests are free and fast.
Phase 1 checked that moving the chat logic out of api.py changed nothing. Phase 2 changed the
decisions on purpose (assess -> choose an action -> check the reply -> remember), so a few
expectations below are new; each one says why.

Run from the backend/ folder:   python -m pytest tests/test_tutor_agent.py
"""

import pytest

from app import assessment, auth, db, policy, problems, tutor_agent
from app.api import app
from app.models.socratic_agent import TutorUnavailable

PROBLEM = "Natalia sold clips to 48 of her friends in April, and then she sold half as many clips in May. How many clips did Natalia sell altogether in April and May?"

# The scripted students of the Stage 8 live test (experiments/phase2_adaptive_agent/test_stage8_live.py).
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
        self.sessions, self.messages, self.indicators, self.created = {}, [], [], []
        self.states, self.solved = {}, []

    def install(self, monkeypatch):
        monkeypatch.setattr(db, "is_configured", lambda: True)
        monkeypatch.setattr(db, "find_student", lambda code: "uuid-" + code)
        monkeypatch.setattr(db, "get_recent_session_levels", lambda student, exclude_session_id=None: [])  # full support
        monkeypatch.setattr(db, "session_has_reflection", lambda sid: False)
        monkeypatch.setattr(db, "get_history_summary", lambda student, exclude_session_id=None: {"sessions": 0})
        monkeypatch.setattr(db, "get_session_state", lambda sid: self.states.get(sid, {}))
        monkeypatch.setattr(db, "save_session_state", self.save_session_state)
        monkeypatch.setattr(db, "get_or_create_student", self.get_or_create_student)
        monkeypatch.setattr(db, "create_session", self.create_session)
        monkeypatch.setattr(db, "session_belongs_to", lambda sid, student: self.sessions.get(sid) == student)
        monkeypatch.setattr(db, "save_messages", lambda sid, msgs: self.messages.extend((sid, r, c) for r, c in msgs))
        monkeypatch.setattr(db, "save_indicators", lambda student, sid, rows: self.indicators.extend(rows))

    def get_or_create_student(self, code):
        if self.broken:
            raise RuntimeError("database is down")
        return "uuid-" + code

    def save_session_state(self, sid, state, solved=False):
        self.states[sid] = state
        if solved:
            self.solved.append(sid)

    def create_session(self, student, problem, problem_id=None):
        sid = f"session-{len(self.sessions) + 1}"
        self.sessions[sid] = student
        self.created.append({"problem": problem, "problem_id": problem_id})
        return sid


@pytest.fixture
def tutor(monkeypatch):
    fake = FakeTutor()
    monkeypatch.setattr(tutor_agent, "socratic_response", fake)
    return fake


def play(code, messages, problem=PROBLEM, problem_id=None):
    """Play a whole chat through run_turn, like the app does. Returns the list of results."""
    history, results, session_id = [], [], None
    result = tutor_agent.run_turn(code, problem, history, session_id, problem_id)  # the tutor opens the chat
    for message in [None] + messages:
        if message is not None:
            history.append({"role": "student", "content": message})
            result = tutor_agent.run_turn(code, problem, history, session_id, problem_id)
            results.append(result)
        session_id = result["session_id"]
        history.append({"role": "teacher", "content": result["reply"]})
    return results


# ---- The basics (unchanged from Phase 1) ----

def test_reply_has_the_same_fields_as_before(tutor):
    result = tutor_agent.run_turn(None, PROBLEM, [])
    assert set(result) == {"reply", "session_id", "hint_level", "scaffold_level", "reflection_type"}
    assert result["reply"] == "What do you notice?"
    assert tutor.calls[0]["raise_on_error"] is True


# Without Gemini (the test safety net has no key), the student check falls back to the word rules.
# Stage 8 recorded [2, 3, 3, 2]; Phase 2 gives [2, 3, 3, 1]: after "Ok, I think the first number
# is 48" the help no longer stays at "a little stuck" (2) - asking for the answer and then trying
# again does not need a hint, only a guiding question (1).
@pytest.mark.parametrize("messages, levels", [(STRUGGLING, [2, 3, 3, 1]), (STRONG, [1, 1, 1, 1])])
def test_hint_levels_with_the_word_rules(tutor, messages, levels):
    assert [r["hint_level"] for r in play(None, messages)] == levels


def test_asking_for_the_answer_gets_a_kind_no(tutor):
    history = [{"role": "teacher", "content": "Where do you start?"},
               {"role": "student", "content": "Just tell me the answer."}]
    tutor_agent.run_turn(None, PROBLEM, history)
    extra = tutor.calls[0]["extra"]
    assert extra.startswith("ACTION: Ask ONE open guiding question")
    assert "asked you to just give the answer" in extra
    assert "Never state the final answer" in extra


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


def test_gemini_failure_saves_nothing_with_the_safe_reply_off(monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    monkeypatch.setattr(tutor_agent, "SAFE_REPLY_WHEN_BUSY", False)
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


def test_chat_endpoint_busy_tutor_gives_503_with_the_safe_reply_off(client, monkeypatch):
    monkeypatch.setattr(tutor_agent, "SAFE_REPLY_WHEN_BUSY", False)
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


# ---- Step 1.4: /chat knows which bank problem it is ----

def login_header(code="P001"):
    return {"Authorization": "Bearer " + auth.make_token(code)}


def test_problem_id_uses_the_bank_text(tutor, client, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    r = client.post("/chat", json={"problem_id": "alg-9-1", "history": []}, headers=login_header())
    assert r.status_code == 200
    assert tutor.calls[0]["problem"] == "Solve: 3x − 5 = 2x + 7"  # the server's own text
    assert store.created == [{"problem": "Solve: 3x − 5 = 2x + 7", "problem_id": "alg-9-1"}]


def test_problem_id_wins_over_the_text_from_the_app(tutor, client, monkeypatch):
    FakeDb().install(monkeypatch)
    r = client.post("/chat", json={"problem_id": "alg-9-1", "problem": "Something else", "history": []},
                    headers=login_header())
    assert r.status_code == 200
    assert tutor.calls[0]["problem"] == "Solve: 3x − 5 = 2x + 7"


def test_old_requests_without_problem_id_work_as_before(tutor, client, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    r = client.post("/chat", json={"problem": PROBLEM, "history": []}, headers=login_header())
    assert r.status_code == 200
    assert store.created == [{"problem": PROBLEM, "problem_id": None}]


@pytest.mark.parametrize("body", [
    {"problem_id": "no-such-problem", "history": []},  # not in the bank
    {"problem_id": "ALG 9 1", "history": []},          # not an id at all
    {"problem_id": 7, "history": []},                  # not text
    {"history": []},                                   # neither problem nor problem_id
])
def test_bad_problem_id_gives_400(tutor, client, body):
    r = client.post("/chat", json=body)
    assert r.status_code == 400
    assert r.get_json()["error"]["code"] == "invalid_request"
    assert tutor.calls == []  # Gemini is not asked


def test_broken_problem_bank_gives_503(tutor, client, monkeypatch):
    from app import problems

    def broken(_problem_id):
        raise problems.ProblemBankError("secret path details")

    monkeypatch.setattr(problems, "find", broken)
    r = client.post("/chat", json={"problem_id": "alg-9-1", "history": []})
    assert r.status_code == 503
    assert "secret path" not in r.get_data(as_text=True)


class FakeTable:
    """Records what db.create_session sends to Supabase."""

    def __init__(self, sent):
        self.sent = sent

    def insert(self, row):
        self.sent.append(row)
        return self

    def execute(self):
        return type("Result", (), {"data": [{"id": "new-session"}]})()


class FakeClient:
    def __init__(self):
        self.sent = []

    def table(self, name):
        assert name == "sessions"
        return FakeTable(self.sent)


def test_create_session_saves_problem_id_only_when_given(monkeypatch):
    fake = FakeClient()
    monkeypatch.setattr(db, "_get_client", lambda: fake)
    assert db.create_session("uuid-1", "Solve: 3x − 5 = 2x + 7", problem_id="alg-9-1") == "new-session"
    db.create_session("uuid-1", "My own problem")
    assert fake.sent == [
        {"student_id": "uuid-1", "problem": "Solve: 3x − 5 = 2x + 7", "problem_id": "alg-9-1"},
        {"student_id": "uuid-1", "problem": "My own problem"},  # no problem_id key at all
    ]


# ---- Phase 2: assess -> decide -> act -> check -> remember ----

ALG = "Solve: 3x − 5 = 2x + 7"  # bank problem alg-9-1, answer x = 12


def check_says(**fields):
    """What a (pretend) Gemini check returns for one student message."""
    raw = {"intent": "answer_attempt", "correctness": "unclear", "current_step": 1, "final_answer_given": False,
           "solved": False, "mistake_id": "none", "mistake_confidence": 0.0, "self_corrected": False,
           "reasoning_shown": "partial", "evidence": ""}
    raw.update(fields)
    return raw


@pytest.fixture
def gemini_check(monkeypatch):
    """Script the Gemini student check: give it the list of forms, one per student message."""
    asked = []

    def install(*forms):
        script = list(forms)

        def fake_generate_json(prompt, schema, system_instruction="", temperature=0.1, **_kw):
            asked.append(prompt)
            return script.pop(0)

        monkeypatch.setattr(assessment, "generate_json", fake_generate_json)
        return asked

    return install


def actions(tutor):
    """The ACTION line the tutor was given for each reply (opening first)."""
    return [call["extra"].splitlines()[0] for call in tutor.calls]


def test_opening_turn_does_not_check_anything(tutor, gemini_check):
    asked = gemini_check()
    tutor_agent.run_turn(None, ALG, [], problem_id="alg-9-1")
    assert asked == [] and actions(tutor)[0].startswith("ACTION: Ask ONE open guiding question")


def test_wrong_answers_get_more_help_each_time(tutor, gemini_check, monkeypatch):
    """The big fix: three wrong answers used to count as 'doing fine' (hint level 1)."""
    store = FakeDb()
    store.install(monkeypatch)
    gemini_check(*[check_says(correctness="incorrect", mistake_id="other")] * 4)
    results = play("P001", ["x = 1", "x = 3", "x = 100", "x = 7"], problem=ALG, problem_id="alg-9-1")
    assert [r["hint_level"] for r in results] == [1, 2, 3, 3]
    lines = actions(tutor)[1:]
    assert lines[0].startswith("ACTION: Something in the student's last step is not right")   # check again
    assert lines[1].startswith("ACTION: Give a SMALL hint")
    assert lines[2].startswith("ACTION: Give a CONCRETE hint")
    assert lines[3].startswith("ACTION: Explain clearly")
    memory = store.states["session-1"]
    assert memory["wrong_attempts"] == 4 and memory["hints"] == {"small": 1, "concrete": 1, "explain": 1}
    assert ("wrong_attempt", 1) in store.indicators


def test_a_known_mistake_is_addressed_once(tutor, gemini_check, monkeypatch):
    FakeDb().install(monkeypatch)
    sign_error = check_says(correctness="incorrect", mistake_id="sign_when_moving", mistake_confidence=0.9)
    gemini_check(sign_error, sign_error)
    play("P001", ["x = 2", "x = 2 again"], problem=ALG, problem_id="alg-9-1")
    first, second = tutor.calls[1]["extra"], tutor.calls[2]["extra"]
    assert "Moves −5 to the other side without changing its sign" in first
    assert second.startswith("ACTION: Give a SMALL hint")  # not the same mistake talk twice


def test_correct_answer_is_confirmed_even_if_gemini_misses_it(tutor, gemini_check, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    gemini_check(check_says(correctness="incorrect"))  # Gemini is wrong here; Python's answer check wins
    results = play("P001", ["So x = 12"], problem=ALG, problem_id="alg-9-1")
    assert actions(tutor)[1].startswith("ACTION: The student has the complete, correct final answer")
    assert results[0]["hint_level"] == 1
    assert store.solved == ["session-1"] and store.states["session-1"]["solved"] is True
    assert ("solved", 1) in store.indicators


def test_gemini_cannot_declare_solved_without_the_answer(tutor, gemini_check):
    gemini_check(check_says(correctness="correct", solved=True, final_answer_given=True))
    play(None, ["x = 2"], problem=ALG, problem_id="alg-9-1")
    assert not actions(tutor)[1].startswith("ACTION: The student has the complete")


def test_asking_for_the_answer_never_climbs_the_ladder(tutor, gemini_check, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    gemini_check(*[check_says(intent="asks_for_answer", correctness="not_applicable")] * 3)
    results = play("P001", ["tell me", "just tell me", "what is the answer"], problem=ALG, problem_id="alg-9-1")
    assert [r["hint_level"] for r in results] == [1, 1, 1]
    assert store.states["session-1"]["answer_requests"] == 3


class LeakyTutor(FakeTutor):
    """A pretend Gemini that gives away the answer the first `leaks` times."""

    def __init__(self, leaks):
        super().__init__()
        self.leaks = leaks

    def __call__(self, problem, history, extra_instruction="", raise_on_error=False):
        super().__call__(problem, history, extra_instruction, raise_on_error)
        if self.leaks > 0:
            self.leaks -= 1
            return "Easy: x = 12."
        return "What could you do to both sides first?"


def test_a_leaking_reply_is_written_again(gemini_check, monkeypatch):
    fake = LeakyTutor(leaks=1)
    monkeypatch.setattr(tutor_agent, "socratic_response", fake)
    result = tutor_agent.run_turn(None, ALG, [{"role": "student", "content": "help"}], problem_id="alg-9-1")
    assert result["reply"] == "What could you do to both sides first?"
    assert "NOT ALLOWED because it gives away" in fake.calls[1]["extra"]


def test_two_leaks_give_the_safe_reply(gemini_check, monkeypatch):
    monkeypatch.setattr(tutor_agent, "socratic_response", LeakyTutor(leaks=2))
    gemini_check(check_says(intent="confused", correctness="not_applicable"))
    result = tutor_agent.run_turn(None, ALG, [{"role": "student", "content": "I'm lost"}], problem_id="alg-9-1")
    assert result["reply"] == policy.SAFE_REPLIES[policy.GIVE_SMALL_HINT]
    assert "12" not in result["reply"]


def test_own_problem_works_without_an_answer_sheet(tutor, gemini_check):
    asked = gemini_check(check_says(correctness="incorrect"))
    tutor_agent.run_turn(None, "Find 7 x 8.", [{"role": "student", "content": "54"}])
    assert "There is no answer sheet" in asked[0]
    assert tutor.calls[0]["extra"].startswith("ACTION: Something in the student's last step is not right")


def test_memory_is_never_written_to_someone_elses_session(tutor, gemini_check, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    store.sessions["session-9"] = "uuid-SOMEONE-ELSE"
    gemini_check(check_says())
    tutor_agent.run_turn("P001", ALG, [{"role": "student", "content": "x?"}], "session-9", "alg-9-1")
    assert store.states == {}


def test_the_answer_sheet_is_never_sent_to_the_reply_writer(tutor, gemini_check):
    """Only the CHECK sees the answer sheet; the tutor that writes to the student does not."""
    gemini_check(check_says(correctness="incorrect"))
    tutor_agent.run_turn(None, ALG, [{"role": "student", "content": "x = 3"}], problem_id="alg-9-1")
    answer = problems.find("alg-9-1")["answer"]
    for call in tutor.calls:
        assert answer not in call["extra"] and answer not in call["problem"]


# ---- Busy Google ----

def test_busy_gemini_gives_the_safe_reply_and_saves_it(monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)
    monkeypatch.setattr(tutor_agent, "socratic_response", FakeTutor(fail=True))
    result = tutor_agent.run_turn("P001", PROBLEM, [])
    assert result["reply"] == policy.SAFE_REPLIES[policy.ASK_GUIDING_QUESTION]
    assert result["session_id"] == "session-1"
    assert store.states["session-1"]["last_guard"] == "gemini_busy"


def test_busy_gemini_still_gives_the_right_kind_of_help(gemini_check, monkeypatch):
    """Check AND reply busy: Python still sees 'x = 2' is wrong, and the safe reply fits that."""
    store = FakeDb()
    store.install(monkeypatch)

    def busy_check(*args, **kwargs):
        raise TutorUnavailable("503")

    monkeypatch.setattr(assessment, "generate_json", busy_check)
    monkeypatch.setattr(tutor_agent, "socratic_response", FakeTutor(fail=True))
    results = play("P001", ["x = 1", "x = 3", "x = 100"], problem=ALG, problem_id="alg-9-1")
    assert [r["hint_level"] for r in results] == [1, 2, 3]
    assert results[0]["reply"] == policy.SAFE_REPLIES[policy.ENCOURAGE_SELF_CORRECTION]
    assert store.states["session-1"]["wrong_attempts"] == 3


def test_x_equals_2_counts_as_a_wrong_try_when_the_check_is_busy(tutor, monkeypatch):
    store = FakeDb()
    store.install(monkeypatch)

    def busy_check(*args, **kwargs):
        raise TutorUnavailable("503")

    monkeypatch.setattr(assessment, "generate_json", busy_check)
    play("P001", ["x = 2"], problem=ALG, problem_id="alg-9-1")
    assert "Moves −5 to the other side without changing its sign" in tutor.calls[1]["extra"]
    assert store.states["session-1"]["wrong_attempts"] == 1
    assert ("wrong_attempt", 1) in store.indicators


def test_busy_endpoint_still_answers(client, monkeypatch):
    monkeypatch.setattr(tutor_agent, "socratic_response", FakeTutor(fail=True))
    r = client.post("/chat", json={"problem": PROBLEM, "history": []})
    assert r.status_code == 200 and r.get_json()["reply"] == policy.SAFE_REPLIES[policy.ASK_GUIDING_QUESTION]
