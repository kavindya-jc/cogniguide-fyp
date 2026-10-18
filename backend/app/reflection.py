"""
CogniGuide personalised reflection prompts - Phase 2, Stage 6

Stages 4 and 5 change HOW MUCH help the tutor gives. Stage 6 lets the tutor ask the
student to think about their OWN way of working, using the student's earlier sessions.

    Example: "You asked for the answer a few times before. What did you try on your own this time?"

Simple rules only. There is no AI call here, and no old message text is ever read or copied.
The rules use NUMBERS that Stage 4 already saved in the indicators table
(hint_level, stuck, asked_for_answer, self_correction).

How it works:
  1. WHEN: at most once per session, only when the student has sent at least 3 messages,
     the newest message is a new one, and it is NOT a struggling one.
  2. WHICH: from the student's last 3 earlier sessions (at least 2 are needed):
       asked for the answer 2 or more times -> "asks_for_answer"
       felt stuck 3 or more times            -> "often_stuck"
       average hint level went down by 0.5+  -> "improving"
       fixed their own mistakes 2+ times     -> "self_checker"
     The first rule that fits wins. Nothing fits -> no reflection.
  3. The chosen type becomes a short extra instruction for the tutor, for ONE reply.

Known limits (first version): the numbers above are our best guesses and have not been
tested with real teenagers (Phase 3). The signs come from word rules (see adaptive.py).
"""

# The student must have sent at least this many messages in this session first.
MIN_STUDENT_MESSAGES = 3
# We need this many earlier sessions before we say anything about the student's past.
MIN_SESSIONS = 2

ASKS_FOR_ANSWER_AT = 2   # asked for the answer this many times (or more) in earlier sessions
OFTEN_STUCK_AT = 3       # said they were stuck this many times (or more)
SELF_CHECKER_AT = 2      # fixed their own mistake this many times (or more)
IMPROVING_DROP = 0.5     # the newest session's average hint level is this much lower than the oldest

ASKS_FOR_ANSWER = "asks_for_answer"
OFTEN_STUCK = "often_stuck"
IMPROVING = "improving"
SELF_CHECKER = "self_checker"

REFLECTION_TYPES = (ASKS_FOR_ANSWER, OFTEN_STUCK, IMPROVING, SELF_CHECKER)

INDICATOR_PREFIX = "reflection_"  # saved in the indicators table, e.g. "reflection_often_stuck"

_TOPICS = {
    ASKS_FOR_ANSWER: (
        "In earlier sessions this student often asked to be told the answer. Ask ONE short, kind question "
        "about that habit, for example what they tried on their own before asking, or what would help them "
        "try one more step alone. Do not scold."
    ),
    OFTEN_STUCK: (
        "In earlier sessions this student often felt stuck. Ask ONE short question about how they get "
        "going, for example how they decided where to start this time, or what helped them move forward."
    ),
    IMPROVING: (
        "In earlier sessions this student needed more help than they do now. Ask ONE short question, for "
        "example what is different for them now compared with before, or what they do now that helps."
    ),
    SELF_CHECKER: (
        "In earlier sessions this student often noticed and fixed their own mistakes. Say in a few words "
        "that this is a strong habit, then ask ONE short question about how they check their own work."
    ),
}

_WRAPPER = (
    "REFLECTION NOTE: {topic} Keep your normal guiding question too, but keep the whole reply short. "
    "Speak naturally (for example 'before' or 'last time'). Never mention data, records, scores or numbers, "
    "never quote the student's old messages, and do not give the answer."
)


def count_student_messages(history):
    """How many student messages the chat has so far."""
    return sum(1 for turn in history if turn.get("role") == "student")


def is_good_moment(analysis, student_message_count):
    """True if this is a fine moment to ask a reflection question (before looking at the past).

    analysis: the dict from adaptive.analyze_history.
    """
    if not analysis.get("new_student_message"):
        return False
    if student_message_count < MIN_STUDENT_MESSAGES:
        return False
    latest = analysis["latest"]
    if latest["asked_for_answer"] or latest["stuck"]:
        return False  # the student needs help right now, not a reflection question
    return True


def choose_reflection_type(summary):
    """Pick ONE reflection type from the student's earlier sessions, or None.

    summary: the dict from db.get_history_summary.
    """
    if summary is None or summary.get("sessions", 0) < MIN_SESSIONS:
        return None
    if summary["asked_for_answer"] >= ASKS_FOR_ANSWER_AT:
        return ASKS_FOR_ANSWER
    if summary["stuck"] >= OFTEN_STUCK_AT:
        return OFTEN_STUCK
    averages = summary.get("averages", [])  # newest session first
    if len(averages) >= MIN_SESSIONS and averages[-1] - averages[0] >= IMPROVING_DROP:
        return IMPROVING
    if summary["self_correction"] >= SELF_CHECKER_AT:
        return SELF_CHECKER
    return None


def build_reflection_instruction(reflection_type):
    """Extra text for the tutor for this one reply. Empty text for an unknown type."""
    topic = _TOPICS.get(reflection_type)
    return _WRAPPER.format(topic=topic) if topic else ""


def indicator_name(reflection_type):
    """The indicator type saved when a reflection question is asked."""
    return INDICATOR_PREFIX + reflection_type
