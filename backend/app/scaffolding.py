"""
CogniGuide scaffolding engine - Phase 2, Stage 5

Stage 4 picks a hint level (1-3) from the student's CURRENT chat.
Stage 5 looks at EARLIER sessions of the same student and slowly takes
help away ("fading") when the student needs less and less of it.

The scaffold level is simply: the HIGHEST hint level the tutor may use.

    scaffold level 3 = full support    (hint levels 1, 2 and 3 are allowed)  <- default
    scaffold level 2 = reduced support (hint levels 1 and 2 are allowed)
    scaffold level 1 = minimal support (only hint level 1 is allowed)

The rules are simple words-and-numbers rules. There is no AI call here.

How the scaffold level is chosen (from the student's earlier sessions only):
  - fewer than 2 earlier sessions with data  -> level 3 (no change, we do not know the student yet)
  - the newest earlier session was hard (average hint level 2.5 or more) -> level 3 (help comes back)
  - average of the last 3 earlier sessions is 1.3 or less -> level 1
  - average is 1.8 or less -> level 2
  - otherwise -> level 3

Safety valve: if the student is clearly struggling RIGHT NOW (2 or more struggling
messages in a row), the tutor may always use at least hint level 2,
even if the scaffold level is 1.

Known limits (first version): the thresholds are our best guesses and have not
been tested with real teenagers (Phase 3). The hint levels they are based on
come from word rules (see adaptive.py), so they cannot tell if an answer is right or wrong.
"""

MAX_SCAFFOLD = 3  # full support (the default)

# Fewest earlier sessions needed before we dare to fade any help.
MIN_SESSIONS = 2
# How many of the newest earlier sessions we average.
MAX_SESSIONS = 3

# If the newest earlier session averaged this or more, help comes back.
BACK_UP_AT = 2.5
# Average hint level at or below these numbers -> fade the help.
MINIMAL_AT = 1.3
REDUCED_AT = 1.8

REDUCED_NOTE = (
    "SCAFFOLD NOTE: In earlier sessions this student needed little help, so keep your hints "
    "smaller than usual. Do NOT name the calculation to do or any numbers to use. "
    "First ask the student what they would try, and only then add a small nudge. "
    "Keep the reply to two short sentences at most. "
    "Example of the right size: 'What do you think the next step is?'"
)

MINIMAL_NOTE = (
    "SCAFFOLD NOTE: This student has been working mostly on their own in earlier sessions. "
    "Ask them to explain their own plan or reasoning first. Give only the smallest possible nudge: "
    "do NOT name the calculation to do or any numbers to use, and do not repeat facts from the problem. "
    "Encourage them to check their own work. Keep the reply to two short sentences at most. "
    "Example of the right size: 'What is your plan? Walk me through it.'"
)


def compute_scaffold_level(session_averages):
    """Choose the scaffold level (1-3) from earlier sessions.

    session_averages: the average hint level of each EARLIER session, newest first.
    Example: [1.2, 1.0, 2.8]
    """
    if len(session_averages) < MIN_SESSIONS:
        return MAX_SCAFFOLD

    recent = session_averages[:MAX_SESSIONS]

    # The student struggled again in their newest session: bring the help back.
    if recent[0] >= BACK_UP_AT:
        return MAX_SCAFFOLD

    average = sum(recent) / len(recent)
    if average <= MINIMAL_AT:
        return 1
    if average <= REDUCED_AT:
        return 2
    return MAX_SCAFFOLD


def apply_scaffold(analysis, scaffold_level):
    """Limit the Stage 4 hint level using the scaffold level.

    Returns a NEW analysis dict:
      "hint_level"   = the level the tutor will really use now
      "needed_level" = the level Stage 4 said the student needs (this is what we save as the
                       'hint_level' indicator, so the data shows real need, not our limit)
    """
    needed = analysis.get("needed_level", analysis["hint_level"])
    used = min(needed, scaffold_level)

    # Safety valve: a student who is clearly stuck right now always gets at least level 2.
    if analysis["struggle_count"] >= 2:
        used = max(used, 2)

    result = dict(analysis)
    result["needed_level"] = needed
    result["hint_level"] = used
    return result


def build_scaffold_instruction(scaffold_level, analysis):
    """Extra text for the tutor when the help has been faded. Empty text when nothing changes."""
    # If the student is clearly stuck right now, do not ask for "smaller hints".
    if analysis["struggle_count"] >= 2:
        return ""
    if scaffold_level == 2:
        return REDUCED_NOTE
    if scaffold_level == 1:
        return MINIMAL_NOTE
    return ""
