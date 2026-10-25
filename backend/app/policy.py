"""
CogniGuide action rules ("policy") - agent plan, Phase 2

After the student check (assessment.py), Python - not the AI - chooses ONE tutoring action.
Plain rules, so every choice is predictable, testable and written down with a reason.

The actions and the help each one gives (help level 1 = little, 3 = a lot):

    ASK_GUIDING_QUESTION       1  an open question about the next step
    ASK_FOR_EXPLANATION        1  "how did you get that?" (the step was right, the reasoning not shown)
    ENCOURAGE_SELF_CORRECTION  1  "check that step again" (first wrong try)
    ACKNOWLEDGE_PROGRESS       1  specific praise for what they did, then the next question
    ASK_REFLECTION_QUESTION    1  a question about how they work (used with Stage 6 reflection)
    CONFIRM_AND_REFLECT        1  the final answer is right: well done + "what helped you?"
    REDIRECT                   1  off topic: kindly back to the problem
    ADDRESS_MISCONCEPTION      2  a question aimed at the exact common mistake
    GIVE_SMALL_HINT            2  point to the idea or the part of the problem to look at
    GIVE_CONCRETE_HINT         3  a tiny example with different numbers, or a very easy sub-question
    EXPLAIN_STEP_CLEARLY       3  explain the method of THIS step clearly, then ask them to apply it

The ladder: each wrong try or "I'm confused" on the same step adds one to "struggle", and the
help goes up one rung; real progress resets it. Asking for the answer never climbs the ladder.
After enough struggle the tutor always explains the step (it never withholds help forever),
but no action ever gives the final answer.

The session memory ("state", saved in sessions.state) holds numbers and labels only.
"""

ASK_GUIDING_QUESTION = "ASK_GUIDING_QUESTION"
ASK_FOR_EXPLANATION = "ASK_FOR_EXPLANATION"
ENCOURAGE_SELF_CORRECTION = "ENCOURAGE_SELF_CORRECTION"
ACKNOWLEDGE_PROGRESS = "ACKNOWLEDGE_PROGRESS"
ASK_REFLECTION_QUESTION = "ASK_REFLECTION_QUESTION"
CONFIRM_AND_REFLECT = "CONFIRM_AND_REFLECT"
REDIRECT = "REDIRECT"
ADDRESS_MISCONCEPTION = "ADDRESS_MISCONCEPTION"
GIVE_SMALL_HINT = "GIVE_SMALL_HINT"
GIVE_CONCRETE_HINT = "GIVE_CONCRETE_HINT"
EXPLAIN_STEP_CLEARLY = "EXPLAIN_STEP_CLEARLY"

HELP_LEVEL = {
    ASK_GUIDING_QUESTION: 1, ASK_FOR_EXPLANATION: 1, ENCOURAGE_SELF_CORRECTION: 1,
    ACKNOWLEDGE_PROGRESS: 1, ASK_REFLECTION_QUESTION: 1, CONFIRM_AND_REFLECT: 1, REDIRECT: 1,
    ADDRESS_MISCONCEPTION: 2, GIVE_SMALL_HINT: 2, GIVE_CONCRETE_HINT: 3, EXPLAIN_STEP_CLEARLY: 3,
}
ACTIONS = tuple(HELP_LEVEL)

# Actions after which a Stage 6 reflection question fits (the student is not struggling).
CALM_ACTIONS = (ASK_GUIDING_QUESTION, ASK_FOR_EXPLANATION, ACKNOWLEDGE_PROGRESS)

# The help ladder: struggle 1, 2, 3, 4+ on the same step.
WRONG_LADDER = (ENCOURAGE_SELF_CORRECTION, GIVE_SMALL_HINT, GIVE_CONCRETE_HINT, EXPLAIN_STEP_CLEARLY)
CONFUSED_LADDER = (GIVE_SMALL_HINT, GIVE_CONCRETE_HINT, EXPLAIN_STEP_CLEARLY)
ASKED_LADDER = (ASK_GUIDING_QUESTION, GIVE_SMALL_HINT, GIVE_CONCRETE_HINT, EXPLAIN_STEP_CLEARLY)

