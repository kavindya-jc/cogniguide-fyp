# CogniGuide backend on Hugging Face Spaces (free, no card). Guide: docs/deploy_huggingface.md
#
# Hugging Face builds this box and starts the backend on port 7860.
# The secrets (GEMINI_API_KEY, SUPABASE_URL, ...) are NOT in this file or in the upload:
# you paste them in the Space under Settings -> Variables and secrets.

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=7860 \
    # Online: only logged-in students can chat, no website may call the API from a browser,
    # at most 20 messages a minute per student. (Change them under "Variables" if needed.)
    REQUIRE_LOGIN=true \
    CORS_ORIGINS=none \
    CHAT_LIMIT_PER_MINUTE=20

# Hugging Face runs Spaces as user 1000.
RUN useradd -m -u 1000 user
WORKDIR /home/user/app

COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=user backend ./backend

USER user
WORKDIR /home/user/app/backend
EXPOSE 7860

# gunicorn = a real web server. Timeout 120 s: a reply can take long when Gemini is busy.
CMD ["sh", "-c", "gunicorn app.api:app --bind 0.0.0.0:${PORT} --workers 1 --threads 4 --timeout 120"]
