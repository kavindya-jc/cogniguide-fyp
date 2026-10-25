"""
CogniGuide Flask API - Phase 2, Stages 1, 3, 4, 5, 6, 7 and 7c

Exposes the Socratic agent over HTTP:
    GET  /health  -> {"status": "ok"}
    POST /auth/signup -> {"token": "...", "student_id": CODE}  (Stage 7c)
    POST /auth/login  -> {"token": "...", "student_id": CODE}  (Stage 7c)
    POST /chat    -> {"reply": "...", "session_id": "..." or null, "hint_level": 1-3, "scaffold_level": 1-3,
                   "reflection_type": "..." or null}
    GET  /progress -> the logged-in student's own progress numbers (Stage 7, token since 7c)
    GET  /dashboard -> a simple web page that shows /progress as words, a chart and cards (Stage 7)
    GET  /problems -> the problem list, without answers (agent plan, Phase 1)

Stage 3: if the request has a student_id, the chat is saved to Supabase
(through db.py). Saving never breaks the chat: if it fails, the student
still gets the tutor's reply and the error goes to the server log.

Stage 4: adaptive.py reads the student's recent messages and picks a hint
level (1-3). That level is added to the tutor's instructions. If Gemini
cannot give a real reply, /chat answers 503 "tutor_unavailable" and NOTHING
is saved (no fallback sentence in the database).

Stage 5: scaffolding.py reads the student's EARLIER sessions from Supabase and, if
the student needs less and less help, lowers the highest hint level the tutor may use
(the "scaffold level"). If the database cannot be read, or the student is new, nothing
changes (scaffold level 3 = full support).

Stage 6: reflection.py can add ONE reflection question per session that refers to how the
student worked in earlier sessions (numbers only, never old message text). If anything goes
wrong while reading the history, no reflection question is asked and the chat works as before.

Stage 7: progress.py sums up the numbers saved by Stages 4 to 6 for ONE student. GET /progress
returns only numbers (never message text) and only for the anonymous code that was asked for.
A new student gives empty lists. If the database cannot be read, /progress answers 503 and the
chat is not affected. The dashboard page (static/dashboard.html) calls /progress from the same server.

Stage 7c: sign up and log in with an anonymous code + password (auth.py). The app then sends
"Authorization: Bearer <token>" on /chat and /progress, and the server takes the student's code
from the token, never from the request. Without a token, /chat still answers but saves nothing,
and /progress refuses.

Agent plan, Phase 1: problems.py keeps the problem bank (backend/data/problems.json) with the
answer, key steps and common mistakes. GET /problems gives the app only id, area, grade and
text: the answer never leaves the server.

Agent plan, Phase 1 (Step 1.3): the tutoring turn itself (Stages 3 to 6 above) now lives in
tutor_agent.py. /chat only checks the request and who the student is, then calls
tutor_agent.run_turn().

See docs/api_contract.md for the full request/reply format.

Run from the backend/ folder:
    python -m app.api
"""

import re
import uuid

from flask import Flask, jsonify, request
from flask_cors import CORS

from app import auth, db, problems, progress, tutor_agent
from app.models.socratic_agent import TutorUnavailable

MAX_TEXT_LENGTH = 2000
MAX_HISTORY_ITEMS = 50
VALID_ROLES = ("teacher", "student")
# Anonymous codes only (like P001). No spaces, no '@', so names/emails are rejected.
STUDENT_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")
# Problem ids look like "alg-9-1".
PROBLEM_ID_PATTERN = re.compile(r"^[a-z0-9-]{1,40}$")

app = Flask(__name__)
# Development only: allow any website/app to call us. Restrict before Phase 3.
CORS(app)


def error_response(status, code, message):
    """Build the standard error JSON used by every error."""
    return jsonify({"error": {"code": code, "message": message}}), status


