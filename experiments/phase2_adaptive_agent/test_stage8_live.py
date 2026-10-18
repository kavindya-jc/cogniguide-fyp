"""
Live test for Stage 8: does the adaptive tutor behave DIFFERENTLY for different students?
(Phase 2, Stage 8)

It plays three pretend students on three different maths problems through the real /chat:

  STRUGGLING - says "I don't know", "I'm confused", "just tell me the answer"
               (a new student: no earlier sessions)
  STRONG     - works out each step correctly on their own (a new student)
  IMPROVING  - says the same fine things as STRONG, but has 3 fake earlier sessions that show
               they needed less and less help (so the tutor fades its help, Stage 5, and may
               ask one reflection question, Stage 6)

Each student gets a NEW code for each problem (so one problem cannot change the next one).
That is 3 students x 3 problems x 4 messages = 36 calls to Gemini. There is a short pause
between calls so we do not hit the free per-minute limit.

For every tutor reply it records: hint level, scaffold level, reflection type, number of
words, number of question marks, how many numbers the reply mentions, and whether the reply
gave away the final answer too early. Then it prints a comparison table, runs checks, and
saves everything (all replies too, so you can read them) to:
    experiments/phase2_adaptive_agent/stage8_results.json
    experiments/phase2_adaptive_agent/stage8_results.md

Start the server first (from the backend folder):  python -m app.api
Then, in a second terminal, from the repo root:
    python experiments\\phase2_adaptive_agent\\test_stage8_live.py

Only test codes are used (TESTS8...). Never use a real name.
"""

import json
import re
import sys
import time
from pathlib import Path

import requests

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / "backend"))

URL = "http://127.0.0.1:5000"
PAUSE_SECONDS = 4          # wait between Gemini calls (free per-minute limit)
BUSY_RETRY_SECONDS = 30    # one extra try if Google says "busy" (503)

# Each problem: the text, the final answer, and what a strong student says step by step.
PROBLEMS = [
    {
        "name": "clips",
        "problem": "Natalia sold clips to 48 of her friends in April, and then she sold half as many clips "
                   "in May. How many clips did she sell altogether?",
        "answer": "72",
        "first_number": "48",
        "strong": [
            "She sold 48 clips in April.",
            "In May she sold half of 48, so 24 clips.",
            "So I add 48 and 24 together.",
            "48 plus 24 is 72 clips altogether.",
        ],
    },
    {
        "name": "muffins",
        "problem": "A baker made 30 muffins in the morning and 4 trays of 8 muffins in the afternoon. "
                   "He sold 40 muffins. How many muffins does he have left?",
        "answer": "22",
        "first_number": "30",
        "strong": [
            "He made 30 muffins in the morning.",
            "The 4 trays of 8 muffins make 32 muffins in the afternoon.",
            "So he made 30 plus 32 muffins in total, and then I take away the 40 he sold.",
            "30 plus 32 is 62, and 62 minus 40 is 22 muffins left.",
        ],
    },
    {
        "name": "pencils",
        "problem": "Tom has 5 boxes with 12 pencils in each box. He gives 15 pencils to his friends. "
                   "How many pencils does Tom have left?",
        "answer": "45",
        "first_number": "5",
        "strong": [
            "Tom has 5 boxes and each box has 12 pencils.",
            "So the total number of pencils is 5 times 12, which is 60.",
            "Then I take away the 15 pencils he gave to his friends.",
            "60 minus 15 is 45 pencils left.",
        ],
    },
]

STRUGGLING_MESSAGES = [
    "I don't know how to start.",
    "I'm confused, I don't understand.",
    "Just tell me the answer.",
    "Ok, I think the first number is {first_number}.",
]

# Fake earlier sessions for IMPROVING (oldest first). Average of the three = 1.2 -> scaffold level 1,
# and the average fell by 0.5 or more from the oldest to the newest -> reflection type "improving".
IMPROVING_HISTORY = [
    [("hint_level", 2), ("hint_level", 2), ("hint_level", 1)],
    [("hint_level", 1), ("hint_level", 1), ("hint_level", 1)],
    [("hint_level", 1), ("hint_level", 1), ("hint_level", 1)],
]

KINDS = ("struggling", "strong", "improving")


