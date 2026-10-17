"""
Offline test for scaffolding.py and the new db.py reading code (Phase 2, Stage 5).

It does NOT use the internet, Gemini or Supabase, so it is free and fast.
Run from the repo root:   python backend\\tests\\test_scaffolding.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the backend folder

from app import adaptive, db, scaffolding  # noqa: E402


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


# ---- 1. Choosing the scaffold level from earlier sessions ----
compute = scaffolding.compute_scaffold_level

check("no earlier sessions -> full support (3)", compute([]) == 3)
check("only 1 earlier session -> full support (3)", compute([1.0]) == 3)
check("student who needs little help -> minimal (1)", compute([1.0, 1.1, 1.2]) == 1)
check("student who needs some help -> reduced (2)", compute([1.5, 1.6, 1.4]) == 2)
check("student who needs a lot of help -> full (3)", compute([2.8, 2.5, 2.9]) == 3)
check("newest session was hard -> help comes back (3)", compute([2.7, 1.0, 1.0]) == 3)
check("only the newest 3 sessions count", compute([1.0, 1.0, 1.0, 3.0, 3.0, 3.0]) == 1)

# ---- 2. The improving student: help fades over time, the struggling student keeps full help ----
improving = [3.0, 2.6, 2.0, 1.6, 1.2, 1.0, 1.0]  # oldest -> newest session averages
levels = []
for n in range(1, len(improving) + 1):
    earlier = list(reversed(improving[:n]))  # newest first
    levels.append(compute(earlier))
check("improving student: level never goes up while improving", levels == sorted(levels, reverse=True))
check("improving student: ends at minimal support (1)", levels[-1] == 1)
check("improving student: starts at full support (3)", levels[0] == 3)
struggling = [3.0, 2.8, 2.9, 3.0, 2.7]
check("struggling student: stays at full support (3)", compute(list(reversed(struggling))) == 3)

# ---- 3. Limiting the Stage 4 hint level ----
a = adaptive.analyze_history(chat("I don't know how to start."))  # Stage 4 says level 2
check("Stage 4 level 2 before scaffolding", a["hint_level"] == 2 and a["needed_level"] == 2)

b = scaffolding.apply_scaffold(a, 1)
check("scaffold 1 lowers level 2 to 1", b["hint_level"] == 1)
check("needed level is kept for the data", b["needed_level"] == 2)
check("the original analysis is not changed", a["hint_level"] == 2)

b = scaffolding.apply_scaffold(a, 3)
check("scaffold 3 changes nothing", b["hint_level"] == 2)

a3 = adaptive.analyze_history(chat("I don't know.", "Just tell me the answer."))  # level 3
b = scaffolding.apply_scaffold(a3, 1)
check("safety valve: clearly stuck student gets at least level 2", b["hint_level"] == 2)
b = scaffolding.apply_scaffold(a3, 2)
check("scaffold 2 limits level 3 to 2", b["hint_level"] == 2)
b = scaffolding.apply_scaffold(a3, 3)
check("scaffold 3 keeps level 3", b["hint_level"] == 3)

# ---- 4. Instruction text ----
check("no note at full support", scaffolding.build_scaffold_instruction(3, a) == "")
check("reduced note at scaffold 2", "SCAFFOLD NOTE" in scaffolding.build_scaffold_instruction(2, a))
check("minimal note at scaffold 1", "own plan" in scaffolding.build_scaffold_instruction(1, a))
check("no 'smaller hints' note for a clearly stuck student", scaffolding.build_scaffold_instruction(1, a3) == "")

# ---- 5. Saved indicator is the NEED, not the limit ----
a = adaptive.analyze_history(chat("I don't know how to start."))
b = scaffolding.apply_scaffold(a, 1)
rows = dict(adaptive.indicator_rows(b))
check("saved hint_level is the needed level (2), not the used level (1)", rows["hint_level"] == 2)


# ---- 6. db.get_recent_session_levels with a fake database ----
class FakeQuery:
    def __init__(self, data):
        self._data = data

    def select(self, *_a, **_k):
        return self

    def eq(self, *_a, **_k):
        return self

    def order(self, *_a, **_k):
        return self

    def limit(self, *_a, **_k):
        return self

    def execute(self):
        return type("Result", (), {"data": self._data})()


class FakeClient:
    def __init__(self, data):
        self._data = data

    def table(self, _name):
        return FakeQuery(self._data)


rows_newest_first = [
    {"session_id": "S3", "value": 1},
    {"session_id": "S3", "value": 1},
    {"session_id": "S2", "value": 2},
    {"session_id": "S2", "value": 1},
    {"session_id": "S1", "value": 3},
    {"session_id": "S1", "value": 3},
    {"session_id": None, "value": 3},  # no session: ignored
    {"session_id": "S0", "value": 3},  # fourth session: cut off by max_sessions=3
]
db._client = FakeClient(rows_newest_first)
check("averages per earlier session, newest first", db.get_recent_session_levels("x") == [1.0, 1.5, 3.0])
check("the session in progress is left out", db.get_recent_session_levels("x", exclude_session_id="S3") == [1.5, 3.0, 3.0])
db._client = FakeClient([])
check("no rows -> empty list", db.get_recent_session_levels("x") == [])
db._client = None

print()
if failures:
    print(f"{failures} check(s) FAILED.")
    sys.exit(1)
print("All checks passed.")
