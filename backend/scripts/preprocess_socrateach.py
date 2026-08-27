# Set up the script skeleton with imports and config
import json
import random
from pathlib import Path

# ---- Config ----
RAW_PATH = Path(__file__).resolve().parent.parent.parent / \
    "data" / "raw" / "socrateach" / "SocraTeach_multi.json"
PROCESSED_DIR = Path(__file__).resolve(
).parent.parent.parent / "data" / "processed"
SEED = 42
SPLIT_RATIOS = {"train": 0.8, "valid": 0.1, "test": 0.1}

# Write the flattening function (the core logic)


def clean_user_type(raw_type):
    """Fix stray ']' artifacts, e.g. '(3)]' -> '(3)'."""
    if raw_type is None:
        return None
    return raw_type.rstrip("]")


def flatten_dialogue(problem_id, problem_data):
    """Convert one problem's dialogues into a list of training records,
    one per teacher turn, each paired with the context before it."""
    records = []
    question = problem_data["question"]

    for dialogue_id, turns in problem_data["dialogues"].items():
        context_lines = []

        for turn_index, turn in enumerate(turns):
            # Every turn has a "system" (teacher) message — this is our target
            target = turn["system"]
            is_end = turn.get("END") == "True"

            record = {
                "id": f"{problem_id}_{dialogue_id}_turn{turn_index}",
                "problem": question,
                "context": "".join(context_lines),
                "target": target,
                "metadata": {
                    "problem_id": problem_id,
                    "dialogue_id": dialogue_id,
                    "turn_index": turn_index,
                    "user_type": clean_user_type(turn.get("user_type")),
                    "is_end": is_end,
                }
            }
            records.append(record)

            # Add this turn to context for the NEXT record
            context_lines.append(f"Teacher: {target}\n")
            if "user" in turn:
                context_lines.append(f"Student: {turn['user']}\n")

    return records

# Write the split logic (by problem ID, not by turn)


def split_problem_ids(problem_ids, ratios, seed):
    ids = list(problem_ids)
    random.seed(seed)
    random.shuffle(ids)

    n = len(ids)
    n_train = int(n * ratios["train"])
    n_valid = int(n * ratios["valid"])

    train_ids = set(ids[:n_train])
    valid_ids = set(ids[n_train:n_train + n_valid])
    test_ids = set(ids[n_train + n_valid:])

    return train_ids, valid_ids, test_ids

# Tie it together in main()


def main():
    print(f"Loading raw data from {RAW_PATH}")
    with open(RAW_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    print(f"Flattening {len(data)} problems into training records...")
    all_records = []
    for problem_id, problem_data in data.items():
        all_records.extend(flatten_dialogue(problem_id, problem_data))

    print(f"Total records: {len(all_records)}")

    train_ids, valid_ids, test_ids = split_problem_ids(
        data.keys(), SPLIT_RATIOS, SEED)

    splits = {"train": [], "valid": [], "test": []}
    for record in all_records:
        pid = record["metadata"]["problem_id"]
        if pid in train_ids:
            splits["train"].append(record)
        elif pid in valid_ids:
            splits["valid"].append(record)
        else:
            splits["test"].append(record)

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    for split_name, records in splits.items():
        out_path = PROCESSED_DIR / f"socrateach_{split_name}.jsonl"
        with open(out_path, "w", encoding="utf-8") as f:
            for record in records:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
        print(f"  {split_name}: {len(records)} records -> {out_path}")


if __name__ == "__main__":
    main()
