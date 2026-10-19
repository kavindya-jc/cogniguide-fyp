# CogniGuide: Handoff to Claude Code (build the Flutter app)

Date: 19 Oct 2026
For: Claude Code
Status: backend Stages 1 to 8 done and pushed (latest commit `6541b0b`). Design finished. Flutter app not started.

This file adds the **backend facts and rules** to `docs/design/HANDOFF.md`. Read both. If they disagree on a backend fact, this file was checked against the repo on 19 Oct 2026 and wins.

---

## 1. Prompt to paste into Claude Code

> I'm building the CogniGuide Flutter app. I'm a beginner with Flutter, on Windows with VS Code and PowerShell. Explain each step in very simple words and don't skip steps.
>
> First read these files in the repo:
> 1. `frontend/CLAUDE.md` (rules for the app)
> 2. `docs/design/HANDOFF.md` (what the design team did)
> 3. `docs/design/README.md` and `docs/design/CogniGuide_Design_Spec.md` (the design)
> 4. `docs/api_contract.md` (the backend API)
> 5. `docs/CLAUDE_CODE_HANDOFF.md` (this file: backend facts, rules, build order)
>
> If any of these files is missing, tell me which one and stop. Don't guess.
>
> Then do **Step 0 only** from section 6 below. Before you change anything, tell me what you will do and wait for my OK. After each step, list the files you changed and how I can test it. Do not commit or push. I commit with the VS Code Source Control panel.

---

## 2. What the project is
CogniGuide is a final-year project. It is a Socratic maths tutor for teenagers (ages 13 to 16 in this app, Grades 8 to 11, Sri Lankan syllabus). The tutor never gives the final answer. It asks guiding questions. The app has a chat with the tutor ("coach") and a private progress screen.

Team decisions:
- Maths only. Areas: Number, Algebra, Geometry, Trigonometry, Graphs, Statistics.
- Typed questions only. No picture upload.
- English first. Sinhala and Tamil later.
- Anonymous code + password. No name, email or photo, anywhere.
- The person talking to you and Claude build the whole app, one step at a time. Do not split work between named team members and do not write plans that give tasks to named people.

---

## 3. Check before Step 0 (what GitHub really has)
I checked `main` on GitHub on 19 Oct 2026. It holds only `frontend/lib/screens/.gitkeep` and `frontend/lib/widgets/.gitkeep`. It does **not** yet hold `docs/design/` or `frontend/CLAUDE.md`. They may exist only on the person's computer and may not be committed yet.

So:
1. Run `git status` and show me the result. Check whether `docs/design/` and `frontend/CLAUDE.md` exist on disk.
2. If they exist but are not committed, tell me. I will commit them with VS Code before we go on.
3. If `frontend/CLAUDE.md` is missing, offer to create it from section 5 of this file.
4. There is a second Flutter project at `C:\Users\GEETH\cogniguide_app`. It is not in this repo. **Do not touch it and do not delete anything outside this repo.** The recommended place for the app is `frontend/` in this repo. Ask me to confirm before Step 0.

---

## 4. The backend (finished, do not change `backend/` unless I ask)

### How to run it
From the repo root, in PowerShell:
```
cd backend
python -m app.api
```
Leave that terminal alone. Use a new terminal for Flutter. The server needs a `.env` file with keys. **Never open, print or ask for `.env` or any key.** Never put a key in the app.

### Addresses for the app
| Where the app runs | Server address |
|---|---|
| Flutter web in Chrome, Windows desktop | `http://127.0.0.1:5000` |
| Android emulator | `http://10.0.2.2:5000` (the emulator cannot reach `127.0.0.1`) |
| Real phone | The computer's local network address, same Wi-Fi, port 5000 (later) |

Put the base address in **one config file** in the app so it is easy to change. CORS is open for development only.

### `POST /chat`
Request (JSON):
```
{"problem": "...", "history": [{"role": "teacher"|"student", "content": "..."}], "student_id": "P001", "session_id": "<id or leave out>"}
```
- `problem` is required, not empty, max 2000 characters. Send it **every call**, even on the first message.
- `history` max 50 items, each text max 2000 characters. The server keeps no memory, so the app sends the whole history every call.
- **First message of a session:** send `history: []` and no `session_id`. The tutor opens the chat. Show the reply as the first coach bubble.
- After the student types, add it to `history` as the **last** item (`student`), then call `/chat`. Add each reply to `history` as a `teacher` item.
- `student_id` is the anonymous code: 1 to 64 characters, letters, digits, `_` or `-`. Never a name or email.
- Keep the `session_id` from the first reply and send it back on every later call of the same chat. Start a new chat (new problem) with no `session_id`.
- Success reply: `{"reply", "session_id", "hint_level", "scaffold_level", "reflection_type"}`. **Show only `reply`.** Never show the other fields to the student.

### `GET /progress?student_id=CODE`
Reply:
```
{"student_id", "sessions": [{"started_at", "needed_level", "allowed_level", "stuck", "asked_for_answer", "self_corrections", "reflection_type"}], "totals": {"sessions", "stuck", "asked_for_answer", "self_corrections", "reflections"}, "growth": {"trend", "message"}}
```
- `sessions` are oldest first. Chart y value is `needed_level` (1 = a little help, 3 = a lot; lower is better).
- Growth sentence is `growth.message`. Hide the small line "Based on your most recent sessions" when `growth.trend` is `not_enough_data`.
- Tiles: Sessions = `totals.sessions`, Fixed own mistake = `totals.self_corrections`, Felt stuck = `totals.stuck`, Reflection questions = `totals.reflections`.
- Fewer than 2 sessions: show the new-student screen. An unknown code returns 200 with empty lists (it is not created).

