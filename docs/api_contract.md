# CogniGuide API Contract (Phase 2, Stages 1, 3, 4, 5, 6, 7 and 7c; agent plan Phase 1)

This is the agreement between the frontend and the Flask backend. The frontend only needs this file.

- Base URL while developing: `http://127.0.0.1:5000`
- All requests and replies are JSON (`Content-Type: application/json`).
- The tutor itself is **stateless**: it does not remember the conversation. The frontend sends the full conversation every time. (The server also saves each chat to the database for a logged-in student, see below.)
- **Stage 7c:** students sign up and log in with their anonymous code + password (section 0). The app then sends the token on `/chat` and `/progress` as the header `Authorization: Bearer <token>`. **The server takes the student from the token**, never from a code typed in the request.

## 0. Sign up and log in (Stage 7c)

**Requests:** `POST /auth/signup` and `POST /auth/login`, both with:

```json
{"student_id": "P001", "password": "my-secret-1"}
```

| Field | Rules |
|---|---|
| `student_id` | Anonymous code, 1-64 letters, digits, `_` or `-` (names and emails are rejected) |
| `password` | 8-128 characters |

**Success reply** (signup `201`, login `200`, both `Cache-Control: no-store`):

```json
{"token": "eyJjb2RlIjoiUDAwMSJ9...", "student_id": "P001"}
```

- The token is a signed ticket that says "this is P001". It is valid for **30 days**. Keep it in the phone's secure storage and send it on every `/chat` and `/progress` call.
- Log out = delete the token on the phone (the server keeps nothing to delete).
- The password is never stored: only a salted hash (Werkzeug). It is never logged.

**Errors:**

| Status | `code` | When | App shows |
|---|---|---|---|
| 400 | `invalid_request` | Bad code, password too short or too long, not JSON | The field fix message |
| 409 | `code_taken` | Sign up with a code that already exists | "That code is taken..." |
| 401 | `details_dont_match` | Log in with a wrong password **or** an unknown code (the same answer, so nobody can find out which codes exist) | "That code and password don't match..." |
| 429 | `too_many_attempts` | 5 wrong passwords for this code in 15 minutes | "Too many tries. Please wait 15 minutes" |
| 503 | `auth_unavailable` | `AUTH_SECRET` or Supabase is not set up, or the database cannot be read | "Something went wrong, try again" |

Students made before Stage 7c (the old test codes) have no password and cannot log in. Make new test accounts with sign up.

**Server setup (once):** run `backend/sql/stage7c_auth.sql` in the Supabase SQL Editor, and add a line `AUTH_SECRET=<at least 32 random characters>` to `backend/.env`. Without `AUTH_SECRET`, sign in is switched off and protected calls answer 503 (it fails closed).

## 1. POST /chat

Asks the Socratic tutor for its next message.

### Request body

