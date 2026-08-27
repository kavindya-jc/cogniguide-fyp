"""
Baseline Socratic Tutoring Agent — CogniGuide 

Uses Gemini API to generate Socratic-style teaching responses:
- Enforces no direct answers in early turns.
- Generates guiding questions and progressive hints.
- Prompts student reflection and metacognition.
"""

import os
from typing import List, Dict
from dotenv import load_dotenv, find_dotenv
from google import genai
from google.genai import types

# Automatically locate and load .env from project root regardless of current working directory
load_dotenv(find_dotenv(), override=True)

# Retrieve and sanitize key string (removes hidden newlines, spaces, and quotes)
_raw_key = os.getenv("GEMINI_API_KEY", "")
API_KEY = _raw_key.strip().strip('"').strip("'")

MODEL_NAME = "gemini-3.6-flash"

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


def _format_history(conversation_history: List[Dict[str, str]]) -> str:
    """Format conversation turns into a readable transcript string."""
    if not conversation_history:
        return "(This is the start of the conversation.)"

    lines = []
    for turn in conversation_history:
        speaker = "Teacher" if turn.get("role") == "teacher" else "Student"
        lines.append(f"{speaker}: {turn.get('content', '').strip()}")
    return "\n".join(lines)


def socratic_response(problem: str, conversation_history: List[Dict[str, str]]) -> str:
    """Generate the next Socratic tutor response."""
    if not API_KEY:
        raise EnvironmentError(
            "GEMINI_API_KEY environment variable not found. "
            "Please add GEMINI_API_KEY to your .env file."
        )

    formatted_history = _format_history(conversation_history)

    prompt = f"""Problem context:
{problem}

Conversation so far:
{formatted_history}

Now provide your next Socratic response according to your teaching rules:"""

    try:
        client = genai.Client(api_key=API_KEY)
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_PROMPT,
                temperature=0.3,
            ),
        )

        if response.text and response.text.strip():
            return response.text.strip()

        return "Let's take a look at this together. What is the very first piece of information given in the problem?"

    except Exception as err:
        print(f"[socratic_agent] API call error: {err}")
        return "I had trouble processing that turn. Could you try restating what step you want to try next?"


if __name__ == "__main__":
    print(
        f"[Debug] Loaded API Key Prefix: '{API_KEY[:6]}...' | Length: {len(API_KEY)}")

    test_problem = (
        "Natalia sold clips to 48 of her friends in April, and then she "
        "sold half as many clips in May. How many clips did Natalia sell "
        "altogether in April and May?"
    )

    print("\n=== CogniGuide Socratic Baseline Agent Test ===")
    print(f"Problem: {test_problem}\n")

    history: List[Dict[str, str]] = []

    # First turn
    initial_reply = socratic_response(test_problem, history)
    print(f"Teacher: {initial_reply}\n")

    # Second turn
    history.append({"role": "teacher", "content": initial_reply})
    history.append({"role": "student", "content": "Is the answer 72 clips?"})
    print(f"Student: {history[-1]['content']}")

    second_reply = socratic_response(test_problem, history)
    print(f"Teacher: {second_reply}")
