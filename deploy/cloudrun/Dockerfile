# CogniGuide backend on Google Cloud Run. Guide: docs/deploy_cloudrun.md
#
# Cloud Run builds this and starts the backend. It sets the PORT itself (usually 8080) and
# the server below listens on it. The secrets (GEMINI_API_KEY, SUPABASE_URL, ...) are NOT in
# this file or in the upload: you add them in Cloud Run (Secret Manager), see the guide.

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # Online: only logged-in students can chat, no website may call the API from a browser,
    # at most 20 messages a minute per student. (Change them in Cloud Run under Variables.)
    REQUIRE_LOGIN=true \
    CORS_ORIGINS=none \
    CHAT_LIMIT_PER_MINUTE=20

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend ./backend

# Run as a normal user, not as root.
RUN useradd -m -u 1000 user
USER user
WORKDIR /app/backend

# gunicorn = a real web server. Timeout 120 s: a reply can take long when Gemini is busy.
# ${PORT} is set by Cloud Run; 8080 is only the fallback when you run this on your own computer.
CMD ["sh", "-c", "gunicorn app.api:app --bind 0.0.0.0:${PORT:-8080} --workers 1 --threads 4 --timeout 120"]
