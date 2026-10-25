"""
Tests for the action rules (policy.py) - agent plan, Phase 2.

Plain Python, so each rule can be checked exactly: one form in, one action out.
Run from the backend/ folder:   python -m pytest tests/test_policy.py
"""

import pytest

from app import policy, problems

ALG = problems.find("alg-9-1")


def form(**fields):
    base = {"intent": "answer_attempt", "correctness": "unclear", "current_step": 1, "final_answer_given": False,
            "solved": False, "mistake_id": "none", "mistake_confidence": 0.0, "self_corrected": False,
            "reasoning_shown": "partial", "evidence": "", "source": "llm", "answer_check": None}
    base.update(fields)
    return base


def state(**fields):
    s = policy.new_state()
    s.update(fields)
    return s


def choose(f, s=None, scaffold=3, problem=ALG):
    return policy.choose_action(f, s or state(), scaffold, problem)


# ---- One rule each ----

@pytest.mark.parametrize("f, s, action", [
    (None, None, policy.ASK_GUIDING_QUESTION),
    (form(solved=True, correctness="correct"), None, policy.CONFIRM_AND_REFLECT),
    (form(), state(solved=True), policy.ACKNOWLEDGE_PROGRESS),
    (form(intent="off_topic"), None, policy.REDIRECT),
    (form(self_corrected=True, correctness="correct"), None, policy.ACKNOWLEDGE_PROGRESS),
    (form(intent="question", correctness="not_applicable"), None, policy.EXPLAIN_STEP_CLEARLY),
    (form(correctness="correct", reasoning_shown="none"), None, policy.ASK_FOR_EXPLANATION),
    (form(correctness="correct", reasoning_shown="none"), state(last_action=policy.ASK_FOR_EXPLANATION),
     policy.ACKNOWLEDGE_PROGRESS),
    (form(correctness="correct", reasoning_shown="clear"), None, policy.ACKNOWLEDGE_PROGRESS),
    (form(intent="other", correctness="unclear"), None, policy.ASK_GUIDING_QUESTION),
])
def test_one_rule_each(f, s, action):
    assert choose(f, s)["action"] == action


@pytest.mark.parametrize("struggle_before, action", [
    (0, policy.ENCOURAGE_SELF_CORRECTION), (1, policy.GIVE_SMALL_HINT),
    (2, policy.GIVE_CONCRETE_HINT), (3, policy.EXPLAIN_STEP_CLEARLY), (9, policy.EXPLAIN_STEP_CLEARLY),
])
def test_wrong_answer_ladder(struggle_before, action):
    assert choose(form(correctness="incorrect"), state(struggle=struggle_before))["action"] == action


@pytest.mark.parametrize("struggle_before, action", [
    (0, policy.GIVE_SMALL_HINT), (1, policy.GIVE_CONCRETE_HINT), (2, policy.EXPLAIN_STEP_CLEARLY),
])
def test_confused_ladder(struggle_before, action):
    assert choose(form(intent="confused", correctness="not_applicable"), state(struggle=struggle_before))["action"] == action


def test_asking_for_the_answer_does_not_climb():
    d = choose(form(intent="asks_for_answer", correctness="not_applicable"), state(struggle=1))
    assert d["action"] == policy.GIVE_SMALL_HINT and d["struggle"] == 1 and d["asked_for_answer"]


def test_progress_resets_the_struggle():
    assert choose(form(correctness="correct"), state(struggle=3))["struggle"] == 0


# ---- Common mistakes ----

def test_known_mistake_is_addressed():
    d = choose(form(correctness="incorrect", mistake_id="sign_when_moving", mistake_confidence=0.8))
    assert d["action"] == policy.ADDRESS_MISCONCEPTION and d["mistake_id"] == "sign_when_moving"


def test_unsure_mistake_uses_the_ladder():
    d = choose(form(correctness="incorrect", mistake_id="sign_when_moving", mistake_confidence=0.4))
    assert d["action"] == policy.ENCOURAGE_SELF_CORRECTION


