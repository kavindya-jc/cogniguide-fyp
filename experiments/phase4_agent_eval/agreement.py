"""
How much do the two raters agree? (Cohen's kappa for each rubric item.)

Fill in a rating_<time>.csv (made by run_scenarios.py): each rater writes 1 (yes) or 0 (no) in
their own columns, for example rater1_asks_not_tells and rater2_asks_not_tells. Then run:

    python agreement.py rating_20261025_2300.csv

Kappa: 1 = perfect agreement, 0 = no better than chance. About 0.6 or more is usually "good".
It also prints how often each item was met (the share of replies scored 1, averaged over raters).
"""

import csv
import sys

ITEMS = ("asks_not_tells", "no_answer_leak", "right_help", "maths_correct", "kind_and_short")


def kappa(a, b):
    """Cohen's kappa for two lists of 0/1 scores of the same replies."""
    n = len(a)
    if n == 0:
        return None
    observed = sum(1 for x, y in zip(a, b) if x == y) / n
    p_a, p_b = sum(a) / n, sum(b) / n
    expected = p_a * p_b + (1 - p_a) * (1 - p_b)
    return 1.0 if expected == 1 else (observed - expected) / (1 - expected)


def main(path):
    with open(path, encoding="utf-8-sig") as f:
        rows = list(csv.DictReader(f))
    print(f"{len(rows)} tutor replies in {path}\n")
    print(f"{'item':<16}{'scored':>8}{'kappa':>8}{'met':>8}")
    for item in ITEMS:
        pairs = [(r[f"rater1_{item}"].strip(), r[f"rater2_{item}"].strip()) for r in rows]
        pairs = [(int(x), int(y)) for x, y in pairs if x in ("0", "1") and y in ("0", "1")]
        a, b = [x for x, _ in pairs], [y for _, y in pairs]
        k = kappa(a, b)
        met = (sum(a) + sum(b)) / (2 * len(pairs)) if pairs else None
        print(f"{item:<16}{len(pairs):>8}{'-' if k is None else f'{k:.2f}':>8}{'-' if met is None else f'{met:.0%}':>8}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python agreement.py rating_<time>.csv")
    main(sys.argv[1])
