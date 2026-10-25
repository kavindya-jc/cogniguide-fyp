# Put the CogniGuide backend online (Render, free plan)

After this, the app works on any phone with internet. Your laptop does not need to be on.

**Who does what:** you create the Render account and paste the secrets yourself. Never send a key
in a chat, never put a key in the app, and never commit `.env`.

## What you need first

1. The code is pushed to GitHub (VS Code: Source Control → **Sync Changes**). Render reads the code from there.
2. In Supabase you have run every SQL file in `backend/sql/` (`schema.sql`, `stage7c_auth.sql`,
   `stage9_agent.sql`, `stage10_agent_log.sql`), with the editor set to **Database** (not Logs).
3. Your secrets are in your own `backend/.env` (or the root `.env`). You will copy them one by one.

## Step 1: Create the service on Render

1. Go to **render.com** and sign up with your **GitHub** account.
2. Click **New +** → **Blueprint**.
3. Pick the **cogniguide-fyp** repository. Render finds `render.yaml` and shows one service:
   **cogniguide-backend**.
4. Render asks for the secret values. Paste each one from your `.env`:

   | Name | What to paste |
   |---|---|
   | `GEMINI_API_KEY` | your Gemini key |
   | `GEMINI_MODEL` | the same model name as in your `.env` |
   | `GEMINI_FALLBACK_MODEL` | optional: a second model name, or leave empty |
   | `SUPABASE_URL` | your Supabase project URL |
   | `SUPABASE_SERVICE_KEY` | your Supabase service key |
   | `AUTH_SECRET` | a NEW long random text (see below) |

   To make a new `AUTH_SECRET`, run this in PowerShell and copy the output:
   ```
   python -c "import secrets; print(secrets.token_urlsafe(48))"
   ```
   (With a new secret, students log in again once. Their progress is kept.)
5. Click **Apply**. The first build takes a few minutes.

### If Render asks for a card

Render's **Free** instance costs nothing, but Render may ask for a card to verify the account,
especially for **Blueprints**. Decide as a team whether to add one (a card on file means paid extras
*could* be charged if someone turns them on). If you do not want to add a card, try **Step 1b**.
If Render asks for a card there too, ask Claude to prepare the no-card alternative
(Hugging Face Spaces, which needs one small extra file, a `Dockerfile`).

## Step 1b: Create the service by hand (no Blueprint)

1. Render **Overview** → **Deploy a Web Service** → connect GitHub → pick **cogniguide-fyp**.
2. Fill in exactly:

   | Setting | Value |
   |---|---|
   | Name | `cogniguide-backend` |
   | Language / Runtime | **Python 3** |
   | Branch | `main` |
   | Root Directory | `backend` |
   | Build Command | `pip install -r ../requirements.txt` |
   | Start Command | `gunicorn app.api:app --bind 0.0.0.0:$PORT --workers 1 --threads 4 --timeout 120` |
   | Instance Type | **Free** |

3. Under **Environment Variables** add these (the first four are plain settings, the rest are secrets
   you paste from your own `.env`, see the table in Step 1):

   | Key | Value |
   |---|---|
   | `PYTHON_VERSION` | `3.12.7` |
   | `REQUIRE_LOGIN` | `true` |
   | `CORS_ORIGINS` | `none` |
   | `CHAT_LIMIT_PER_MINUTE` | `20` |
   | `GEMINI_API_KEY`, `GEMINI_MODEL`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `AUTH_SECRET` | your secrets |
   | `GEMINI_FALLBACK_MODEL` | optional |

4. **Advanced** → **Health Check Path**: `/health`.
5. Click **Deploy Web Service**.

## Step 2: Check it works

When Render says **Live**, it shows the address, for example `https://cogniguide-backend.onrender.com`.
Open these in your browser:

- `https://<your-address>/health` → `{"status": "ok"}`
- `https://<your-address>/problems` → the problem list (no answers)

## Step 3: Build the app for the online server

In PowerShell, in the `frontend` folder (one line, with your own address):

```
flutter build apk --release --dart-define=API_BASE_URL=https://cogniguide-backend.onrender.com
```

The APK is in `frontend\build\app\outputs\flutter-apk\app-release.apk`. Send it to the team's phones.

## Good to know

- **The free server sleeps** after about 15 minutes with no use. The first message after that
  takes about a minute (the app waits up to 75 s for log in and 120 s for the coach). After that it is fast.
- **Online settings** (already in `render.yaml`):
  - `REQUIRE_LOGIN=true`: only logged-in students can talk to the coach.
  - `CORS_ORIGINS=none`: websites cannot call the API (the phone app does not need it).
  - `CHAT_LIMIT_PER_MINUTE=20`: at most 20 messages a minute per student.
  - Debug mode is off. The server runs with gunicorn.
- **Logs:** Render dashboard → cogniguide-backend → **Logs**. Gemini "busy" (503) messages there are normal.
- **Change a secret:** Render dashboard → cogniguide-backend → **Environment**.
- **On your laptop** nothing changes: `..\venv\Scripts\python -m app.api` from `backend/`.
  For auto-restart while coding, add `FLASK_DEBUG=1` to your `.env`.
