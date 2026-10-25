"""
CogniGuide problem bank - Agent plan, Phase 1 (Step 1.2)

The problems now live on the server too, in backend/data/problems.json, WITH the
answer, the key steps and common mistakes. That gives the tutor a goal it can check:
later steps compare the student's answer with the real one.

Two views of a problem:
  - the FULL problem (answer, steps, mistakes): only for the backend. Never send it.
  - the PUBLIC problem (id, area, grade, text): what GET /problems gives the app.

The file is read once and checked when it is first used. A broken file stops with a
clear message, so a typo in the JSON is found at once and not in the middle of a chat.

Known limit: the problems are the 15 samples from the design. A maths teacher must
check them (checked_by_teacher is false for all of them for now).
"""

import json
from pathlib import Path

PROBLEMS_FILE = Path(__file__).resolve().parent.parent / "data" / "problems.json"

# The same areas as the app (frontend/lib/models/maths_area.dart).
AREAS = ("number", "algebra", "geometry", "trigonometry", "graphs", "statistics")
GRADES = (8, 9, 10, 11)

# The only fields the app may see.
PUBLIC_FIELDS = ("id", "area", "grade", "text")

_problems = None  # id -> full problem, filled the first time it is needed


class ProblemBankError(Exception):
    """The problem file is missing or has a mistake in it."""


def _check(problem, seen_ids):
    """Return an error message (string) if this problem is not complete, else None."""
    pid = problem.get("id")
    if not isinstance(pid, str) or not pid:
        return "a problem has no 'id'"
    if pid in seen_ids:
        return f"'{pid}' is used twice"
    if problem.get("area") not in AREAS:
        return f"'{pid}': area must be one of {', '.join(AREAS)}"
    if problem.get("grade") not in GRADES:
        return f"'{pid}': grade must be 8, 9, 10 or 11"
    for field in ("text", "answer"):
        if not isinstance(problem.get(field), str) or not problem[field].strip():
            return f"'{pid}': '{field}' must be a non-empty text"
    parts = problem.get("answer_parts")
    if not isinstance(parts, list) or not parts:
        return f"'{pid}': 'answer_parts' needs at least one part"
    for part in parts:
        if not isinstance(part, dict) or not part.get("label") or not str(part.get("value", "")).strip():
            return f"'{pid}': every answer part needs a 'label' and a 'value'"
    steps = problem.get("steps")
    if not isinstance(steps, list) or not 1 <= len(steps) <= 6 or not all(isinstance(s, str) and s.strip() for s in steps):
        return f"'{pid}': 'steps' must be 1 to 6 texts"
    mistakes = problem.get("mistakes")
    if not isinstance(mistakes, list):
        return f"'{pid}': 'mistakes' must be a list"
    for m in mistakes:
        if not isinstance(m, dict) or not m.get("id") or not m.get("description"):
            return f"'{pid}': every mistake needs an 'id' and a 'description'"
    return None


def load(path=PROBLEMS_FILE):
    """Read and check the problem file. Returns {id: full problem}. Raises ProblemBankError."""
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError) as err:
        raise ProblemBankError(f"Cannot read {path}: {err}") from err

    items = data.get("problems") if isinstance(data, dict) else None
    if not isinstance(items, list) or not items:
        raise ProblemBankError(f"{path} must have a non-empty 'problems' list")

    bank = {}
    for problem in items:
        if not isinstance(problem, dict):
            raise ProblemBankError(f"{path}: every problem must be an object")
        problem_error = _check(problem, bank)
        if problem_error:
            raise ProblemBankError(f"{path}: {problem_error}")
        bank[problem["id"]] = problem
    return bank


def _bank():
    global _problems
    if _problems is None:
        _problems = load()
    return _problems


def find(problem_id):
    """The FULL problem (with the answer) for this id, or None. Backend use only."""
    return _bank().get(problem_id)


def public_view(problem):
    """Only the fields the app may see: id, area, grade and text. Never the answer."""
    return {field: problem[field] for field in PUBLIC_FIELDS}


def list_public(area=None, grade=None):
    """The PUBLIC problems, in file order, filtered by area and/or grade when given."""
    return [
        public_view(p)
        for p in _bank().values()
        if (area is None or p["area"] == area) and (grade is None or p["grade"] == grade)
    ]
