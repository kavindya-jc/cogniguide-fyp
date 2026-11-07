"""
Researcher analytics dashboard: one web page that adds up the metacognitive indicators
and tutor decisions across ALL students, for the research team to review.

READ ONLY and LAPTOP ONLY. It is not part of the server: there is no web address for it, it
writes nothing to Supabase, and it never reads the messages table or typed-in problems.
Students appear only as "Student 1", "Student 2"..., never by their username.

Run from the backend/ folder (it uses the Supabase keys in your .env; it never prints them):

    python scripts/researcher_dashboard.py                        # every account, marked as test data
    python scripts/researcher_dashboard.py --exclude TEST DEMO    # leave out codes starting with these
    python scripts/researcher_dashboard.py --study                # real study data: no test-data banner

The page goes to experiments/analytics/researcher_dashboard.html (ignored by Git).
Double-click it to open it. It works with no internet.
"""

import argparse
import html
import json
import statistics
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

DEFAULT_OUTPUT = BACKEND.parent / "experiments" / "analytics" / "researcher_dashboard.html"

# Exactly what this script may read. "messages" is not here, and neither are sessions.problem
# (a typed-in problem is free text) or sessions.state.
COLUMNS = {
    "students": "id, anon_code",
    "sessions": "id, student_id, problem_id, status, started_at",
    "indicators": "student_id, session_id, indicator_type, value",
    "agent_turns": "id, session_id, student_id, problem_id, action, needed_level, hint_level, "
                   "intent, check_source, guard, latency_ms",
}
PAGE_SIZE = 1000

# indicator_type in Supabase -> the words on the page. Fixed order, so reports can be compared.
INDICATORS = [
    ("self_correction", "Fixed their own mistake"),
    ("reflection", "Coach asked a reflection question"),
    ("stuck", "Felt stuck"),
    ("asked_for_answer", "Asked for the answer"),
    ("wrong_attempt", "Wrong try"),
    ("misconception", "Common mistake spotted"),
]
AREAS = {"alg": "Algebra", "geo": "Geometry", "trig": "Trigonometry", "num": "Number", "sta": "Statistics"}
TYPED_IN = "Typed-in problem"
GUARD_LABELS = {
    "ok": "Reply passed first time",
    "rewritten": "Reply rewritten",
    "safe_reply": "Ready-made safe reply",
    "gemini_busy": "Gemini busy: ready-made reply",
}
CHECK_LABELS = {"llm": "Gemini", "fallback": "Word rules (backup)"}
MAX_SESSION_POSITIONS = 8


def fetch_all(client, table):
    """Every row of one allowed table, a page at a time (Supabase returns at most 1000 at once)."""
    rows, start = [], 0
    while True:
        page = (
            client.table(table)
            .select(COLUMNS[table])
            .range(start, start + PAGE_SIZE - 1)
            .execute()
            .data
            or []
        )
        rows.extend(page)
        if len(page) < PAGE_SIZE:
            return rows
        start += PAGE_SIZE


def read_data(client):
    return {table: fetch_all(client, table) for table in COLUMNS}


def _mean(values):
    return sum(values) / len(values) if values else None


def _percent(part, whole):
    return round(100 * part / whole) if whole else None


def area_of(problem_id):
    if not problem_id:
        return TYPED_IN
    return AREAS.get(problem_id.split("-")[0], "Other")


def pretty_action(action):
    return (action or "Unknown").replace("_", " ").capitalize()


