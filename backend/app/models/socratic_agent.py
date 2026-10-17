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
"""

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

# Seconds to wait before each retry when Google is busy (so up to 3 tries in total).
RETRY_WAITS = (2, 5)

SYSTEM_PROMPT = """You are a Socratic math tutor for teenage students.

Your teaching style follows these strict rules:
1. NEVER give the final answer directly, especially in the first 2-3 turns of a conversation. Guide the student to find it themselves.
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

    formatted_history = _format_history(conversation_history)

    prompt = f"""Problem context:
{problem}

Conversation so far:
{formatted_history}

Now provide your next Socratic response according to your teaching rules:"""

    system_instruction = SYSTEM_PROMPT
    if extra_instruction:
        system_instruction += "\nFor THIS reply only:\n" + extra_instruction + "\n"

    client = genai.Client(api_key=API_KEY)

    for attempt in range(len(RETRY_WAITS) + 1):
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    temperature=0.3,
                ),
            )
            if response.text and response.text.strip():
                return response.text.strip()

            if raise_on_error:
                raise TutorUnavailable("Gemini returned an empty reply.")
            return FALLBACK_EMPTY

        except TutorUnavailable:
            raise
        except Exception as err:
            print(f"[socratic_agent] API call error (try {attempt + 1}): {err}")
            if _is_busy(err) and attempt < len(RETRY_WAITS):
                time.sleep(RETRY_WAITS[attempt])
                continue
            if raise_on_error:
                raise TutorUnavailable(str(err)) from err
            return FALLBACK_ERROR


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
