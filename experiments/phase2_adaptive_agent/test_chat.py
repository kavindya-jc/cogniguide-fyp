"""
Manual test for the /chat endpoint (Phase 2, Stages 1 and 3).

Start the server first (from the backend folder):  python -m app.api
Then, in a second terminal, from the repo root:     python experiments/phase2_adaptive_agent/test_chat.py

You need:  pip install requests
"""

import requests

URL = "http://127.0.0.1:5000/chat"
PROBLEM = (
    "Natalia sold clips to 48 of her friends in April, and then she sold half "
    "as many clips in May. How many clips did she sell altogether?"
)
STUDENT = "TEST01"  # anonymous test code; never use a real name


def call(history, session_id=None):
    body = {"problem": PROBLEM, "history": history, "student_id": STUDENT, "session_id": session_id}
    r = requests.post(URL, json=body, timeout=60)
    print(f"  status {r.status_code}: {r.json()}")
    return r.json()


print("1) First message (no history):")
first = call([])
session_id = first.get("session_id")

print("\n2) Student says they are stuck:")
second = call(
    [
        {"role": "teacher", "content": first["reply"]},
        {"role": "student", "content": "I don't know how to start."},
    ],
    session_id,
)

print("\n3) Student asks for the answer (the tutor should NOT give it):")
call(
    [
        {"role": "teacher", "content": first["reply"]},
        {"role": "student", "content": "I don't know how to start."},
        {"role": "teacher", "content": second["reply"]},
        {"role": "student", "content": "Just tell me the answer."},
    ],
    session_id,
)

print("\nsession_id is None until Supabase is set up (Stage 2). After that it is a long id.")
