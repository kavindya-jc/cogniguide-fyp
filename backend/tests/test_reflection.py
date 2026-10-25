"""
Offline test for reflection.py, the new db.py reading code and /chat (Phase 2, Stage 6).

It does NOT use the internet, Gemini or Supabase, so it is free and fast.
A pretend tutor and a pretend database (kept in memory) are used instead.
Run from the repo root:   python backend\\tests\\test_reflection.py
"""

import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the backend folder

import os  # noqa: E402

# A made-up secret for the tests only (never the real one in .env).
os.environ["AUTH_SECRET"] = "test-secret-for-offline-tests-only-0123456789"

from app import adaptive, auth, db, reflection  # noqa: E402

failures = 0


def check(name, condition):
    global failures
    print(("PASS  " if condition else "FAIL  ") + name)
    if not condition:
        failures += 1


def chat(*student_messages):
    """Build a history that ends with the last student message."""
    history = [{"role": "teacher", "content": "What is the first thing the problem tells us?"}]
    for i, msg in enumerate(student_messages):
        history.append({"role": "student", "content": msg})
        if i < len(student_messages) - 1:
            history.append({"role": "teacher", "content": "Good. What next?"})
    return history


def summary(sessions=3, averages=(1.5, 1.5, 1.5), stuck=0, asked=0, fixed=0):
    return {"sessions": sessions, "averages": list(averages), "stuck": stuck,
            "asked_for_answer": asked, "self_correction": fixed}


# ---- 1. Which reflection type? ----
choose = reflection.choose_reflection_type
check("no summary -> no reflection", choose(None) is None)
check("only 1 earlier session -> no reflection", choose(summary(sessions=1, asked=5)) is None)
check("nothing special -> no reflection", choose(summary()) is None)
check("asked for the answer twice -> asks_for_answer", choose(summary(asked=2)) == "asks_for_answer")
check("asked for the answer once -> not enough", choose(summary(asked=1)) is None)
check("stuck 3 times -> often_stuck", choose(summary(stuck=3)) == "often_stuck")
check("stuck 2 times -> not enough", choose(summary(stuck=2)) is None)
check("hint level fell from 3.0 to 1.0 -> improving", choose(summary(averages=(1.0, 2.0, 3.0))) == "improving")
check("hint level fell only a little -> no reflection", choose(summary(averages=(1.4, 1.5, 1.6))) is None)
check("hint level went UP -> not improving", choose(summary(averages=(3.0, 2.0, 1.0))) is None)
check("fixed own mistakes twice -> self_checker", choose(summary(fixed=2)) == "self_checker")
check("asks_for_answer beats often_stuck", choose(summary(asked=2, stuck=5)) == "asks_for_answer")
check("often_stuck beats improving", choose(summary(stuck=3, averages=(1.0, 2.0, 3.0))) == "often_stuck")
check("improving beats self_checker", choose(summary(fixed=4, averages=(1.0, 2.0, 3.0))) == "improving")

# ---- 2. Is this a good moment? ----
good = reflection.is_good_moment


def moment(*student_messages):
    h = chat(*student_messages)
    return good(adaptive.analyze_history(h), reflection.count_student_messages(h))


check("2 student messages -> too early", moment("48 clips.", "Half of 48 is 24.") is False)
check("3 fine messages -> good moment", moment("48 clips.", "Half of 48 is 24.", "So 48 + 24.") is True)
check("newest message is 'I don't know' -> not now", moment("48 clips.", "24.", "I don't know.") is False)
check("newest message asks for the answer -> not now", moment("48 clips.", "24.", "Just tell me the answer.") is False)
check("struggled before but newest is fine -> good moment", moment("I don't know.", "I'm confused.", "Oh, 48 + 24.") is True)
check("no new student message -> not now", good(adaptive.analyze_history(chat("a", "b", "c") + [{"role": "teacher", "content": "ok"}]), 3) is False)

# ---- 3. The instruction text ----
for kind in reflection.REFLECTION_TYPES:
    text = reflection.build_reflection_instruction(kind)
    check(f"{kind}: instruction exists", text.startswith("REFLECTION NOTE:"))
    check(f"{kind}: tells the tutor not to give the answer or quote old messages",
          "do not give the answer" in text and "never quote" in text)
