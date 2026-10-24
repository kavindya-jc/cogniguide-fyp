"""
Offline test for progress.py and GET /progress, GET /dashboard (Phase 2, Stage 7).

It does NOT use the internet, Gemini or Supabase, so it is free and fast.
A pretend database (kept in memory) is used instead.
Run from the repo root:   python backend\\tests\\test_progress.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the backend folder

import os  # noqa: E402

# A made-up secret for the tests only (never the real one in .env).
os.environ["AUTH_SECRET"] = "test-secret-for-offline-tests-only-0123456789"

from app import api, auth, db, progress  # noqa: E402

failures = 0


def check(name, condition):
    global failures
    print(("PASS  " if condition else "FAIL  ") + name)
    if not condition:
        failures += 1


def rows(session_id, hint_levels, scaffold=3, stuck=0, asked=0, fixed=0, reflection=None):
    """Indicator rows for one pretend session."""
    out = [{"session_id": session_id, "indicator_type": "hint_level", "value": v} for v in hint_levels]
    out.append({"session_id": session_id, "indicator_type": "scaffold_level", "value": scaffold})
    out += [{"session_id": session_id, "indicator_type": "stuck", "value": 1}] * stuck
    out += [{"session_id": session_id, "indicator_type": "asked_for_answer", "value": 1}] * asked
    out += [{"session_id": session_id, "indicator_type": "self_correction", "value": 1}] * fixed
    if reflection:
        out.append({"session_id": session_id, "indicator_type": "reflection_" + reflection, "value": 1})
    return out


def sess(sid, day):
    return {"id": sid, "started_at": f"2026-10-{day:02d}T10:00:00+00:00"}


# ---- 1. progress.py (no database, no Flask) ----
empty = progress.build_progress("P001", [], [])
check("new student -> empty session list", empty["sessions"] == [])
check("new student -> totals are zero", empty["totals"]["sessions"] == 0 and empty["totals"]["stuck"] == 0)
check("new student -> not_enough_data", empty["growth"]["trend"] == "not_enough_data")

one = progress.build_progress("P001", [sess("a", 1)], rows("a", [2, 2]))
check("1 session -> not_enough_data", one["growth"]["trend"] == "not_enough_data")
check("needed level is the average", one["sessions"][0]["needed_level"] == 2.0)

# sessions come NEWEST first from the database; the reply is OLDEST first
improving = progress.build_progress(
    "P001", [sess("c", 3), sess("b", 2), sess("a", 1)],
    rows("a", [3, 3, 3]) + rows("b", [2, 2]) + rows("c", [1, 1, 1], scaffold=1, fixed=2, reflection="improving"))
check("order is oldest first", [s["needed_level"] for s in improving["sessions"]] == [3.0, 2.0, 1.0])
check("help fell 2.0 -> less_help", improving["growth"]["trend"] == "less_help")
check("self corrections counted", improving["totals"]["self_corrections"] == 2)
check("reflection type shown as a word", improving["sessions"][-1]["reflection_type"] == "improving")
check("reflections counted", improving["totals"]["reflections"] == 1)
check("allowed level shown", improving["sessions"][-1]["allowed_level"] == 1)

worse = progress.build_progress("P001", [sess("b", 2), sess("a", 1)], rows("a", [1, 1]) + rows("b", [2, 2]))
check("help rose by 1.0 -> more_help", worse["growth"]["trend"] == "more_help")
same = progress.build_progress("P001", [sess("b", 2), sess("a", 1)], rows("a", [2, 2]) + rows("b", [2.3, 2.3]))
check("small change -> steady", same["growth"]["trend"] == "steady")
edge = progress.build_progress("P001", [sess("b", 2), sess("a", 1)], rows("a", [2.5]) + rows("b", [2.0]))
check("exactly 0.5 lower -> less_help", edge["growth"]["trend"] == "less_help")

only_tutor = progress.build_progress("P001", [sess("b", 2), sess("a", 1)], rows("a", [1, 1]))
check("session with no hint_level rows is left out", len(only_tutor["sessions"]) == 1)
other_kind = progress.build_progress("P001", [sess("a", 1)], [{"session_id": "a", "indicator_type": "reflection_nonsense", "value": 1}] + rows("a", [1]))
check("unknown reflection name is ignored", other_kind["sessions"][0]["reflection_type"] is None)

window = progress.build_progress(
    "P001", [sess("d", 4), sess("c", 3), sess("b", 2), sess("a", 1)],
    rows("a", [3]) + rows("b", [2]) + rows("c", [2]) + rows("d", [2]))
check("only the newest 3 sessions are compared (oldest 3.0 ignored)", window["growth"]["trend"] == "steady")

text = repr(improving)
check("reply has no session ids", "'id'" not in text and "session_id" not in text)

# ---- 2. The Flask routes, with a pretend database ----
FAKE = {"P001": {"uuid": "u1", "sessions": [sess("c", 3), sess("b", 2), sess("a", 1)],
                 "indicators": rows("a", [3, 3]) + rows("b", [2]) + rows("c", [1, 1])},
        "P002": {"uuid": "u2", "sessions": [sess("z", 9)], "indicators": rows("z", [2])}}
calls = {"created": 0}

db.is_configured = lambda: True
db.find_student = lambda code: FAKE[code]["uuid"] if code in FAKE else None


def fake_rows(student_uuid, max_sessions=10):
    for rec in FAKE.values():
        if rec["uuid"] == student_uuid:
            return rec["sessions"], rec["indicators"]
    return [], []


db.get_progress_rows = fake_rows
db.get_or_create_student = lambda code: calls.__setitem__("created", calls["created"] + 1)

client = api.app.test_client()


def as_(code):
    """Stage 7c: the login token header for this student."""
    return {"Authorization": "Bearer " + auth.make_token(code)}


r = client.get("/progress", headers=as_("P001"))
body = r.get_json()
check("GET /progress -> 200", r.status_code == 200)
check("reply has the student's code", body["student_id"] == "P001")
check("reply has 3 sessions", len(body["sessions"]) == 3)
check("growth sentence is there", body["growth"]["trend"] == "less_help" and len(body["growth"]["message"]) > 10)
check("Cache-Control is no-store", r.headers.get("Cache-Control") == "no-store")

r2 = client.get("/progress", headers=as_("P002"))
check("another student gets only their own session", len(r2.get_json()["sessions"]) == 1)

r3 = client.get("/progress", headers=as_("NEWKID"))
check("unknown student -> 200 with empty lists", r3.status_code == 200 and r3.get_json()["sessions"] == [])
check("unknown student is NOT created", calls["created"] == 0)

# Stage 7c: only the logged-in student, and only their own numbers.
check("no token -> 401", client.get("/progress").status_code == 401)
check("old-style ?student_id without a token -> 401", client.get("/progress?student_id=P001").status_code == 401)
check("a made-up token -> 401", client.get("/progress", headers={"Authorization": "Bearer abc.def"}).status_code == 401)
check("asking for ANOTHER student's code -> 403",
      client.get("/progress?student_id=P002", headers=as_("P001")).status_code == 403)
check("asking for your own code is fine",
      client.get("/progress?student_id=P001", headers=as_("P001")).status_code == 200)
check("error uses the standard format", "code" in client.get("/progress").get_json()["error"])

db.is_configured = lambda: False
r4 = client.get("/progress", headers=as_("P001"))
check("no Supabase settings -> 503 progress_unavailable", r4.status_code == 503 and r4.get_json()["error"]["code"] == "progress_unavailable")

db.is_configured = lambda: True


def broken(_uuid, max_sessions=10):
    raise RuntimeError("database is down")


db.get_progress_rows = broken
r5 = client.get("/progress", headers=as_("P001"))
check("database error -> 503, not a crash", r5.status_code == 503 and r5.get_json()["error"]["code"] == "progress_unavailable")
check("error message does not leak details", "down" not in r5.get_data(as_text=True))

page = client.get("/dashboard")
html = page.get_data(as_text=True)
check("GET /dashboard -> the page", page.status_code == 200 and "<title>" in html and "/auth/login" in html)
page.close()

print()
print("All checks passed." if failures == 0 else f"{failures} check(s) FAILED.")
sys.exit(1 if failures else 0)
