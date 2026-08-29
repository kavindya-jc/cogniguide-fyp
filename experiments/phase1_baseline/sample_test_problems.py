"""
Sample a handful of distinct test-set problems for manual testing
of the baseline Socratic agent.

Not part of the training pipeline - just a helper for picking
held-out problems to manually try the agent on.
"""

import json
import random

TEST_PATH = "data/processed/socrateach_test.jsonl"
NUM_SAMPLES = 5
SEED = 1


def load_problems_grouped(path):
    """Load all test records, grouped by problem_id."""
    problems = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            record = json.loads(line)
            pid = record["metadata"]["problem_id"]
            problems.setdefault(pid, []).append(record)
    return problems


def main():
    problems = load_problems_grouped(TEST_PATH)

    random.seed(SEED)
    sample_ids = random.sample(list(problems.keys()), NUM_SAMPLES)

    print(
        f"Sampled {NUM_SAMPLES} problems from {len(problems)} test problems:\n")

    for pid in sample_ids:
        first_turn = problems[pid][0]  # turn_index 0 has the problem text
        print(f"{pid}:")
        print(f"{first_turn['problem']}\n")


if __name__ == "__main__":
    main()
