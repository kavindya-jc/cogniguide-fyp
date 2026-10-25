# CogniGuide: where we are and what comes next

Updated: 25 October 2026. For the whole team. Simple summary first, details after.

## In one minute

- **The app is finished for now.** All screens work, in English only, light and dark.
- **The tutor is now a real tutoring agent**, not just a chatbot. Before every reply it checks the
  student's answer, chooses one kind of help, writes the reply, checks the reply does not give the
  answer away, and remembers what happened.
- **Everything is tested**: 231 backend checks and 158 app checks pass. It was also tried in the app
  on an Android emulator against the real backend and database.
- **Not done yet:** putting the backend online (Render; the repository owner does this, see below),
  and the study preparation (teacher check, test-account cleanup, scoring the tutor, ethics).

---

## 1. What we built

### The app (Flutter, `frontend/`)

| Part | Status |
|---|---|
| New design (Round 4): pastel + glass, light and dark, "Look" switch in Settings | Done |
| Welcome, Create account (with buddy picture), Log in (with show/hide password), Settings, Log out | Done |
| "Username" instead of "anonymous code" (same privacy rules: no real names) | Done |
| Pick a problem: areas, grades, own problem; **top bar folds into a slim bar when you scroll** | Done |
| **Smooth fade when switching** between Practice and My progress | Done |
| Chat with the coach, maths keys, "coach busy" / "no internet" notes | Done |
| "I worked it out!" celebration (no points or badges), now also **told to the server** | Done |
| My progress: numbers, chart, list | Done |
| **App icon with Pip's face**, app name **CogniGuide** | Done (Android and web; iPhone icon not made, we have no Mac) |
| **English only.** Sinhala and Tamil were removed (team decision) | Done |
| Glass turns itself off on slow phones; everything respects "reduce motion" | Done |

### The tutor agent (Python/Flask, `backend/`)

Each student message goes through one cycle (`backend/app/tutor_agent.py`):

1. **Check** (`assessment.py`): Gemini fills in a short form: what is the student doing, is it right,
   which common mistake. Python checks every answer it gives.
2. **Answer sheet** (`answer_check.py`): Python compares the student's answer with the real answer
   (stored only on the server, in `backend/data/problems.json`). Python has the last word: Gemini
   cannot say "solved" if the right answer is not there, and "x = 2" is caught as wrong even when
   Gemini is busy.
3. **Decide** (`policy.py`): plain rules choose ONE of 11 actions. Each wrong try or "I'm confused"
   gives a little more help (check again → small hint → concrete hint → explain the step).
   A known mistake gets a question aimed at it. Asking for the answer never gives more help by itself.
   The final answer is never given.
4. **Reply**: Gemini writes the reply for that action.
5. **Safety check**: the reply must not contain the answer and must be short; otherwise it is
   written again, then a safe ready-made reply is used.
6. **Remember**: the session memory and a log of every decision are saved in Supabase.

When Google's Gemini is busy (this happens often on the free plan), the chat still answers with a
safe ready-made reply instead of an error.

### Research data (Supabase)

| Data | Where | What it is for |
|---|---|---|
| Messages, sessions | `messages`, `sessions` | The transcripts. Sessions now have `problem_id`, `status` (in progress / solved / ended) and the agent's memory |
| Numbers per turn | `indicators` | hint level needed, stuck, asked for the answer, self-correction, **wrong try, solved, misconception, claimed solved** |
| Every tutor decision | `agent_turns` | action, reason, help level, what the check saw, Gemini or backup, safety-check result, time taken (labels only, never message text) |

