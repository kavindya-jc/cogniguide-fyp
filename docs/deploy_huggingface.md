# Put the CogniGuide backend online on Hugging Face Spaces (free, no card)

Use this when Render asks for a card. After this, the app works on any phone with internet, and your
laptop does not need to be on. It is your own Hugging Face account, so the GitHub owner is not needed.

**Rules:** you paste the secrets yourself, in the Space's settings. Never send a key in a chat, never
put a key in the app or in an uploaded file, never upload `.env`.

## Before you start

- Supabase is ready (all files in `backend/sql/` were run with the editor set to **Database**).
- Your secrets are in your own `.env`, so you can copy them one by one.

## Step 1: Make a Hugging Face account and a Space

1. Go to **huggingface.co** → **Sign Up** (free). Confirm your email.
2. Click your picture (top right) → **New Space**.
3. Fill in:

   | Field | Choose |
   |---|---|
   | Space name | `cogniguide-backend` |
   | License | any (for example `other`) |
   | Select the Space SDK | **Docker** → template **Blank** |
   | Space hardware | **CPU basic · FREE** |
   | Visibility | **Public** (the phone app cannot open a private Space) |

4. Click **Create Space**.

> **Public means** people can see the *code* in the Space's **Files** tab, including the problem list
> with answers (`backend/data/problems.json`). The **secrets stay hidden** and the students' data stays
> in Supabase. If the team is not happy with the answers being visible, talk to Claude about it before
> the real study.

## Step 2: Add the secrets (before uploading)

In the Space: **Settings** → **Variables and secrets** → **New secret**, once for each:

| Name | What to paste |
|---|---|
| `GEMINI_API_KEY` | your Gemini key |
| `GEMINI_MODEL` | the same model name as in your `.env` |
| `SUPABASE_URL` | your Supabase project URL |
| `SUPABASE_SERVICE_KEY` | your Supabase service key |
| `AUTH_SECRET` | a NEW long random text (see below) |
| `GEMINI_FALLBACK_MODEL` | optional: a second model name |

To make a new `AUTH_SECRET`, run this in PowerShell and copy the output:
```
python -c "import secrets; print(secrets.token_urlsafe(48))"
```
(Students log in again once with a new secret. Their progress is kept.)

The online settings (login required, no websites, 20 messages a minute) are already inside the
`Dockerfile`. You do not need to add them.

## Step 3: Make the upload folder

In PowerShell, in the main project folder:
```
.\venv\Scripts\python backend\scripts\make_hf_space.py
```
It makes the folder **`hf-space`** with 21 files: `Dockerfile`, `README.md`, `requirements.txt` and a
`backend` folder. It never contains `.env` or a key. (Git ignores this folder; you can make it again any time.)

## Step 4: Upload

1. In the Space, open the **Files** tab → **+ Contribute** (or **Add file**) → **Upload files**.
2. Open the `hf-space` folder in Windows Explorer, select **everything inside it** (the `backend`
   folder and the three files), and drag it into the upload box.
   - Upload the CONTENTS of `hf-space`, not the `hf-space` folder itself.
   - It replaces the Space's starting `README.md`. That is right: our `README.md` holds the Space's settings.
3. Click **Commit changes to main**.

## Step 5: Wait for it to start, then check

1. Open the **App** tab. It says **Building**, then **Running** (a few minutes the first time).
   If it says **Build error** or **Runtime error**, open **Logs** and send Claude a screenshot.
2. Find the address: the **⋮** menu (top right of the Space) → **Embed this Space** → **Direct URL**.
   It looks like `https://<your-name>-cogniguide-backend.hf.space`.
3. Open in your browser:
   - `https://<address>/health` → `{"status": "ok"}`
   - `https://<address>/problems` → the problem list (no answers)

## Step 6: Build the app for the online server

In PowerShell, in the `frontend` folder (one line, with your own address):
```
flutter build apk --release --dart-define=API_BASE_URL=https://<your-name>-cogniguide-backend.hf.space
```
The APK is in `frontend\build\app\outputs\flutter-apk\app-release.apk`. Send it to the team's phones.

## Good to know

- **Sleeping:** a free Space sleeps after about 2 days with no use. The next visit wakes it (1–2 minutes).
  The app waits long enough for that. **Settings → Restart this Space** also wakes it.
- **Updating the backend later:** run Step 3 again, then upload again (Step 4). The Space rebuilds by itself.
- **Logs:** the **Logs** button at the top of the Space. Gemini "busy" (503) lines there are normal.
- **Change a secret:** Settings → Variables and secrets → edit, then **Restart this Space**.
- **Not tested yet:** we checked the upload folder and that the server code starts without your `.env`,
  but the real Hugging Face build has not been tried. If the first build fails, send Claude the Logs.