def summarise(students, sessions, indicators, turns, exclude=()):
    """Add everything up. Plain lists in, plain numbers out, with no names or codes in the result."""
    prefixes = tuple(p.upper() for p in exclude)
    kept = {s["id"] for s in students if not (s.get("anon_code") or "").upper().startswith(prefixes or ("\0",))}
    sessions = [s for s in sessions if s["student_id"] in kept]
    indicators = [i for i in indicators if i["student_id"] in kept]
    turns = [t for t in turns if t["student_id"] in kept]

    # A student turn is a reply to something the student wrote: the opening turn has no intent.
    student_turns = [t for t in turns if t.get("intent") is not None]
    worked_ids = {t["session_id"] for t in student_turns}
    # Same sessions everywhere, so the totals and the per-student rows add up. Chats from before
    # the decision log was switched on have no turns, so they are not counted anywhere.
    indicators = [i for i in indicators if i.get("session_id") in worked_ids]
    worked = sorted(
        (s for s in sessions if s["id"] in worked_ids),
        key=lambda s: (s.get("started_at") or "", s["id"]),
    )

    # Students become numbers in the order they first worked on something.
    numbers = {}
    for session in worked:
        numbers.setdefault(session["student_id"], len(numbers) + 1)

    counts = Counter()
    per_student = {sid: Counter() for sid in numbers}
    claimed = confirmed = 0
    for row in indicators:
        kind = row.get("indicator_type") or ""
        positive = bool(row.get("value"))
        if kind == "claimed_solved":
            claimed += 1
            confirmed += 1 if positive else 0
            continue
        if kind.startswith("reflection_"):
            kind = "reflection"
        if positive:
            counts[kind] += 1
            if row["student_id"] in per_student:
                per_student[row["student_id"]][kind] += 1

    needed = Counter(t.get("needed_level") for t in student_turns)
    given = Counter(t.get("hint_level") for t in student_turns)

    by_session = {}
    for turn in student_turns:
        if turn.get("needed_level") is not None:
            by_session.setdefault(turn["session_id"], []).append(turn["needed_level"])

    # Average help needed in each student's 1st session, 2nd session, and so on.
    position_of_student, positions = Counter(), {}
    for session in worked:
        if session["id"] not in by_session:
            continue
        position_of_student[session["student_id"]] += 1
        positions.setdefault(position_of_student[session["student_id"]], []).append(_mean(by_session[session["id"]]))
    trend = [
        {"position": p, "average": round(_mean(positions[p]), 2), "sessions": len(positions[p])}
        for p in sorted(positions)
        if p <= MAX_SESSION_POSITIONS
    ]

    area_rows = {}
    solved_ids = {s["id"] for s in worked if s.get("status") == "solved"}
    for session in worked:
        area = area_rows.setdefault(area_of(session.get("problem_id")), {"sessions": 0, "solved": 0, "levels": []})
        area["sessions"] += 1
        area["solved"] += 1 if session["id"] in solved_ids else 0
        area["levels"].extend(by_session.get(session["id"], []))
    areas = [
        {
            "area": name,
            "sessions": row["sessions"],
            "solved": row["solved"],
            "average_help": round(_mean(row["levels"]), 2) if row["levels"] else None,
        }
        for name, row in sorted(area_rows.items())
    ]

    student_rows = []
    for sid, number in numbers.items():
        own_turns = [t for t in student_turns if t["student_id"] == sid]
        levels = [t["needed_level"] for t in own_turns if t.get("needed_level") is not None]
        row = {
            "student": f"Student {number}",
            "sessions": len({t["session_id"] for t in own_turns}),
            "replies": len(own_turns),
            "average_help": round(_mean(levels), 2) if levels else None,
        }
        for kind, _label in INDICATORS:
            row[kind] = per_student[sid][kind]
        student_rows.append(row)

    latencies = sorted(t["latency_ms"] for t in student_turns if t.get("latency_ms") is not None)
    checks = Counter(t.get("check_source") or "not recorded" for t in student_turns)
    guards = Counter(t.get("guard") or "not recorded" for t in student_turns)

    return {
        "students": len(numbers),
        "sessions": len(worked),
        "student_turns": len(student_turns),
        "solved": len(solved_ids),
        "solved_percent": _percent(len(solved_ids), len(worked)),
        "claimed": claimed,
        "confirmed": confirmed,
        "actions": Counter(t.get("action") for t in student_turns).most_common(),
        "indicators": [
            {
                "kind": kind,
                "label": label,
                "total": counts[kind],
                "per_session": round(counts[kind] / len(worked), 2) if worked else 0,
            }
            for kind, label in INDICATORS
        ],
        "levels": [{"level": n, "needed": needed[n], "given": given[n]} for n in (1, 2, 3)],
        "trend": trend,
        "areas": areas,
        "per_student": student_rows,
        "checks": checks.most_common(),
        "guards": guards.most_common(),
        "latency_median_s": round(statistics.median(latencies) / 1000, 1) if latencies else None,
        "latency_p90_s": round(latencies[int(0.9 * (len(latencies) - 1))] / 1000, 1) if latencies else None,
        "first": min((s.get("started_at") or "" for s in worked), default="")[:10],
        "last": max((s.get("started_at") or "" for s in worked), default="")[:10],
    }


