# CogniGuide: the Socratic tutoring agent (report for the team)

Updated 25 October 2026. This answers the team's audit questions (the 11 sections below), using the
code **as it is now**, after the agent was built. The first audit (before any change) found that
CogniGuide was "a Gemini chatbot steered by keyword rules"; this report says what changed, what is
verified, and what is still missing.

**How things were checked:** reading the code; 235 automatic backend tests and 158 app tests (all
pass); live runs with the real Gemini; a full chat in the Android app against the real backend and
Supabase (on an emulator, also through a public tunnel). Where something was not checked, it says so.
No keys or passwords appear in this report.

---

## 1. Executive summary

- **CogniGuide is now a rule-guided AI tutoring agent**, not just a chatbot. Every student message
  goes through a fixed cycle: **check → decide → reply → check the reply → remember**.
- **Gemini** does what needs understanding of language: it fills in a structured form about the
  student's message, and it writes the reply. **Python** does what must be predictable and testable:
  it checks the final answer against a server-side answer sheet, chooses the tutoring action with
  plain rules, blocks replies that give the answer away, and keeps the session memory.
- **The big problem from the first audit is fixed:** three wrong answers used to count as "doing fine"
  (the old system only read words like "I'm stuck"). Now each wrong try raises the help one step, and a
  correct answer is recognised by Python even when Gemini misses it.
- **Every decision is logged** (`agent_turns` table) with its reason, so the research data can be
  checked.
- **Still open:** online hosting (we test with a laptop server for now), a maths teacher's check of
  the problems, human scoring of the tutor's replies, and the ethics/consent work. And as always:
  behaviour data (fewer hints) is **not** proof of better critical thinking; that needs the study.

---

## 2. Actual project purpose and architecture

**Purpose (from `README.md`, `docs/phase1_report.md`):** study how generative AI affects teenagers'
critical thinking and metacognition, and build a tutor that guides instead of answering; then compare
it with a direct-answer assistant (pre/post tests: adapted Watson–Glaser and MAI). Maths only,
Grades 8–11, Sri Lankan syllabus, **English only** (team decision).

| Layer | What it is | Key files |
|---|---|---|
| App | Flutter, light/dark, anonymous username + password, chat, progress | `frontend/lib/screens/*.dart`, `frontend/lib/services/*.dart` |
| API | Flask | `backend/app/api.py` (`/auth/signup`, `/auth/login`, `/problems`, `/chat`, `/session/end`, `/progress`, `/dashboard`) |
| **Agent controller** | One tutoring turn | `backend/app/tutor_agent.py` → `run_turn()` |
| Student check | Gemini JSON form + word-rule backup | `backend/app/assessment.py` → `assess()` |
| Answer sheet + checker | Problems with answers; Python answer check and leak guard | `backend/data/problems.json`, `backend/app/problems.py`, `backend/app/answer_check.py` |
| Action rules + memory | 11 actions, the help ladder, session memory | `backend/app/policy.py` → `choose_action()`, `update_state()` |
| Gemini calls | Reply text and structured JSON, retries, backup model | `backend/app/models/socratic_agent.py` → `socratic_response()`, `generate_json()` |
| Older modules (kept) | Word rules (now the backup), scaffold fading, reflection, progress | `adaptive.py`, `scaffolding.py`, `reflection.py`, `progress.py` |
| Database | Supabase (row-level security on, server key only) | `backend/app/db.py`, `backend/sql/*.sql` |
| Sign-in | Hashed passwords, signed 30-day tokens, lockout | `backend/app/auth.py` |

---

## 3. End-to-end execution flow (one student message)

1. **App** (`chat_screen.dart` → `ChatApi.send`) sends the problem id and text, the chat so far, the
   session id and the login token.
2. **API** (`api.chat`) checks the request, takes the student from the token (online: login required),
   applies the 20-messages-a-minute limit, and uses the server's own text for a bank problem.
3. **RECEIVE** (`tutor_agent.run_turn`): loads the problem's answer sheet, the session memory
   (`sessions.state`), and the scaffold level (earlier sessions **in the same maths area**).
