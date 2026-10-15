"""
CogniGuide Flask API - Phase 2, Stages 1 and 3

Exposes the Phase 1 baseline Socratic agent over HTTP:
    GET  /health  -> {"status": "ok"}
    POST /chat    -> {"reply": "...", "session_id": "..." or null}

This file only CALLS socratic_response(). It never changes socratic_agent.py.
Stage 3: if the request has a student_id, the chat is saved to Supabase
(through db.py). Saving never breaks the chat: if it fails, the student
still gets the tutor's reply and the error goes to the server log.
See docs/api_contract.md for the full request/reply format.

Run from the backend/ folder:
    python -m app.api
"""

import re
import uuid

from flask import Flask, jsonify, request
from flask_cors import CORS

from app import db
from app.models.socratic_agent import socratic_response

MAX_TEXT_LENGTH = 2000
MAX_HISTORY_ITEMS = 50
VALID_ROLES = ("teacher", "student")
# Anonymous codes only (like P001). No spaces, no '@', so names/emails are rejected.
STUDENT_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")

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

    problem = body.get("problem")
    if not isinstance(problem, str) or not problem.strip():
        return "'problem' is required and must be a non-empty string."
    if len(problem) > MAX_TEXT_LENGTH:
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


def log_turn(student_code, session_id, problem, history, reply):
    """Save this turn to the database and return the session id.

    Saves the student's newest message (if the history ends with one) and the tutor's reply.
    Raises an exception if anything fails; the caller handles it.
    """
    if not db.is_configured():
        app.logger.warning("Supabase is not configured; chat not saved.")
        return session_id

    student_uuid = db.get_or_create_student(student_code)

    if session_id:
        if not db.session_belongs_to(session_id, student_uuid):
            raise ValueError("session_id does not exist or belongs to another student")
    else:
        session_id = db.create_session(student_uuid, problem)

    messages = []
    if history and history[-1]["role"] == "student":
        messages.append(("student", history[-1]["content"]))
    messages.append(("teacher", reply))
    db.save_messages(session_id, messages)

    return session_id


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/chat")
def chat():
    body = request.get_json(silent=True)  # None if body is missing / not JSON
    if body is None:
        return error_response(400, "invalid_request", "Request body must be valid JSON.")

    problem_msg = validate_chat_body(body)
    if problem_msg:
        return error_response(400, "invalid_request", problem_msg)

    history = body.get("history", [])

    try:
        reply = socratic_response(body["problem"], history)
    except Exception as err:  # e.g. missing GEMINI_API_KEY
        app.logger.error("socratic_response failed: %s", err)
        return error_response(500, "server_error", "The tutor is unavailable right now.")

    # Stage 3: save the chat. Never let a database problem break the reply.
    session_id = body.get("session_id")
    student_code = body.get("student_id")
    if student_code:
        try:
            session_id = log_turn(student_code, session_id, body["problem"], history, reply)
        except Exception as err:
            app.logger.error("Saving chat to database failed: %s", err)

    return jsonify({"reply": reply, "session_id": session_id})


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