CSS = """
:root {
  color-scheme: light;
  --surface-0: #f4f4f1; --surface-1: #fcfcfb; --border: #e2e1dc; --track: #eeeeea;
  --text-primary: #0b0b0b; --text-secondary: #52514e; --text-muted: #6e6d68;
  --series-1: #2a78d6; --series-2: #eb6834; --banner: #fff6e0; --banner-text: #5e4300; --banner-border: #e8cf8f;
  --tip-bg: #0b0b0b; --tip-text: #fcfcfb;
}
@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
    --surface-0: #111110; --surface-1: #1a1a19; --border: #33332f; --track: #2a2a27;
    --text-primary: #f0efec; --text-secondary: #c3c2b7; --text-muted: #a5a49a;
    --series-1: #3987e5; --series-2: #d95926; --banner: #2e2610; --banner-text: #f2dfae; --banner-border: #5c4c1f;
    --tip-bg: #f0efec; --tip-text: #1a1a19;
  }
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--surface-0); color: var(--text-primary);
  font: 16px/1.5 "Segoe UI", system-ui, -apple-system, Roboto, sans-serif; }
main { max-width: 1120px; margin: 0 auto; padding: 32px 24px 56px; }
h1 { font-size: 30px; line-height: 1.2; margin: 0 0 4px; }
h2 { font-size: 19px; line-height: 1.3; margin: 0 0 2px; }
p { margin: 0; }
.sub { color: var(--text-secondary); }
.note { color: var(--text-secondary); font-size: 15px; margin-bottom: 16px; }
.banner { background: var(--banner); color: var(--banner-text); border: 1px solid var(--banner-border);
  border-radius: 8px; padding: 12px 16px; margin: 20px 0 0; }
.tiles { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 12px; margin: 20px 0; }
.tile { background: var(--surface-1); border: 1px solid var(--border); border-radius: 8px; padding: 14px 16px; }
.tile b { display: block; font-size: 30px; line-height: 1.15; font-variant-numeric: tabular-nums; }
.tile span { color: var(--text-secondary); font-size: 15px; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(440px, 1fr)); gap: 12px; }
section { background: var(--surface-1); border: 1px solid var(--border); border-radius: 8px; padding: 20px; min-width: 0; }
section.wide { margin-top: 12px; }
.bar-row { display: grid; grid-template-columns: minmax(150px, 215px) 1fr; gap: 12px; align-items: center;
  min-height: 32px; border-radius: 4px; }
.bar-row:hover { background: var(--track); }
.bar-label { font-size: 15px; color: var(--text-secondary); text-align: right; }
.bar-cell { display: flex; align-items: center; gap: 8px; min-width: 0; }
.bar-fill { height: 12px; min-width: 2px; border-radius: 0 4px 4px 0; background: var(--series-1); }
.bar-fill.two { background: var(--series-2); }
.bar-value { font-size: 15px; font-variant-numeric: tabular-nums; }
.pair { padding: 4px 0; }
.pair .bar-cell + .bar-cell { margin-top: 2px; }
.legend { display: flex; gap: 16px; font-size: 15px; color: var(--text-secondary); margin-bottom: 8px; }
.key { display: inline-block; width: 12px; height: 12px; border-radius: 3px; margin-right: 6px; vertical-align: -1px; }
.trend { display: block; width: 100%; height: auto; }
.trend text { fill: var(--text-muted); font-size: 14px; }
.trend .value { fill: var(--text-primary); font-size: 14px; }
.trend .grid-line { stroke: var(--border); stroke-width: 1; }
.trend .line { fill: none; stroke: var(--series-1); stroke-width: 2; }
.trend .dot { fill: var(--series-1); stroke: var(--surface-1); stroke-width: 2; }
.trend .hit { fill: transparent; }
.table-wrap { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; font-size: 15px; font-variant-numeric: tabular-nums; }
th, td { padding: 7px 10px; border-bottom: 1px solid var(--border); text-align: right; white-space: nowrap; }
th { color: var(--text-secondary); font-weight: 600; white-space: normal; vertical-align: bottom; }
th:first-child, td:first-child { text-align: left; }
details { margin-top: 12px; font-size: 15px; }
summary { cursor: pointer; color: var(--text-secondary); }
summary:focus-visible { outline: 2px solid var(--series-1); outline-offset: 2px; }
.empty { color: var(--text-muted); padding: 16px 0; }
footer { color: var(--text-muted); font-size: 14px; margin-top: 20px; }
#tip { position: fixed; display: none; z-index: 5; pointer-events: none; max-width: 280px; padding: 6px 10px;
  border-radius: 6px; background: var(--tip-bg); color: var(--tip-text); font-size: 14px; }
@media (max-width: 560px) {
  main { padding: 20px 16px 40px; }
  .grid { grid-template-columns: minmax(0, 1fr); }
  .bar-row { grid-template-columns: minmax(0, 1fr); gap: 2px; padding: 4px 0; }
  .bar-label { text-align: left; }
}
"""