def measure(reply, answer, check_answer):
    """Simple automatic measures of one tutor reply."""
    text = reply.replace(",", "")
    numbers = re.findall(r"(?<![\w.])\d+(?:\.\d+)?(?![\w.])", text)
    sentences = [s for s in re.split(r"(?<=[.!?])\s+", reply.strip()) if s]
    return {
        "words": len(reply.split()),
        "sentences": len(sentences),
        "questions": reply.count("?"),
        "numbers": len(numbers),
        "gave_answer": bool(check_answer and answer in numbers),
    }


def post_chat(body):
    """Call /chat. One extra try after a pause if Google is busy. Returns (reply_dict or None, status)."""
    for attempt in (1, 2):
        r = requests.post(URL + "/chat", json=body, timeout=180)
        if r.status_code == 200:
            return r.json(), 200
        if r.status_code == 503 and attempt == 1:
            print(f"  (Google is busy; waiting {BUSY_RETRY_SECONDS} seconds and trying this message once more)")
            time.sleep(BUSY_RETRY_SECONDS)
            continue
        return None, r.status_code
    return None, 503


def avg(values):
    values = list(values)
    return sum(values) / len(values) if values else 0.0


def save_results(turns, stamp, finished):
    (HERE / "stage8_results.json").write_text(
        json.dumps({"run": stamp, "finished": finished, "turns": turns}, indent=2), encoding="utf-8")
    lines = [f"# Stage 8 results (run {stamp})", ""]
    if not finished:
        lines += ["**This run stopped early. Only the turns below were completed.**", ""]
    lines += ["All tutor replies, so they can be read and labelled by hand. "
              "Test students only (pretend, scripted).", ""]
    for t in turns:
        lines.append(f"## {t['kind']} / {t['problem_name']} / message {t['message_number']}")
        lines.append(f"- Student: {t['student_message']}")
        lines.append(f"- hint {t['hint_level']}, scaffold {t['scaffold_level']}, reflection {t['reflection_type']}, "
                     f"words {t['words']}, questions {t['questions']}, numbers {t['numbers']}, "
                     f"gave answer too early: {t['gave_answer']}")
        lines.append(f"- Tutor: {t['reply']}")
        lines.append("")
    (HERE / "stage8_results.md").write_text("\n".join(lines), encoding="utf-8")


