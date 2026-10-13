"""
Interactive manual test for the baseline Socratic agent (Phase 1, Stage 4).

Lets you play the "student" role in a live conversation with the agent,
for a chosen test problem. Not part of the training pipeline - a manual
sanity-check tool before formal evaluation (Stage 5).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from backend.app.models.socratic_agent import socratic_response


def run_manual_test(problem: str):
    print(f"\n{'='*60}")
    print(f"PROBLEM: {problem}")
    print(f"{'='*60}\n")

    history = []

    while True:
        reply = socratic_response(problem, history)
        print(f"Teacher: {reply}\n")

        history.append({"role": "teacher", "content": reply})

        student_input = input("Student (you) [type 'quit' to end this problem]: ").strip()
        if student_input.lower() == "quit":
            break

        history.append({"role": "student", "content": student_input})
        print()


if __name__ == "__main__":
    test_problems = [
        "Joshua packs 12 bottles in each crate. He has a total of 130 bottles and 10 crates. How many bottles will not be placed in a crate?",
        "If Pam is currently twice as young as Rena is, and in 10 years Rena will be 5 years older than her, how old is Pam now?",
        "There are 97 erasers in a box. Ernest has 17 erasers in a bag. Mark takes 97 erasers out of the box. How many erasers are left in the box?",
    ]

    for problem in test_problems:
        run_manual_test(problem)
