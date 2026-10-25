# Use a laptop as the CogniGuide server (free, for team testing)

> **Want to do everything on your own computer** (code, server, app, testing the agent)?
> Use **`docs/TEAM_SELF_SETUP.md`**. This file is for the person who runs a shared test server for the whole team.

Free online hosting needs a card (Render) or is paid (Hugging Face Docker). Until the team chooses
hosting for the study, **one team laptop is the server**, and a free **Cloudflare tunnel** gives it a
public address that everyone's phone can use.

```
Team phone  →  internet  →  Cloudflare tunnel  →  the laptop (backend)  →  Gemini + Supabase
```

**Use this for testing and demos only, not for the real study with students.**

## How it works, in one minute

- The laptop runs **two windows**: the **backend** (our Flask server) and the **tunnel**.
- The tunnel prints an address like `https://some-random-words.trycloudflare.com`.
- The app (APK) is **built with that address**, then installed on the phones.
- While both windows stay open and the laptop is awake and online, the phones work.
- **The address changes every time the tunnel is restarted**, so the APK must be rebuilt then.

## What happens when the laptop is off

**When the server laptop is off, asleep, offline, or one of the two windows is closed, the app does
not work for anyone.** The app opens, but logging in and the coach do not work (it says the coach is
busy or there is no connection). Nothing is lost: accounts, chats and progress are safe in Supabase.
When the server is started again, everything works again (after installing the new APK if the
address changed).

So the team tests **at agreed times**, like a meeting:

