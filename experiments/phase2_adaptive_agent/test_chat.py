"""
Manual test for the /chat endpoint (Phase 2, Stages 1, 3 and 4).

Start the server first (from the backend folder):  python -m app.api
Then, in a second terminal, from the repo root:     python experiments\\phase2_adaptive_agent\\test_chat.py

You need:  pip install requests
"""

import sys

import requests

URL = "http://127.0.0.1:5000/chat"
PROBLEM = (
    "Natalia sold clips to 48 of her friends in April, and then she sold half "
    "as many clips in May. How many clips did she sell altogether?"
)
STUDENT = "TEST01"  # anonymous test code; never use a real name


def call(history, session_id=None):
    body = {"problem": PROBLEM, "history": history, "student_id": STUDENT, "session_id": session_id}
    r = requests.post(URL, json=body, timeout=120)
    print(f"  status {r.status_code}: {r.json()}")
    if r.status_code != 200:
        print("\nThe tutor did not give a real reply (Google may be busy). Nothing was saved. Wait a minute and run again.")
        sys.exit(1)
    return r.json()


print("1) First message (no history):")
first = call([])
session_id = first.get("session_id")

print("\n2) Student says they are stuck (hint_level should be 2):")
second = call(
    [
        {"role": "teacher", "content": first["reply"]},
        {"role": "student", "content": "I don't know how to start."},
    ],
    session_id,
)

print("\n3) Student asks for the answer (hint_level should be 3, and the tutor should NOT give the answer):")
call(
    [
        {"role": "teacher", "content": first["reply"]},
        {"role": "student", "content": "I don't know how to start."},
        {"role": "teacher", "content": second["reply"]},
        {"role": "student", "content": "Just tell me the answer."},
    ],
    session_id,
)

print("\nDone. If Supabase is set up, session_id above is a long id (the same on all three replies).")