def main():
    from app import db  # imported here so a missing setup gives a clear message

    try:
        requests.get(URL + "/health", timeout=10).raise_for_status()
    except Exception:
        print("The server is not running. Start it first: cd backend, then python -m app.api")
        return 1
    if not db.is_configured():
        print("Supabase is not set up in .env (SUPABASE_URL and SUPABASE_SERVICE_KEY). Fix that and try again.")
        return 1

    stamp = time.strftime("%H%M%S")
    turns = []
    total = len(KINDS) * len(PROBLEMS) * 4
    print(f"This will make {total} calls to Gemini (about {total * (PAUSE_SECONDS + 3) // 60 + 1} minutes).\n")

    for p_index, prob in enumerate(PROBLEMS, start=1):
        for kind in KINDS:
            code = f"TESTS8{kind.upper()}{p_index}{stamp}"
            if kind == "improving":
                student_uuid = db.get_or_create_student(code)
                for rows in IMPROVING_HISTORY:
                    sid = db.create_session(student_uuid, "Fake earlier session for the Stage 8 test")
                    db.save_indicators(student_uuid, sid, rows)
            if kind == "struggling":
                messages = [m.format(first_number=prob["first_number"]) for m in STRUGGLING_MESSAGES]
            else:
                messages = prob["strong"]

            print("=" * 70)
            print(f"{kind.upper()}  |  problem: {prob['name']}  |  code: {code}")
            print("=" * 70)
            history = [{"role": "teacher",
                        "content": "Let's read the problem together. What is the very first piece of "
                                   "information it gives us?"}]
            session_id = None
            for number, msg in enumerate(messages, start=1):
                print(f"Student: {msg}")
                history.append({"role": "student", "content": msg})
                body = {"problem": prob["problem"], "history": history, "student_id": code,
                        "session_id": session_id}
                reply, status = post_chat(body)
                if reply is None:
                    save_results(turns, stamp, finished=False)
                    print(f"\nStopped: /chat answered status {status}. Google may be busy or the daily limit is used.")
                    print("The turns done so far were saved. Wait a while, then run again.")
                    return 1
                session_id = reply["session_id"]
                # The strong and improving students state the final answer themselves in message 4,
                # so only the earlier messages are checked for "gave the answer too early".
                check_answer = (kind == "struggling") or number < 4
                m = measure(reply["reply"], prob["answer"], check_answer)
                print(f"[hint {reply['hint_level']}, scaffold {reply['scaffold_level']}, "
                      f"reflection {reply['reflection_type']}] Teacher: {reply['reply']}\n")
                turns.append({
                    "kind": kind, "problem_name": prob["name"], "student_code": code,
                    "message_number": number, "student_message": msg,
                    "hint_level": reply["hint_level"], "scaffold_level": reply["scaffold_level"],
                    "reflection_type": reply["reflection_type"], "reply": reply["reply"], **m,
                })
                history.append({"role": "teacher", "content": reply["reply"]})
                time.sleep(PAUSE_SECONDS)

    save_results(turns, stamp, finished=True)

    # ---- comparison table ----
    by = {k: [t for t in turns if t["kind"] == k] for k in KINDS}
    print("=" * 70)
    print("COMPARISON (averages over 3 problems x 4 messages each)")
    print("=" * 70)
    header = f"{'':<12}{'hint':>6}{'scaffold':>10}{'words':>7}{'questions':>11}{'numbers':>9}{'gave answer':>13}{'reflections':>13}"
    print(header)
    for k in KINDS:
        ts = by[k]
        print(f"{k:<12}{avg(t['hint_level'] for t in ts):>6.2f}{avg(t['scaffold_level'] for t in ts):>10.2f}"
              f"{avg(t['words'] for t in ts):>7.1f}{avg(t['questions'] for t in ts):>11.2f}"
              f"{avg(t['numbers'] for t in ts):>9.2f}{sum(t['gave_answer'] for t in ts):>13}"
              f"{sum(1 for t in ts if t['reflection_type']):>13}")
    print()

    # ---- checks ----
    failures = 0

    def check(name, ok):
        nonlocal failures
        print(("PASS  " if ok else "FAIL  ") + name)
        failures += 0 if ok else 1

    def soft(name, ok):
        print(("PASS  " if ok else "NOT YET  ") + name + "   (reported, not a failure)")

    s, g, i = by["struggling"], by["strong"], by["improving"]
    print("Checks that must pass (the rules in the code):")
    check("struggling students get a higher hint level than strong students on average",
          avg(t["hint_level"] for t in s) > avg(t["hint_level"] for t in g))
    check("struggling students reach hint level 3 at least once on every problem",
          all(any(t["hint_level"] == 3 for t in s if t["problem_name"] == p["name"]) for p in PROBLEMS))
    check("strong students stay at hint level 1 on every message",
          all(t["hint_level"] == 1 for t in g))
    check("new students (struggling and strong) have full support (scaffold 3)",
          all(t["scaffold_level"] == 3 for t in s + g))
    check("improving students get faded help (scaffold 1) on every message",
          all(t["scaffold_level"] == 1 for t in i))
    check("exactly one 'improving' reflection per problem, on message 3",
          all(sum(1 for t in i if t["problem_name"] == p["name"] and t["reflection_type"] == "improving") == 1
              and any(t["problem_name"] == p["name"] and t["message_number"] == 3 and t["reflection_type"]
                      for t in i) for p in PROBLEMS))
    check("no reflection question for the struggling or strong (new) students",
          not any(t["reflection_type"] for t in s + g))
    check("the tutor never gave the final answer too early",
          not any(t["gave_answer"] for t in turns))

    print("\nChecks about the tutor's WORDS (Gemini follows instructions only partly, so these are reported only):")
    soft("improving students' replies mention fewer numbers than strong students' replies",
         avg(t["numbers"] for t in i) < avg(t["numbers"] for t in g))
    soft("improving students' replies are not longer than strong students' replies",
         avg(t["words"] for t in i) <= avg(t["words"] for t in g))
    refl = [t for t in i if t["reflection_type"]]
    soft("replies that carry a reflection question have at most 3 sentences",
         all(t["sentences"] <= 3 for t in refl))
    print("\nRead stage8_results.md to see every reply. In the improving student's replies, look for")
    print("smaller nudges (no calculation named) than for the strong student on the same message.")
    if failures:
        print(f"\n{failures} check(s) FAILED.")
        return 1
    print("\nAll must-pass checks passed. Results saved in experiments\\phase2_adaptive_agent\\.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