### Errors (always `{"error": {"code", "message"}}`)
| Status | Code | What the app shows |
|---|---|---|
| 503 | `tutor_unavailable` | "Coach is busy". Safe to resend the same request. Nothing was saved. |
| 503 | `progress_unavailable` | "Progress is not available right now" |
| 500 | `server_error` | "Something went wrong" |
| 400 | `invalid_request` | A bug in the app. Log it. Show "Something went wrong". |
| no connection | | "No internet" |

### Test codes (for the real server)
- `P001` or any new code: a new student (new-student screen).
- `TESTS8IMPROVING1163822`: 4 sessions (progress screen with data).
- `TESTS8STRONG1163822`: 1 session (not enough sessions).
These are fake test students and will be deleted before real students use the app.

### Not in the backend yet (a separate Stage 7c, done in the cloud chat, not by you)
1. **Sign up and log in** (code + password, passwords hashed, a login token, errors "code taken" and "details don't match").
2. **A problem list endpoint** (`GET /problems?area=&grade=`).
3. **`area`, `grade` and `language` fields** on `/chat`.

Until 7c is done, build the screens against **small stand-ins** so we can swap them later:
- An `AuthService` with `signUp`, `logIn`, `logOut`. For now it only saves the code on the phone and **does not check any password**. Mark it clearly in the code as a temporary stand-in.
- A `ProblemRepository` that reads a local JSON file (sample problems are in the design screens). A maths teacher must check them.
- The `language` and the area and grade stay app-only for now.

Warning to keep in the report: the tutor's stuck and "asked for the answer" signs come from English word rules. They will not work for Sinhala or Tamil messages.

---

## 5. Rules for `frontend/CLAUDE.md` (or follow these now)
1. **Beginner.** Very simple words, short sentences. Say exactly what to click or type. One step at a time. After each step list the files you changed and how to test it.
2. **Wait for my OK** before changing files at the start of each step.
3. **Windows and PowerShell.** Give commands as single lines in code format. Start Python commands with `python`.
4. **Secrets.** Never open or print `.env`. Never ask for keys. Never put keys in the app.
5. **Git.** Do not commit or push. I use the VS Code Source Control panel. Suggest a clear commit message. Before each commit, tell me to check the file list for `.env`, `venv`, `build/`, `.dart_tool/`, the Flutter SDK, `.idea/` and PDFs. Make sure `frontend/.gitignore` covers the Flutter build folders. Keep `pubspec.lock`.
6. **No PDFs or progress reports in the repo.** Team approval and progress PDFs are shared in chat only.
7. **Do not change `backend/`** unless I ask. If the API needs a change, write it down and I will take it to the cloud chat.
8. **Do not delete files outside this repo.**
9. **Student privacy.** No name, email, photo or school anywhere in the app, logs or saved data. The code is the only identity.
10. **Show only the coach's `reply`.** Never show hint level, scaffold level or reflection type.
11. **Design.** Follow the design spec and tokens exactly. Text at least 16px, buttons 52px tall, touch targets at least 44px. No red or coral for student actions. No points, badges, streaks or leaderboards. All motion turns off with "reduce motion".
12. **Words.** Put all app text in ARB language files from the start. Use Noto Sans Sinhala and Noto Sans Tamil for those languages later.
13. **Keep every colour in the theme** so dark mode can be added later.
14. After each step, write a short plain-language note for the team (not in the repo unless I ask).

---

## 6. Build plan (one step at a time)

| Step | What | Done when |
|---|---|---|
| 0 | Set up the Flutter project in `frontend/` (`flutter create .`, keep the existing `lib/`). Run `flutter doctor` and explain it. Add packages: `google_fonts`, `flutter_svg`, `flutter_animate`, `http`, `shared_preferences`, `flutter_localizations` and `intl`. Add the Flutter lines to `.gitignore`. | `flutter run -d chrome` shows a blank app |
| 1 | Theme in `lib/theme/` from `docs/design/tokens/` (colours, Outfit font, text styles, radius, spacing) | A test page shows the colours and text styles |
| 2 | Shared widgets: pill buttons, icon button, area chip, grade filter, problem card, stat tile, bottom nav, chat bubbles, maths key row, notice card, Pip | Each widget looks like the design |
| 3 | Screens without the server: Welcome, Language, Create account, Log in (stand-in `AuthService`), Pick a problem (local JSON), Settings, Log-out sheet | The student can click through the whole flow |
| 4 | Chat connected to `POST /chat`: typing dots and the 3 error states | A real chat with the local Flask server |
| 5 | My progress connected to `GET /progress`: tiles, chart, list view, new-student and loading states | Real numbers show for the test codes in section 4 |
| 6 | Real sign up and log in. **Wait** until the backend Stage 7c is done and I say so. | Accounts work end to end |
| 7 | Motion with `flutter_animate`, reduce-motion check | Animations match the spec |
| 8 | Language files (English ARB, Sinhala and Tamil later) | All text comes from ARB |

Test first in Chrome. Test on an Android emulator or a real phone later.

---

## 7. Open items
- Add PNG screenshots to `docs/design/screenshots/`.
- Pick the one Flutter project folder (recommended: `frontend/`).
- Replace the sample problems with a checked bank (Grades 8 to 11).
- Test accessibility on a real phone (large system font, screen reader labels, 44px targets).
- Keep the code and session saved on the phone so the student stays logged in.
- Later (Phase 3 readiness): restrict CORS, add a real sign-in check, delete the test students, ethics approval.