4. **ASSESS** (`assessment.assess`): Gemini fills in a form (intent, correctness, current step, common
   mistake, self-correction, reasoning shown). Python validates every value; **Python's answer checker
   has the last word** on "solved" and catches clear wrong answers like "x = 2". If Gemini fails, the
   word rules fill in the form.
5. **DECIDE** (`policy.choose_action`): one of 11 actions, with a written reason, limited by the
   scaffold level (struggling students always get enough help).
6. **ACT**: Gemini writes the reply for that action (`socratic_response` with the action instruction).
   If Gemini is busy: a safe ready-made reply for that action.
7. **CHECK THE REPLY** (`tutor_agent.check_reply`): no part of the final answer, not too long;
   otherwise written again once, then the safe reply.
8. **UPDATE**: messages, indicators (`hint_level`, `wrong_attempt`, `solved`, `misconception`, ...),
   the session memory and one `agent_turns` row are saved. A database problem never breaks the reply.
9. **Next message = OBSERVE + REASSESS** with the updated memory (the feedback loop).
10. "**I worked it out!**" → `POST /session/end`: the server compares it with its own memory
    (`claimed_solved` = 1 if the answer check agreed, 0 if not).

---

## 4. AI agent characteristics (now)

| # | Characteristic | Now | Where | Still missing |
|---|---|---|---|---|
| 1 | Goal | ✅ Each bank problem has an answer, key steps and common mistakes; sessions have a status (in progress / solved / ended) | `problems.json`, `sessions.status` | A teacher has not checked the 15 problems yet; typed-in problems have no answer sheet |
| 2 | Perception | ✅ Structured Gemini check of the student's message + Python answer check | `assessment.py`, `answer_check.py` | In-between steps are judged by Gemini only; numbers written as words are not understood |
| 3 | Reasoning | ✅ The check is a separate, logged step | `assessment.validate`, `agent_turns` | — |
| 4 | Action selection | ✅ 11 actions chosen by plain, tested rules, each with a reason | `policy.choose_action` | The rules' thresholds are first guesses (to tune with real data) |
| 5 | Tools | ✅ Answer checker, answer-leak guard, problem bank | `answer_check.py` | No algebra system (sympy) for unusual answer forms |
| 6 | Memory | ✅ Session memory, indicators, decision log, earlier sessions per area | `sessions.state`, `indicators`, `agent_turns` | The chat text itself still comes from the app each time |
| 7 | Feedback loop | ✅ Each new message is judged against the memory: help goes up after struggle, resets after progress | `policy.update_state` | No direct "did this exact hint help?" measure yet |
| 8 | Planning | 🟡 Key steps per problem; the current step is tracked and used when explaining | `problems.json` steps, `state.step` | No step-by-step plan beyond that (fine for a baseline) |
| 9 | Adaptation | ✅ Help ladder in a session, targeted mistake questions, hint fading per area, reflection at calm moments and when solved | `policy.py`, `scaffolding.py`, `reflection.py` | Fading thresholds untested with real students |
| 10 | Evaluation and safety | 🟡 235 + 158 tests, fake-Gemini scenario tests, live runs, answer-leak guard, off-topic redirect, login + rate limit online | `backend/tests/`, `experiments/phase4_agent_eval/` | Human scoring of replies not done yet; no teacher check yet |

**Verdict:** a working **baseline Socratic tutoring agent**: goal-directed (answer sheet), it perceives
(structured check), decides (rules), acts (Gemini), checks itself (guard), remembers and adapts.
It is deliberately **one** controller with plain rules, not several AI agents or a framework.

---

## 5. Implemented versus missing

| Feature | Status |
|---|---|
| Structured student check with fallback | ✅ Implemented, tested |
| Python answer check (many answer forms, wrong-answer detection) | ✅ Implemented, 70+ test cases |
| 11 tutoring actions, help ladder, misconception questions | ✅ Implemented, tested |
| Reply safety check (no answer leak, length) | ✅ Implemented, tested |
| Session memory, decision log, session end | ✅ Implemented; seen working live in Supabase |
| Per-area hint fading, honest progress wording, solved counts | ✅ Implemented, tested |
| Safe replies when Gemini is busy; optional backup model | ✅ Implemented; seen live |
| App: problem ids, "I worked it out" to server, folding top bar, tab fade, Pip icon, English only | ✅ Implemented, tested |
| Online hosting | 🟡 Ready for Render (needs a card) and Hugging Face (now paid); **laptop + tunnel works now** |
| Teacher-checked problems, more problems | ❌ To do |
| Human scoring of the tutor (2 raters) | ❌ To do (kit ready) |
| Ethics, consent, privacy notice | ❌ To do |
| iPhone build and icon | ❌ Not done (no Mac) |

