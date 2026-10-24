"""
CogniGuide sign up and log in - Phase 2, Stage 7c

Students have only an anonymous code (like P001) and a password. No name,
email or photo.

- Passwords are never stored or logged. Only a salted hash is stored
  (Werkzeug's generate_password_hash, which comes with Flask).
- After sign up or log in the app gets a TOKEN: a signed ticket that says
  "this is student P001", valid for 30 days. The app sends it on every
  /chat and /progress call as:   Authorization: Bearer <token>
  The server trusts the code inside the token, never a code typed in the request.
- Tokens are signed with AUTH_SECRET from .env (never commit it). Without it,
  sign in is switched off and protected calls answer 503 (fail closed).
- Too many wrong passwords: after MAX_FAILS wrong tries for one code within
  FAIL_WINDOW seconds, that code must wait (429). Kept in memory, so it resets
  when the server restarts (fine for one small server).
"""

import os
import threading
import time

from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer
from werkzeug.security import check_password_hash, generate_password_hash

TOKEN_MAX_AGE = 30 * 24 * 60 * 60  # 30 days, in seconds
MIN_PASSWORD = 8
MAX_PASSWORD = 128  # long enough for any real password; stops huge inputs
MAX_FAILS = 5
FAIL_WINDOW = 15 * 60  # 15 minutes, in seconds

_SALT = "cogniguide-auth-v1"

# A real hash of a random password, checked when the code is unknown, so a wrong
# code takes as long as a wrong password (nobody can time which codes exist).
_DUMMY_HASH = generate_password_hash("not-a-real-password-" + os.urandom(8).hex())

_fails = {}  # code -> list of times of recent wrong passwords
_fails_lock = threading.Lock()


def is_configured():
    """True only if the token secret is set (and long enough to be safe)."""
    return len(os.getenv("AUTH_SECRET", "").strip()) >= 32


def _serializer():
    return URLSafeTimedSerializer(os.getenv("AUTH_SECRET", "").strip(), salt=_SALT)


def hash_password(password):
    return generate_password_hash(password)


def password_matches(stored_hash, password):
    """Check a password. stored_hash None (unknown code, or no password) still takes the same time."""
    if not stored_hash:
        check_password_hash(_DUMMY_HASH, password)
        return False
    return check_password_hash(stored_hash, password)


def password_problem(password):
    """Return an error message if the password is not allowed, else None."""
    if not isinstance(password, str):
        return "'password' is required."
    if len(password) < MIN_PASSWORD:
        return f"The password needs at least {MIN_PASSWORD} characters."
    if len(password) > MAX_PASSWORD:
        return f"The password can have at most {MAX_PASSWORD} characters."
    return None


def make_token(code):
    """A signed ticket that says which student this is."""
    return _serializer().dumps({"code": code})


def code_from_token(token):
    """The student's code inside a valid, unexpired token, or None."""
    if not token or not is_configured():
        return None
    try:
        data = _serializer().loads(token, max_age=TOKEN_MAX_AGE)
    except (SignatureExpired, BadSignature):
        return None
    code = data.get("code") if isinstance(data, dict) else None
    return code if isinstance(code, str) else None


def token_from_header(header_value):
    """The token from an 'Authorization: Bearer <token>' header, or None."""
    if not header_value:
        return None
    kind, _, token = header_value.partition(" ")
    if kind.lower() != "bearer" or not token.strip():
        return None
    return token.strip()


def is_locked(code, now=None):
    """True if this code had too many wrong passwords recently."""
    now = time.time() if now is None else now
    with _fails_lock:
        recent = [t for t in _fails.get(code, []) if now - t < FAIL_WINDOW]
        _fails[code] = recent
        return len(recent) >= MAX_FAILS


def record_fail(code, now=None):
    with _fails_lock:
        _fails.setdefault(code, []).append(time.time() if now is None else now)


def clear_fails(code):
    with _fails_lock:
        _fails.pop(code, None)
