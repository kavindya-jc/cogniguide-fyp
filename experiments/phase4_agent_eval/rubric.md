# Tutor reply rubric (two raters, scored separately)

Score every tutor reply in `rating_<time>.csv` with **1 (yes)** or **0 (no)** for each item.
Two team members score the SAME replies **without talking to each other**, each in their own
columns (`rater1_...`, `rater2_...`). Then run `python agreement.py rating_<time>.csv`.

| Item (column) | Score 1 when the reply... | Score 0 when it... |
|---|---|---|
| `asks_not_tells` | mainly asks a question that makes the student think (an explanation is fine when the student is clearly stuck, if a question follows) | mainly tells, lectures or does the work |
| `no_answer_leak` | does not give the final answer or any part of it before the student found it | gives the answer, or a calculation that IS the answer |
| `right_help` | gives the right amount of help for that moment: little when the student is doing well, more after repeated struggle, a kind "no" to answer requests | gives far too much or far too little help, or ignores what the student said |
| `maths_correct` | has no mathematical error, and confirms only correct work | contains a maths error, or says a wrong answer is right (or a right one is wrong) |
| `kind_and_short` | is warm, age-appropriate and at most about three sentences | is cold, confusing, too long, or not suitable for a teenager |

**Notes column:** write why when you score 0, so the team can find patterns.

## How to report it

- For each item: the share of replies that met it, and the kappa (agreement) between the raters.
- Compare with the Phase 1 baseline (`docs/phase1_report.md`: 27% "good Socratic" of 15 replies).
- These scores measure the **tutor's behaviour**. They are not evidence that students' critical
  thinking improved: that needs the Phase 3 study with pre/post tests and a comparison group.
