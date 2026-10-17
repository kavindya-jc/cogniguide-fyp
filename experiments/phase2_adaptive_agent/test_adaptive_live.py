"""
Live test for Stage 4: does the tutor act differently for a STRUGGLING student
and a STRONG student?  (Phase 2, Stage 4)

Start the server first (from the backend folder):  python -m app.api
Then, in a second terminal, from the repo root:
    python experiments\\phase2_adaptive_agent\\test_adaptive_live.py

It makes about 8 calls to Gemini. It saves to Supabase under two test codes
(TESTSTRUGGLING and TESTSTRONG). Never use a real name.
"""

import sys

import requests

URL = "http://127.0.0.1:5000/chat"
PROBLEM = (
    "Natalia sold clips to 48 of her friends in April, and then she sold half "
    "as many clips in May. How many clips did she sell altogether?"
)

STUDENTS = {
    "TESTSTRUGGLING": [
        "I don't know how to start.",
        "I'm confused. I still don't understand.",
        "Just tell me the answer.",
    ],
    "TESTSTRONG": [
        "She sold 48 clips in April, and half as many in May.",
        "Half of 48 is 24, so she sold 24 in May.",
        "48 plus 24 is 72 clips altogether.",
    ],
}


def call(student, history, session_id):
    body = {"problem": PROBLEM, "history": history, "student_id": student, "session_id": session_id}
    r = requests.post(URL, json=body, timeout=120)
    if r.status_code != 200:
        print(f"  status {r.status_code}: {r.json()}")
        print("\nThe tutor did not give a real reply (Google may be busy). Wait a minute and run again.")
        sys.exit(1)
    return r.json()


for student, messages in STUDENTS.items():
    print("=" * 70)
    print(f"STUDENT: {student}")
    print("=" * 70)

    history = []
    session_id = None
    out = call(student, history, session_id)
    session_id = out["session_id"]
    print(f"[level {out['hint_level']}] Teacher: {out['reply']}\n")
    history.append({"role": "teacher", "content": out["reply"]})

    for msg in messages:
        print(f"Student: {msg}")
        history.append({"role": "student", "content": msg})
        out = call(student, history, session_id)
        print(f"[level {out['hint_level']}] Teacher: {out['reply']}\n")
        history.append({"role": "teacher", "content": out["reply"]})

print("Compare the two chats: the struggling student should reach level 3 and get a more")
print("concrete (but still not final) hint. The strong student should stay at level 1.")
