# Put the CogniGuide backend online on Google Cloud Run

After this, the backend runs on Google's servers: **no laptop, no tunnel**, a permanent address, and
**one APK works for everyone, any time.**

**Who does what:** the person who owns the Google Cloud account runs the steps. You paste the secrets
yourself into Google's Secret Manager. Never send a key in a chat, never put a key in the app or in an
uploaded file, never upload `.env`.

**Honest status:** this guide was written carefully but **not yet tested on a real Google Cloud
project** (the computer it was written on has no `gcloud` or Docker). If a step fails, copy the red error
text to the team/Claude; the table at the end covers the likely ones.

## What it costs

Cloud Run has a monthly **free allowance** (requests, CPU and memory seconds), and a small backend like
ours is expected to stay inside it, so $0. **Check the current numbers** on Google's Cloud Run pricing
page, because Google changes them. A project needs a **billing account** (a card) linked, even when you
stay in the free allowance. To be safe we add a **budget alert** (Step 2) and **max 1 instance**.

## Before you start

- A Google Cloud **project with billing linked** (Console → Billing). A Google account alone is not
  enough.
- The Supabase SQL files in `backend/sql/` were all run (editor set to **Database**).
- Your secrets, to copy one by one: Gemini key, Gemini model name, Supabase URL, Supabase service key.
  The sixth, `AUTH_SECRET`, you make new (Step 3).

## Step 1: Install and sign in to `gcloud` (once)

In PowerShell:
```
winget install --id Google.CloudSDK
```
Close and reopen the terminal, then:
```
gcloud auth login
```
(a browser opens: sign in with the Google account that owns the project). Then pick the project:
```
gcloud config set project YOUR_PROJECT_ID
```
(`YOUR_PROJECT_ID` is shown at the top of the Google Cloud Console, for example `cogniguide-123456`.)

Turn on the services Cloud Run needs (it may ask to confirm; answer `y`):
```
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com
```

## Step 2: Add a budget alert (do not skip)

Console → **Billing** → **Budgets & alerts** → **Create budget** → amount **$1** (or the smallest the
form allows) → keep the alert thresholds → add your email. Google will email you if spending ever starts.

## Step 3: Put the secrets in Secret Manager

Console → **Security → Secret Manager** → **Create secret**. One secret for each name below (the name
must be exactly this; paste the value into **Secret value**; leave the rest as it is):

| Secret name | Value |
|---|---|
| `GEMINI_API_KEY` | your Gemini key |
| `GEMINI_MODEL` | the same model name as in your `.env` |
| `SUPABASE_URL` | your Supabase project URL |
| `SUPABASE_SERVICE_KEY` | your Supabase service key |
| `AUTH_SECRET` | a NEW long random text (below) |

To make a new `AUTH_SECRET`, run this in PowerShell and copy the output:
```
python -c "import secrets; print(secrets.token_urlsafe(48))"
```
(Students log in again once after the change. Their progress stays in Supabase.)

Then let Cloud Run read them. In PowerShell (use your own project number: Console → project
dashboard → **Project number**):
```
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
```

## Step 4: Make the upload folder

In the main project folder:
```
.\venv\Scripts\python backend\scripts\make_hf_space.py cloudrun
```
It makes **`cloudrun-upload`** (20 files: `Dockerfile`, `requirements.txt`, the `backend` code). No `.env`,
no keys, no tests. (Git ignores the folder; make it again any time.)

## Step 5: Deploy

One line, in the main project folder:
```
gcloud run deploy cogniguide-backend --source cloudrun-upload --region asia-south1 --allow-unauthenticated --max-instances 1 --concurrency 4 --memory 512Mi --timeout 300 --set-secrets "GEMINI_API_KEY=GEMINI_API_KEY:latest,GEMINI_MODEL=GEMINI_MODEL:latest,SUPABASE_URL=SUPABASE_URL:latest,SUPABASE_SERVICE_KEY=SUPABASE_SERVICE_KEY:latest,AUTH_SECRET=AUTH_SECRET:latest"
```

What it means:

| Part | Why |
|---|---|
| `--region asia-south1` | Mumbai, the closest Cloud Run region to Sri Lanka (`asia-southeast1` = Singapore also works) |
| `--allow-unauthenticated` | Phones must be able to reach it. (The server itself still needs a login for the coach.) |
| `--max-instances 1` | At most one copy runs, so costs cannot grow. Our login lockout and 20-messages-a-minute limit live in memory, so one copy is also what they need |
| `--concurrency 4`, `--timeout 300` | Matches the server's 4 threads; a reply may take long when Gemini is busy |
| `--set-secrets` | Gives the server the five secrets from Secret Manager (never written into the code) |

The first time, `gcloud` may ask: *"Allow unauthenticated invocations?"* → `y`, and *"Create an Artifact
Registry repository?"* → `y`. The build takes a few minutes. At the end it prints:
```
Service URL: https://cogniguide-backend-xxxxxxxx-el.a.run.app
```
**Copy that address.** It is permanent.

## Step 6: Check it

Open in your browser:
- `https://<address>/health` → `{"status": "ok"}`
- `https://<address>/problems` → the problem list (no answers)

## Step 7: Build the app for it (once)

In PowerShell, in the `frontend` folder (one line, with your address):
```
flutter build apk --release --dart-define=API_BASE_URL=https://cogniguide-backend-xxxxxxxx-el.a.run.app
```
The APK is `frontend\build\app\outputs\flutter-apk\app-release.apk`. Send it to the team: **this one
works any time**, with no laptop and no tunnel, until the address changes (it does not).

## Good to know

- **Sleeping:** when nobody uses it, Cloud Run scales to zero; the first message after a break takes a
  few seconds longer. The app waits long enough.
- **Update the backend later:** change the code, `git pull`, run Step 4 and Step 5 again. The address stays.
- **Logs:** Console → Cloud Run → `cogniguide-backend` → **Logs**. `503 UNAVAILABLE ... high demand` lines
  are Google's free Gemini being busy (normal; the coach uses short safe replies).
- **Change a secret:** Secret Manager → the secret → **New version**, then deploy again (Step 5) or
  Cloud Run → **Edit & deploy new revision**.
- **Stop everything:** `gcloud run services delete cogniguide-backend --region asia-south1`.
- **Privacy for the consent forms:** chat messages are processed by Google's Gemini and stored in Supabase;
  the server runs in the region you chose. Say so in the privacy notice.

## If something goes wrong

| What you see | What to do |
|---|---|
| `gcloud` is not recognized | Close and reopen the terminal (or VS Code) after installing |
| "Billing must be enabled" | Link a billing account to the project (Console → Billing) |
| "Permission denied on secret ..." or "Secret Manager Secret Accessor" | Run the `add-iam-policy-binding` command in Step 3 again with the right project number; wait one minute; deploy again |
| "Setting IAM policy failed" / the service asks for login (403) | An organization policy (for example a university account) may block public access. Ask the Google Cloud administrator to allow `allUsers` access to this service, or use a personal project |
| The build fails | Open the **Build log** link in the output and send the last lines to the team |
| The service starts but `/health` fails | Cloud Run → service → **Logs**. A line about a missing `GEMINI_API_KEY`/`SUPABASE_URL` means a secret name is wrong |
| Logging in says "something went wrong" | Check `SUPABASE_URL`, `SUPABASE_SERVICE_KEY` and `AUTH_SECRET` in Secret Manager, and that all SQL files were run |
| The coach never answers or says busy | Cloud Run Logs: look for `POST /chat` lines. Gemini busy is normal; no lines at all means the APK has the wrong address |
