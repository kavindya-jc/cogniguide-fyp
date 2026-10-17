"""
Offline test for adaptive.py (Phase 2, Stage 4).

It does NOT use the internet, Gemini or Supabase, so it is free and fast.
Run from the repo root:   python backend\\tests\\test_adaptive.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the backend folder

from app import adaptive  # noqa: E402


def chat(*student_messages):
    """Build a history that ends with the last student message."""
    history = [{"role": "teacher", "content": "What is the first thing the problem tells us?"}]
    for i, msg in enumerate(student_messages):
        history.append({"role": "student", "content": msg})
        if i < len(student_messages) - 1:
            history.append({"role": "teacher", "content": "Good. What next?"})
    return history


failures = 0


def check(name, condition):
    global failures
    print(("PASS  " if condition else "FAIL  ") + name)
    if not condition:
        failures += 1


# 1. No history at all -> level 1
a = adaptive.analyze_history([])
check("empty chat gives level 1", a["hint_level"] == 1)
check("empty chat has no new student message", a["new_student_message"] is False)

# 2. A student who is doing fine stays at level 1
a = adaptive.analyze_history(chat("She sold 48 clips in April.", "Half of 48 is 24."))
check("strong student stays at level 1", a["hint_level"] == 1)

# 3. One stuck message -> level 2
a = adaptive.analyze_history(chat("I don't know how to start."))
check("one stuck message gives level 2", a["hint_level"] == 2)

# 4. Two struggling messages -> level 3
a = adaptive.analyze_history(chat("I don't know how to start.", "Just tell me the answer."))
check("two struggling messages give level 3", a["hint_level"] == 3)
check("asked_for_answer is noticed", a["latest"]["asked_for_answer"] is True)

# 5. Struggled, then recovered -> level goes down by one
a = adaptive.analyze_history(chat("I don't know.", "I'm confused.", "Oh, half of 48 is 24."))
check("recovery lowers the level (3 -> 2)", a["hint_level"] == 2)

# 6. Self-correction is noticed
a = adaptive.analyze_history(chat("48 divided by 2 is 28.", "Oops, wait, let me try again. It is 24."))
check("self-correction is noticed", a["latest"]["self_correct"] is True)

# 7. Only the last 3 student messages count
a = adaptive.analyze_history(
    chat("I don't know.", "I don't know.", "Half of 48 is 24.", "Then 48 plus 24.", "That is 72.")
)
check("old struggles outside the window are ignored", a["hint_level"] == 1)

# 8. Instruction text matches the level
text = adaptive.build_instruction(adaptive.analyze_history(chat("I don't know.", "Just tell me the answer.")))
check("level 3 instruction text is used", "HINT LEVEL 3" in text)
check("asking for the answer adds the kind refusal text", "will not do that" in text)

# 9. Indicators are only made for a NEW student message
a = adaptive.analyze_history(chat("Oops, I made a mistake."))
rows = dict(adaptive.indicator_rows(a))
check("indicators include hint_level and self_correction", "hint_level" in rows and rows.get("self_correction") == 1)
history_ends_with_teacher = chat("I don't know.") + [{"role": "teacher", "content": "Let's try a small step."}]
a = adaptive.analyze_history(history_ends_with_teacher)
check("no indicators when chat ends with a teacher message", adaptive.indicator_rows(a) == [])

print()
if failures:
    print(f"{failures} check(s) FAILED.")
    sys.exit(1)
print("All checks passed.")