---

## 6. Main technical and research gaps (and what was fixed)

### Fixed since the first audit
- Wrong answers counted as "doing fine" → **fixed** (answer check + help ladder).
- Gemini could confirm a wrong answer or leak the answer → **guarded** (Python decides "solved"; leak check).
- No problem goal on the server → **fixed** (answer sheet, never sent to the app).
- Help faded across unrelated topics → **fixed** (per maths area).
- Progress said "growing as a thinker" → **fixed** (behaviour words only).
- "I worked it out" was app-only → **fixed** (sent and checked by the server).
- Open CORS, debug on, no rate limit, chat without login → **fixed for online use** (settings).
- README described files that did not exist → **fixed**.
- **The phone (release) app had no internet permission**, so it could never reach a server → **fixed**
  (found while testing through the tunnel).
- Gemini "busy" stopped the chat → **fixed** (safe replies; the app keeps going).

### Still open
- **Chat history comes from the app.** A changed app could send a false history. The memory and the
  answer check reduce the impact; reading the saved transcript on the server would close it.
- **A database failure on a session's first message** can split one chat into two sessions (rare).
- **Free text is stored as typed** (a student could type their name). Needs a privacy notice, a
  retention period and maybe name redaction before the study.
- **Messages go to Google Gemini** (and through Cloudflare when using the laptop tunnel). Say so in the consent forms.
- **Free Gemini is often busy**: safe replies keep the chat going but are simpler; a paid or backup
  model would help in the study.
- **Hosting for the study** is not decided (laptop tunnel is for testing only).

### Behaviour versus real improvement (important for the report)
Fewer hints, fewer "I'm stuck" messages, more solved problems or more self-corrections describe
**how students used the tutor**. They can also come from easier problems, guessing or learning which
words to avoid. Only the study design shows real change in thinking: **pre/post Watson–Glaser and MAI,
a comparison group (direct-answer assistant), matched problem difficulty, and transfer problems solved
without the tutor.** Report the logs as process evidence only.

---

## 7. The agent architecture (as built)

```
RECEIVE  problem + answer sheet + session memory + scaffold level (same maths area)
   ↓
ASSESS   Gemini form (JSON) → Python validation → Python answer check (last word) → backup: word rules
   ↓
DECIDE   policy.choose_action → one of 11 actions + reason (scaffold limit, never withhold forever)
   ↓
ACT      Gemini writes the reply for that action (busy → safe reply)
   ↓
CHECK    no answer leak, short → else rewrite once → else safe reply
   ↓
UPDATE   messages, indicators, session memory, agent_turns log
   ↓
next message = OBSERVE + REASSESS
```

**The 11 actions:** ask a guiding question · ask for an explanation · encourage self-correction ·
acknowledge progress · ask a reflection question · confirm and reflect (solved) · redirect (off topic) ·
address a misconception · small hint · concrete hint · explain the step clearly (never the final answer).

**The help ladder (same step):** wrong try 1 → "check that step" · 2 → small hint · 3 → concrete hint ·
4+ → explain the step clearly. "I'm confused" climbs faster. Asking for the answer never climbs it.

---

## 8. File-by-file status

