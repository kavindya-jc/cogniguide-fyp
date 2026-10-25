"""
Baseline Socratic Tutoring Agent — CogniGuide

Uses Gemini API to generate Socratic-style teaching responses:
- Enforces no direct answers in early turns.
- Generates guiding questions and progressive hints.
- Prompts student reflection and metacognition.

Stage 4 changes (Phase 2):
- socratic_response() can take an extra instruction (the hint level from adaptive.py).
- It waits and tries again when Gemini says 503 "high demand".
- With raise_on_error=True it raises TutorUnavailable instead of returning
  a fallback sentence, so the API can tell a failed reply from a real one.
  The default (False) keeps the old Phase 1 behaviour, so the notebook and
  manual test script still work as before.

Agent plan, Phase 1 (Step 1.5):
- ONE Gemini client for the whole server, made the first time it is needed (not on every call).
- generate_json() asks Gemini for a STRUCTURED answer (JSON that follows a schema). Phase 2 uses it
  to assess the student's reasoning. It never guesses: a reply that is not valid JSON raises
  InvalidModelOutput, so the caller can fall back to the simple word rules.
- Rule 1 is now "never give the final answer before the student has solved it". The old rule said
  "especially in the first 2-3 turns", which sounded as if giving it later was fine.
"""

import json
import os
import time
from typing import List, Dict
from dotenv import load_dotenv, find_dotenv
from google import genai
from google.genai import types

# Automatically locate and load .env from project root regardless of current working directory
load_dotenv(find_dotenv(), override=True)

# Retrieve and sanitize key string (removes hidden newlines, spaces, and quotes)
_raw_key = os.getenv("GEMINI_API_KEY", "")
API_KEY = _raw_key.strip().strip('"').strip("'")

# The model name lives ONLY in .env (GEMINI_MODEL). To switch models, edit .env — not this file.
_raw_model = os.getenv("GEMINI_MODEL", "")
MODEL_NAME = _raw_model.strip().strip('"').strip("'")

# Optional backup model, tried once when the main model is still busy after its retries.
# Leave it out of .env to switch this off. Set it in .env only (like GEMINI_MODEL), never here.
_raw_fallback = os.getenv("GEMINI_FALLBACK_MODEL", "")
FALLBACK_MODEL_NAME = _raw_fallback.strip().strip('"').strip("'")

# Seconds to wait before each retry when Google is busy (so up to 3 tries in total).
RETRY_WAITS = (2, 5)

SYSTEM_PROMPT = """You are a Socratic math tutor for teenage students.

Your teaching style follows these strict rules:
1. NEVER give the final answer. The student must reach it themselves, however many turns it takes. Guide them with questions and hints instead. If they keep asking for the answer, kindly explain why you won't, and help with the next small step.
2. Always respond with a guiding QUESTION, not a statement of fact, unless the student is asking about a basic concept they genuinely don't understand (then a short explanation is okay, followed by a question).
3. If the student is stuck or wrong, gently point out that something is off WITHOUT stating the correct answer, and ask a question that helps them find their own mistake.
4. Give gradually more specific hints if the student struggles across multiple turns on the same step, but still stop short of the answer.
5. Encourage reflection - ask the student what they think, why they think it, or what they'd try next.
6. Speak naturally, like a real, warm human teacher - not stiffly or robotically. Keep responses concise (1-3 sentences).
7. If the student has clearly solved the full problem correctly, confirm their success and summarize what they did well.
"""

FALLBACK_EMPTY = "Let's take a look at this together. What is the very first piece of information given in the problem?"
FALLBACK_ERROR = "I had trouble processing that turn. Could you try restating what step you want to try next?"


class TutorUnavailable(Exception):
    """Gemini could not give a real reply (busy, quota used up, empty answer...)."""


class InvalidModelOutput(TutorUnavailable):
    """Step 1.5: Gemini answered, but not with valid JSON of the right shape (see generate_json)."""


_client = None  # the one Gemini client, made by _get_client()


def _check_settings():
    """Stop with a clear message if the key or the model name is missing from .env."""
    if not API_KEY:
        raise EnvironmentError(
            "GEMINI_API_KEY environment variable not found. "
            "Please add GEMINI_API_KEY to your .env file."
        )
    if not MODEL_NAME:
        raise EnvironmentError(
            "GEMINI_MODEL environment variable not found. "
            "Please add GEMINI_MODEL (the Gemini model name) to your .env file."
        )


def _get_client():
    """Make the Gemini client once, the first time it is needed, and reuse it after that."""
    global _client
    if _client is None:
        _client = genai.Client(api_key=API_KEY)
    return _client


def _generate(contents, config, retry_waits=None):
    """Call Gemini, waiting and trying again when it is busy (503). Returns the reply text.

    retry_waits: seconds to wait before each retry (default RETRY_WAITS). When the main model is
    still busy after that, the backup model GEMINI_FALLBACK_MODEL (if set in .env) is tried once.
    Raises TutorUnavailable when no real text came back (still busy, quota, empty reply...).
    """
    waits = RETRY_WAITS if retry_waits is None else retry_waits
    plan = [(MODEL_NAME, attempt) for attempt in range(len(waits) + 1)]
    if FALLBACK_MODEL_NAME and FALLBACK_MODEL_NAME != MODEL_NAME:
        plan.append((FALLBACK_MODEL_NAME, None))

    for step, (model, attempt) in enumerate(plan):
        try:
            response = _get_client().models.generate_content(model=model, contents=contents, config=config)
        except Exception as err:
            print(f"[socratic_agent] API call error ({model}, try {step + 1}): {err}")
            if not _is_busy(err) or step == len(plan) - 1:
                raise TutorUnavailable(str(err)) from err
            if attempt is not None and attempt < len(waits):
                time.sleep(waits[attempt])
            continue
        if response.text and response.text.strip():
            return response.text.strip()
        raise TutorUnavailable("Gemini returned an empty reply.")


