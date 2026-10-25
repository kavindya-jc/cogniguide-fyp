# CogniGuide: run and test it yourself (step by step)

This guide is for every team member. With it you can do **everything on your own computer**: get
the code, run the server, test how the tutor agent works, and build the app (APK) for your own phone.
You do not need anyone else's laptop to be on.

**Time:** about 1 hour the first time (mostly installing tools). After that, about 5 minutes.

**Which parts do you need?**

| You want to... | Do these steps |
|---|---|
| See how the **agent thinks and decides** (easiest) | 1, 2, 3, 4, 5, **6A** |
| Use the **app** on an Android **emulator** | 1, 2, 3, 4, 5, **6B** |
| Use the **app on your own phone** | 1, 2, 3, 4, 5, **6C** |

---

## Step 1: Install the tools (once)

| Tool | Get it from | Needed for |
|---|---|---|
| **Git** | git-scm.com → Download for Windows (keep the default options) | Getting the code |
| **VS Code** | code.visualstudio.com | Opening the project and terminals |
| **Python 3.12 or newer** | python.org → Downloads. Tick **"Add python.exe to PATH"** in the installer | The server |
| **Flutter** | docs.flutter.dev → Get started → Windows → Android | Steps 6B and 6C only |
| **Android Studio** | developer.android.com/studio (Flutter's guide shows how) | Steps 6B and 6C only |
| **cloudflared** | in PowerShell: `winget install --id Cloudflare.cloudflared` | Step 6C only |

After installing, **close and reopen VS Code** so it finds the new tools.
Check (in a VS Code terminal: **Terminal → New Terminal**):
```
git --version
```
```
python --version
```
For 6B/6C also: `flutter doctor` (fix anything it marks with ✗ for Android).

## Step 2: Get access (once)

1. **GitHub:** ask the repository owner to add your GitHub account to **cogniguide-fyp**
   (GitHub → repository → Settings → Collaborators). Accept the email invitation.
2. **The secret settings file `.env`:** ask the project owner to send it to you **privately**
   (a direct message, never the group chat). It holds the keys for Gemini and Supabase.
   - **Never** commit it, post it, screenshot it or put it in the app.
   - It contains five settings: `GEMINI_API_KEY`, `GEMINI_MODEL`, `SUPABASE_URL`,
     `SUPABASE_SERVICE_KEY`, `AUTH_SECRET`.
3. *(Optional, to see the agent's decisions in Supabase)* ask the Supabase owner to invite you to the
   project (Supabase → Project Settings → Team).

## Step 3: Get the code (once)

1. In VS Code: **Source Control** (left bar) → **Clone Repository**.
2. Paste: `https://github.com/kavindya-jc/cogniguide-fyp.git` → press Enter.
3. Choose a folder (for example `D:\Projects`) → **Open** when VS Code asks.
4. Put the **`.env`** file you received into the **main project folder** (the folder that has
   `backend`, `frontend` and `README.md` in it). The name must be exactly `.env`.

**Later, every time before you start:** get the newest code with **Source Control → ⋯ → Pull**
(or `git pull` in a terminal in the project folder).

## Step 4: Set up the server (once)

In VS Code, open a terminal (**Terminal → New Terminal**). It opens in the project folder. Type one line at a time:
```
python -m venv venv
```
```
.\venv\Scripts\python -m pip install -r requirements.txt
```
Check that everything works:
```
cd backend
```
```
..\venv\Scripts\python -m pytest
```
At the end you should see **`235 passed`** (the number may be higher later). If something fails, send
the last lines to the team.

> If PowerShell says "running scripts is disabled", you do not need to activate anything: the commands
> above call `venv\Scripts\python` directly, which always works.

## Step 5: Start the server

In the terminal (inside the `backend` folder):
```
$env:REQUIRE_LOGIN="true"; ..\venv\Scripts\python -m app.api
```
Wait for **`Running on http://127.0.0.1:5000`** and **`Debug mode: off`**.
**Leave this terminal open** while you test: closing it stops the server.

Check it: open `http://127.0.0.1:5000/health` in your browser → `{"status": "ok"}`.

> For 6B (emulator) you can start without `$env:REQUIRE_LOGIN="true"`: just `..\venv\Scripts\python -m app.api`.

---

## Step 6A: See how the agent thinks (no app needed, easiest)

Open a **second** terminal (the **+** button in the terminal panel) and type:
```
cd backend
```
```
..\venv\Scripts\python ..\experiments\phase4_agent_eval\run_scenarios.py
```
It plays **8 pretend students** through the real agent (a correct answer, a wrong answer, a typical
mistake, a confused student, a student begging for the answer, a student who fixes their own mistake,
a student who makes no progress, an off-topic message). It takes a few minutes (Gemini is slow when
busy). Then open the new file **`experiments/phase4_agent_eval/results_<time>.md`**. For every reply
you see:

```
- Student: x = 2
  - [ADDRESS_MISCONCEPTION | help 2 | a common mistake: sign_when_moving | check incorrect/llm | guard ok]
- Tutor: If you plug x = 2 back into the original equation, ...
```

- **ACTION** (the first word): which of the 11 tutoring actions the agent chose.
- **help 1–3**: how much help (1 = a question, 3 = a clear explanation of the step).
- **the reason**: why it chose that action.
- **check**: what the student check saw (`llm` = Gemini, `fallback` = word rules because Gemini was busy).
- **guard**: the safety check on the reply (`ok`, `rewritten`, `safe_reply`, `gemini_busy`).

This run does **not** write to Supabase (it uses a pretend database). How the agent works is explained
in `docs/AGENT_REPORT.md`, sections 3 and 7.

## Step 6B: Use the app on an emulator (no phone needed)

1. Android Studio → **Device Manager** → start a phone (create one if there is none, for example Pixel).
2. Server running (Step 5). In a **second** terminal:
   ```
   cd frontend
   ```
   ```
   flutter pub get
   ```
   ```
   flutter run
   ```
3. The app opens on the emulator and talks to **your** server automatically.
4. Create an account (a made-up username, never your real name) and follow the checklist in Step 7.

## Step 6C: Use the app on your own phone

Your phone cannot reach `127.0.0.1` on your laptop, so a free **tunnel** gives your server a public address.

1. Server running (Step 5, with `REQUIRE_LOGIN="true"`). In a **second** terminal:
   ```
   & "C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:5000
   ```
   Copy the **`https://....trycloudflare.com`** address it prints. Leave this terminal open.
2. Check: open `https://<address>/health` in your browser → `{"status": "ok"}`.
3. In a **third** terminal, build the app with **your** address (one line):
   ```
   cd frontend
   ```
   ```
   flutter build apk --release --dart-define=API_BASE_URL=https://<your-address>.trycloudflare.com
   ```
   The app is `frontend\build\app\outputs\flutter-apk\app-release.apk`.
4. Send that file to your phone (USB cable, Google Drive, or WhatsApp to yourself as a **Document**).
5. On the phone: tap the file → if asked, **Settings → Allow from this source** → **Install**
   (if Play Protect warns: **More details → Install anyway**).
6. Test with the checklist in Step 7.

**Remember:** this APK works **only while your laptop runs both terminals** (server + tunnel).
Every time you restart the tunnel, the address changes, so you build a new APK (step 3 again).
You can share your APK with teammates for a test session: then you are the server for them.

---

## Step 7: What to test in the app (about 15 minutes)

| Try this | What should happen |
|---|---|
| Open **Algebra → Problem 1** (*3x − 5 = 2x + 7*) and wait | The coach asks a first question |
| Answer **`x = 2`** | The coach asks you to test that idea (a typical sign mistake), no answer given |
| Answer wrong two more times (`x = 3`, `x = 100`) | More help each time (hint, then a clearer hint) |
| Type **I don't know** | A hint |
| Type **just tell me the answer** | A kind "no" and a small next step, never the answer |
| Answer **`x = 12`** | "Correct" + one question about how you did it |
| Tap **I worked it out!** | The celebration screen |
| **My progress** | Your numbers (the chart needs 2+ sessions) |
| **Settings → Look → Dark**; scroll a long list | Dark mode; the top bar folds when you scroll down |
| Log out and log in again | Works with your username and password |

If Gemini is busy (free plan), the coach gives short simple replies. That is normal; the chat continues.

### See the agent's decisions for your own chat (needs Supabase access, Step 2.3)

Supabase → **Table Editor → `agent_turns`** → newest rows at the bottom. Each row is one coach reply:
`intent`, `correctness`, `mistake_id`, `answer_check` (what the agent saw), `action` + `reason` (what it
chose and why), `hint_level`, `guard`. Labels only, never message text.

## Step 8: Stop

Press **Ctrl + C** in each terminal (tunnel first, then the server). Close VS Code.

## Safety rules

- **`.env` stays private**: never commit, post, screenshot or share it in groups.
- Never turn on debug mode (`FLASK_DEBUG=1`) while a tunnel is running.
- Start the server with `REQUIRE_LOGIN="true"` when you use a tunnel.
- Share a tunnel address or APK only with the team. Stop the tunnel when you finish.
- Use made-up usernames only. No real names, schools or phone numbers in chats.

## If something goes wrong

| What you see | What to do |
|---|---|
| `python` or `git` "is not recognized" | Close and reopen VS Code. If still not, reinstall Python with "Add to PATH" ticked |
| `pip install` fails | Check your internet; run the command again. Send the last lines to the team |
| Tests fail | `git pull` first (maybe old code); send the failing test's name to the team |
| `/health` does not open | The server terminal is closed or shows an error: start Step 5 again |
| Creating an account or logging in says "something went wrong", or the coach never answers in 6A | `.env` is missing or in the wrong folder: it must be in the main project folder, named exactly `.env` (not `.env.txt`). Then restart the server |
| The coach says **busy** and the server shows **no new `POST /chat`** lines | The app cannot reach your server: are both terminals open? Did the tunnel address change (build a new APK)? |
| The server shows `503 UNAVAILABLE ... high demand` | Google's free Gemini is busy. Normal: the coach uses short safe replies |
| `flutter` "is not recognized" / `flutter doctor` shows ✗ | Finish Flutter's Windows + Android setup guide, then reopen VS Code |
| `cloudflared` "is not recognized" | Use the full path command in 6C, or reopen VS Code |
| The phone will not install the APK | Allow "Install unknown apps" for the app you opened it from; or Play Protect → Install anyway |

## Want to change the code?

1. **Pull** first (Source Control → ⋯ → Pull).
2. Make your change, then run the tests (Step 4 for the backend; `flutter test` in `frontend` for the app).
3. Commit with a clear message and **Sync Changes** (push). Check the file list: never `.env`, `venv`,
   `build` or `.pytest_cache`.

## More reading

| File | What is in it |
|---|---|
| `docs/AGENT_REPORT.md` | How the agent works, what was built and fixed, what is still missing |
| `docs/TEAM_STATUS.md` | What is done and what comes next for the project |
| `docs/laptop_server.md` | For the person running a shared test server for the whole team |
| `docs/api_contract.md` | The messages between the app and the server |
| `experiments/phase4_agent_eval/rubric.md` | How to score the tutor's replies (two raters) |