check("unknown type -> empty text", reflection.build_reflection_instruction("nonsense") == "")
check("indicator name", reflection.indicator_name("often_stuck") == "reflection_often_stuck")
# Stage 8: softer wording, and short replies
_asker = reflection.build_reflection_instruction("asks_for_answer")
check("asks_for_answer: soft wording (about quick answers, no 'instead of asking')",
      "quick answers" in _asker and "instead of asking" not in _asker and "Do not mention asking" in _asker)
check("every reflection note asks for a short reply (at most three sentences)",
      all("at most three short sentences" in reflection.build_reflection_instruction(k) for k in reflection.REFLECTION_TYPES))


# ---- 4. A small pretend database (kept in memory) ----
class FakeDB:
    def __init__(self):
        self.tables = {"students": [], "sessions": [], "messages": [], "indicators": []}
        self.counter = 0
        self.fail_on = None  # name of a table that raises an error when read


class Q:
    def __init__(self, store, name):
        self.store, self.name = store, name
        self.op, self.payload, self.filters, self.n, self.newest_first = "select", None, [], None, False

    def select(self, *_a, **_k):
        return self

    def insert(self, rows):
        self.op, self.payload = "insert", rows if isinstance(rows, list) else [rows]
        return self

    def upsert(self, row, on_conflict=None):
        self.op, self.payload, self.conflict = "upsert", [row], on_conflict
        return self

    def eq(self, col, val):
        self.filters.append(lambda r: r.get(col) == val)
        return self

    def in_(self, col, vals):
        self.filters.append(lambda r: r.get(col) in vals)
        return self

    def like(self, col, pattern):
        prefix = pattern.rstrip("%")
        self.filters.append(lambda r: str(r.get(col, "")).startswith(prefix))
        return self

    def order(self, _col, desc=False):
        self.newest_first = self.newest_first or desc
        return self

    def limit(self, n):
        self.n = n
        return self

    def _new_id(self):
        self.store.counter += 1
        return str(uuid.uuid4()) if self.name in ("students", "sessions") else self.store.counter

    def execute(self):
        rows = self.store.tables[self.name]
        if self.op == "select":
            if self.store.fail_on == self.name:
                raise RuntimeError("pretend database error")
            found = [dict(r) for r in rows if all(f(r) for f in self.filters)]
            if self.newest_first:
                found.reverse()
            return type("Result", (), {"data": found[: self.n] if self.n else found})()
        out = []
        for row in self.payload:
            if self.op == "upsert":
                same = [r for r in rows if r.get(self.conflict) == row.get(self.conflict)]
                if same:
                    out.append(dict(same[0]))
                    continue
            new = dict(row, id=self._new_id())
            rows.append(new)
            out.append(dict(new))
        return type("Result", (), {"data": out})()


class FakeClient:
    def __init__(self, store):
        self.store = store

    def table(self, name):
        return Q(self.store, name)


def new_db():
    store = FakeDB()
    db._client = FakeClient(store)
    return store


def seed(code, sessions):
    """Fake earlier sessions, OLDEST first. Each session is a list of (indicator_type, value) pairs."""
    student_id = db.get_or_create_student(code)
    for rows in sessions:
        session_id = db.create_session(student_id, "Fake earlier session")
        db.save_indicators(student_id, session_id, rows)
    return student_id


def hints(*levels):
    return [("hint_level", lv) for lv in levels]


