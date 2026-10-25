"""
Tests for the Gemini helper (models/socratic_agent.py) - agent plan, Phase 1 (Step 1.5).

Offline: Gemini is replaced by a fake client, so no internet and no API key are needed.
Run from the backend/ folder:   python -m pytest tests/test_socratic_agent.py
"""

import pytest

from app.models import socratic_agent as sa

SCHEMA = {
    "type": "object",
    "properties": {"correct": {"type": "boolean"}, "note": {"type": "string"}},
    "required": ["correct"],
}


class FakeResponse:
    def __init__(self, text):
        self.text = text


class FakeModels:
    """Gives the answers in `script` one by one. An Exception in the script is raised instead."""

    def __init__(self, script):
        self.script = list(script)
        self.calls = []

    def generate_content(self, model, contents, config):
        self.calls.append({"model": model, "contents": contents, "config": config})
        item = self.script.pop(0)
        if isinstance(item, Exception):
            raise item
        return FakeResponse(item)


class FakeClient:
    def __init__(self, script):
        self.models = FakeModels(script)


@pytest.fixture
def gemini(monkeypatch):
    """Install a fake Gemini. Call it with the list of answers it should give."""
    monkeypatch.setattr(sa, "API_KEY", "fake-key")
    monkeypatch.setattr(sa, "MODEL_NAME", "fake-model")
    monkeypatch.setattr(sa, "RETRY_WAITS", (0, 0))  # no real waiting in tests

    def install(*script):
        client = FakeClient(script)
        monkeypatch.setattr(sa, "_client", client)
        return client.models

    return install


# ---- One shared client ----

def test_the_client_is_made_only_once(monkeypatch):
    made = []
    monkeypatch.setattr(sa, "_client", None)
    monkeypatch.setattr(sa, "API_KEY", "fake-key")
    monkeypatch.setattr(sa.genai, "Client", lambda api_key: made.append(api_key) or object())
    first, second = sa._get_client(), sa._get_client()
    assert first is second and made == ["fake-key"]


def test_missing_key_gives_a_clear_error(monkeypatch):
    monkeypatch.setattr(sa, "API_KEY", "")
    with pytest.raises(EnvironmentError, match="GEMINI_API_KEY"):
        sa.socratic_response("1 + 1", [])
    with pytest.raises(EnvironmentError, match="GEMINI_API_KEY"):
        sa.generate_json("Is it right?", SCHEMA)


# ---- socratic_response: the same behaviour as before ----

def test_reply_text_comes_back(gemini):
    models = gemini("  What do you notice?  ")
    assert sa.socratic_response("1 + 1", [], extra_instruction="HINT LEVEL 1") == "What do you notice?"
    config = models.calls[0]["config"]
    assert "HINT LEVEL 1" in config.system_instruction and config.temperature == 0.3
    assert models.calls[0]["model"] == "fake-model"


def test_busy_gemini_is_tried_again(gemini):
    models = gemini(RuntimeError("503 UNAVAILABLE"), RuntimeError("503 overloaded"), "Third time lucky?")
    assert sa.socratic_response("1 + 1", [], raise_on_error=True) == "Third time lucky?"
    assert len(models.calls) == 3


def test_still_busy_after_three_tries(gemini):
    gemini(*[RuntimeError("503 UNAVAILABLE")] * 3)
    with pytest.raises(sa.TutorUnavailable):
        sa.socratic_response("1 + 1", [], raise_on_error=True)


def test_other_errors_are_not_retried(gemini):
    models = gemini(RuntimeError("429 quota used up"), "never reached")
    with pytest.raises(sa.TutorUnavailable):
        sa.socratic_response("1 + 1", [], raise_on_error=True)
    assert len(models.calls) == 1


def test_phase1_fallback_sentences_are_kept(gemini):
    gemini("")
    assert sa.socratic_response("1 + 1", []) == sa.FALLBACK_EMPTY
    gemini(RuntimeError("400 bad request"))
    assert sa.socratic_response("1 + 1", []) == sa.FALLBACK_ERROR
    gemini("")
    with pytest.raises(sa.TutorUnavailable):
        sa.socratic_response("1 + 1", [], raise_on_error=True)


def test_rule_1_never_allows_the_final_answer():
    rule_1 = sa.SYSTEM_PROMPT.split("\n2.")[0]
    assert "NEVER give the final answer" in rule_1
    assert "first 2-3 turns" not in rule_1  # the old wording that sounded like "later is fine"


# ---- generate_json: structured answers ----

def test_json_answer_becomes_a_dict(gemini):
    models = gemini('{"correct": false, "note": "sign error"}')
    assert sa.generate_json("Is x = 2 right?", SCHEMA, system_instruction="Be strict.") == {
        "correct": False, "note": "sign error"}
    config = models.calls[0]["config"]
    assert config.response_mime_type == "application/json"
    assert config.response_json_schema == SCHEMA
    assert config.temperature == 0.1 and config.system_instruction == "Be strict."


@pytest.mark.parametrize("bad", [
    "The answer is correct.",  # not JSON
    "[true]",                  # JSON, but not an object
    '{"note": "no verdict"}',  # a required field is missing
    '{"correct": tru',         # cut off half way
])
def test_bad_json_raises_invalid_model_output(gemini, bad):
    gemini(bad)
    with pytest.raises(sa.InvalidModelOutput):
        sa.generate_json("Is it right?", SCHEMA)


def test_invalid_output_is_also_a_tutor_unavailable():
    """So code that already catches TutorUnavailable is safe with generate_json too."""
    assert issubclass(sa.InvalidModelOutput, sa.TutorUnavailable)


def test_generate_json_retries_when_busy(gemini):
    models = gemini(RuntimeError("503 UNAVAILABLE"), '{"correct": true}')
    assert sa.generate_json("Is it right?", SCHEMA) == {"correct": True}
    assert len(models.calls) == 2
