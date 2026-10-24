"""
Offline test for sign up, log in and the login token (Phase 2, Stage 7c).

It does NOT use the internet, Gemini or Supabase, so it is free and fast.
A pretend database (kept in memory) and a pretend tutor are used instead.
Run from the repo root:   python backend\\tests\\test_auth.py
"""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the backend folder

# A made-up secret for the tests only (never the real one in .env).
os.environ["AUTH_SECRET"] = "test-secret-for-offline-tests-only-0123456789"

from itsdangerous import URLSafeTimedSerializer  # noqa: E402

from app import api, auth, db  # noqa: E402

failures = 0


def check(name, condition):
    global failures
    print(("PASS  " if condition else "FAIL  ") + name)
    if not condition:
        failures += 1


# ---- a pretend database: code -> {"id", "password_hash"} ----
STUDENTS = {}
SAVED = []  # (student code, saved?) per /chat call


def find_student_login(code):
    return STUDENTS.get(code)


def create_student_with_password(code, password_hash):
    if code in STUDENTS:
        raise RuntimeError("duplicate key")
    STUDENTS[code] = {"id": "uuid-" + code, "password_hash": password_hash}
    return STUDENTS[code]["id"]


db.is_configured = lambda: True
db.find_student_login = find_student_login
db.create_student_with_password = create_student_with_password
db.find_student = lambda code: STUDENTS[code]["id"] if code in STUDENTS else None
db.get_progress_rows = lambda student_uuid, max_sessions=10: ([], [])
api.socratic_response = lambda problem, history, extra_instruction="", raise_on_error=False: "What do you notice?"
api.log_turn = lambda code, session_id, *rest, **kw: SAVED.append(code) or "session-1"
api.load_scaffold_level = lambda code, session_id: 3
api.load_reflection_type = lambda *a: None

client = api.app.test_client()


def signup(code, password="password1"):
    return client.post("/auth/signup", json={"student_id": code, "password": password})


def login(code, password="password1"):
    return client.post("/auth/login", json={"student_id": code, "password": password})


def bearer(token):
    return {"Authorization": "Bearer " + token}


# ---- 1. sign up ----
r = signup("P001")
body = r.get_json()
check("sign up -> 201 with a token", r.status_code == 201 and isinstance(body.get("token"), str))
check("sign up -> says whose account it is", body.get("student_id") == "P001")
check("sign up reply is not cached", r.headers.get("Cache-Control") == "no-store")
stored = STUDENTS["P001"]["password_hash"]
check("the password itself is NOT stored", "password1" not in stored)
check("a hash is stored instead", len(stored) > 30)

r = signup("P001", "another-pass")
check("same code again -> 409 code_taken", r.status_code == 409 and r.get_json()["error"]["code"] == "code_taken")
check("the first password still works", login("P001").status_code == 200)

check("short password -> 400", signup("P002", "short").status_code == 400)
check("password over 128 characters -> 400", signup("P002", "x" * 129).status_code == 400)
check("a name with a space -> 400", signup("Anna Lee").status_code == 400)
check("an email -> 400", signup("a@b.com").status_code == 400)
check("no password -> 400", client.post("/auth/signup", json={"student_id": "P002"}).status_code == 400)
check("not JSON -> 400", client.post("/auth/signup", data="hello").status_code == 400)
check("nothing was made for bad requests", "P002" not in STUDENTS)

# ---- 2. log in ----
r = login("P001")
check("right code + password -> 200 with a token", r.status_code == 200 and r.get_json().get("token"))
token = r.get_json()["token"]

wrong_pw = login("P001", "wrong-password")
wrong_code = login("NOBODY", "password1")
check("wrong password -> 401 details_dont_match",
      wrong_pw.status_code == 401 and wrong_pw.get_json()["error"]["code"] == "details_dont_match")
check("unknown code gives the SAME answer as a wrong password",
      wrong_code.status_code == 401 and wrong_code.get_json() == wrong_pw.get_json())