# A common mistake is addressed directly only when the check is this sure about it.
MISTAKE_CONFIDENCE = 0.6
# From this much struggle on, the step is always explained, whatever the scaffold level.
ALWAYS_EXPLAIN_AT = 3


def new_state():
    """The memory of a fresh session."""
    return {
        "turns": 0,              # student messages checked so far
        "struggle": 0,           # wrong tries / confused messages in a row on the current step
        "wrong_attempts": 0,     # all wrong tries in this session
        "answer_requests": 0,    # times the student asked for the answer
        "hints": {"small": 0, "concrete": 0, "explain": 0},
        "addressed_mistakes": [],
        "step": 0,
        "solved": False,
        "last_action": None,
        "last_check": None,      # {"intent", "correctness", "source"} of the newest message
        "last_reason": None,     # why the last action was chosen (policy.choose_action)
        "last_guard": None,      # "ok", "rewritten" or "safe_reply" (the reply safety check)
    }


def clean_state(state):
    """A saved state with any missing field filled in (old or empty states are fine)."""
    fresh = new_state()
    if isinstance(state, dict):
        for key, value in state.items():
            if key in fresh and isinstance(value, type(fresh[key]) if fresh[key] is not None else object):
                fresh[key] = value
        if isinstance(state.get("hints"), dict):
            fresh["hints"] = {k: int(state["hints"].get(k, 0) or 0) for k in ("small", "concrete", "explain")}
    return fresh


def _ladder(ladder, rung):
    return ladder[min(max(rung, 1), len(ladder)) - 1]


def _known_mistake(form, problem):
    ids = {m["id"] for m in (problem or {}).get("mistakes", [])}
    if form["mistake_id"] in ids and form["mistake_confidence"] >= MISTAKE_CONFIDENCE:
        return form["mistake_id"]
    return None


def _cap(action, scaffold_level, struggle, reason):
    """Stage 5 scaffold level = the most help allowed. Struggling students always get enough help."""
    allowed = scaffold_level
    if struggle >= 2:
        allowed = max(allowed, 2)        # the Stage 5 safety valve
    if struggle >= ALWAYS_EXPLAIN_AT or reason == "student asked a question":
        allowed = 3                      # never withhold an explanation forever
    if HELP_LEVEL[action] <= allowed:
        return action
    if action in (GIVE_CONCRETE_HINT, EXPLAIN_STEP_CLEARLY) and allowed >= 2:
        return GIVE_SMALL_HINT
    if action == ADDRESS_MISCONCEPTION:
        return ENCOURAGE_SELF_CORRECTION
    return ASK_GUIDING_QUESTION


