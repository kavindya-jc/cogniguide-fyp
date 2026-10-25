"""
Tests for the problem bank (problems.py) and GET /problems - agent plan, Phase 1 (Step 1.2).

Offline: no internet, Gemini or Supabase.
Run from the backend/ folder:   python -m pytest tests/test_problems.py
"""

import json
import math
from pathlib import Path

import pytest

from app import problems
from app.api import app

APP_PROBLEMS = Path(__file__).resolve().parents[2] / "frontend" / "assets" / "problems" / "sample_problems.json"
SECRET_FIELDS = ("answer", "answer_parts", "steps", "mistakes", "checked_by_teacher")


@pytest.fixture
def client():
    return app.test_client()


def problem(pid):
    p = problems.find(pid)
    assert p is not None, pid
    return p


def value(pid, label=None):
    """The answer value of a problem as a number (the first part, or the part with this label)."""
    parts = problem(pid)["answer_parts"]
    part = parts[0] if label is None else next(p for p in parts if p["label"] == label)
    return float(part["value"])


# ---- The bank file ----

def test_bank_loads_all_15_problems():
    assert len(problems.load()) == 15


def test_every_problem_is_complete():
    for p in problems.load().values():
        assert p["area"] in problems.AREAS
        assert p["grade"] in problems.GRADES
        assert p["answer_parts"] and p["steps"], p["id"]
        assert p["mistakes"], f"{p['id']}: add at least one common mistake"


def test_same_problems_as_the_app():
    """Until the app reads GET /problems, its own file and the server must list the same problems."""
    if not APP_PROBLEMS.exists():
        pytest.skip("the app's problem file is not in this checkout")
    app_items = json.loads(APP_PROBLEMS.read_text(encoding="utf-8"))["problems"]
    assert [p for p in app_items] == problems.list_public()


def test_broken_files_give_a_clear_error(tmp_path):
    cases = {
        "not json": "{",
        "no problems": '{"problems": []}',
        "missing answer": json.dumps({"problems": [{"id": "a", "area": "number", "grade": 8, "text": "1+1",
                                                    "answer_parts": [{"label": "r", "value": "2"}],
                                                    "steps": ["add"], "mistakes": []}]}),
        "bad area": json.dumps({"problems": [{"id": "a", "area": "music", "grade": 8, "text": "1+1", "answer": "2",
                                              "answer_parts": [{"label": "r", "value": "2"}],
                                              "steps": ["add"], "mistakes": []}]}),
    }
    for name, text in cases.items():
        path = tmp_path / f"{name}.json"
        path.write_text(text, encoding="utf-8")
        with pytest.raises(problems.ProblemBankError):
            problems.load(path)


def test_public_view_has_no_answer():
    view = problems.public_view(problem("alg-9-1"))
    assert set(view) == {"id", "area", "grade", "text"}


def test_find_unknown_id_gives_none():
    assert problems.find("no-such-problem") is None


# ---- The answers are mathematically right (checked by Python, not by hand) ----

def test_answers_are_correct():
    assert value("num-8-1") == 3 / 4 * 240
    assert value("num-9-1") == 2400 - 2400 * 15 / 100
    assert math.isclose(problem("num-10-1")["answer_parts"][0]["decimal"], 0.000045)
    assert math.isclose(4.5 * 10 ** -5, 0.000045)

    x = value("alg-9-1")
    assert 3 * x - 5 == 2 * x + 7

    for x in range(-5, 6):  # (x+2)(x+3) equals x² + 5x + 6 for every x
        assert (x + 2) * (x + 3) == x * x + 5 * x + 6

    x, y = value("alg-11-1", "x"), value("alg-11-1", "y")
    assert 2 * x + y == 11 and x - y == 1

    assert value("geo-8-1") == 180 - 48 - 67
    assert value("geo-10-1") == (180 - 40) / 2
    assert value("geo-11-1") == pytest.approx(22 / 7 * 7 * 7)

    assert problem("trig-10-1")["answer_parts"][0]["decimal"] == 6 / 10
    height = problem("trig-11-1")["answer_parts"][0]["decimal"]
    assert height == pytest.approx(5 * math.sin(math.radians(60)), abs=0.005)

    line = {p["label"]: p["value"] for p in problem("gra-9-1")["answer_parts"]}
    for x in (-2, 0, 2):
        assert float(line[f"y when x = {x}"]) == 2 * x + 1
    assert line["y-axis crossing"] == "(0, 1)"

    assert value("gra-10-1") == (9 - 3) / (4 - 1)
    assert value("sta-8-1") == sum([4, 7, 9, 10, 15]) / 5
    ordered = sorted([12, 5, 8, 20, 9, 15])
    assert value("sta-9-1") == (ordered[2] + ordered[3]) / 2


def test_no_mistake_gives_the_right_answer_by_accident():
    """A 'wrong answer' must really be wrong (sta-8-1 is the known exception: median = mean = 9).

    Only one-part answers are compared: for a many-part answer (x = 4, y = 3), giving one
    right part alone IS a mistake (an incomplete answer), so it may match a part.
    """
    for p in problems.load().values():
        if len(p["answer_parts"]) > 1:
            continue
        right = {str(p["answer_parts"][0]["value"]).replace(" ", "")}
        for m in p["mistakes"]:
            wrong = str(m.get("wrong_answer", "")).replace(" ", "")
            if p["id"] == "sta-8-1" and m["id"] == "picks_middle":
                continue
            assert wrong not in right, f"{p['id']} / {m['id']}"


# ---- GET /problems ----

def test_get_problems_lists_all_without_answers(client):
    r = client.get("/problems")
    assert r.status_code == 200
    items = r.get_json()["problems"]
    assert len(items) == 15
    for item in items:
        assert set(item) == {"id", "area", "grade", "text"}
    body = r.get_data(as_text=True)
    for field in SECRET_FIELDS:
        assert f'"{field}"' not in body


def test_get_problems_filters(client):
    algebra = client.get("/problems?area=algebra").get_json()["problems"]
    assert [p["id"] for p in algebra] == ["alg-9-1", "alg-10-1", "alg-11-1"]
    grade9 = client.get("/problems?grade=9").get_json()["problems"]
    assert grade9 and all(p["grade"] == 9 for p in grade9)
    both = client.get("/problems?area=algebra&grade=9").get_json()["problems"]
    assert [p["id"] for p in both] == ["alg-9-1"]
    assert client.get("/problems?area=algebra&grade=8").get_json()["problems"] == []


@pytest.mark.parametrize("query", ["area=music", "grade=7", "grade=12", "grade=nine", "grade=-9", "grade=9.5"])
def test_get_problems_rejects_bad_filters(client, query):
    r = client.get(f"/problems?{query}")
    assert r.status_code == 400
    assert r.get_json()["error"]["code"] == "invalid_request"


def test_get_problems_broken_bank_gives_503(client, monkeypatch):
    def broken(**_filters):
        raise problems.ProblemBankError("secret path details")

    monkeypatch.setattr(problems, "list_public", broken)
    r = client.get("/problems")
    assert r.status_code == 503
    assert r.get_json()["error"]["code"] == "problems_unavailable"
    assert "secret path" not in r.get_data(as_text=True)
