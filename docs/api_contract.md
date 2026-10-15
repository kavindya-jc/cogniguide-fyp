# CogniGuide API Contract (Phase 2, Stages 1 and 3)

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
{"reply": "Nice start! What does 'half as many' tell you about May?", "session_id": "3f2b8c1e-5a47-4d6e-9b0a-1c2d3e4f5a6b"}
```

`session_id` is always present. It is `null` when nothing was saved (no `student_id` sent, or the database is not set up). **Saving never breaks the chat:** if saving fails, the reply is still returned (with the `session_id` you sent, or `null`), and the problem is only recorded in the server log.

## 2. GET /health

Checks the server is running. Reply (200): `{"status": "ok"}`

## 3. Error format

Every error uses the same shape:

```json
{"error": {"code": "invalid_request", "message": "'problem' is required and must be a non-empty string."}}
```

| HTTP status | `code` | When | What the frontend should do |
|---|---|---|---|
| 400 | `invalid_request` | Body is not JSON, a field is missing, wrong type, empty, too long, bad role, bad `student_id`, or `session_id` not a valid id | Fix the request (a bug in the app) |
| 404 | `not_found` | Unknown URL | Check the URL |
| 405 | `method_not_allowed` | Wrong method (e.g. GET on /chat) | Use POST |
| 500 | `server_error` | Unexpected failure, or the Gemini API key is missing on the server | Show "Something went wrong, try again" |

Known limitation: if the Gemini call itself fails, the Phase 1 agent returns a friendly fallback sentence instead of raising an error, so the API replies **200** with that sentence. We are not changing `socratic_agent.py`, so the API cannot tell this apart from a normal reply.

## 4. CORS

CORS is a browser safety rule that blocks a web page from calling a server on a different address unless the server allows it. The backend allows all origins during development (`flask-cors`). The frontend runs in a browser, so CORS applies to it (native mobile apps would not need it). Before the user study (Phase 3), restrict this to the real frontend address.

## 5. Quick test

```
curl -X POST http://127.0.0.1:5000/chat -H "Content-Type: application/json" -d "{\"problem\": \"What is 2+3?\", \"history\": [], \"student_id\": \"TEST01\"}"
```