def validate_chat_body(body):
    """Return an error message (string) if the body is bad, else None."""
    if not isinstance(body, dict):
        return "Request body must be a JSON object."

    # Agent plan, Step 1.4: a problem from the bank is named by its id. Then 'problem'
    # (the text) may be left out, because the server knows the text itself.
    problem_id = body.get("problem_id")
    if problem_id is not None:
        if not isinstance(problem_id, str) or not PROBLEM_ID_PATTERN.match(problem_id):
            return "'problem_id' must be the id of a problem from GET /problems."

    problem = body.get("problem")
    if problem is None and problem_id is not None:
        pass  # the text comes from the problem bank
    elif not isinstance(problem, str) or not problem.strip():
        return "'problem' is required and must be a non-empty string."
    elif len(problem) > MAX_TEXT_LENGTH:
        return f"'problem' must be at most {MAX_TEXT_LENGTH} characters."

    history = body.get("history", [])
    if not isinstance(history, list):
        return "'history' must be a list."
    if len(history) > MAX_HISTORY_ITEMS:
        return f"'history' can have at most {MAX_HISTORY_ITEMS} items."

    for i, turn in enumerate(history):
        if not isinstance(turn, dict):
            return f"history[{i}] must be an object with 'role' and 'content'."
        if turn.get("role") not in VALID_ROLES:
            return f"history[{i}].role must be 'teacher' or 'student'."
        content = turn.get("content")
        if not isinstance(content, str) or not content.strip():
            return f"history[{i}].content must be a non-empty string."
        if len(content) > MAX_TEXT_LENGTH:
            return f"history[{i}].content must be at most {MAX_TEXT_LENGTH} characters."

    student_id = body.get("student_id")
    if student_id is not None:
        if not isinstance(student_id, str) or not STUDENT_ID_PATTERN.match(student_id):
            return "'student_id' must be an anonymous code of 1-64 letters, digits, '_' or '-' (no names or emails)."

    session_id = body.get("session_id")
    if session_id is not None:
        try:
            uuid.UUID(session_id)
        except (ValueError, AttributeError, TypeError):
            return "'session_id' must be the session id returned by a previous /chat reply."

    return None


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


def _no_store(response):
    """Personal replies (tokens, progress): the browser must not keep a copy."""
    response.headers["Cache-Control"] = "no-store"
    return response


def _read_login_body():
    """(code, password, error_response or None) from a sign up / log in request."""
    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        return None, None, error_response(400, "invalid_request", "Request body must be a JSON object.")
    code = body.get("student_id")
    if not isinstance(code, str) or not STUDENT_ID_PATTERN.match(code):
        return None, None, error_response(
            400, "invalid_request",
            "'student_id' must be an anonymous code of 1-64 letters, digits, '_' or '-' (no names or emails)."
        )
    password = body.get("password")
    problem = auth.password_problem(password)
    if problem:
        return None, None, error_response(400, "invalid_request", problem)
    return code, password, None


def _auth_unavailable():
    return error_response(503, "auth_unavailable", "Sign in is not available right now. Please try again later.")


def student_from_request():
    """Stage 7c: (code, error_response). code is None when no token was sent.

    A token that is wrong or too old gives a 401, so the app can ask the student to log in again.
    """
    token = auth.token_from_header(request.headers.get("Authorization"))
    if token is None:
        return None, None
    if not auth.is_configured():
        return None, _auth_unavailable()
    code = auth.code_from_token(token)
    if code is None:
        return None, error_response(401, "login_required", "Please log in again.")
    return code, None


@app.post("/auth/signup")
def signup():
    """Stage 7c: make a new account. 409 if the code is taken."""
    code, password, err = _read_login_body()
    if err:
        return err
    if not auth.is_configured() or not db.is_configured():
        return _auth_unavailable()
    try:
        if db.find_student_login(code) is not None:
            return error_response(409, "code_taken", "That code is taken. Try a different one.")
        try:
            db.create_student_with_password(code, auth.hash_password(password))
        except Exception:
            # Two sign ups for the same code at the same moment: the second one loses.
            if db.find_student_login(code) is not None:
                return error_response(409, "code_taken", "That code is taken. Try a different one.")
            raise
    except Exception as err:
        app.logger.error("Sign up failed: %s", err)  # never log the password
        return _auth_unavailable()
    return _no_store(jsonify({"token": auth.make_token(code), "student_id": code})), 201


@app.post("/auth/login")
def login():
    """Stage 7c: log in. A wrong code and a wrong password give the SAME answer."""
    code, password, err = _read_login_body()
    if err:
        return err
    if not auth.is_configured() or not db.is_configured():
        return _auth_unavailable()
    if auth.is_locked(code):
        return error_response(429, "too_many_attempts", "Too many tries. Please wait 15 minutes and try again.")
    try:
        row = db.find_student_login(code)
    except Exception as err:
        app.logger.error("Log in failed: %s", err)
        return _auth_unavailable()
    if not auth.password_matches(row.get("password_hash") if row else None, password):
        auth.record_fail(code)
        return error_response(401, "details_dont_match", "That code and password don't match.")
    auth.clear_fails(code)
    return _no_store(jsonify({"token": auth.make_token(code), "student_id": code}))


