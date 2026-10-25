"""
CogniGuide answer checker - agent plan, Phase 2

Plain Python (no AI), so it is free, fast and always gives the same result.
It compares text with the answer sheet of a bank problem (backend/data/problems.json):

  check_final_answer(text, problem) -> did the student give the WHOLE correct final answer?
  find_wrong_answer(text, problem)  -> did the student clearly give a WRONG final answer ("x = 2")?
  reply_leaks_answer(text, problem) -> does a tutor reply give away any part of the answer?

It understands common ways of writing the same answer:
  "x = 12" and "12";  "3/5", "6/10" and "0.6";  "(x + 3)(x + 2)" and "(x+2)(x+3)";
  "4.5 × 10⁻⁵", "4.5x10^-5" and "4.5e-5";  "5√3/2" and "4.33";  "(0, 1)".

Careful rules:
  - A number that is already in the problem (for example 9 in "the mean of 4, 7, 9, 10 and 15")
    only counts when it is clearly stated as a result: "= 9", "is 9", "answer 9"... or when it
    is the only number in a short message ("9").
  - A part with "form": "scientific" needs proper scientific notation (one digit before the point).
  - "x = 2" counts as the student's value for x, even if a 12 appears elsewhere in the message.

Known limits: it does not understand words for numbers ("twelve"), and an in-between result that
happens to equal the final answer would count as the answer.
"""

import math
import re

_NUM = r"-?\d+(?:\.\d+)?"
_SUPERSCRIPT = str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹⁻", "0123456789-")

# Words just before a number that show it is stated as a result. A list counts too:
# in "y = -3, 1 and 5" the 1 and the 5 are stated like the -3.
_STATED_BEFORE = re.compile(
    r"(=|\bis|\bequals?|\bget|\bgot|\bgives?|\banswer\b[^\d-]{0,12}|\bbe|\bmakes?|\bfound)\s*"
    r"(?:-?\d+(?:\.\d+)?\s*(?:,|and)\s*)*$"
)


def _normalise(text):
    """One way of writing maths symbols, so the patterns below stay simple."""
    t = str(text).lower()
    # Gemini sometimes writes maths in LaTeX: $x = 12$, \frac{3}{5}, \sqrt{3}, 4.5 \times 10^{-5}.
    t = re.sub(r"\\sqrt\s*\{([^{}]*)\}", r"√\1", t)  # first, so \frac{5\sqrt{3}}{2} has no inner braces
    t = re.sub(r"\\[dt]?frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}", r"\1/\2", t)
    t = re.sub(r"\^\s*\{([^{}]*)\}", r"^\1", t)
    t = t.replace("\\times", "*").replace("\\cdot", "*").replace("$", "")
    t = t.replace("−", "-").replace("–", "-").replace("×", "*").replace("·", "*").replace("÷", "/")
    t = re.sub(r"10\s*([⁻⁰¹²³⁴⁵⁶⁷⁸⁹]+)", lambda m: "10^" + m.group(1).translate(_SUPERSCRIPT), t)
    t = re.sub(r"(\d),(\d{3})\b", r"\1\2", t)  # 2,040 -> 2040 (a list "4, 7, 9" has spaces, so it is safe)
    t = re.sub(r"\brs\.?\s*", "", t)  # "Rs. 2040" -> "2040"

    # Square roots: "5√3/2", "5 sqrt(3) / 2" -> the number itself.
    def root(m):
        a = float(m.group(1)) if m.group(1) else 1.0
        value = a * math.sqrt(float(m.group(2)))
        if m.group(3):
            value /= float(m.group(3))
        return f"{value:.6f}"

    t = re.sub(r"(\d+(?:\.\d+)?)?\s*\*?\s*(?:√|sqrt\s*\(?)\s*(\d+(?:\.\d+)?)\s*\)?(?:\s*/\s*(\d+(?:\.\d+)?))?", root, t)
    return t


def _scientific(text):
    """Numbers written in scientific notation: [(mantissa, value, start, end), ...]."""
    found = []
    for m in re.finditer(rf"({_NUM})\s*(?:\*|x)\s*10\s*\^\s*\(?\s*(-?\d+)\s*\)?|({_NUM})e(-?\d+)\b", text):
        mantissa = float(m.group(1) or m.group(3))
        power = int(m.group(2) or m.group(4))
        found.append((mantissa, mantissa * 10 ** power, m.start(), m.end()))
    return found


def _numbers(text):
    """Every number in the (normalised) text with its position: [(value, start), ...].

    Fractions "3/5" count as one number (0.6). Scientific notation counts as one number too.
    """
    sci = _scientific(text)
    taken = [(start, end) for _, _, start, end in sci]
    found = [(value, start) for _, value, start, _ in sci]
    # A number written right before an unknown or "(" is part of an expression (the 2 in "2x",
    # "2(x + 1)"), not a value, so it is skipped. Units stay: "154cm" and "2.5m" are values.
    for m in re.finditer(rf"(?<![\w.]){_NUM}(?:\s*/\s*\d+(?:\.\d+)?)?(?![\d.]*(?:[xyzabn](?![a-z])|\())", text):
        if any(s <= m.start() < e for s, e in taken):
            continue
        raw = m.group(0).replace(" ", "")
        if "/" in raw:
            top, bottom = raw.split("/")
            if float(bottom) == 0:
                continue
            value = float(top) / float(bottom)
        else:
            value = float(raw)
        found.append((value, m.start()))
    return found


