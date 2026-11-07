"""Offline tests for the researcher analytics page: correct totals, and no private data on it."""

import importlib.util
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "researcher_dashboard.py"
spec = importlib.util.spec_from_file_location("researcher_dashboard", SCRIPT)
rd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rd)

STUDENTS = [
    {"id": "s1", "anon_code": "PRIVATE-NAME-ONE"},
    {"id": "s2", "anon_code": "PRIVATE-NAME-TWO"},
    {"id": "t1", "anon_code": "TEST01"},
    {"id": "s3", "anon_code": "NEVER-CHATTED"},
]
SESSIONS = [
    {"id": "a", "student_id": "s1", "problem_id": "alg-9-1", "status": "solved", "started_at": "2026-11-01T10:00:00+00:00"},
    {"id": "b", "student_id": "s1", "problem_id": None, "status": "ended", "started_at": "2026-11-02T10:00:00+00:00"},
    {"id": "c", "student_id": "s2", "problem_id": "geo-8-1", "status": "in_progress", "started_at": "2026-11-03T10:00:00+00:00"},
    {"id": "d", "student_id": "s2", "problem_id": "alg-9-1", "status": "in_progress", "started_at": "2026-11-04T10:00:00+00:00"},
    {"id": "e", "student_id": "t1", "problem_id": "num-8-1", "status": "solved", "started_at": "2026-11-05T10:00:00+00:00"},
]


def turn(session, student, action, needed=1, given=1, intent="attempt", check="llm", guard="ok", latency=1000):
    return {
        "session_id": session, "student_id": student, "action": action, "needed_level": needed, "hint_level": given,
        "intent": intent, "check_source": check, "guard": guard, "latency_ms": latency, "problem_id": None,
    }


TURNS = [
    turn("a", "s1", "ASK_GUIDING_QUESTION", intent=None),  # opening: not a reply to the student
    turn("a", "s1", "GIVE_SMALL_HINT", needed=2, given=2, latency=2000),
    turn("a", "s1", "CONFIRM_AND_REFLECT", latency=4000),
    turn("b", "s1", "GIVE_CONCRETE_HINT", needed=3, given=2, check="fallback", guard="gemini_busy", latency=6000),
    turn("c", "s2", "GIVE_SMALL_HINT", needed=2, given=1),
    turn("d", "s2", "ASK_GUIDING_QUESTION", intent=None),  # opening only: session d does not count
    turn("e", "t1", "GIVE_SMALL_HINT"),
]
INDICATORS = [
    {"student_id": "s1", "session_id": "a", "indicator_type": "self_correction", "value": 1},
    {"student_id": "s1", "session_id": "a", "indicator_type": "hint_level", "value": 2},
    {"student_id": "s1", "session_id": "a", "indicator_type": "reflection_often_stuck", "value": 1},
    {"student_id": "s1", "session_id": "a", "indicator_type": "claimed_solved", "value": 1},
    {"student_id": "s1", "session_id": "b", "indicator_type": "claimed_solved", "value": 0},
    {"student_id": "s2", "session_id": "c", "indicator_type": "stuck", "value": 1},
    {"student_id": "t1", "session_id": "e", "indicator_type": "stuck", "value": 1},
]


def summary(exclude=("TEST",)):
    return rd.summarise(STUDENTS, SESSIONS, INDICATORS, TURNS, exclude)


def indicator(result, kind):
    return next(r for r in result["indicators"] if r["kind"] == kind)


def test_totals_ignore_opening_only_sessions_and_excluded_accounts():
    s = summary()
    assert (s["students"], s["sessions"], s["student_turns"]) == (2, 3, 4)
    assert (s["solved"], s["solved_percent"]) == (1, 33)


def test_no_exclude_keeps_every_account():
    s = summary(exclude=())
    assert (s["students"], s["sessions"], s["student_turns"]) == (3, 4, 5)


def test_indicators_are_counted_and_reflections_grouped():
    s = summary()
    assert indicator(s, "self_correction")["total"] == 1
    assert indicator(s, "reflection")["total"] == 1
    assert indicator(s, "stuck")["total"] == 1  # the excluded test account is not counted
    assert indicator(s, "self_correction")["per_session"] == 0.33


def test_totals_match_the_per_student_rows():
    # Session d has only an opening turn, and session "old" is from before the decision log.
    extra = [
        {"student_id": "s2", "session_id": "d", "indicator_type": "stuck", "value": 1},
        {"student_id": "s2", "session_id": "old", "indicator_type": "stuck", "value": 1},
        {"student_id": "s1", "session_id": None, "indicator_type": "stuck", "value": 1},
    ]
    s = rd.summarise(STUDENTS, SESSIONS, INDICATORS + extra, TURNS, ("TEST",))
    assert indicator(s, "stuck")["total"] == sum(r["stuck"] for r in s["per_student"]) == 1