Hints now fade **per maths area** (doing well in Number does not take help away in Trigonometry).
The progress screen now uses honest words: it describes what the student *did* ("you used less
help"), not claims about their thinking.

### Ready to go online

- `render.yaml` and `docs/deploy_backend.md` (step-by-step guide).
- Online settings: only logged-in students can chat, websites cannot call the API, at most 20 messages
  a minute per student, debug mode off, a real web server (gunicorn).
- The app waits long enough for a free server that is waking up.

### Tools for the study

- `backend/scripts/delete_test_students.py`: lists test accounts; deletes them only with `--yes`.
- `experiments/phase4_agent_eval/`: play scripted students through the real tutor
  (`run_scenarios.py`), score the replies with two raters (`rubric.md`), and measure how much the
  raters agree (`agreement.py`).

---

## 2. What needs doing next (who and how)

### A. Fix: the decision-log table is missing (anyone with Supabase access, 2 minutes)

Our check found that the table `agent_turns` is **not** in Supabase yet. The chat works without it,
but the decisions are not saved.

1. Supabase → **SQL Editor** → **New query**.
2. **Important:** the dropdown next to **Save** (top right) must say **Database**, not **Logs**.
3. Paste all of `backend/sql/stage10_agent_log.sql` → **Run** → "Success. No rows returned".
4. Check: **Table Editor** → you should see a table **agent_turns**.

### B. Put the backend online on Render (the GitHub repository owner)

Render must connect to the GitHub account that owns `cogniguide-fyp`, so **the repository owner**
does this. Full guide: **`docs/deploy_backend.md`**. Short version:

1. Sign up at **render.com** with GitHub; allow access to **cogniguide-fyp** only.
2. Create the service:
   - **Easiest:** Blueprints → New Blueprint Instance → `cogniguide-fyp` (it reads `render.yaml`).
   - **If Render asks for a card** and the team does not want to add one: use
     **Deploy a Web Service** instead and type the settings from "Step 1b" of the guide.
   - If Render asks for a card there too: ask for the **no-card option** (Hugging Face Spaces; it
     needs one extra file, a `Dockerfile`, which can be added quickly).
3. Paste the secrets into Render yourself (never in chat, never in the app):
   `GEMINI_API_KEY`, `GEMINI_MODEL`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, and a **new** `AUTH_SECRET`.
4. Check `https://<address>/health` shows `{"status": "ok"}`.
5. Build the app for the online server (in `frontend/`):
   `flutter build apk --release --dart-define=API_BASE_URL=https://<address>`
   and share the APK with the team.

Good to know about Render's free plan: the server **sleeps after ~15 minutes** without use, so the
first message after that takes about a minute. That is normal.

### C. Before real students (study preparation)

| Task | Who | Notes |
|---|---|---|
| A maths teacher checks the 15 problems, answers, steps and common mistakes | Team + teacher | `backend/data/problems.json`; every problem says `"checked_by_teacher": false` until then. More problems should be added the same way. |
| Delete test accounts | Anyone with the `.env` | `python scripts/delete_test_students.py TEST AGENTDEMO` lists 21 test accounts; add `--yes` to delete |
| Score the tutor | Two team members | Run `run_scenarios.py`, score `rating_*.csv` with `rubric.md`, then `agreement.py`. Compare with Phase 1 (27% "good Socratic") |
| Ethics approval, parent and student consent, privacy notice | Team + supervisor | Say that messages go to Google Gemini and are stored in Supabase; decide how long data is kept |
| Turn off the "type your own problem" box for the study? | Team + supervisor | Own problems have no answer sheet, so the answer check cannot help there |
| Update the team PDF report | Team | Add: tutor agent, buddy, Look switch, English only, icon, online backend |

---

## 3. Honest limits (please read before writing the report)

- **Behaviour is not thinking.** Fewer hints, fewer "I'm stuck" messages or more solved problems show
  how students *used the tutor*. They do not prove better critical thinking. That needs the study:
  pre/post tests (Watson–Glaser, MAI) and a comparison group.
- **Gemini can still be wrong.** Python checks the final answer and blocks leaks, but the check of
  *in-between steps* comes from Gemini. Two raters should read real transcripts (section C).
- **The answer checker reads digits, not words** ("twelve" is not understood).
- **Free Gemini is often busy.** The chat keeps going with safe replies, but those are simpler.
- **Not tested yet:** the backend running on Render (we only checked the settings), and the iPhone app.

---

## 4. Where things are

| What | File |
|---|---|
| The full code audit and plan (from before the agent work) | Shared link from Claude (private page; ask for it) |
| API between app and backend | `docs/api_contract.md` |
| Putting the backend online | `docs/deploy_backend.md` |
| The design | `docs/design/README.md`, `docs/design/CogniGuide_Design_Spec.md` |
| Problems with answers | `backend/data/problems.json` |
| Database setup (run in order) | `backend/sql/` |
| Run the backend tests | in `backend/`: `..\venv\Scripts\python -m pytest` |
| Run the app tests | in `frontend/`: `flutter test` |
