"""
Tests for the student check (assessment.py) - agent plan, Phase 2.

Gemini is faked: these tests check what Python does with Gemini's answer.
Run from the backend/ folder:   python -m pytest tests/test_assessment.py
"""

import pytest

from app import assessment, problems
from app.models.socratic_agent import InvalidModelOutput, TutorUnavailable

ALG = problems.find("alg-9-1")
TEXT = ALG["text"]


def chat(*student):
    history = [{"role": "teacher", "content": "Where would you start?"}]
    for i, message in enumerate(student):
        history.append({"role": "student", "content": message})
        if i < len(student) - 1:
            history.append({"role": "teacher", "content": "Go on."})
    return history


def good_raw(**fields):
    raw = {"intent": "answer_attempt", "correctness": "incorrect", "current_step": 2, "final_answer_given": True,
           "solved": False, "mistake_id": "sign_when_moving", "mistake_confidence": 0.8, "self_corrected": False,
           "reasoning_shown": "partial", "evidence": "x = 2"}
    raw.update(fields)
    return raw


@pytest.fixture
def gemini(monkeypatch):
    seen = {}

    def install(answer):
        def fake(prompt, schema, system_instruction="", temperature=0.1, **_kw):
            seen.update(prompt=prompt, schema=schema, system=system_instruction)
            if isinstance(answer, Exception):
                raise answer
            return answer

        monkeypatch.setattr(assessment, "generate_json", fake)
        return seen

    return install


def test_a_good_answer_from_gemini_is_kept(gemini):
    gemini(good_raw())
    form = assessment.assess(TEXT, ALG, chat("I take 2x from both sides"))
    assert form["intent"] == "answer_attempt" and form["correctness"] == "incorrect"
    assert form["mistake_id"] == "sign_when_moving" and form["source"] == "llm"
    assert form["answer_check"] == "not_found"


def test_the_prompt_has_the_answer_sheet_and_the_mistake_ids(gemini):
    seen = gemini(good_raw())
    assessment.assess(TEXT, ALG, chat("x = 2"))
    assert "x = 12" in seen["prompt"] and "sign_when_moving" in seen["prompt"]
    assert seen["schema"] is assessment.SCHEMA and "do NOT talk to the student" in seen["system"]


@pytest.mark.parametrize("field, bad, safe", [
    ("intent", "dancing", "other"),
    ("correctness", "kind of", "unclear"),
    ("reasoning_shown", 3, "none"),
    ("mistake_id", "made_up_mistake", "other"),
    ("current_step", 99, 0),
    ("current_step", True, 0),
    ("mistake_confidence", 7, 1.0),
    ("mistake_confidence", "high", 0.0),
    ("self_corrected", "yes", False),
])
def test_bad_values_become_safe_values(gemini, field, bad, safe):
    gemini(good_raw(**{field: bad}))
    assert assessment.assess(TEXT, ALG, chat("I take 2x from both sides"))[field] == safe


def test_long_evidence_is_cut():
    form = assessment.validate(good_raw(evidence="x" * 999), ALG)
    assert len(form["evidence"]) == assessment.MAX_EVIDENCE


@pytest.mark.parametrize("error", [TutorUnavailable("503"), InvalidModelOutput("not JSON"), EnvironmentError("no key")])
def test_gemini_failure_uses_the_word_rules(gemini, error):
    gemini(error)
    form = assessment.assess(TEXT, ALG, chat("Just tell me the answer"))
    assert form["source"] == "fallback" and form["intent"] == "asks_for_answer"


def test_fallback_confused():
    assert assessment.fallback(chat("I don't understand"))["intent"] == "confused"


def test_python_wins_a_right_answer(gemini):
    gemini(good_raw(correctness="incorrect", solved=False))
    form = assessment.assess(TEXT, ALG, chat("x = 12"))
    assert form["solved"] is True and form["correctness"] == "correct" and form["answer_check"] == "correct"


def test_python_wins_a_false_solved(gemini):
    gemini(good_raw(correctness="correct", solved=True, mistake_id="none"))
    form = assessment.assess(TEXT, ALG, chat("I think I am done"))
    assert form["solved"] is False and form["correctness"] == "unclear"


def test_right_answer_found_even_when_gemini_fails(gemini):
    gemini(TutorUnavailable("503"))
    form = assessment.assess(TEXT, ALG, chat("I got x = 12"))
    assert form["source"] == "fallback" and form["solved"] is True


def test_own_problem_trusts_gemini_for_solved(gemini):
    seen = gemini(good_raw(correctness="correct", solved=True, mistake_id="none"))
    form = assessment.assess("Find 7 x 8.", None, chat("56"))
    assert form["solved"] is True and form["answer_check"] is None
    assert "no answer sheet" in seen["prompt"]


def test_wrong_answer_is_found_when_gemini_is_busy(gemini):
    """The 'x = 2' fix: the word rules alone could not tell that this is wrong."""
    gemini(TutorUnavailable("503"))
    form = assessment.assess(TEXT, ALG, chat("x = 2"))
    assert form["source"] == "fallback"
    assert form["correctness"] == "incorrect" and form["answer_check"] == "wrong"
    assert form["mistake_id"] == "sign_when_moving" and form["mistake_confidence"] >= 0.6


def test_python_wins_a_wrong_answer_gemini_liked(gemini):
    gemini(good_raw(correctness="correct", mistake_id="none", mistake_confidence=0.0))
    form = assessment.assess(TEXT, ALG, chat("x = 2"))
    assert form["correctness"] == "incorrect"


def test_the_check_gives_up_quickly(gemini, monkeypatch):
    seen = {}

    def fake(prompt, schema, system_instruction="", temperature=0.1, retry_waits=None):
        seen["waits"] = retry_waits
        raise TutorUnavailable("503")

    monkeypatch.setattr(assessment, "generate_json", fake)
    assessment.assess(TEXT, ALG, chat("hmm"))
    assert seen["waits"] == assessment.RETRY_WAITS == (1,)