# ---- 5. db.get_history_summary and db.session_has_reflection ----
store = new_db()
sid = seed("S1", [
    hints(3, 3) + [("stuck", 1), ("asked_for_answer", 1)],        # oldest
    hints(2, 2) + [("stuck", 1), ("self_correction", 1)],
    hints(1, 1) + [("self_correction", 1)],                       # newest
])
s = db.get_history_summary(sid)
check("summary: 3 sessions", s["sessions"] == 3)
check("summary: averages newest first", s["averages"] == [1.0, 2.0, 3.0])
check("summary: counts add up", (s["stuck"], s["asked_for_answer"], s["self_correction"]) == (2, 1, 2))
newest_session = store.tables["indicators"][-1]["session_id"]
s = db.get_history_summary(sid, exclude_session_id=newest_session)
check("summary: the session in progress is left out", s["sessions"] == 2 and s["averages"] == [2.0, 3.0])
check("summary: only the newest 3 sessions count", db.get_history_summary(sid, max_sessions=1)["sessions"] == 1)
other = seed("S2", [hints(1, 1)])
check("summary: another student's rows are never used", db.get_history_summary(other)["sessions"] == 1)
check("summary: unknown student -> 0 sessions", db.get_history_summary("nobody")["sessions"] == 0)
check("no reflection saved yet", db.session_has_reflection(newest_session) is False)
db.save_indicators(sid, newest_session, [("reflection_often_stuck", 1)])
check("a saved reflection is found", db.session_has_reflection(newest_session) is True)
db._client = None

# ---- 6. /chat with a pretend tutor and the pretend database ----
try:
    from app import api, tutor_agent  # noqa: E402
except Exception as err:  # e.g. flask or google-genai is not installed
    print(f"\nSKIPPED  the /chat checks (could not import app.api: {err})")
    api = None