SCRIPT = """
(function () {
  var tip = document.getElementById('tip');
  function move(e) {
    var x = Math.min(e.clientX + 14, window.innerWidth - tip.offsetWidth - 8);
    var y = Math.max(e.clientY - tip.offsetHeight - 10, 8);
    tip.style.left = x + 'px';
    tip.style.top = y + 'px';
  }
  document.querySelectorAll('[data-tip]').forEach(function (el) {
    el.addEventListener('mouseenter', function (e) {
      tip.textContent = el.getAttribute('data-tip');
      tip.style.display = 'block';
      move(e);
    });
    el.addEventListener('mousemove', move);
    el.addEventListener('mouseleave', function () { tip.style.display = 'none'; });
  });
})();
"""


def _e(value):
    return html.escape(str(value), quote=True)


def _show(value, suffix=""):
    return "n/a" if value is None else f"{value}{suffix}"


def _table(headers, rows):
    head = "".join(f"<th scope='col'>{_e(h)}</th>" for h in headers)
    body = "".join("<tr>" + "".join(f"<td>{_e(_show(c))}</td>" for c in row) + "</tr>" for row in rows)
    return f"<div class='table-wrap'><table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>"


def _data_table(headers, rows):
    return f"<details><summary>Show as a table</summary>{_table(headers, rows)}</details>"


def _empty():
    return "<p class='empty'>No data yet.</p>"


def _bars(rows):
    """rows: (label, value, tooltip). One series, one colour."""
    if not rows:
        return _empty()
    top = max(value for _l, value, _t in rows) or 1
    parts = []
    for label, value, tooltip in rows:
        parts.append(
            f"<div class='bar-row' data-tip='{_e(tooltip)}'><div class='bar-label'>{_e(label)}</div>"
            f"<div class='bar-cell'><div class='bar-fill' style='width:{84 * value / top:.1f}%"
            f"{';min-width:0' if not value else ''}'></div>"
            f"<span class='bar-value'>{_e(value)}</span></div></div>"
        )
    return "".join(parts)


def _levels(levels):
    top = max([max(r["needed"], r["given"]) for r in levels] + [1])
    if not any(r["needed"] or r["given"] for r in levels):
        return _empty()
    parts = [
        "<div class='legend'><span><i class='key' style='background:var(--series-1)'></i>Help needed</span>"
        "<span><i class='key' style='background:var(--series-2)'></i>Help given</span></div>"
    ]
    for r in levels:
        tooltip = f"Level {r['level']}: needed in {r['needed']} replies, given in {r['given']}"
        parts.append(
            f"<div class='bar-row pair' data-tip='{_e(tooltip)}'><div class='bar-label'>Level {r['level']}</div><div>"
            f"<div class='bar-cell'><div class='bar-fill' style='width:{84 * r['needed'] / top:.1f}%'></div>"
            f"<span class='bar-value'>{r['needed']}</span></div>"
            f"<div class='bar-cell'><div class='bar-fill two' style='width:{84 * r['given'] / top:.1f}%'></div>"
            f"<span class='bar-value'>{r['given']}</span></div></div></div>"
        )
    return "".join(parts)


