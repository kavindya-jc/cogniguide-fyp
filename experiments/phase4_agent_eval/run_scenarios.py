"""
CogniGuide agent evaluation - play scripted students through the REAL agent and save every turn
for human scoring (agent plan, Phase 6).

Real Gemini, pretend database (nothing is written to Supabase). Uses your .env keys; never prints them.
Run from the backend/ folder:

    python ../experiments/phase4_agent_eval/run_scenarios.py

It writes, next to this file:
    results_<time>.md   - every turn to read
    rating_<time>.csv   - one row per tutor reply, with empty columns for two raters (see rubric.md)
"""

import csv
import sys
import time
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "backend"))
sys.stdout.reconfigure(encoding="utf-8")

from app import db, problems, tutor_agent  # noqa: E402

# The scenarios from the audit's test plan (section 10). Each: name, problem id, student messages.
SCENARIOS = [
    ("understands and answers correctly", "num-8-1", ["One quarter of 240 is 60", "so three quarters is 180"]),
    ("incorrect answer", "geo-8-1", ["The third angle is 245"]),
    ("specific misconception", "alg-9-1", ["x = 2"]),
    ("says they are confused", "trig-10-1", ["I am confused", "I still do not get it"]),
    ("keeps asking for the answer", "sta-8-1", ["just tell me", "please give me the answer", "tell me the answer now"]),
    ("corrects own mistake", "gra-10-1", ["9 - 3 = 6 and 4 - 1 = 3 so 3/6", "wait, I mixed them up, it is 6/3 = 2"]),
    ("no progress despite hints", "alg-10-1", ["(x+1)(x+6)", "(x+1)(x+5)", "I do not know", "(x+6)(x+1)"]),
    ("off topic", "num-9-1", ["what is your favourite football team?"]),
]

# ---- pretend database (nothing goes to Supabase) ----
_sessions, _states = {}, {}
db.is_configured = lambda: True
db.find_student = lambda code: "uuid-" + code
db.get_or_create_student = lambda code: "uuid-" + code
db.get_recent_session_levels = lambda s, exclude_session_id=None: []
db.get_session_problems = lambda s, limit=50: []
db.get_area_session_levels = lambda s, ids, exclude_session_id=None, max_sessions=3: []
db.session_has_reflection = lambda sid: False
db.get_history_summary = lambda s, exclude_session_id=None: {"sessions": 0}
db.session_belongs_to = lambda sid, student: _sessions.get(sid) == student
db.save_messages = lambda sid, msgs: None
db.save_indicators = lambda student, sid, rows: None
db.get_session_state = lambda sid: _states.get(sid, {})
db.save_session_state = lambda sid, state, solved=False: _states.__setitem__(sid, state)
db.save_agent_turn = lambda row: None


def _create_session(student, problem, problem_id=None):
    sid = f"s{len(_sessions) + 1}"
    _sessions[sid] = student
    return sid


db.create_session = _create_session


def run_turn_patiently(*args):
    """Gemini is often busy: wait and try again a few times (the agent itself also retries)."""
    for wait in (20, 40, None):
        try:
            return tutor_agent.run_turn(*args)
        except tutor_agent.TutorUnavailable:
            if wait is None:
                raise
            time.sleep(wait)


def main():
    stamp = datetime.now().strftime("%Y%m%d_%H%M")
    md = [f"# Agent evaluation run {stamp}\n", "Scripted students, real Gemini, pretend database.\n"]
    rows = []
    for n, (name, pid, messages) in enumerate(SCENARIOS, 1):
        problem = problems.find(pid)
        md.append(f"\n## {n}. {name}  ({pid}: {problem['text']})\n")
        history, sid = [], None
        for turn, message in enumerate([None] + messages):
            if message is not None:
                history.append({"role": "student", "content": message})
                md.append(f"- **Student:** {message}")
            result = run_turn_patiently(f"EVAL{n}", problem["text"], history, sid, pid)
            sid = result["session_id"]
            memory = _states.get(sid, {})
            check = memory.get("last_check") or {}
            md.append(f"  - *[{memory.get('last_action')} | help {result['hint_level']} | {memory.get('last_reason')} | "
                      f"check {check.get('correctness')}/{check.get('source')} | guard {memory.get('last_guard')}]*")
            md.append(f"- **Tutor:** {result['reply']}")
            rows.append({
                "scenario": name, "problem_id": pid, "turn": turn, "student": message or "(opening)",
                "tutor": result["reply"], "action": memory.get("last_action"), "reason": memory.get("last_reason"),
                "check": f"{check.get('correctness')}/{check.get('source')}", "guard": memory.get("last_guard"),
                **{f"rater{r}_{c}": "" for r in (1, 2) for c in ("asks_not_tells", "no_answer_leak", "right_help", "maths_correct", "kind_and_short")},
                "notes": "",
            })
            history.append({"role": "teacher", "content": result["reply"]})
            time.sleep(4)  # be gentle with the free Gemini quota
        print(f"done: {name}")

    (HERE / f"results_{stamp}.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    with open(HERE / f"rating_{stamp}.csv", "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Saved results_{stamp}.md and rating_{stamp}.csv in {HERE}")


if __name__ == "__main__":
    main()