def _is_busy(err: Exception) -> bool:
    text = str(err).upper()
    return "503" in text or "UNAVAILABLE" in text or "OVERLOADED" in text


def _format_history(conversation_history: List[Dict[str, str]]) -> str:
    """Format conversation turns into a readable transcript string."""
    if not conversation_history:
        return "(This is the start of the conversation.)"

    lines = []
    for turn in conversation_history:
        speaker = "Teacher" if turn.get("role") == "teacher" else "Student"
        lines.append(f"{speaker}: {turn.get('content', '').strip()}")
    return "\n".join(lines)


def socratic_response(
    problem: str,
    conversation_history: List[Dict[str, str]],
    extra_instruction: str = "",
    raise_on_error: bool = False,
) -> str:
    """Generate the next Socratic tutor response.

    extra_instruction: optional text added to the system prompt (Stage 4 hint level).
    raise_on_error: if True, raise TutorUnavailable when no real reply could be made.
                    If False (default), return a fallback sentence instead.
    """
    _check_settings()

    formatted_history = _format_history(conversation_history)

    prompt = f"""Problem context:
{problem}

Conversation so far:
{formatted_history}

Now provide your next Socratic response according to your teaching rules:"""

    system_instruction = SYSTEM_PROMPT
    if extra_instruction:
        system_instruction += "\nFor THIS reply only:\n" + extra_instruction + "\n"

    config = types.GenerateContentConfig(system_instruction=system_instruction, temperature=0.3)
    try:
        return _generate(prompt, config)
    except TutorUnavailable as err:
        if raise_on_error:
            raise
        # Phase 1 behaviour: a short fallback sentence instead of an error.
        return FALLBACK_EMPTY if "empty reply" in str(err) else FALLBACK_ERROR


def generate_json(prompt, schema, system_instruction="", temperature=0.1, retry_waits=None):
    """Step 1.5: ask Gemini for a STRUCTURED answer and return it as a Python dict.

    prompt: the question for Gemini.
    schema: a JSON Schema (a dict) that the answer must follow, for example
            {"type": "object", "properties": {"correct": {"type": "boolean"}}, "required": ["correct"]}
    A low temperature, so the same question gives (nearly) the same answer.
    retry_waits: like _generate; a caller with its own backup plan can wait less (for example (1,)).

    Raises TutorUnavailable when Gemini cannot answer (busy, quota...), and InvalidModelOutput
    when it answers with something that is not a JSON object with every "required" field.
    The caller must still check the VALUES (Phase 2): never trust them blindly.
    """
    _check_settings()
    config = types.GenerateContentConfig(
        system_instruction=system_instruction or None,
        temperature=temperature,
        response_mime_type="application/json",
        response_json_schema=schema,
    )
    text = _generate(prompt, config, retry_waits)
    try:
        data = json.loads(text)
    except ValueError as err:
        raise InvalidModelOutput(f"Gemini did not return valid JSON: {err}") from err
    if not isinstance(data, dict):
        raise InvalidModelOutput("Gemini returned JSON, but not an object.")
    missing = [name for name in schema.get("required", []) if name not in data]
    if missing:
        raise InvalidModelOutput(f"Gemini's JSON is missing: {', '.join(missing)}")
    return data

if __name__ == "__main__":
    test_problem = (
        "Natalia sold clips to 48 of her friends in April, and then she "
        "sold half as many clips in May. How many clips did Natalia sell "
        "altogether in April and May?"
    )

    print("=== CogniGuide Socratic Agent Demonstration ===")
    print(f"Model: {MODEL_NAME}")
    print(f"Problem: {test_problem}\n")

    history: List[Dict[str, str]] = []

    # Turn 1: Initial prompt from teacher
    reply_1 = socratic_response(test_problem, history)
    print(f"Teacher: {reply_1}\n")
    history.append({"role": "teacher", "content": reply_1})

    # Turn 2: Student is confused
    student_msg_1 = "I don't know how to start."
    print(f"Student: {student_msg_1}")
    history.append({"role": "student", "content": student_msg_1})

    reply_2 = socratic_response(test_problem, history)
    print(f"Teacher: {reply_2}\n")
    history.append({"role": "teacher", "content": reply_2})

    # Turn 3: Student figures out the intermediate step
    student_msg_2 = "Oh, half of 48 is 24, so she sold 24 clips in May!"
    print(f"Student: {student_msg_2}")
    history.append({"role": "student", "content": student_msg_2})

    reply_3 = socratic_response(test_problem, history)
    print(f"Teacher: {reply_3}\n")
    history.append({"role": "teacher", "content": reply_3})

    # Turn 4: Student calculates the total
    student_msg_3 = "48 plus 24 is 72 clips altogether!"
    print(f"Student: {student_msg_3}")
    history.append({"role": "student", "content": student_msg_3})

    reply_4 = socratic_response(test_problem, history)
    print(f"Teacher: {reply_4}")