def _trend(trend):
    if len(trend) < 2:
        return "<p class='empty'>This needs students with at least two sessions.</p>"
    width, height, left, right, top, bottom = 480, 230, 34, 18, 22, 42
    plot_w, plot_h = width - left - right, height - top - bottom
    x = lambda i: left + plot_w * i / (len(trend) - 1)
    y = lambda level: top + plot_h * (3 - level) / 2
    out = [f"<svg class='trend' viewBox='0 0 {width} {height}' role='img' "
           f"aria-label='Average help level by session number; the table below has the same numbers.'>"]
    for level in (1, 2, 3):
        out.append(f"<line class='grid-line' x1='{left}' x2='{width - right}' y1='{y(level):.1f}' y2='{y(level):.1f}'/>")
        out.append(f"<text x='{left - 10}' y='{y(level) + 5:.1f}' text-anchor='end'>{level}</text>")
    points = " ".join(f"{x(i):.1f},{y(p['average']):.1f}" for i, p in enumerate(trend))
    out.append(f"<polyline class='line' points='{points}'/>")
    for i, p in enumerate(trend):
        tooltip = f"Session {p['position']}: average help {p['average']}, from {p['sessions']} session(s)"
        out.append(f"<text x='{x(i):.1f}' y='{height - 18}' text-anchor='middle'>{p['position']}</text>")
        out.append(f"<circle class='dot' cx='{x(i):.1f}' cy='{y(p['average']):.1f}' r='5'/>")
        out.append(f"<circle class='hit' cx='{x(i):.1f}' cy='{y(p['average']):.1f}' r='18' data-tip='{_e(tooltip)}'/>")
    out.append(f"<text x='{left + plot_w / 2:.1f}' y='{height - 1}' text-anchor='middle'>Each student's session number</text>")
    out.append("</svg>")
    return "".join(out)