```json
{
  "problem": "Natalia sold clips to 48 of her friends in April, and then she sold half as many clips in May. How many clips did Natalia sell altogether?",
  "history": [
    {"role": "teacher", "content": "What is the very first piece of information in the problem?"},
    {"role": "student", "content": "She sold 48 clips in April."}
  ],
  "student_id": "P001",
  "session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b"
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| `problem_id` | string | no | Agent plan, Step 1.4: the `id` of a problem from `GET /problems` (for example `"alg-9-1"`). Then the server uses **its own** text for that problem and saves the id with the session. An unknown id gives 400. |
| `problem` | string | yes, unless `problem_id` is sent | Not empty, max 2000 characters. Ignored when `problem_id` is sent. Still needed for a problem the student typed in. |
| `history` | list | no (default `[]`) | Max 50 items |
| `history[].role` | string | yes | Exactly `"teacher"` or `"student"` |
| `history[].content` | string | yes | Not empty, max 2000 characters |
| `student_id` | string | no | Stage 7c: optional. If sent, it must be the same code as in the token (else 403). The student is always taken from the token. |
| `session_id` | string | no | The `session_id` from an earlier reply. Leave it out on the first message of a session. |

Notes for the frontend:
- First message of a session: send `"history": []` and no `session_id`. The tutor opens the conversation.
- After the student types something, add it to `history` as a `"student"` item (as the **last** item), then call `/chat`.
- Add each reply to `history` as a `"teacher"` item.
- Send the header `Authorization: Bearer <token>` on every call (Stage 7c). Without a token the tutor still answers, but **nothing is saved**. A code in the body without a token gives 401.
- Send the `session_id` from the previous reply on every call after the first, so the whole conversation is saved in one session.
- A token that is wrong or older than 30 days gives **401 `login_required`**: send the student back to Log in.
- Only the newest student message (the last `history` item, if it is from the student) and the tutor's reply are saved on each call, so earlier messages are not saved twice.
- For a problem from the list, send `problem_id` on every call of the session (Step 1.4). Old apps that only send `problem` keep working exactly as before. **Server setup (once):** run `backend/sql/stage9_agent.sql` in the Supabase SQL Editor before the app starts sending `problem_id`; without it, the session cannot be saved (the reply still comes back).

### Success reply (200)

```json
{"reply": "Nice start! What does 'half as many' tell you about May?", "session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b", "hint_level": 1, "scaffold_level": 3, "reflection_type": null}
```

- `session_id` is always present. It is `null` when nothing was saved (no `student_id` sent, or the database is not set up). **Saving never breaks the chat:** if saving fails, the reply is still returned (with the `session_id` you sent, or `null`), and the problem is only recorded in the server log.
- `hint_level` (new in Stage 4) is a number from 1 to 3. It is the hint level the tutor **used** for this reply (see sections 2 and 2b). The frontend may ignore it, or show it later on the progress dashboard.
- `scaffold_level` (new in Stage 5) is a number from 1 to 3: the **highest** hint level the tutor was allowed to use for this student (see section 2b). 3 = full support (the default, also for new students and when no `student_id` is sent). The frontend does not need to send anything new for this; it only needs the same `student_id` on every call. The frontend may ignore it, or show it later on the progress dashboard.
- `reflection_type` (new in Stage 6) is `null` on most replies. On the one reply in a session where the tutor was asked to add a personal reflection question, it is a short word: `"asks_for_answer"`, `"often_stuck"`, `"improving"` or `"self_checker"` (see section 2c). The frontend does not need to send anything new for this; it only needs the same `student_id` and `session_id` on every call. The frontend may ignore it, or show it later on the progress dashboard.

## 2. How the tutor decides (agent plan, Phase 2)

Since Phase 2 the server runs a full cycle for every student message (`backend/app/tutor_agent.py`):

1. **Check** (`assessment.py`): Gemini fills in a short form about the newest message (what the student is doing, right or wrong, which common mistake). Python checks every value. For a problem sent with `problem_id`, Python's **answer checker** (`answer_check.py`) has the last word on whether the problem is solved. If Gemini fails, the Stage 4 word rules below fill in the form.
2. **Decide** (`policy.py`): plain rules choose ONE action. Each wrong try or "I'm confused" on the same step gives one more rung of help: check-again → small hint → concrete hint → explain the step clearly (never the final answer). A known common mistake gets a question aimed at it (once). A correct final answer gets "well done" and one reflection question. Asking for the answer never gives more help by itself.
3. **Reply**: Gemini writes the reply for that action.
4. **Safety check**: the reply must not give away any part of the answer and must be short; otherwise it is written again once, then a safe ready-made reply is used.
5. **Remember**: the session memory (`sessions.state`: tries, hints, last action; numbers and labels only) is saved for the next message. The session gets `status = 'solved'` when the answer is found.

`hint_level` in the reply is now the help level of the chosen action (1 = a question, 2 = a small hint or a mistake question, 3 = a concrete hint or an explanation). The reply fields and the app do not change. Each student message now uses **two** Gemini calls, so a reply takes a little longer, and "coach busy" (503) can happen a little more often when Google is busy.

New indicator rows (value 1): `wrong_attempt`, `solved`, `misconception`. The Stage 4-7 rows are still saved as before.

### The Stage 4 word rules (now the backup)

The server reads the student's **last 3 messages** in `history` and counts how many show a struggle ("I don't know", "I'm confused", "just tell me the answer", and similar). It uses simple word rules, not an AI call.

| Struggling messages in the last 3 | `hint_level` | What the tutor does |
|---|---|---|
| 0 | 1 | Only a guiding question, no hint |
| 1 | 2 | Points to the part of the problem to look at |
| 2 or 3 | 3 | Small, concrete hint, extra warm. Still never the final answer |

If the student struggled earlier but the newest message is fine, the level goes down by one. If the student fixes their own mistake ("oops, let me try again"), the tutor praises that habit.

Known limit: the rules cannot check if a number is right or wrong. They only read the words the student uses.

When the chat ends with a new student message and a `student_id` was sent, the server also saves rows in the database table `indicators`: `hint_level` (1-3), `scaffold_level` (1-3, new in Stage 5), and `self_correction`, `asked_for_answer`, `stuck` (value 1) when they were noticed, and (new in Stage 6) `reflection_asks_for_answer`, `reflection_often_stuck`, `reflection_improving` or `reflection_self_checker` (value 1) on the one turn where a reflection question was asked.

## 2b. How the scaffold level works (Stage 5)

Stage 4 looks at the **current chat**. Stage 5 also looks at the student's **earlier sessions** (saved in the `indicators` table) and slowly takes help away when the student needs less and less of it. This only happens when a `student_id` is sent.

The server takes the average `hint_level` of each of the student's last 3 **earlier** sessions (the session in progress is left out):

| Earlier sessions | `scaffold_level` | Highest hint level the tutor may use |
|---|---|---|
| Fewer than 2 sessions with data (new student) | 3 | 3 (full support, same as Stage 4) |
| Newest earlier session averaged 2.5 or more | 3 | 3 (help comes back) |
| Average of last 3 is 1.3 or less | 1 | 1 (minimal support) |
| Average of last 3 is 1.8 or less | 2 | 2 (reduced support) |
| Anything else | 3 | 3 |

The hint level used is `min(hint level from Stage 4, scaffold_level)`. When help has been faded, the tutor is also told to ask the student to explain their own plan first.

**Safety valve:** if 2 or more of the student's last 3 messages show a struggle (for example "I don't know" and then "just tell me"), the tutor may always use at least hint level 2, so a student is never left without help.

If the database cannot be read, the server uses `scaffold_level` 3 and the chat works as in Stage 4. Nothing for the frontend to handle.

In the `indicators` table, the saved `hint_level` is the level the student **needed** (from Stage 4, before the limit), so the data keeps showing real need. A new indicator `scaffold_level` (1-3) is saved next to it, on the same turns.

Known limits: the thresholds (1.3, 1.8, 2.5, 3 sessions) are first guesses and are not tested with real teenagers yet (Phase 3). They are based on the word rules of Stage 4, which cannot check if an answer is right.

## 2c. How personalised reflection questions work (Stage 6)

Stage 6 lets the tutor ask the student to think about their **own way of working**, using the student's **earlier sessions**. Example: "You asked for the answer a few times before. What did you try on your own this time?" This only happens when a `student_id` **and** a `session_id` are sent.

**When (all must be true):**
- The student has sent at least 3 messages in this session.
- The newest message is a new student message that is **not** a struggle (not "I don't know", not "just tell me").
- No reflection question has been asked in this session yet (**at most one per session**).
- The student has at least 2 earlier sessions with data.

**Which one** (from the last 3 earlier sessions; the first rule that fits wins):

| Earlier sessions show | `reflection_type` | What the tutor asks about |
|---|---|---|
| Asked for the answer 2 or more times | `asks_for_answer` | What they tried on their own before asking |
| Said they were stuck 3 or more times | `often_stuck` | How they got going or decided where to start |
| Average hint level fell by 0.5 or more (oldest to newest) | `improving` | What is different for them now |
| Fixed their own mistakes 2 or more times | `self_checker` | How they check their own work (after a short praise) |
| None of these | `null` | No reflection question |

The tutor still asks its normal guiding question and never gives the answer.

**Privacy:** the server reads only **numbers** (the `indicators` table) of **this student's own** earlier sessions. It never reads old message text and never copies it into a prompt. A `session_id` that belongs to another student is never used.

If the history cannot be read, the server asks no reflection question and the chat works as in Stage 5. Nothing for the frontend to handle. If saving the `reflection_...` indicator fails, the question could be asked once more in the same session.

Known limits: the numbers (2, 3, 0.5, 3 messages) are first guesses and are not tested with real teenagers yet (Phase 3). The signs come from the word rules of Stage 4, which cannot check if an answer is right. Gemini does not always follow the reflection instruction closely; this will be checked in Stage 8.

## 2d. GET /progress and the dashboard page (Stage 7)

Stage 7 lets a student see how their own thinking is growing. It is **not a grade**.

**Request:** `GET /progress` with the header `Authorization: Bearer <token>` (Stage 7c). The numbers are always the logged-in student's own. An old-style `?student_id=CODE` is still allowed only if it is the same code (else 403).

**Success reply (200):**

```json
{
  "student_id": "P001",
  "sessions": [
    {"started_at": "2026-10-01T10:00:00+00:00", "needed_level": 3.0, "allowed_level": 3,
     "stuck": 1, "asked_for_answer": 1, "self_corrections": 0, "reflection_type": null}
  ],
  "totals": {"sessions": 1, "stuck": 1, "asked_for_answer": 1, "self_corrections": 0, "reflections": 0},
  "growth": {"trend": "not_enough_data", "message": "Not enough sessions yet. ..."}
}
```

- `sessions`: the student's newest 10 sessions, **oldest first**. A session with no student messages is left out.
- `needed_level`: average hint level the student needed (1 = little help, 3 = a lot). `allowed_level`: the scaffold level used at the end of the session (or `null`).
- `reflection_type`: `asks_for_answer`, `often_stuck`, `improving`, `self_checker` or `null`.
- `growth.trend`: `less_help`, `more_help`, `steady` or `not_enough_data`. Needs at least 2 sessions. It compares the oldest and newest of the last 3 sessions; a change of 0.5 or more counts (the same rule as Stage 6). `growth.message` is a plain sentence for the student.
- A student the server has never seen gets **200 with empty lists**, and nothing is created.
- The reply has **numbers only**: no message text, no session ids, no names. It is sent with `Cache-Control: no-store`.

**Errors:** 401 `login_required` (no token, or a wrong or old token: log in again); 403 `forbidden` (asking for another student's code); 503 `progress_unavailable` (Supabase is not set up or cannot be read; the chat is not affected).

**Page:** `GET /dashboard` is a simple web page served by the same server. The student logs in with their code and password and sees the growth sentence, number cards, and a line chart of the help needed per session (with a table of the same numbers).

Known limits: the numbers come from the word rules of Stage 4, so "growth" is a rough guide, not proof. The 0.5 rule and the 3-session window are first guesses (Phase 3). Since Stage 7c a student needs their password to see their progress. Still to do before real participants (Phase 3): restrict CORS. The real Flutter screen can use the same `/progress` data.

## 2f. POST /session/end (agent plan, Phase 3)

The app calls this when the student presses **"I worked it out!"** (`reason: "worked_it_out"`) or leaves the chat (`"left"`). Needs the login token. Research data only: the app never shows its errors.

```json
{"session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b", "reason": "worked_it_out"}
```

Reply (200): `{"status": "solved" | "ended", "verified": true | false}`. `verified` says whether the server's own answer check had seen the right answer. For "worked_it_out" the server saves the indicator `claimed_solved` (1 = verified, 0 = not).

Errors: 401 `login_required`; 400 `invalid_request` (bad session id or reason); 404 `not_found` (not this student's session); 503 `session_unavailable`.

## 2g. Settings when the server runs online

See `docs/deploy_backend.md`. With `REQUIRE_LOGIN=true`, `/chat` without a token gives **401 `login_required`**. Every server limits `/chat` to `CHAT_LIMIT_PER_MINUTE` calls per student (default 20): more gives **429 `too_many_requests`** (the app shows "coach is busy, try again"). Every tutor decision is logged in the table `agent_turns` (labels only, never message text; `backend/sql/stage10_agent_log.sql`).

## 2e. GET /problems (agent plan, Phase 1)

The problems a student can pick. No login needed.

**Request:** `GET /problems`, with optional filters `?area=algebra` and/or `?grade=9`.
`area` is one of `number`, `algebra`, `geometry`, `trigonometry`, `graphs`, `statistics`; `grade` is 8, 9, 10 or 11.

**Success reply (200):**

```json
{"problems": [{"id": "alg-9-1", "area": "algebra", "grade": 9, "text": "Solve: 3x − 5 = 2x + 7"}]}
```

- Only `id`, `area`, `grade` and `text`. The **answer, key steps and common mistakes stay on the server** (`backend/data/problems.json`) and are never sent to the app.
- The list is in the file's order. A filter with no matches gives `{"problems": []}`.
- For now these are the same 15 sample problems as the app's own file. A maths teacher must check them before real students use the app.

**Errors:** 400 `invalid_request` (unknown area, or a grade that is not 8-11); 503 `problems_unavailable` (the problem file cannot be read).

## 3. GET /health

Checks the server is running. Reply (200): `{"status": "ok"}`

## 4. Error format

Every error uses the same shape:

```json
{"error": {"code": "invalid_request", "message": "'problem' is required and must be a non-empty string."}}
```

| HTTP status | `code` | When | What the frontend should do |
|---|---|---|---|
| 400 | `invalid_request` | Body is not JSON, a field is missing, wrong type, empty, too long, bad role, bad `student_id`, or `session_id` not a valid id | Fix the request (a bug in the app) |
| 404 | `not_found` | Unknown URL | Check the URL |
| 405 | `method_not_allowed` | Wrong method (e.g. GET on /chat) | Use POST |
| 401 | `login_required` (Stage 7c) | No token where one is needed, or a wrong or old token | Send the student to Log in ("Please log in again") |
| 403 | `forbidden` (Stage 7c) | A code in the request is not the logged-in student | A bug in the app |
| 500 | `server_error` | Unexpected failure, or the Gemini API key or model name is missing on the server | Show "Something went wrong, try again" |
| 503 | `progress_unavailable` (Stage 7, `/progress` only) | Supabase is not set up or cannot be read | Show "Progress is not available right now" |
| 503 | `tutor_unavailable` (new in Stage 4) | Gemini was busy or failed, even after the server tried again 3 times | Show "The tutor is busy, please try again" and let the student press send again. **Nothing was saved**, so it is safe to repeat the same request |

Change in Stage 4: before, a failed Gemini call gave a 200 reply with a fallback sentence that was also saved as a real tutor message. Now it gives the 503 error above and saves nothing.

## 5. CORS

CORS is a browser safety rule that blocks a web page from calling a server on a different address unless the server allows it. The backend allows all origins during development (`flask-cors`). The frontend runs in a browser, so CORS applies to it (native mobile apps would not need it). Before the user study (Phase 3), restrict this to the real frontend address.

## 6. Quick test

```
curl -X POST http://127.0.0.1:5000/auth/signup -H "Content-Type: application/json" -d "{\"student_id\": \"TEST01\", \"password\": \"test-pass-1\"}"
```

Copy the `token` from the reply, then:

```
curl -X POST http://127.0.0.1:5000/chat -H "Content-Type: application/json" -H "Authorization: Bearer PASTE_TOKEN_HERE" -d "{\"problem\": \"What is 2+3?\", \"history\": []}"
```
