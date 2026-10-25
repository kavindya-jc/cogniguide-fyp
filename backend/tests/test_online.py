"""
Tests for the settings used when the backend runs online - agent plan, Phase 5.

Run from the backend/ folder:   python -m pytest tests/test_online.py
"""

import pytest

from app import api, auth, tutor_agent
from app.api import app

PROBLEM = "Find 3/4 of 240."


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("AUTH_SECRET", "test-secret-for-the-online-tests-0123456789abc")
    monkeypatch.setattr(tutor_agent, "socratic_response", lambda *a, **k: "What do you notice?")
    return app.test_client()


def login(code="P001"):
    return {"Authorization": "Bearer " + auth.make_token(code)}


def test_login_required_online(client, monkeypatch):
    monkeypatch.setattr(api, "REQUIRE_LOGIN", True)
    r = client.post("/chat", json={"problem": PROBLEM, "history": []})
    assert r.status_code == 401 and r.get_json()["error"]["code"] == "login_required"
    assert client.post("/chat", json={"problem": PROBLEM, "history": []}, headers=login()).status_code == 200


def test_no_login_needed_on_a_laptop(client):
    assert client.post("/chat", json={"problem": PROBLEM, "history": []}).status_code == 200


def test_speed_limit_per_student(client, monkeypatch):
    monkeypatch.setattr(api, "CHAT_LIMIT_PER_MINUTE", 3)
    codes = [client.post("/chat", json={"problem": PROBLEM, "history": []}, headers=login("P001")).status_code
             for _ in range(4)]
    assert codes == [200, 200, 200, 429]
    # another student is not slowed down by P001
    other = client.post("/chat", json={"problem": PROBLEM, "history": []}, headers=login("P002"))
    assert other.status_code == 200


def test_speed_limit_resets_after_a_minute():
    api._chat_calls.clear()
    old = api.CHAT_LIMIT_PER_MINUTE
    try:
        api.CHAT_LIMIT_PER_MINUTE = 1
        assert api.too_many_chats("P009", now=1000) is False
        assert api.too_many_chats("P009", now=1010) is True
        assert api.too_many_chats("P009", now=1061) is False
    finally:
        api.CHAT_LIMIT_PER_MINUTE = old
        api._chat_calls.clear()


def test_render_blueprint_has_no_secrets():
    """The hosting file may name the secrets but never hold their values."""
    from pathlib import Path

    text = (Path(__file__).resolve().parents[2] / "render.yaml").read_text(encoding="utf-8")
    for secret in ("GEMINI_API_KEY", "SUPABASE_SERVICE_KEY", "AUTH_SECRET", "SUPABASE_URL"):
        block = text.split(f"- key: {secret}")[1].split("- key:")[0]
        assert "sync: false" in block and "value:" not in block, secret
    assert "REQUIRE_LOGIN" in text and 'value: "true"' in text