1. **Agree a time** in the team chat, for example "Testing tonight 8–9 pm".
2. **The server person** starts both windows a few minutes before, checks `https://<address>/health`,
   and posts in the team chat: *"Server is ON. Address changed: new APK attached"* (or *"same APK as
   last time"*).
3. **The team tests** during that time.
4. **The server person** posts *"Server is OFF"* when finished and closes both windows.

Tip: if the server person keeps the tunnel window open between sessions (laptop on and awake), the
address stays the same and nobody needs a new APK. Every restart of the tunnel means a new address
and a new APK.

## When the server laptop is off: how to test on your own

The APK only works while **its** server laptop and tunnel are on. When that laptop is off (for
example at night), any team member can still test in one of these ways.

**All of them need the code and the secret `.env` file.** Get the code with "part 2" below (clone).
Ask the project owner for `.env` **privately** (a direct message, never the group chat), put it in the
main project folder, and never commit or share it.

### Way 1: be your own server (test on your own phone)

You do exactly what the server person does, on **your** laptop:

1. Do "part 2" below once: clone the project, set up `venv`, add `.env`, `flutter pub get`.
2. Install the tunnel once: `winget install --id Cloudflare.cloudflared`
3. Follow **"Every time you start the server"** below on your laptop: Window 1 (backend), Window 2
   (tunnel, copy the new address), then build the APK with **your** address.
4. Install that APK on your phone and test. It works while **your** laptop runs both windows.

You can share your APK with others too: then you are the server person for that session.

### Way 2: test the agent on your computer only (no phone, no tunnel)

The easiest way to see **how the agent works**:

1. Do "part 2" below once (clone, `venv`, `.env`, `flutter pub get`).
2. **Start your backend:** `cd backend` then `..\venv\Scripts\python -m app.api`
3. Pick one:
   - **The app on an Android emulator** (Android Studio → Device Manager → start a phone), then in a
     second terminal: `cd frontend` then `flutter run`. The app talks to your own backend automatically.
   - **Scripted students** (no app at all): in a second terminal, `cd backend` then
     `..\venv\Scripts\python ..\experiments\phase4_agent_eval\run_scenarios.py`. It plays 8 pretend
     students through the real agent and saves every reply, with the action the agent chose and why,
     in `experiments/phase4_agent_eval/results_<time>.md`.
4. See the decisions in Supabase: **Table Editor → `agent_turns`** (explained in "See how the agent decides").

### Way 3 (later): real hosting

With Render (free plan, needs a card for verification) or university hosting, the server is always
on, no laptop is needed, and one APK works for everyone. See `docs/deploy_backend.md`.

## One-time setup (on the server laptop)

1. The project is on the laptop, with its `.env` file (the secrets) and the `venv` folder.
2. Install the tunnel program (official, free, no account):
   ```
   winget install --id Cloudflare.cloudflared
   ```
   It installs to `C:\Program Files (x86)\cloudflared\cloudflared.exe`.
3. Stop the laptop from sleeping while it is the server:
   **Settings → System → Power & battery → Screen and sleep → "When plugged in, put my device to sleep after" → Never.**
   Keep it plugged in. Closing the lid may put it to sleep, so leave it open.

## Every time you start the server

### Window 1: the backend
In VS Code, open a terminal and type, one line at a time:
```
cd "D:\SLTC\Projects\fyp folder\cogniguide-fyp\backend"
```
```
$env:REQUIRE_LOGIN="true"; ..\venv\Scripts\python -m app.api
```
Wait for `Running on http://127.0.0.1:5000` and **`Debug mode: off`**. Leave it open.

### Window 2: the tunnel
Open a **second** terminal (the **+** button) and type:
```
& "C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:5000
```
Find the box with **`https://....trycloudflare.com`** and copy that address. Leave it open.

### Check it
Open `https://<address>/health` in a browser → `{"status":"ok"}`.

### Build the app for this address (only when the address changed)
Open a **third** terminal:
```
cd "D:\SLTC\Projects\fyp folder\cogniguide-fyp\frontend"
```
```
flutter build apk --release --dart-define=API_BASE_URL=https://<address>
```
The app is `frontend\build\app\outputs\flutter-apk\app-release.apk`. Send it to the team
(for example in the team chat or Google Drive).

## For team members, part 1: test the app on your phone (no code needed)

Only during a test time when the server person has posted **"Server is ON"**.

### Install the APK (Android)

1. Download the newest **APK** from the team chat or Google Drive (the server person posts it).
   Use the newest one: an old APK may point to an old address.
2. Tap the downloaded file (in **Downloads**, or in WhatsApp / Drive).
3. If the phone says *"For your security, your phone is not allowed to install unknown apps from
   this source"*: tap **Settings** → turn on **Allow from this source** → go back → **Install**.
   This is normal for apps that are not from the Play Store.
4. If Google Play Protect warns about an unknown app: **More details → Install anyway**
   (it is our own app, not from the Play Store).
5. A newer APK installs **over** the old one. Your account stays.

### Test it (about 15 minutes)

1. Open **CogniGuide** → **Create an account**: a made-up username (never your real name) and a password you remember.
2. Pick a buddy, then try these and note what happens:

   | Try this | What should happen |
   |---|---|
   | Open an **Algebra** problem and wait | The coach asks a first question (if Gemini is busy, a short simple question) |
   | Give a **wrong answer** (for example `x = 2` for *3x − 5 = 2x + 7*) | The coach says to check that step, without giving the answer |
   | Give two more wrong answers | The help grows each time (hint, then a clearer hint) |
   | Type **"I don't know"** | A hint |
   | Type **"just tell me the answer"** | A kind "no" and a small next step, never the answer |
   | Give the **right answer** (`x = 12`) | "Correct, well done" + one question about how you did it |
   | Tap **I worked it out!** | The celebration screen |
   | Open **My progress** | Your numbers (the chart needs 2 or more sessions) |
   | **Settings** → Look → Dark; scroll the problem list | Dark mode; the top bar folds when you scroll down |
   | Log out, then log in again | Works with your username and password |

3. **Report problems** in the team chat with: what you did, what you saw (a screenshot), the time,
   and your username. Never share your password.

### See how the agent decides (the "brain" behind each reply)

Every coach reply is logged with **what the agent thought and why**. Three ways to look:

1. **Supabase (anyone with access to the project's Supabase dashboard):**
   **Table Editor → `agent_turns`**. One row per reply, newest at the bottom:
   - `intent`, `correctness`, `mistake_id`: what the student check saw (`check_source`: `llm` = Gemini, `fallback` = word rules)
   - `answer_check`: Python's answer check (`correct`, `wrong`, `partial`, `not_found`)
   - `action` and `reason`: what the tutor chose and why (for example `GIVE_SMALL_HINT`, "wrong try 2 on this step")
   - `hint_level`: how much help (1 = a question, 3 = a clear explanation); `guard`: the safety check (`ok`, `rewritten`, `safe_reply`, `gemini_busy`)

   Tip: chat in the app with your test username, then look at the newest rows. The table holds labels
   only, never message text. (Ask the Supabase owner to invite you to the project; never share keys.)
2. **The server laptop, Window 1:** each message shows a line `"POST /chat HTTP/1.1" 200`. Lines with
   `503 UNAVAILABLE` mean Gemini was busy (the coach then used a safe reply).
3. **Scripted students (team members with the code and `.env`):** run
   `python ../experiments/phase4_agent_eval/run_scenarios.py` from `backend/`. It plays 8 pretend
   students (right answer, wrong answer, misconception, confused, begging for the answer...) through the
   real agent and saves every reply with its action and reason, ready for scoring with `rubric.md`.
   How the agent works is explained in `docs/AGENT_REPORT.md` (sections 3 and 7).

## For team members, part 2: get the code on your computer (only if you work on the code)

You do **not** need this to test the app. It is for team members who change the code or want to run
their own copy.

### First time: copy the project to your computer ("clone")

1. Install **Git** (git-scm.com) and **VS Code**. For the backend also **Python 3.12 or newer**;
   for the app also **Flutter** (flutter.dev).
2. In VS Code: **Source Control** (left bar) → **Clone Repository** → paste
   `https://github.com/kavindya-jc/cogniguide-fyp.git` → choose a folder (for example `D:\Projects`).
   (You need access to the repository: ask the owner to add you on GitHub.)
3. **Backend setup** (in a VS Code terminal, in the project folder):
   ```
   python -m venv venv
   ```
   ```
   .\venv\Scripts\python -m pip install -r requirements.txt
   ```
4. **The secrets file `.env`:** ask the project owner for it **privately** (never in a group chat).
   Put it in the main project folder. Git ignores it: **never commit it, never share it.**
5. **App setup:**
   ```
   cd frontend
   ```
   ```
   flutter pub get
   ```

### Every time before you start working: get the newest code ("pull")

- VS Code: **Source Control** → **⋯** (three dots) → **Pull** (or the **Sync Changes** button).
- Or in a terminal, in the project folder: `git pull`
- After a pull, if `requirements.txt` or `pubspec.yaml` changed, run the install commands again
  (`pip install -r requirements.txt`, `flutter pub get`).

### Check that everything works on your computer

- Backend tests: `cd backend` then `..\venv\Scripts\python -m pytest` → all **passed**.
- App tests: `cd frontend` then `flutter test` → **All tests passed!**
- Run your own backend: `cd backend` then `..\venv\Scripts\python -m app.api`
  (it only works on your own computer; it needs the `.env`).
- Run the app on an emulator against your own backend: `cd frontend` then `flutter run`.

### When you changed something

1. Run both test commands above.
2. **Pull** first (to get the others' changes), then commit and **push** (VS Code: Source Control →
   message → **Commit** → **Sync Changes**).
3. Check the file list before committing: never `.env`, `venv`, `build`, `.pytest_cache`.
4. Tell the server person when the backend changed: they restart Window 1 to use the new code.

## When you finish (server person)

- Press **Ctrl + C** in the tunnel window, then in the backend window. The address stops working at once.

## Safety rules (please follow)

- Share the address **only with the team**, never in public groups.
- **Never** turn on debug mode (`FLASK_DEBUG=1`) while the tunnel runs.
- Always start the backend with `REQUIRE_LOGIN="true"` (only logged-in users can chat; each user can send at most 20 messages a minute).
- Close the tunnel when testing is finished.
- Messages pass through Cloudflare and Google Gemini: fine for team testing; for real students this
  must be in the consent/privacy notice (and real hosting should be used).
- The secrets stay in the laptop's `.env`; they are never sent through the tunnel.

## If something goes wrong

| What you see | What it means / what to do |
|---|---|
| Logging in or the coach does not work for **everyone** at once | The server is off: the laptop is off or asleep, or a window was closed. Ask the server person; check the team chat for "Server is ON". |
| The coach says **"busy"** but the backend window shows **no new `POST /chat` lines** | The phone cannot reach the laptop: is the tunnel window still open? Did the address change (then rebuild the APK)? Is the laptop online and awake? |
| The backend window shows `503 UNAVAILABLE ... high demand` | Google's free Gemini is busy. Normal. The coach still answers with a short safe reply. Try again later for full replies. |
| `/health` does not open | Window 1 or 2 is closed, or the laptop went to sleep. Start them again (the address will be new → rebuild the APK). |
| "Please log in again" in the app | The login expired or the server secret changed. Log in again (progress is kept). |
| `cloudflared is not recognized` | Use the full path command above, or close and reopen VS Code. |
| Phone says the app is not installed / blocked | Allow "Install unknown apps" for the app you opened the APK from. |

## Later: real hosting for the study

The laptop must stay on, and the address changes, so for the study use real hosting:
**Render** (free plan, needs a card for verification; see `docs/deploy_backend.md`) or **university
hosting**. The app only needs to be rebuilt once with the permanent address.