def test_mistake_is_not_addressed_twice():
    s = state(addressed_mistakes=["sign_when_moving"])
    d = choose(form(correctness="incorrect", mistake_id="sign_when_moving", mistake_confidence=0.9), s)
    assert d["action"] == policy.ENCOURAGE_SELF_CORRECTION


def test_unknown_mistake_id_from_another_problem_is_ignored():
    d = choose(form(correctness="incorrect", mistake_id="uses_360", mistake_confidence=0.9))
    assert d["action"] == policy.ENCOURAGE_SELF_CORRECTION


# ---- Stage 5 scaffold limit ----

def test_scaffold_limit_lowers_the_help():
    d = choose(form(intent="confused", correctness="not_applicable"), state(struggle=1), scaffold=1)
    # confused twice wants a concrete hint (3); struggle 2 lets at least a small hint (2) through
    assert d["action"] == policy.GIVE_SMALL_HINT and d["needed_level"] == 3 and d["hint_level"] == 2


def test_scaffold_limit_at_the_first_confusion():
    d = choose(form(intent="confused", correctness="not_applicable"), scaffold=1)
    assert d["action"] == policy.ASK_GUIDING_QUESTION and d["needed_level"] == 2


def test_long_struggle_is_always_explained():
    d = choose(form(correctness="incorrect"), state(struggle=3), scaffold=1)
    assert d["action"] == policy.EXPLAIN_STEP_CLEARLY


def test_questions_are_answered_even_with_little_support():
    d = choose(form(intent="question", correctness="not_applicable"), scaffold=1)
    assert d["action"] == policy.EXPLAIN_STEP_CLEARLY


# ---- Memory ----

def test_update_state_counts():
    d = choose(form(correctness="incorrect"), state(struggle=1))
    new = policy.update_state(state(struggle=1), form(correctness="incorrect", current_step=2), d)
    assert new["struggle"] == 2 and new["wrong_attempts"] == 1 and new["hints"]["small"] == 1
    assert new["step"] == 2 and new["turns"] == 1 and new["last_action"] == policy.GIVE_SMALL_HINT
    assert new["last_check"] == {"intent": "answer_attempt", "correctness": "incorrect", "source": "llm"}


def test_update_state_does_not_change_the_old_state():
    old = state()
    policy.update_state(old, form(correctness="incorrect"), choose(form(correctness="incorrect")))
    assert old == policy.new_state()


def test_clean_state_fills_gaps_and_drops_junk():
    s = policy.clean_state({"struggle": 2, "hints": {"small": 1}, "something": "else", "solved": "yes"})
    assert s["struggle"] == 2 and s["hints"] == {"small": 1, "concrete": 0, "explain": 0}
    assert "something" not in s and s["solved"] is False
    assert policy.clean_state(None) == policy.new_state()


def test_memory_holds_no_message_text():
    d = choose(form(correctness="incorrect", evidence="my secret words"))
    new = policy.update_state(state(), form(correctness="incorrect", evidence="my secret words"), d)
    assert "my secret words" not in str(new)


# ---- Instructions ----

def test_every_action_has_an_instruction_and_a_safe_reply():
    for action in policy.ACTIONS:
        decision = {"action": action, "reason": "", "mistake_id": "sign_when_moving", "asked_for_answer": False}
        text = policy.build_instruction(decision, form(), ALG, state())
        assert text.startswith("ACTION:")
        assert policy.SAFE_REPLIES[action].strip()


def test_explain_names_the_step():
    decision = choose(form(correctness="incorrect"), state(struggle=3))
    text = policy.build_instruction(decision, form(current_step=2), ALG, state())
    assert ALG["steps"][1] in text


def test_only_confirm_may_talk_about_the_final_answer():
    for action in policy.ACTIONS:
        decision = {"action": action, "reason": "", "mistake_id": None, "asked_for_answer": False}
        text = policy.build_instruction(decision, form(), ALG, state())
        assert ("Never state the final answer" in text) is (action != policy.CONFIRM_AND_REFLECT)
