"""
Live test for Stage 5: does the tutor give LESS help to a student who has needed
less and less help, and keep full help for a student who keeps struggling?
(Phase 2, Stage 5)

What it does:
  1. Puts FAKE earlier sessions into Supabase for two test students (no Gemini used):
       TESTIMPROVING...  - needed a lot of help at first, then less and less
       TESTSTILLSTUCK... - still needs a lot of help every time
     Each run makes NEW test codes (the time is added to the name), so an old run
     can never change the result of a new run.
  2. Asks the tutor the SAME thing for both students: "I don't know how to start."
     That is 4 calls to Gemini in total.
  3. Prints PASS or FAIL for what we expect.

Start the server first (from the backend folder):  python -m app.api
Then, in a second terminal, from the repo root:
    python experiments\\phase2_adaptive_agent\\test_scaffolding_live.py

Only test codes are used. Never use a real name.
"""

import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "backend"))

from app import db  # noqa: E402

URL = "http://127.0.0.1:5000/chat"
PROBLEM = (
    "Natalia sold clips to 48 of her friends in April, and then she sold half "
    "as many clips in May. How many clips did she sell altogether?"
)

STAMP = time.strftime("%H%M%S")
IMPROVING = f"TESTIMPROVING{STAMP}"
STILL_STUCK = f"TESTSTILLSTUCK{STAMP}"

# Fake earlier sessions, OLDEST first. Each list = the hint levels saved during that session.
FAKE_HISTORY = {
    IMPROVING: [[3, 3, 3], [2, 2, 1], [1, 1, 1], [1, 1, 1]],
    STILL_STUCK: [[3, 3, 3], [3, 2, 3], [2, 3, 3]],
}

# What we expect (scaffold_level, hint_level) after the student says "I don't know how to start."
EXPECTED = {
    IMPROVING: (1, 1),   # help has faded: only hint level 1 allowed
    STILL_STUCK: (3, 2),  # full help: Stage 4 says level 2 for one stuck message
}

failures = 0


def check(name, condition):
    global failures
    print(("PASS  " if condition else "FAIL  ") + name)
    if not condition:
        failures += 1


def seed(code, sessions):
    student_id = db.get_or_create_student(code)
    for levels in sessions:  # one database call per session, so their order is kept
        session_id = db.create_session(student_id, "Fake earlier session for the Stage 5 test")
        db.save_indicators(student_id, session_id, [("hint_level", level) for level in levels])
    print(f"{code}: added {len(sessions)} fake earlier sessions.")


def call(student, history, session_id=None):
    body = {"problem": PROBLEM, "history": history, "student_id": student, "session_id": session_id}
    r = requests.post(URL, json=body, timeout=120)
    if r.status_code != 200:
        print(f"  status {r.status_code}: {r.json()}")
        print("\nThe tutor did not give a real reply (Google may be busy). Wait a minute and run again.")
        sys.exit(1)
    return r.json()


print("Step 1: fake earlier sessions")
for code, sessions in FAKE_HISTORY.items():
    seed(code, sessions)

results = {}
for code in FAKE_HISTORY:
    print("\n" + "=" * 70)
    print(f"STUDENT: {code}")
    print("=" * 70)
    first = call(code, [])
    print(f"[scaffold {first['scaffold_level']}, hint {first['hint_level']}] Teacher: {first['reply']}\n")
    msg = "I don't know how to start."
    print(f"Student: {msg}")
    history = [{"role": "teacher", "content": first["reply"]}, {"role": "student", "content": msg}]
    second = call(code, history, first["session_id"])
    print(f"[scaffold {second['scaffold_level']}, hint {second['hint_level']}] Teacher: {second['reply']}\n")
    results[code] = (second["scaffold_level"], second["hint_level"])

print("=" * 70)
for code, expected in EXPECTED.items():
    check(f"{code}: (scaffold_level, hint_level) is {expected}", results[code] == expected)

print()
print("Also read the two tutor replies above. The improving student should get a smaller")
print("nudge (asked what they would try). The student who is still stuck should get a clearer hint.")
if failures:
    print(f"\n{failures} check(s) FAILED.")
    sys.exit(1)
print("\nAll checks passed.")