| File | Status |
|---|---|
| `backend/app/tutor_agent.py` | ADDED: the controller |
| `backend/app/assessment.py`, `policy.py`, `answer_check.py`, `problems.py` | ADDED |
| `backend/data/problems.json` | ADDED (needs teacher check) |
| `backend/app/models/socratic_agent.py` | MODIFIED: shared client, JSON helper, retries, backup model, strict "never the answer" rule |
| `backend/app/api.py` | MODIFIED: thin `/chat`, `/problems`, `/session/end`, online settings |
| `backend/app/db.py` | MODIFIED: memory, decision log, per-area history, session end |
| `adaptive.py`, `scaffolding.py`, `reflection.py`, `progress.py` | KEPT and adapted (word rules are the backup now) |
| `backend/sql/stage9_agent.sql`, `stage10_agent_log.sql` | ADDED (both run in Supabase) |
| Flutter `chat_api.dart`, `chat_screen.dart`, `pick_problem_tab.dart`, `home_screen.dart` | MODIFIED: problem id, session end, folding bar, tab fade |
| Flutter language screen, Sinhala/Tamil | REMOVED (English only) |
| `AndroidManifest.xml` | MODIFIED: internet permission for the phone app |
| `render.yaml`, `deploy/huggingface/`, `docs/deploy_*.md` | ADDED: hosting options |
| `backend/scripts/delete_test_students.py`, `experiments/phase4_agent_eval/` | ADDED: study tools |

---

## 9. Roadmap: done and next

| Phase | Status |
|---|---|
| 1. Baseline foundation (tests, problem bank, controller, problem ids, Gemini JSON) | ✅ Done |
| 2. Assessment and action selection | ✅ Done |
| 3. Feedback loop, session memory, decision log, session end | ✅ Done |
| 4. Per-area fading, reflection, honest progress | ✅ Done (thresholds to tune with data) |
| 5. Full-system testing and hardening | 🟡 Done on emulator + tunnel; online hosting for the study still to choose |
| 6. Tutoring quality and study readiness | ❌ Next: teacher check, 2-rater scoring, pilot, ethics |

---

## 10. Testing and evaluation strategy

### A. Technical checks (done, automatic)
`backend/tests/` (235 tests, fake Gemini, fake database) and `frontend/test/` (158 tests) cover:

| Scenario | Expected behaviour | Covered by |
|---|---|---|
| Correct answer | Confirm + one reflection question; session solved | `test_tutor_agent.py`, `test_answer_check.py` |
| Incorrect answer | "Check that step" first, more help each time | `test_tutor_agent.py::test_wrong_answers_get_more_help_each_time` |
| Specific misconception | A question aimed at that mistake, once | `test_a_known_mistake_is_addressed_once` |
| Confused | Small hint, then more | `test_policy.py::test_confused_ladder` |
| Keeps asking for the answer | Kind no; help does not climb | `test_asking_for_the_answer_never_climbs_the_ladder` |
| Corrects own mistake | Praise that habit | `test_policy.py` |
| No progress despite hints | Ends in a clear explanation of the step, never the answer | `test_wrong_answer_ladder` |
| Improvement across sessions | Less help in that maths area only | `test_research_data.py::test_scaffold_uses_only_the_same_area` |
| Invalid Gemini output / wrong judgement | Word-rule backup; Python overrides "solved" | `test_assessment.py` |
| Gemini or database down | Safe reply / chat still answers | `test_tutor_agent.py`, `test_research_data.py` |

### B. Tutor quality (next, by people)
`experiments/phase4_agent_eval/`: run scripted students (`run_scenarios.py`), two team members score
every reply with `rubric.md` (asks not tells, no answer leak, right amount of help, maths correct, kind
and short), then `agreement.py` gives agreement (kappa). Compare with Phase 1 (27% "good Socratic").

### C. Educational impact (the study, separate)
Pre/post tests, comparison group, matched problems, transfer tasks. The logs support, but do not prove,
changes in critical thinking.

---

## 11. Final recommendations and priorities

1. **Test as a team now** with the laptop server (`docs/laptop_server.md`) and note anything odd.
2. **Maths teacher checks** `backend/data/problems.json`; add more problems the same way.
3. **Score the tutor** with two raters (section 10B).
4. **Choose hosting for the study** (Render with a card on the free plan, or university hosting).
5. **Ethics and privacy:** consent forms mention Gemini and Supabase; data retention; delete test
   accounts (`delete_test_students.py`).
6. Later improvements: read the chat history on the server, avoid split sessions, tune the rule
   thresholds with real data, consider a paid Gemini model for the study.
