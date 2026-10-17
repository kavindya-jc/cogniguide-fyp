# CogniGuide API Contract (Phase 2, Stages 1, 3, 4 and 5)

This is the agreement between the frontend and the Flask backend. The frontend only needs this file.

- Base URL while developing: `http://127.0.0.1:5000`
- All requests and replies are JSON (`Content-Type: application/json`).
- The tutor itself is **stateless**: it does not remember the conversation. The frontend sends the full conversation every time. (The server also saves each chat to the database when a `student_id` is sent, see below.)

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
| `problem` | string | yes | Not empty, max 2000 characters |
| `history` | list | no (default `[]`) | Max 50 items |
| `history[].role` | string | yes | Exactly `"teacher"` or `"student"` |
| `history[].content` | string | yes | Not empty, max 2000 characters |
| `student_id` | string | no | Anonymous code, 1-64 characters: letters, digits, `_` or `-` only (so names and emails are rejected). **If missing, nothing is saved.** |
| `session_id` | string | no | The `session_id` from an earlier reply. Leave it out on the first message of a session. |

Notes for the frontend:
- First message of a session: send `"history": []` and no `session_id`. The tutor opens the conversation.
- After the student types something, add it to `history` as a `"student"` item (as the **last** item), then call `/chat`.
- Add each reply to `history` as a `"teacher"` item.
- Send the same `student_id` on every call. Send the `session_id` from the previous reply on every call after the first, so the whole conversation is saved in one session.
- Only the newest student message (the last `history` item, if it is from the student) and the tutor's reply are saved on each call, so earlier messages are not saved twice.

### Success reply (200)

```json
{"reply": "Nice start! What does 'half as many' tell you about May?", "session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b", "hint_level": 1, "scaffold_level": 3}
```

- `session_id` is always present. It is `null` when nothing was saved (no `student_id` sent, or the database is not set up). **Saving never breaks the chat:** if saving fails, the reply is still returned (with the `session_id` you sent, or `null`), and the problem is only recorded in the server log.
- `hint_level` (new in Stage 4) is a number from 1 to 3. It is the hint level the tutor **used** for this reply (see sections 2 and 2b). The frontend may ignore it, or show it later on the progress dashboard.
- `scaffold_level` (new in Stage 5) is a number from 1 to 3: the **highest** hint level the tutor was allowed to use for this student (see section 2b). 3 = full support (the default, also for new students and when no `student_id` is sent). The frontend does not need to send anything new for this; it only needs the same `student_id` on every call. The frontend may ignore it, or show it later on the progress dashboard.

## 2. How the hint level works (Stage 4)

The server reads the student's **last 3 messages** in `history` and counts how many show a struggle ("I don't know", "I'm confused", "just tell me the answer", and similar). It uses simple word rules, not an AI call.

| Struggling messages in the last 3 | `hint_level` | What the tutor does |
|---|---|---|
| 0 | 1 | Only a guiding question, no hint |
| 1 | 2 | Points to the part of the problem to look at |
| 2 or 3 | 3 | Small, concrete hint, extra warm. Still never the final answer |

If the student struggled earlier but the newest message is fine, the level goes down by one. If the student fixes their own mistake ("oops, let me try again"), the tutor praises that habit.

Known limit: the rules cannot check if a number is right or wrong. They only read the words the student uses.

When the chat ends with a new student message and a `student_id` was sent, the server also saves rows in the database table `indicators`: `hint_level` (1-3), `scaffold_level` (1-3, new in Stage 5), and `self_correction`, `asked_for_answer`, `stuck` (value 1) when they were noticed.

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
| 500 | `server_error` | Unexpected failure, or the Gemini API key or model name is missing on the server | Show "Something went wrong, try again" |
| 503 | `tutor_unavailable` (new in Stage 4) | Gemini was busy or failed, even after the server tried again 3 times | Show "The tutor is busy, please try again" and let the student press send again. **Nothing was saved**, so it is safe to repeat the same request |

Change in Stage 4: before, a failed Gemini call gave a 200 reply with a fallback sentence that was also saved as a real tutor message. Now it gives the 503 error above and saves nothing.

## 5. CORS

CORS is a browser safety rule that blocks a web page from calling a server on a different address unless the server allows it. The backend allows all origins during development (`flask-cors`). The frontend runs in a browser, so CORS applies to it (native mobile apps would not need it). Before the user study (Phase 3), restrict this to the real frontend address.

## 6. Quick test

```
curl -X POST http://127.0.0.1:5000/chat -H "Content-Type: application/json" -d "{\"problem\": \"What is 2+3?\", \"history\": [], \"student_id\": \"TEST01\"}"
```