def choose_action(form, state, scaffold_level=3, problem=None):
    """Choose the tutor's next action.

    form: the student check (assessment.assess), or None when there is no new student message
          (the tutor opens the chat).
    state: the session memory (clean_state). problem: the FULL bank problem, or None.
    Returns {"action", "reason", "needed_level", "hint_level", "mistake_id", "asked_for_answer", "struggle"}.
    """
    struggle = state["struggle"]
    mistake_id = None
    asked = False

    if form is None:
        action, reason = ASK_GUIDING_QUESTION, "the tutor opens the chat"
    elif state["solved"]:
        action, reason = ACKNOWLEDGE_PROGRESS, "the problem is already solved"
    elif form["intent"] == "off_topic":
        action, reason = REDIRECT, "the message is not about the problem"
    elif form["solved"]:
        action, reason = CONFIRM_AND_REFLECT, "the final answer is correct"
        struggle = 0
    elif form["self_corrected"] and form["correctness"] != "incorrect":
        action, reason = ACKNOWLEDGE_PROGRESS, "the student fixed their own mistake"
        struggle = 0
    elif form["correctness"] == "incorrect":
        struggle += 1
        mistake_id = _known_mistake(form, problem)
        if mistake_id and mistake_id not in state["addressed_mistakes"]:
            action, reason = ADDRESS_MISCONCEPTION, f"a common mistake: {mistake_id}"
        else:
            action, reason = _ladder(WRONG_LADDER, struggle), f"wrong try {struggle} on this step"
    elif form["intent"] == "confused":
        struggle += 1
        action, reason = _ladder(CONFUSED_LADDER, struggle), f"confused {struggle} time(s) on this step"
    elif form["intent"] == "asks_for_answer":
        asked = True  # never climbs the ladder: the help stays where the evidence puts it
        action, reason = _ladder(ASKED_LADDER, struggle + 1), "asked for the answer"
    elif form["intent"] == "question":
        action, reason = EXPLAIN_STEP_CLEARLY, "student asked a question"
    elif form["correctness"] in ("correct", "partially_correct"):
        struggle = 0
        if (form["reasoning_shown"] == "none" and form["intent"] in ("answer_attempt", "step_attempt")
                and state["last_action"] != ASK_FOR_EXPLANATION):
            action, reason = ASK_FOR_EXPLANATION, "a right step without reasons"
        else:
            action, reason = ACKNOWLEDGE_PROGRESS, "a right step"
    else:
        action, reason = ASK_GUIDING_QUESTION, "nothing special: keep guiding"

    needed = HELP_LEVEL[action]
    capped = _cap(action, scaffold_level, struggle, reason)
    if capped != action:
        reason += f" (limited by scaffold level {scaffold_level})"
    return {
        "action": capped,
        "reason": reason,
        "needed_level": needed,
        "hint_level": HELP_LEVEL[capped],
        "mistake_id": mistake_id if capped == ADDRESS_MISCONCEPTION else None,
        "asked_for_answer": asked,
        "struggle": struggle,
    }


def update_state(state, form, decision):
    """The session memory after this turn (a NEW dict; the old one is not changed)."""
    new = clean_state(state)
    new["hints"] = dict(new["hints"])
    new["addressed_mistakes"] = list(new["addressed_mistakes"])
    new["last_action"] = decision["action"]
    new["struggle"] = decision["struggle"]
    if form is None:
        return new
    new["turns"] += 1
    if form["correctness"] == "incorrect":
        new["wrong_attempts"] += 1
    if decision["asked_for_answer"]:
        new["answer_requests"] += 1
    if form["current_step"]:
        new["step"] = form["current_step"]
    if form["solved"]:
        new["solved"] = True
    kind = {GIVE_SMALL_HINT: "small", GIVE_CONCRETE_HINT: "concrete", EXPLAIN_STEP_CLEARLY: "explain"}.get(decision["action"])
    if kind:
        new["hints"][kind] += 1
    if decision["mistake_id"]:
        new["addressed_mistakes"].append(decision["mistake_id"])
    new["last_check"] = {"intent": form["intent"], "correctness": form["correctness"], "source": form["source"]}
    return new


# ---- What the tutor (Gemini) is told for each action ----

