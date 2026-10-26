# Deploy the CogniGuide backend on Google Cloud Run

**Status: deployed and tested (27 October 2026).**

| What       | Value                                                          |
| ---------- | -------------------------------------------------------------- |
| Project ID | `cogniguide-fyp`                                               |
| Service    | `cogniguide-backend`                                           |
| Region     | `asia-south1` (Mumbai)                                         |
| URL        | `https://cogniguide-backend-1056396913855.asia-south1.run.app` |

The URL is not secret. Never post a key, commit `.env`, or put a key in the app.

## Before you start

- A Google Cloud project with billing linked.
- All SQL files in `backend/sql/` run in Supabase (editor set to **Database**).
- The 4 secret values from the project owner, sent privately: Gemini key, Gemini model name, Supabase URL, Supabase service key.
- Latest code (`git pull`). Run every command in the VS Code terminal, in the main project folder, one command at a time.

## 1. Sign in to Google Cloud

```
winget install --id Google.CloudSDK
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

## 2. Turn on the services

```
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com
```

## 3. Save the secrets

Console, Secret Manager, Create secret. Make five secrets with these exact names: `GEMINI_API_KEY`, `GEMINI_MODEL`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `AUTH_SECRET`.

Copy the first four from the `.env` file. For `AUTH_SECRET`, generate a new value and paste the output:

```
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## 4. Give permissions

New Google Cloud projects need these, or the build fails with "does not have storage.objects.get access". Use your Project number (Console dashboard) and run each line:

```
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/cloudbuild.builds.builder"
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/storage.objectViewer"
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/artifactregistry.writer"
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/logging.logWriter"
```

Wait one minute.

## 5. Make the upload folder and deploy

```
python backend\scripts\make_hf_space.py cloudrun
```

```
gcloud run deploy cogniguide-backend --source cloudrun-upload --region asia-south1 --allow-unauthenticated --max-instances 1 --concurrency 4 --memory 512Mi --timeout 300 --set-secrets "GEMINI_API_KEY=GEMINI_API_KEY:latest,GEMINI_MODEL=GEMINI_MODEL:latest,SUPABASE_URL=SUPABASE_URL:latest,SUPABASE_SERVICE_KEY=SUPABASE_SERVICE_KEY:latest,AUTH_SECRET=AUTH_SECRET:latest"
```

Answer `y` to any question. It prints the Service URL at the end. `max-instances 1` is required because the login lockout and rate limit are kept in memory.

## 6. Check it

| Open             | You should see             |
| ---------------- | -------------------------- |
| `<URL>/health`   | `{"status": "ok"}`         |
| `<URL>/problems` | 15 problems, no answers    |
| `<URL>/progress` | `login_required` (correct) |

The first request after a quiet period can take up to a minute.

## 7. Build the app

On a computer with Flutter, in the `frontend` folder:

```
flutter build apk --release --dart-define=API_BASE_URL=https://cogniguide-backend-1056396913855.asia-south1.run.app
```

The APK is `frontend\build\app\outputs\flutter-apk\app-release.apk`.

## Update later

`git pull`, then repeat step 5. The URL stays the same, so the APK does not need rebuilding. Rebuild the APK only when the frontend changes.

## Cost

Cloud Run's monthly free allowance should cover this app (check Google's pricing page). `max-instances 1` and a $1 budget alert (Console, Billing, Budgets and alerts) protect against surprises. To remove the service:

```
gcloud run services delete cogniguide-backend --region asia-south1
```

## Problems

| What you see                               | What to do                                                               |
| ------------------------------------------ | ------------------------------------------------------------------------ |
| Permission error during the build          | Run the commands in step 4, wait a minute, deploy again                  |
| 403 or a login prompt on the URL           | An organization policy blocks public access. Use a personal project      |
| `/health` fails                            | Cloud Run, Logs. A missing-key message means a secret name is misspelled |
| Coach says "busy", no `POST /chat` in Logs | The APK has the wrong URL. Rebuild it                                    |
| `503 ... high demand` in Logs              | Gemini is busy. Normal                                                   |