if api is not None:
    seen = {"instructions": []}

    def pretend_tutor(problem, history, extra_instruction="", raise_on_error=False):
        seen["instructions"].append(extra_instruction)
        return "Pretend tutor reply. What do you think comes next?"

    tutor_agent.socratic_response = pretend_tutor  # Step 1.3: the turn runs in tutor_agent.py
    # Phase 2: the student check uses the word rules here (never the real Gemini).
    from app import assessment  # noqa: E402
    tutor_agent.assess = lambda problem, bank, history: assessment.fallback(history)
    db.is_configured = lambda: True  # always use the pretend database below, never the real Supabase
    client = api.app.test_client()
    PROBLEM = "Natalia sold 48 clips in April and half as many in May. How many altogether?"
    FINE = ["48 clips in April.", "Half of 48 is 24.", "So 48 plus 24.", "That makes 72.", "72 clips."]

    def talk(code, messages, session_id=None, problem=PROBLEM):
        """Play a whole session. Returns the list of (reflection_type, instruction) for each student message."""
        history, results = [], []
        login = {"Authorization": "Bearer " + auth.make_token(code)}  # Stage 7c
        first = client.post("/chat", json={"problem": problem, "history": [], "student_id": code},
                            headers=login).get_json()
        session_id = first["session_id"]
        history.append({"role": "teacher", "content": first["reply"]})
        for msg in messages:
            history.append({"role": "student", "content": msg})
            r = client.post("/chat", json={"problem": problem, "history": history,
                                           "student_id": code, "session_id": session_id}, headers=login)
            body = r.get_json()
            results.append((body["reflection_type"], seen["instructions"][-1], r.status_code))
            history.append({"role": "teacher", "content": body["reply"]})
        return session_id, results

    # a. Student who often asked for the answer
    store = new_db()
    seed("ASKER", [hints(3, 3) + [("asked_for_answer", 1)], hints(3, 2) + [("asked_for_answer", 1)]])
    session_id, res = talk("ASKER", FINE)
    types = [r[0] for r in res]
    check("a. all replies are OK (200)", all(r[2] == 200 for r in res))
    check("a. no reflection on message 1 and 2 (too early)", types[0] is None and types[1] is None)
    check("a. reflection asks_for_answer on message 3", types[2] == "asks_for_answer")
    check("a. the tutor was given the REFLECTION NOTE", "REFLECTION NOTE" in res[2][1])
    check("a. never twice in one session", types[3] is None and types[4] is None)
    check("a. no note on the other turns", "REFLECTION NOTE" not in res[3][1] and "REFLECTION NOTE" not in res[0][1])
    saved = [r["indicator_type"] for r in store.tables["indicators"] if r["session_id"] == session_id]
    check("a. saved exactly one reflection_asks_for_answer", saved.count("reflection_asks_for_answer") == 1)
    check("a. no old message text is in the note", "Half of 48" not in res[2][1])

    # b. Student with an improving history
    store = new_db()
    seed("GETTINGBETTER", [hints(3, 3, 3), hints(2, 2, 1), hints(1, 1, 1)])
    _, res = talk("GETTINGBETTER", FINE[:3])
    check("b. improving student gets 'improving'", res[2][0] == "improving")

    # c. Student who often got stuck
    store = new_db()
    seed("STUCKY", [hints(2, 2) + [("stuck", 1), ("stuck", 1)], hints(2, 3) + [("stuck", 1)]])
    _, res = talk("STUCKY", FINE[:3])
    check("c. often stuck student gets 'often_stuck'", res[2][0] == "often_stuck")

    # d. Student who fixes own mistakes
    store = new_db()
    seed("CHECKER", [hints(2, 2) + [("self_correction", 1)], hints(2, 2) + [("self_correction", 1)]])
    _, res = talk("CHECKER", FINE[:3])
    check("d. self-correcting student gets 'self_checker'", res[2][0] == "self_checker")

    # e. New student and a student with only one earlier session
    store = new_db()
    _, res = talk("BRANDNEW", FINE)
    check("e. new student: never a reflection", all(r[0] is None for r in res))
    seed("ONESESSION", [hints(3, 3) + [("asked_for_answer", 1), ("asked_for_answer", 1)]])
    _, res = talk("ONESESSION", FINE)
    check("e. only 1 earlier session: never a reflection", all(r[0] is None for r in res))

    # f. The 3rd message is a struggle: wait for a better moment
    store = new_db()
    seed("ASKER2", [hints(3, 3) + [("asked_for_answer", 1)], hints(3, 2) + [("asked_for_answer", 1)]])
    _, res = talk("ASKER2", ["48 clips.", "I don't know.", "I'm stuck.", "Oh, 24 more.", "72."])
    check("f. no reflection while the student is stuck", res[1][0] is None and res[2][0] is None)
    check("f. reflection comes at the first fine message", res[3][0] == "asks_for_answer")

    def as_(code):
        """Stage 7c: the login token header for this student."""
        return {"Authorization": "Bearer " + auth.make_token(code)}

    # g. Safety: a database problem never breaks the chat
    store = new_db()
    seed("ASKER3", [hints(3, 3) + [("asked_for_answer", 1)], hints(3, 2) + [("asked_for_answer", 1)]])
    session_id, _ = talk("ASKER3", FINE[:2])
    store.fail_on = "indicators"  # reading the history now fails
    history = chat(*FINE[:3])
    r = client.post("/chat", json={"problem": PROBLEM, "history": history, "student_id": "ASKER3", "session_id": session_id}, headers=as_("ASKER3"))
    check("g. database read error: chat still gives 200", r.status_code == 200)
    check("g. database read error: no reflection", r.get_json()["reflection_type"] is None)
    store.fail_on = None

    # h. Privacy: someone else's session id is never used
    store = new_db()
    seed("ASKER4", [hints(3, 3) + [("asked_for_answer", 1)], hints(3, 2) + [("asked_for_answer", 1)]])
    seed("OTHERKID", [hints(1, 1)])
    other_session = store.tables["sessions"][-1]["id"]
    r = client.post("/chat", json={"problem": PROBLEM, "history": chat(*FINE[:3]), "student_id": "ASKER4", "session_id": other_session}, headers=as_("ASKER4"))
    check("h. a session of another student -> no reflection", r.get_json()["reflection_type"] is None)

    # i. No student_id / no session_id: same as Stage 5
    r = client.post("/chat", json={"problem": PROBLEM, "history": chat(*FINE[:3])})
    check("i. no student_id: reflection_type is null", r.status_code == 200 and r.get_json()["reflection_type"] is None)
    store = new_db()
    seed("ASKER5", [hints(3, 3) + [("asked_for_answer", 1)], hints(3, 2) + [("asked_for_answer", 1)]])
    r = client.post("/chat", json={"problem": PROBLEM, "history": chat(*FINE[:3]), "student_id": "ASKER5"}, headers=as_("ASKER5"))
    check("i. no session_id: reflection_type is null", r.get_json()["reflection_type"] is None)
    check("i. the Stage 5 fields are still there", {"reply", "session_id", "hint_level", "scaffold_level"} <= set(r.get_json()))

    db._client = None

print()
if failures:
    print(f"{failures} check(s) FAILED.")
    sys.exit(1)
print("All checks passed.")