@app.post("/chat")
def chat():
    body = request.get_json(silent=True)  # None if body is missing / not JSON
    if body is None:
        return error_response(400, "invalid_request", "Request body must be valid JSON.")

    problem_msg = validate_chat_body(body)
    if problem_msg:
        return error_response(400, "invalid_request", problem_msg)

    # Stage 7c: who is this? Only the token can say. A code in the body must match it.
    token_code, auth_err = student_from_request()
    if auth_err:
        return auth_err
    body_code = body.get("student_id")
    if body_code and token_code is None:
        return error_response(401, "login_required", "Please log in to save your work.")
    if body_code and body_code != token_code:
        return error_response(403, "forbidden", "That is not your account.")
    student_code = token_code  # None = an anonymous chat that is not saved

    # Step 1.4: a bank problem is used with the server's own text (the same text the app shows).
    problem_id = body.get("problem_id")
    problem_text = body.get("problem")
    if problem_id is not None:
        try:
            bank_problem = problems.find(problem_id)
        except problems.ProblemBankError as err:
            app.logger.error("Problem bank cannot be read: %s", err)
            return error_response(503, "problems_unavailable", "The problem list is not available right now.")
        if bank_problem is None:
            return error_response(400, "invalid_request", "'problem_id' must be the id of a problem from GET /problems.")
        problem_text = bank_problem["text"]

    try:
        result = tutor_agent.run_turn(
            student_code, problem_text, body.get("history", []), body.get("session_id"), problem_id=problem_id
        )
    except TutorUnavailable as err:
        # Gemini was busy or failed. Save nothing, tell the app clearly.
        app.logger.error("Tutor unavailable: %s", err)
        return error_response(503, "tutor_unavailable", "The tutor is busy right now. Please try again in a moment.")
    except Exception as err:  # e.g. missing GEMINI_API_KEY
        app.logger.error("socratic_response failed: %s", err)
        return error_response(500, "server_error", "The tutor is unavailable right now.")

    return jsonify(result)


@app.get("/progress")
def progress_view():
    """Stage 7: this student's own progress numbers. Reads only; never creates a student.

    Stage 7c: needs the login token; the student is the one in the token. An old-style
    ?student_id=CODE is still allowed, but only if it is the same code.
    """
    student_code, auth_err = student_from_request()
    if auth_err:
        return auth_err
    if student_code is None:
        return error_response(401, "login_required", "Please log in to see your progress.")
    asked = request.args.get("student_id")
    if asked is not None and asked != student_code:
        return error_response(403, "forbidden", "You can only see your own progress.")
    if not db.is_configured():
        return error_response(503, "progress_unavailable", "Progress is not available right now.")

    try:
        student_uuid = db.find_student(student_code)
        if student_uuid is None:
            sessions, indicators = [], []  # a new student: empty lists, nothing is created
        else:
            sessions, indicators = db.get_progress_rows(student_uuid)
        body = progress.build_progress(student_code, sessions, indicators)
    except Exception as err:
        app.logger.error("Reading progress failed: %s", err)
        return error_response(503, "progress_unavailable", "Progress is not available right now.")

    return _no_store(jsonify(body))  # personal numbers: do not let the browser keep a copy


@app.get("/problems")
def problem_list():
    """Agent plan, Phase 1: the problems the student can pick, WITHOUT answers.

    Optional filters: ?area=algebra and/or ?grade=9. No login needed: the list has no
    personal data, and the answers, steps and mistakes are never in it.
    """
    area = request.args.get("area")
    if area is not None and area not in problems.AREAS:
        return error_response(400, "invalid_request", f"'area' must be one of: {', '.join(problems.AREAS)}.")
    grade = request.args.get("grade")
    if grade is not None:
        if not grade.isdigit() or int(grade) not in problems.GRADES:
            return error_response(400, "invalid_request", "'grade' must be 8, 9, 10 or 11.")
        grade = int(grade)
    try:
        items = problems.list_public(area=area, grade=grade)
    except problems.ProblemBankError as err:
        app.logger.error("Problem bank cannot be read: %s", err)
        return error_response(503, "problems_unavailable", "The problem list is not available right now.")
    return jsonify({"problems": items})


@app.get("/dashboard")
def dashboard():
    """Stage 7: the simple progress page (a plain HTML file in app/static)."""
    return app.send_static_file("dashboard.html")


@app.errorhandler(404)
def not_found(_err):
    return error_response(404, "not_found", "That URL does not exist.")


@app.errorhandler(405)
def method_not_allowed(_err):
    return error_response(405, "method_not_allowed", "That method is not allowed here.")


@app.errorhandler(500)
def server_error(_err):
    return error_response(500, "server_error", "Something went wrong on the server.")


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
