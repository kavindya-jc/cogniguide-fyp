"""
Tests for the answer checker (answer_check.py) - agent plan, Phase 2.

Offline and exact: plain Python, no AI. Each line is one way a student (or the tutor) might write.
Run from the backend/ folder:   python -m pytest tests/test_answer_check.py
"""

import pytest

from app import answer_check, problems

FINAL_ANSWERS = [
    # (problem id, what the student wrote, is it the WHOLE correct final answer?)
    ("num-8-1", "It's 180", True),
    ("num-8-1", "3/4 of 240 is 180", True),
    ("num-8-1", "240 ÷ 4 = 60", False),              # only the first step
    ("num-8-1", "320", False),                       # a common mistake
    ("num-9-1", "The new price is Rs. 2040", True),
    ("num-9-1", "Rs. 2,040", True),
    ("num-9-1", "the discount is 360", False),
    ("num-10-1", "4.5 × 10⁻⁵", True),
    ("num-10-1", "4.5x10^-5", True),
    ("num-10-1", "4.5e-5", True),
    ("num-10-1", "45 × 10^-6", False),               # right size, but not scientific notation
    ("num-10-1", "0.000045", False),                 # just the question again
    ("num-10-1", "4.5 * 10^5", False),
    ("alg-9-1", "x = 12", True),
    ("alg-9-1", "I got 12", True),
    ("alg-9-1", "x = 2", False),                     # the sign mistake
    ("alg-9-1", "x - 5 = 7", False),
    ("alg-10-1", "(x + 3)(x + 2)", True),             # any order
    ("alg-10-1", "(x+2)(x+3)", True),
    ("alg-10-1", "(x+1)(x+6)", False),
    ("alg-11-1", "x = 4, y = 3", True),
    ("alg-11-1", "x = 4", False),                    # only half of the answer
    ("alg-11-1", "x = 3, y = 4", False),             # swapped
    ("geo-8-1", "65°", True),
    ("geo-8-1", "48 + 67 = 115", False),
    ("geo-10-1", "angle B = 70", True),
    ("geo-11-1", "154 cm²", True),
    ("geo-11-1", "44", False),
    ("trig-10-1", "sin θ = 6/10", True),             # not simplified, still right
    ("trig-10-1", "0.6", True),
    ("trig-10-1", "4/5", False),
    ("trig-11-1", "5√3/2 m", True),
    ("trig-11-1", "about 4.33 m", True),
    ("trig-11-1", "2.5", False),
    ("gra-9-1", "y = -3, 1 and 5, crosses at (0, 1)", True),
    ("gra-9-1", "-3, 1, 5", False),                  # the crossing point is missing
    ("gra-10-1", "gradient = 6/3 = 2", True),
    ("gra-10-1", "1/2", False),
    ("sta-8-1", "the numbers are 4, 7, 9, 10 and 15", False),  # 9 is in the list, not an answer
    ("sta-8-1", "the mean is 9", True),
    ("sta-8-1", "45 / 5 = 9", True),
    ("sta-9-1", "10.5", True),
    ("sta-9-1", "(9 + 12) / 2 = 10.5", True),
    ("sta-9-1", "9", False),
    ("geo-11-1", "154cm2", True),                    # units with no space
    ("trig-11-1", "4.33m", True),
    ("gra-10-1", "y = 2x + 1", False),               # the 2 in 2x is not a value
]


@pytest.mark.parametrize("pid, text, correct", FINAL_ANSWERS)
def test_final_answer(pid, text, correct):
    assert answer_check.check_final_answer(text, problems.find(pid))["all_correct"] is correct


def test_parts_are_counted():
    result = answer_check.check_final_answer("x = 4", problems.find("alg-11-1"))
    assert result == {"all_correct": False, "parts_found": 1, "parts_total": 2}


LEAKS = [
    # (problem id, tutor reply, does it give away (part of) the answer?)
    ("alg-9-1", "What do you get if you add 5 to both sides?", False),
    ("alg-9-1", "So x = 12, well done", True),
    ("alg-11-1", "Nice, x = 4. Now what is y?", True),       # half the answer is still a leak
    ("sta-8-1", "Add 4, 7, 9, 10 and 15 first. What is the total?", False),
    ("num-9-1", "What is 15% of 2400?", False),
    ("num-9-1", "15% of 2400 is 360. What is left after the discount?", False),  # a step result, not the answer
    ("gra-10-1", "How much does y change from 3 to 9?", False),
    ("trig-11-1", "sin 60° is √3/2. What is 5 times that?", False),
    ("trig-11-1", "So the height is 5√3/2 m.", True),
    ("alg-10-1", "Is it (x + 2)(x + 3)?", True),
    # Gemini's LaTeX style must be understood too
    ("alg-9-1", "So $x = 12$.", True),
    ("alg-9-1", "Try subtracting $2x$ from both sides of $3x - 5 = 2x + 7$.", False),
    ("trig-10-1", "That gives $\\frac{3}{5}$.", True),
    ("trig-11-1", "The height is $\\frac{5\\sqrt{3}}{2}$ m.", True),
    ("num-10-1", "It is $4.5 \\times 10^{-5}$.", True),
]


@pytest.mark.parametrize("pid, reply, leaks", LEAKS)
def test_reply_leak(pid, reply, leaks):
    assert answer_check.reply_leaks_answer(reply, problems.find(pid)) is leaks


def test_every_bank_answer_is_recognised():
    """The answer sheet's own wording must count as correct for every problem."""
    for problem in problems.load().values():
        assert answer_check.check_final_answer(problem["answer"], problem)["all_correct"], problem["id"]


WRONG_ANSWERS = [
    # (problem id, what the student wrote, clearly wrong?, common mistake found)
    ("alg-9-1", "x = 2", True, "sign_when_moving"),
    ("alg-9-1", "x = 12", False, None),
    ("alg-9-1", "x - 5 = 7", False, None),          # a right step, not an answer
    ("alg-9-1", "x = 2x + 12", False, None),        # not a value for x
    ("num-8-1", "320", True, "divide_by_3"),
    ("num-8-1", "240 ÷ 4 = 60", False, None),       # a right first step
    ("alg-10-1", "(x+1)(x+6)", True, "product_only"),
    ("alg-11-1", "x = 4", False, None),             # right, just not finished
    ("alg-11-1", "x = 10, y = 9", True, None),      # a wrong x
    ("sta-8-1", "9", False, None),                  # right (and the same as the 'median' mistake)
    ("geo-8-1", "48 + 67 = 115", False, None),
    ("geo-8-1", "245", True, "uses_360"),
    ("trig-11-1", "2.5 m", True, "uses_cos"),
]


@pytest.mark.parametrize("pid, text, wrong, mistake", WRONG_ANSWERS)
def test_wrong_answer(pid, text, wrong, mistake):
    assert answer_check.find_wrong_answer(text, problems.find(pid)) == {"wrong": wrong, "mistake_id": mistake}