def _stated(text, start):
    """True if the number at this position is clearly given as a result ("= 9", "is 9")."""
    return bool(_STATED_BEFORE.search(text[max(0, start - 40):start]))


def _close(a, b, rounded):
    if rounded:
        return abs(a - b) <= max(0.01, 0.002 * abs(b))
    return abs(a - b) <= 1e-9 * max(1.0, abs(b))


def _part_target(part):
    """(number to compare with, compare with rounding?) for a number part."""
    if part.get("decimal") is not None:
        return float(part["decimal"]), True
    value = str(part["value"]).replace(" ", "")
    if "/" in value:
        top, bottom = value.split("/")
        return float(top) / float(bottom), False
    return float(value), False


def _factors(text):
    """The factors like (x + 2) in the text, as a set of (letter, number) pairs."""
    return {(m.group(1), float(m.group(2) + m.group(3)))
            for m in re.finditer(r"\(\s*([a-z])\s*([+-])\s*(\d+(?:\.\d+)?)\s*\)", text)}


def _points(text):
    return {(float(m.group(1)), float(m.group(2)))
            for m in re.finditer(rf"\(\s*({_NUM})\s*,\s*({_NUM})\s*\)", text)}


def _part_found(text, part, problem_numbers):
    """True if this one answer part is in the (normalised) text."""
    form = part.get("form")
    if form == "factors":
        want = _factors(_normalise(part["value"]))
        return bool(want) and _factors(text) == want

    if form == "point":
        want = next(iter(_points(_normalise(part["value"]))))
        if want in _points(text):
            return True
        # "it crosses the y-axis at 1" / "the y-intercept is 1"
        return any(_close(v, want[1], False) and _stated(text, s) for v, s in _numbers(text))

    target, rounded = _part_target(part)

    if form == "scientific":
        return any(1 <= abs(mantissa) < 10 and _close(value, target, True) for mantissa, value, _, _ in _scientific(text))

    candidates = _numbers(text)
    label = str(part.get("label", ""))
    if re.fullmatch(r"[a-z]", label):  # "x": use the value the student gave for x, if they named it
        named = [(float(m.group(1)), m.start(1)) for m in re.finditer(rf"\b{label}\s*=\s*({_NUM})", text)]
        if named:
            candidates = named
            return any(_close(v, target, rounded) for v, _ in candidates)

    in_problem = any(_close(target, n, rounded) for n in problem_numbers)
    # A short message with just one number ("9", "it's 9") is an answer too.
    alone = len(candidates) == 1 and len(text.strip()) <= 25
    return any(
        _close(v, target, rounded) and (not in_problem or alone or _stated(text, s))
        for v, s in candidates
    )


def _matches(text, problem):
    """How many answer parts the text contains: (found, total)."""
    t = _normalise(text)
    problem_numbers = [v for v, _ in _numbers(_normalise(problem["text"]))]
    parts = problem["answer_parts"]
    found = sum(1 for part in parts if _part_found(t, part, problem_numbers))
    return found, len(parts)


def check_final_answer(text, problem):
    """Did this message give the WHOLE correct final answer of the bank problem?

    Returns {"all_correct": bool, "parts_found": int, "parts_total": int}.
    problem: a FULL bank problem (problems.find), with answer_parts.
    """
    found, total = _matches(text, problem)
    return {"all_correct": found == total, "parts_found": found, "parts_total": total}


def _plain_number(value):
    """A mistake's wrong answer as one number, or None when it is not a single number."""
    value = str(value).replace(" ", "")
    try:
        if "/" in value:
            top, bottom = value.split("/")
            return float(top) / float(bottom)
        return float(value)
    except ValueError:
        return None


def find_wrong_answer(text, problem):
    """Does this message clearly give a WRONG final answer? (Used most when the Gemini check is busy.)

    Two cases only, so in-between steps are never called wrong:
      - the student names the answer's letter with a wrong value: "x = 2" when x is 12;
      - a short message with just one value that is a listed common mistake: "320", "(x+1)(x+6)".
    Returns {"wrong": bool, "mistake_id": the matching common mistake or None}.
    """
    t = _normalise(text)
    wrong = False
    for part in problem["answer_parts"]:
        label = str(part.get("label", ""))
        if part.get("form") or not re.fullmatch(r"[a-z]", label):
            continue
        target, rounded = _part_target(part)
        named = [float(m.group(1)) for m in re.finditer(rf"\b{label}\s*=\s*({_NUM})(?![\d.]*\s*[a-z(])", t)]
        if named and not any(_close(v, target, rounded) for v in named):
            wrong = True

    mistake_id = None
    numbers = _numbers(t)
    short = len(t.strip()) <= 25
    for m in problem.get("mistakes", []):
        given = str(m.get("wrong_answer", ""))
        if not given or check_final_answer(given, problem)["parts_found"]:
            # A "mistake" that gives a right number cannot be told apart from a right step:
            # sta-8-1 (median = mean = 9) and "x = 4" alone in alg-11-1 (right, just not finished).
            continue
        factors = _factors(_normalise(given))
        if factors and _factors(t) == factors:
            mistake_id = m["id"]
            break
        value = _plain_number(given)
        if value is not None and short and len(numbers) == 1 and _close(numbers[0][0], value, False):
            mistake_id = m["id"]
            break
    if mistake_id:
        wrong = True
    return {"wrong": wrong, "mistake_id": mistake_id}


def reply_leaks_answer(text, problem):
    """True if a tutor reply gives away ANY part of the final answer (before the student found it)."""
    found, _ = _matches(text, problem)
    return found > 0