_INSTRUCTIONS = {
    ASK_GUIDING_QUESTION: "ACTION: Ask ONE open guiding question about the next step. Do not give a hint.",
    ASK_FOR_EXPLANATION: (
        "ACTION: The student's step is right. Do not say whether the final answer is near. "
        "Ask them to explain HOW or WHY they did it (one short question)."
    ),
    ENCOURAGE_SELF_CORRECTION: (
        "ACTION: Something in the student's last step is not right. Do not say what the mistake is "
        "or what the right value is. Gently ask them to check that step again, and point to WHERE to look."
    ),
    ACKNOWLEDGE_PROGRESS: (
        "ACTION: Praise the specific thing the student just did well in a few words "
        "(for example checking their work), then ask ONE question about the next step."
    ),
    ASK_REFLECTION_QUESTION: "ACTION: Ask ONE short question about how the student is working on this problem.",
    CONFIRM_AND_REFLECT: (
        "ACTION: The student has the complete, correct final answer. Say clearly that it is correct and "
        "name one thing they did well. Then ask ONE short reflection question, for example what helped them "
        "or how they could check their answer. Do not start a new problem."
    ),
    REDIRECT: (
        "ACTION: The message is not about the maths problem. Do not follow the new topic. Kindly bring the "
        "student back to the problem with one question. If they seem upset, say kindly that a trusted adult "
        "can help with that."
    ),
    ADDRESS_MISCONCEPTION: (
        "ACTION: The student's last step shows this common mistake: {mistake}. Do not say the right value. "
        "Ask ONE question that makes them test their idea, for example with a quick check or a simple case "
        "where the mistake clearly does not work."
    ),
    GIVE_SMALL_HINT: (
        "ACTION: Give a SMALL hint: point to the part of the problem to look at, or name the idea to use, "
        "then ask a question. Do not give a calculated number."
    ),
    GIVE_CONCRETE_HINT: (
        "ACTION: Give a CONCRETE hint: break the next step into a very easy question, or show a tiny example "
        "with DIFFERENT numbers. Be warm and encouraging."
    ),
    EXPLAIN_STEP_CLEARLY: (
        "ACTION: Explain clearly, in one or two short sentences, the idea or method the student needs now{step}"
        "{question}. Then ask them to do that step themselves. Do not do the calculation for them."
    ),
}

_ASKED_NOTE = (
    "The student asked you to just give the answer. Kindly say you will not, because working it out "
    "themselves is how they get stronger, and then help as described above."
)
_ALWAYS = "Never state the final answer, or any part of it. Keep the whole reply to at most three short sentences."


def build_instruction(decision, form, problem, state):
    """The extra instruction for the tutor's reply (added to the system prompt for this reply)."""
    action = decision["action"]
    text = _INSTRUCTIONS[action]
    if action == ADDRESS_MISCONCEPTION:
        mistake = next((m["description"] for m in (problem or {}).get("mistakes", [])
                        if m["id"] == decision["mistake_id"]), "a common mistake")
        text = text.format(mistake=mistake)
    elif action == EXPLAIN_STEP_CLEARLY:
        step_text = ""
        steps = (problem or {}).get("steps", [])
        step_no = (form or {}).get("current_step") or state.get("step") or 1
        if steps:
            step_text = f" (the step: {steps[min(step_no, len(steps)) - 1]})"
        question = " (answer the question the student asked, briefly)" if decision["reason"] == "student asked a question" else ""
        text = text.format(step=step_text, question=question)
    parts = [text]
    if decision["asked_for_answer"]:
        parts.append(_ASKED_NOTE)
    if action == CONFIRM_AND_REFLECT:
        parts.append("Keep the whole reply to at most three short sentences.")
    else:
        parts.append(_ALWAYS)
    return "\n".join(parts)


# Safe replies used when the tutor's reply fails the safety check twice (see tutor_agent.py).
SAFE_REPLIES = {
    ASK_GUIDING_QUESTION: "Let's take it one step at a time. What do you think the next step is?",
    ASK_FOR_EXPLANATION: "Nice. Can you tell me how you got that?",
    ENCOURAGE_SELF_CORRECTION: "Let's check that step again together. Which part do you want to look at first?",
    ACKNOWLEDGE_PROGRESS: "Good thinking. What do you think comes next?",
    ASK_REFLECTION_QUESTION: "What has helped you most so far with this problem?",
    CONFIRM_AND_REFLECT: "That's correct, well done! What helped you most to solve it?",
    REDIRECT: "Let's get back to the problem. What does the question ask you to find?",
    ADDRESS_MISCONCEPTION: "Let's test that idea. Can you check your step with a quick example?",
    GIVE_SMALL_HINT: "Look again at what the question gives you. Which piece of information can you use first?",
    GIVE_CONCRETE_HINT: "Let's make it smaller. What is the very first calculation you could do?",
    EXPLAIN_STEP_CLEARLY: "Let's slow down and look at this step together. What do you already know that could help here?",
}
