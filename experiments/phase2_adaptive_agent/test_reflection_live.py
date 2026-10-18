"""
Live test for Stage 6: does the tutor ask the RIGHT reflection question, from the
student's own earlier sessions, and only when the student is working well?
(Phase 2, Stage 6)

What it does:
  1. Puts FAKE earlier sessions into Supabase for two test students (no Gemini used):
       TESTASKER...   - asked for the answer in two earlier sessions
       TESTIMPROVER...- needed a lot of help at first, then less and less
     Each run makes NEW test codes (the time is added to the name).
  2. Plays 3 student messages for each student (fine messages, no struggle).
     That is 3 calls to Gemini per student, 6 in total.
  3. Checks that the 3rd reply carries the right reflection_type (and the first two carry none),
     and that the reflection was saved in the indicators table.

Start the server first (from the backend folder):  python -m app.api
Then, in a second terminal, from the repo root:
    python experiments\\phase2_adaptive_agent\\test_reflection_live.py

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
OPENING = "Let's read the problem together. What is the very first piece of information it gives us?"
MESSAGES = [
    "She sold 48 clips in April.",
    "In May she sold half of 48, so 24 clips.",
    "So I add 48 and 24 together.",
]

STAMP = time.strftime("%H%M%S")
ASKER = f"TESTASKER{STAMP}"
IMPROVER = f"TESTIMPROVER{STAMP}"

# Fake earlier sessions, OLDEST first. Each session = the indicators saved during it.
FAKE_HISTORY = {
    ASKER: [
        [("hint_level", 3), ("hint_level", 3), ("asked_for_answer", 1)],
        [("hint_level", 3), ("hint_level", 2), ("asked_for_answer", 1)],
    ],
    IMPROVER: [
        [("hint_level", 3), ("hint_level", 3), ("hint_level", 3)],
        [("hint_level", 2), ("hint_level", 2), ("hint_level", 1)],
        [("hint_level", 1), ("hint_level", 1), ("hint_level", 1)],
    ],
}
EXPECTED = {ASKER: "asks_for_answer", IMPROVER: "improving"}

failures = 0


def check(name, condition):
    global failures
    print(("PASS  " if condition else "FAIL  ") + name)
    if not condition:
        failures += 1


def seed(code, sessions):
    student_id = db.get_or_create_student(code)
    for rows in sessions:  # one session at a time, so their order is kept
        session_id = db.create_session(student_id, "Fake earlier session for the Stage 6 test")
        db.save_indicators(student_id, session_id, rows)
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
    history = [{"role": "teacher", "content": OPENING}]
    session_id = None
    types = []
    for number, msg in enumerate(MESSAGES, start=1):
        print(f"Student: {msg}")
        history.append({"role": "student", "content": msg})
        reply = call(code, history, session_id)
        session_id = reply["session_id"]
        types.append(reply["reflection_type"])
        print(f"[hint {reply['hint_level']}, scaffold {reply['scaffold_level']}, reflection {reply['reflection_type']}] "
              f"Teacher: {reply['reply']}\n")
        history.append({"role": "teacher", "content": reply["reply"]})
    results[code] = (types, session_id)

print("=" * 70)
for code, expected in EXPECTED.items():
    types, session_id = results[code]
    check(f"{code}: no reflection on messages 1 and 2", types[0] is None and types[1] is None)
    check(f"{code}: reflection on message 3 is '{expected}'", types[2] == expected)
    saved = db.session_has_reflection(session_id) if session_id else False
    check(f"{code}: the reflection was saved in Supabase", saved)

print()
print("Also read the 3rd tutor reply of each student above. It should still ask a normal guiding")
print("question AND one short question about how the student works. It must not give the answer.")
if failures:
    print(f"\n{failures} check(s) FAILED.")
    sys.exit(1)
print("\nAll checks passed.")
