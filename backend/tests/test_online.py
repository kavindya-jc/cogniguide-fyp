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


# ---- Hugging Face Spaces upload folder (scripts/make_hf_space.py) ----

def _hf_script():
    import importlib.util
    from pathlib import Path

    path = Path(__file__).resolve().parents[1] / "scripts" / "make_hf_space.py"
    spec = importlib.util.spec_from_file_location("make_hf_space", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_hf_folder_has_what_the_server_needs(tmp_path):
    files = _hf_script().make(tmp_path / "space")
    for needed in ("Dockerfile", "README.md", "requirements.txt", "backend/app/api.py",
                   "backend/app/tutor_agent.py", "backend/data/problems.json"):
        assert needed in files
    assert not any("tests/" in f or f.endswith(".sql") or "__pycache__" in f for f in files)


def test_hf_folder_never_copies_a_secret_file(tmp_path):
    hf = _hf_script()
    source = tmp_path / "source"
    (source / "inner").mkdir(parents=True)
    for name in (".env", ".env.local", "inner/.env", "keep.py"):
        (source / name).write_text("X=1", encoding="utf-8")
    hf._copy_tree(source, tmp_path / "out")
    copied = sorted(p.name for p in (tmp_path / "out").rglob("*") if p.is_file())
    assert copied == ["keep.py"]


def test_hf_folder_is_only_rebuilt_if_the_script_made_it(tmp_path):
    hf = _hf_script()
    other = tmp_path / "someone_elses_folder"
    other.mkdir()
    (other / "important.txt").write_text("keep me", encoding="utf-8")
    with pytest.raises(SystemExit):
        hf.make(other)
    assert (other / "important.txt").exists()


def test_space_card_and_dockerfile_agree_on_the_port():
    from pathlib import Path

    root = Path(__file__).resolve().parents[2] / "deploy" / "huggingface"
    card = (root / "README.md").read_text(encoding="utf-8")
    docker = (root / "Dockerfile").read_text(encoding="utf-8")
    assert "sdk: docker" in card and "app_port: 7860" in card
    assert "PORT=7860" in docker and "REQUIRE_LOGIN=true" in docker
    for secret in ("GEMINI_API_KEY=", "SUPABASE_SERVICE_KEY=", "AUTH_SECRET="):
        assert secret not in docker