def test_claimed_solved_counts_confirmed_separately():
    s = summary()
    assert (s["confirmed"], s["claimed"]) == (1, 2)


def test_actions_leave_out_opening_turns():
    assert dict(summary()["actions"]) == {"GIVE_SMALL_HINT": 2, "CONFIRM_AND_REFLECT": 1, "GIVE_CONCRETE_HINT": 1}


def test_needed_and_given_levels_are_separate():
    assert summary()["levels"] == [
        {"level": 1, "needed": 1, "given": 2},
        {"level": 2, "needed": 2, "given": 2},
        {"level": 3, "needed": 1, "given": 0},
    ]


def test_trend_uses_each_students_session_order():
    # 1st sessions: s1 (2, 1) = 1.5 and s2 (2) = 2, so 1.75. 2nd session: s1 (3).
    assert summary()["trend"] == [
        {"position": 1, "average": 1.75, "sessions": 2},
        {"position": 2, "average": 3.0, "sessions": 1},
    ]


def test_areas_and_typed_in_problems():
    areas = {a["area"]: a for a in summary()["areas"]}
    assert areas["Algebra"]["solved"] == 1
    assert areas["Geometry"]["sessions"] == 1
    assert rd.TYPED_IN in areas


def test_gemini_failure_and_latency_are_reported():
    s = summary()
    assert dict(s["checks"]) == {"llm": 3, "fallback": 1}
    assert dict(s["guards"]) == {"ok": 3, "gemini_busy": 1}
    assert s["latency_median_s"] == 3.0


def test_page_has_no_usernames_and_uses_numbers():
    page = rd.render_html(summary(exclude=()))
    assert "PRIVATE-NAME" not in page
    assert "TEST01" not in page
    assert "Student 1" in page


def test_unexpected_text_is_escaped():
    turns = [turn("a", "s1", "<script>alert(1)</script>", guard="<b>x</b>")]
    page = rd.render_html(rd.summarise(STUDENTS, SESSIONS, [], turns))
    body = page.split('<script type="application/json"')[0]
    assert "<script>alert" not in body
    assert "<b>x</b>" not in body
    assert "<script>alert" not in page.split('id="report-data">')[1].split("</script>")[0]


def test_banner_shows_for_test_data_only():
    assert "not study results" in rd.render_html(summary())
    assert "not study results" not in rd.render_html(summary(), study=True)


def test_empty_database_still_makes_a_page():
    s = rd.summarise([], [], [], [])
    page = rd.render_html(s)
    assert s["solved_percent"] is None
    assert "No data yet" in page


class FakeQuery:
    def __init__(self, client, table):
        self.client, self.table_name = client, table

    def select(self, columns):
        self.client.selected.append((self.table_name, columns))
        return self

    def range(self, start, end):
        self.client.ranges.append((start, end))
        self.start, self.end = start, end
        return self

    def execute(self):
        class Result:
            pass

        result = Result()
        result.data = self.client.rows[self.start:self.end + 1]
        return result


class FakeClient:
    def __init__(self, rows):
        self.rows, self.selected, self.ranges, self.tables = rows, [], [], []

    def table(self, name):
        self.tables.append(name)
        return FakeQuery(self, name)


def test_reads_every_page_of_rows(monkeypatch):
    monkeypatch.setattr(rd, "PAGE_SIZE", 2)
    client = FakeClient([1, 2, 3, 4, 5])
    assert rd.fetch_all(client, "students") == [1, 2, 3, 4, 5]
    assert client.ranges == [(0, 1), (2, 3), (4, 5)]


def test_never_reads_messages_or_free_text():
    client = FakeClient([])
    rd.read_data(client)
    assert set(client.tables) == {"students", "sessions", "indicators", "agent_turns"}
    columns = {table: [c.strip() for c in text.split(",")] for table, text in client.selected}
    assert "problem" not in columns["sessions"]
    assert "state" not in columns["sessions"]
    assert "reason" not in columns["agent_turns"]


def test_only_read_calls_exist_in_the_script():
    source = SCRIPT.read_text(encoding="utf-8").replace("sys.path.insert(", "")  # Python's path, not the database
    for write_call in (".insert(", ".update(", ".upsert(", ".delete(", ".rpc("):
        assert write_call not in source


@pytest.mark.parametrize("bad", ["ab", "x"])
def test_short_exclude_prefix_is_refused(monkeypatch, bad):
    monkeypatch.setattr("sys.argv", ["researcher_dashboard.py", "--exclude", bad])
    with pytest.raises(SystemExit):
        rd.main()