def render_html(summary, study=False, generated=None):
    generated = generated or datetime.now().strftime("%d %b %Y, %H:%M")
    s = summary
    banner = "" if study else (
        "<p class='banner'><b>Test accounts, not study results.</b> These numbers show that the data "
        "collection works. They say nothing yet about how teenagers think.</p>"
    )
    period = f"{s['first']} to {s['last']}" if s["first"] else "no sessions yet"
    claimed = f"{s['confirmed']} of {s['claimed']}" if s["claimed"] else "n/a"
    tiles = [
        (s["students"], "Students with a chat"),
        (s["sessions"], "Sessions worked on"),
        (s["student_turns"], "Coach replies to students"),
        (_show(s["solved_percent"], "%"), f"Sessions solved ({s['solved']})"),
        (claimed, "“I worked it out!” confirmed"),
    ]
    tiles_html = "".join(f"<div class='tile'><b>{_e(v)}</b><span>{_e(l)}</span></div>" for v, l in tiles)

    total = s["student_turns"] or 1
    action_rows = [
        (pretty_action(a), n, f"{pretty_action(a)}: {n} replies, {round(100 * n / total)}%") for a, n in s["actions"]
    ]
    indicator_rows = [
        (r["label"], r["total"], f"{r['label']}: {r['total']} in total, {r['per_session']} per session")
        for r in s["indicators"]
    ]
    check_rows = [(CHECK_LABELS.get(k, k), n, f"{CHECK_LABELS.get(k, k)}: {n} replies") for k, n in s["checks"]]
    guard_rows = [(GUARD_LABELS.get(k, k), n, f"{GUARD_LABELS.get(k, k)}: {n} replies") for k, n in s["guards"]]

    student_headers = ["Student", "Sessions", "Replies", "Average help"] + [label for _k, label in INDICATORS]
    student_rows = [
        [r["student"], r["sessions"], r["replies"], r["average_help"]] + [r[k] for k, _l in INDICATORS]
        for r in s["per_student"]
    ]

    sections = f"""
<div class="grid">
  <section>
    <h2>Metacognitive indicators</h2>
    <p class="note">How often each behaviour was recorded, across all students.</p>
    {_bars(indicator_rows)}
    {_data_table(["Indicator", "Total", "Per session"], [[r["label"], r["total"], r["per_session"]] for r in s["indicators"]])}
  </section>
  <section>
    <h2>What the coach chose</h2>
    <p class="note">Replies to students, by action. Opening messages are left out.</p>
    {_bars(action_rows)}
    {_data_table(["Action", "Replies"], [[pretty_action(a), n] for a, n in s["actions"]])}
  </section>
  <section>
    <h2>Help needed and help given</h2>
    <p class="note">Level 1 is a light nudge, level 3 is the most help. Given can be lower than needed when hints fade.</p>
    {_levels(s["levels"])}
    {_data_table(["Level", "Needed", "Given"], [[r["level"], r["needed"], r["given"]] for r in s["levels"]])}
  </section>
  <section>
    <h2>Average help level across sessions</h2>
    <p class="note">Later points come from fewer sessions. Check the counts in the table before reading a trend.</p>
    {_trend(s["trend"])}
    {_data_table(["Session number", "Average help", "Sessions counted"], [[p["position"], p["average"], p["sessions"]] for p in s["trend"]])}
  </section>
  <section>
    <h2>How the coach checked students</h2>
    <p class="note">Gemini, or the word rules when Gemini was not available.</p>
    {_bars(check_rows)}
    {_data_table(["Check", "Replies"], [[CHECK_LABELS.get(k, k), n] for k, n in s["checks"]])}
  </section>
  <section>
    <h2>Reply safety check</h2>
    <p class="note">Median reply time {_e(_show(s["latency_median_s"], " s"))}. Slowest 10% took {_e(_show(s["latency_p90_s"], " s"))} or more.</p>
    {_bars(guard_rows)}
    {_data_table(["Result", "Replies"], [[GUARD_LABELS.get(k, k), n] for k, n in s["guards"]])}
  </section>
</div>
<section class="wide">
  <h2>By maths area</h2>
  <p class="note">Sessions that had at least one reply to the student.</p>
  {_table(["Area", "Sessions", "Solved", "Average help"], [[a["area"], a["sessions"], a["solved"], a["average_help"]] for a in s["areas"]]) if s["areas"] else _empty()}
</section>
<section class="wide">
  <h2>By student</h2>
  <p class="note">Numbers replace usernames. They can change between reports if students are added or left out.</p>
  {_table(student_headers, student_rows) if student_rows else _empty()}
</section>
"""
    # json.dumps keeps the embedded numbers valid for any later tooling; the summary holds no names or codes.
    data = json.dumps(s).replace("<", "\\u003c")
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CogniGuide Researcher Analytics</title>
<style>{CSS}</style>
</head>
<body>
<main>
  <h1>CogniGuide researcher analytics</h1>
  <p class="sub">Sessions from {_e(period)}. Report made {_e(generated)}.</p>
  {banner}
  <div class="tiles">{tiles_html}</div>
  {sections}
  <footer>These numbers describe how students used the tutor. They do not measure critical thinking;
  that needs the pre/post tests in the study. No messages, usernames or typed-in problems are in this report.
  Chats from before the decision log was switched on are not counted.</footer>
</main>
<div id="tip" role="status"></div>
<script type="application/json" id="report-data">{data}</script>
<script>{SCRIPT}</script>
</body>
</html>
"""


def main():
    parser = argparse.ArgumentParser(description="Make the researcher analytics page (read only).")
    parser.add_argument("--exclude", nargs="*", default=[], help="leave out codes that START with these (for example TEST)")
    parser.add_argument("--study", action="store_true", help="real study data: remove the test-data banner")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="where to write the page")
    args = parser.parse_args()
    if any(len(p) < 3 for p in args.exclude):
        parser.error("exclude prefixes must be at least 3 characters, so a typo cannot match everyone")

    from app import db

    if not db.is_configured():
        sys.exit("Supabase is not set up in .env.")
    try:
        data = read_data(db._get_client())
    except Exception as err:  # only the kind of error: the full text could include the database address
        sys.exit(f"Could not read the data ({type(err).__name__}). Check your internet and try again.")

    summary = summarise(data["students"], data["sessions"], data["indicators"], data["agent_turns"], args.exclude)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(render_html(summary, study=args.study), encoding="utf-8")
    print(f"Done: {summary['students']} students, {summary['sessions']} sessions, {summary['student_turns']} replies.")
    print(f"Open this file: {args.output}")


if __name__ == "__main__":
    main()
