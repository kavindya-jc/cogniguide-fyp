"""
Live test for Stage 7: does GET /progress show the right numbers for a student?
(Phase 2, Stage 7)

What it does (NO Gemini calls, so it is free):
  1. Puts 3 FAKE sessions into Supabase for a new test student (TESTPROGRESS + the time).
     The student needed a lot of help first, then less and less, fixed 2 mistakes
     and was asked one reflection question in the last session.
  2. Asks the running server: GET /progress?student_id=<that code>
  3. Checks the numbers, the growth sentence, that an unknown code gives empty lists
     (and is not created), and that bad codes are refused.

Start the server first (from the backend folder):  python -m app.api
Then, in a second terminal, from the repo root:
    python experiments\\phase2_adaptive_agent\\test_progress_live.py

Afterwards open this in your browser and type the printed code:
    http://127.0.0.1:5000/dashboard

Only test codes are used. Never use a real name.
"""

import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "backend"))

from app import db  # noqa: E402

BASE = "http://127.0.0.1:5000"
STAMP = time.strftime("%H%M%S")
CODE = f"TESTPROGRESS{STAMP}"
UNKNOWN = f"TESTNOBODY{STAMP}"

# Fake sessions, OLDEST first. Each = the indicators saved during that session.
SESSIONS = [
    [("hint_level", 3), ("scaffold_level", 3), ("stuck", 1), ("hint_level", 3), ("asked_for_answer", 1)],
    [("hint_level", 2), ("scaffold_level", 3), ("hint_level", 2), ("self_correction", 1)],
    [("hint_level", 1), ("scaffold_level", 2), ("hint_level", 1), ("self_correction", 1), ("reflection_improving", 1)],
]

failures = 0


def check(name, condition):
    global failures
    print(("PASS  " if condition else "FAIL  ") + name)
    if not condition:
        failures += 1


if not db.is_configured():
    print("Supabase is not set up in .env (SUPABASE_URL and SUPABASE_SERVICE_KEY). Stopping.")
    sys.exit(1)

student = db.get_or_create_student(CODE)
for rows in SESSIONS:
    session_id = db.create_session(student, "Natalia sold clips (progress test)")
    db.save_indicators(student, session_id, rows)
    time.sleep(0.05)  # so the sessions are in a clear order
print(f"Test student: {CODE}  (3 fake sessions saved)")

try:
    r = requests.get(f"{BASE}/progress", params={"student_id": CODE}, timeout=30)
except requests.exceptions.ConnectionError:
    print("Could not reach the server. Start it first: cd backend, then python -m app.api")
    sys.exit(1)

body = r.json()
print("Server said:", body.get("growth", {}).get("trend"), "|", body.get("totals"))
check("status 200", r.status_code == 200)
check("3 sessions shown", len(body.get("sessions", [])) == 3)
levels = [s["needed_level"] for s in body.get("sessions", [])]
check("help needed went 3.0 -> 2.0 -> 1.0 (oldest first)", levels == [3.0, 2.0, 1.0])
check("growth trend is less_help", body.get("growth", {}).get("trend") == "less_help")
totals = body.get("totals", {})
check("1 stuck, 1 asked for answer", totals.get("stuck") == 1 and totals.get("asked_for_answer") == 1)
check("2 self corrections", totals.get("self_corrections") == 2)
check("1 reflection question, type improving",
      totals.get("reflections") == 1 and body["sessions"][-1].get("reflection_type") == "improving")
check("allowed level 2 in the last session", body["sessions"][-1].get("allowed_level") == 2)
check("no message text and no ids in the reply", "content" not in r.text and "session_id" not in r.text)

r2 = requests.get(f"{BASE}/progress", params={"student_id": UNKNOWN}, timeout=30)
check("unknown code -> 200 with empty lists", r2.status_code == 200 and r2.json().get("sessions") == [])
check("unknown code was NOT created in the database", db.find_student(UNKNOWN) is None)

check("bad code (has a space) -> 400", requests.get(f"{BASE}/progress", params={"student_id": "Anna Lee"}, timeout=30).status_code == 400)
check("missing code -> 400", requests.get(f"{BASE}/progress", timeout=30).status_code == 400)
check("dashboard page opens", requests.get(f"{BASE}/dashboard", timeout=30).status_code == 200)

print()
print("All checks passed." if failures == 0 else f"{failures} check(s) FAILED.")
if failures == 0:
    print(f"Now open http://127.0.0.1:5000/dashboard and type: {CODE}")
sys.exit(1 if failures else 0)
