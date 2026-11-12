"""
Fair scoring of the baseline agent and the current agent with the same rubric (rubric.md).

Replies from both agents are mixed into one list with neutral ids (R01, R02...), and the raters
are not told which agent wrote each reply. Each rater has their own score sheet.

Run from this folder:

    python blind_scoring.py make rating_20261108_0028.csv   # makes the items, 2 score sheets and the key
    python blind_scoring.py score                           # after both raters filled in their sheets

Everything goes in the scoring/ folder. Do not open scoring/key.csv until the scoring is finished.
These scores describe how the tutor behaves, on a small sample. They do not measure students' thinking.
"""

import csv
import json
import random
import sys
from pathlib import Path

from agreement import ITEMS, kappa

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE / "scoring"
BASELINE = ROOT / "experiments" / "phase1_baseline" / "baseline_eval_results.json"
BANK = ROOT / "backend" / "data" / "problems.json"
SEED = 42

COLUMNS = ["id", *ITEMS, "notes"]


def _clean(text):
    """The app does not show the $ signs Gemini puts around maths, so raters should not see them either."""
    return str(text).replace("$", "").strip()


def baseline_items():
    results = json.loads(BASELINE.read_text(encoding="utf-8"))
    return [
        {"agent": "baseline", "source": key, "problem": _clean(r["problem"]),
         "conversation": _clean(r["context"]), "reply": _clean(r["agent_reply"])}
        for key, r in results.items()
    ]


def current_items(rating_csv):
    bank = json.loads(BANK.read_text(encoding="utf-8"))
    problems = bank if isinstance(bank, list) else bank["problems"]
    text_of = {p["id"]: p["text"] for p in problems}
    items, scenario, lines = [], None, []
    with open(rating_csv, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            if row["scenario"] != scenario:
                scenario, lines = row["scenario"], []
            if row["student"] != "(opening)":
                lines.append(f"Student: {_clean(row['student'])}")
            items.append({
                "agent": "current", "source": f"{row['scenario']} / turn {row['turn']}",
                "problem": _clean(text_of[row["problem_id"]]),
                "conversation": "\n".join(lines), "reply": _clean(row["tutor"]),
            })
            lines.append(f"Teacher: {_clean(row['tutor'])}")
    return items


def make(rating_csv):
    items = baseline_items() + current_items(HERE / rating_csv)
    random.Random(SEED).shuffle(items)
    OUT.mkdir(exist_ok=True)
    for number, item in enumerate(items, 1):
        item["id"] = f"R{number:02}"

    def write(name, fields, rows):
        with open(OUT / name, "w", encoding="utf-8-sig", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
            writer.writeheader()
            writer.writerows(rows)

    write("items.csv", ["id", "problem", "conversation", "reply"], items)
    write("key.csv", ["id", "agent", "source"], items)
    blank = [{"id": item["id"]} for item in items]
    write("rater1_scores.csv", COLUMNS, blank)
    write("rater2_scores.csv", COLUMNS, blank)
    print(f"{len(items)} replies mixed. Files are in {OUT}")


def _read_scores(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return {row["id"]: row for row in csv.DictReader(f)}


def _score(row, item):
    value = (row.get(item) or "").strip()
    return int(value) if value in ("0", "1") else None


def _good(row):
    """1 if the rater gave all five items a 1, 0 if any item got a 0, None if any item is blank."""
    scores = [_score(row, item) for item in ITEMS]
    return None if None in scores else int(all(scores))


def _share(values):
    return f"{sum(values) / len(values):.0%}" if values else "-"


def score():
    with open(OUT / "key.csv", encoding="utf-8-sig", newline="") as f:
        agent_of = {row["id"]: row["agent"] for row in csv.DictReader(f)}
    one, two = _read_scores(OUT / "rater1_scores.csv"), _read_scores(OUT / "rater2_scores.csv")

    print("Agreement between the raters")
    print(f"{'item':<16}{'scored':>8}{'agree':>8}{'kappa':>8}")
    for item in ITEMS:
        pairs = [(_score(one[i], item), _score(two[i], item)) for i in agent_of]
        pairs = [p for p in pairs if None not in p]
        a, b = [x for x, _ in pairs], [y for _, y in pairs]
        k = kappa(a, b)
        agree = _share([int(x == y) for x, y in pairs])
        print(f"{item:<16}{len(pairs):>8}{agree:>8}{'-' if k is None else f'{k:.2f}':>8}")

    print("\nShare of replies scored 1 (both raters together)")
    print(f"{'item':<16}{'baseline':>10}{'current':>10}")
    for item in ITEMS:
        cells = []
        for agent in ("baseline", "current"):
            ids = [i for i, a in agent_of.items() if a == agent]
            values = [s for i in ids for s in (_score(one[i], item), _score(two[i], item)) if s is not None]
            cells.append(_share(values))
        print(f"{item:<16}{cells[0]:>10}{cells[1]:>10}")

    print("\nGood reply = a 1 on all five items")
    for agent in ("baseline", "current"):
        ids = [i for i, a in agent_of.items() if a == agent]
        by_each = [g for i in ids for g in (_good(one[i]), _good(two[i])) if g is not None]
        both = [_good(one[i]) == 1 and _good(two[i]) == 1 for i in ids
                if _good(one[i]) is not None and _good(two[i]) is not None]
        print(f"{agent:<10} {len(ids)} replies: rater average {_share(by_each)}, both raters agree it is good {_share([int(b) for b in both])}")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "make":
        make(sys.argv[2])
    elif len(sys.argv) == 2 and sys.argv[1] == "score":
        score()
    else:
        sys.exit("Usage: python blind_scoring.py make rating_<time>.csv   or   python blind_scoring.py score")