STUDENTS["OLDKID"] = {"id": "uuid-old", "password_hash": None}  # made before Stage 7c
check("a student with no password cannot log in", login("OLDKID", "anything1").status_code == 401)

# ---- 3. too many wrong tries ----
signup("LOCKME")
for _ in range(auth.MAX_FAILS):
    login("LOCKME", "wrong-password")
r = login("LOCKME")
check("after 5 wrong tries even the right password must wait (429)",
      r.status_code == 429 and r.get_json()["error"]["code"] == "too_many_attempts")
check("other codes are not affected", login("P001").status_code == 200)
long_ago = auth._fails["LOCKME"][0] - auth.FAIL_WINDOW - 1
auth._fails["LOCKME"] = [long_ago] * auth.MAX_FAILS
check("after 15 minutes the code can log in again", login("LOCKME").status_code == 200)
check("a good log in clears the wrong tries", "LOCKME" not in auth._fails)

# ---- 4. the token decides who the student is ----
check("a token gives back its code", auth.code_from_token(token) == "P001")
check("a changed token is refused", auth.code_from_token(token[:-2] + "xx") is None)
forged = URLSafeTimedSerializer("someone-elses-secret-0123456789abcdef", salt="cogniguide-auth-v1").dumps({"code": "P001"})
check("a token signed with another secret is refused", auth.code_from_token(forged) is None)
check("header must say Bearer", auth.token_from_header("Basic " + token) is None)

# /progress
check("progress with the token -> 200", client.get("/progress", headers=bearer(token)).status_code == 200)
check("progress without a token -> 401", client.get("/progress").status_code == 401)
check("progress of someone else -> 403",
      client.get("/progress?student_id=LOCKME", headers=bearer(token)).status_code == 403)
check("progress with a bad token -> 401 login_required",
      client.get("/progress", headers=bearer("nope")).get_json()["error"]["code"] == "login_required")

# /chat
CHAT = {"problem": "Solve 3x - 5 = 2x + 7", "history": []}
r = client.post("/chat", json=CHAT, headers=bearer(token))
check("chat with a token -> 200 and saved for that student", r.status_code == 200 and SAVED[-1] == "P001")
r = client.post("/chat", json={**CHAT, "student_id": "P001"}, headers=bearer(token))
check("chat: the code in the body may match the token", r.status_code == 200)
r = client.post("/chat", json={**CHAT, "student_id": "LOCKME"}, headers=bearer(token))
check("chat: a DIFFERENT code in the body -> 403", r.status_code == 403)
saved_before = len(SAVED)
r = client.post("/chat", json={**CHAT, "student_id": "P001"})
check("chat: claiming a code without a token -> 401", r.status_code == 401)
r = client.post("/chat", json=CHAT)
check("chat with no code and no token still answers", r.status_code == 200)
check("...but nothing is saved", len(SAVED) == saved_before)
r = client.post("/chat", json=CHAT, headers=bearer("nope"))
check("chat with a bad token -> 401 (log in again)", r.status_code == 401)

# ---- 5. no secret set: fail closed ----
secret = os.environ.pop("AUTH_SECRET")
check("no secret: sign up -> 503", signup("P009").status_code == 503)
check("no secret: log in -> 503", login("P001").status_code == 503)
check("no secret: a token is not trusted", client.get("/progress", headers=bearer(token)).status_code == 503)
os.environ["AUTH_SECRET"] = "too-short"
check("a too-short secret counts as no secret", auth.is_configured() is False)
os.environ["AUTH_SECRET"] = secret

db.is_configured = lambda: False
check("no database: sign up -> 503", signup("P010").status_code == 503)
db.is_configured = lambda: True


def broken(_code):
    raise RuntimeError("database is down: secret details")


db.find_student_login = broken
r = login("P001")
check("database error on log in -> 503, not a crash", r.status_code == 503)
check("the error does not leak details", "secret details" not in r.get_data(as_text=True))

print()
print("All checks passed." if failures == 0 else f"{failures} check(s) FAILED.")
sys.exit(1 if failures else 0)
