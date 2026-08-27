# Processed Data — SocraTeach

This folder's `processed/` files are generated from the raw SocraTeach dataset
by running:

```bash
python backend/scripts/preprocess_socrateach.py
```

Raw and processed files are not tracked in Git (see `.gitignore`) — run the
script locally to regenerate them. The split is deterministic (fixed random
seed = 42), so everyone gets the same train/valid/test split.

## Files

- `processed/socrateach_train.jsonl` — 80% of problems
- `processed/socrateach_valid.jsonl` — 10% of problems
- `processed/socrateach_test.jsonl` — 10% of problems

Split is done **by problem ID**, not by individual dialogue or turn — so all
dialogues belonging to one math problem stay together in the same split
(no data leakage across splits).

## Record schema

Each line is one JSON object representing a single **teacher turn**, paired
with the conversation history that came before it.

```json
{
  "id": "GSM8K_train_0_GSM8K_train_0_0_turn0",
  "problem": "Natalia sold clips to 48 of her friends in April, and then she sold half as many clips in May. How many clips did Natalia sell altogether in April and May?",
  "context": "",
  "target": "How many clips did Natalia sell in May?",
  "metadata": {
    "problem_id": "GSM8K_train_0",
    "dialogue_id": "GSM8K_train_0_0",
    "turn_index": 0,
    "user_type": "(1)",
    "is_end": false
  }
}
```

### Field descriptions

| Field                  | Type           | Description                                                                                                               |
| ---------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | string         | Unique record ID: `{problem_id}_{dialogue_id}_turn{turn_index}`                                                           |
| `problem`              | string         | The original math word problem                                                                                            |
| `context`              | string         | All prior turns in this dialogue, formatted as `"Teacher: ...\nStudent: ...\n"` lines. Empty string for the first turn.   |
| `target`               | string         | The teacher's message for this turn — this is what a trained model should learn to generate                               |
| `metadata.problem_id`  | string         | Source problem ID (e.g. `GSM8K_train_0`)                                                                                  |
| `metadata.dialogue_id` | string         | Which of the problem's multiple dialogue variants this came from                                                          |
| `metadata.turn_index`  | int            | Position of this turn within its dialogue (0-indexed)                                                                     |
| `metadata.user_type`   | string or null | One of six simulated student cognitive states (see below). `null` for the closing `END` turn, which has no student reply. |
| `metadata.is_end`      | bool           | `true` if this is the dialogue's closing teacher statement (no student reply follows)                                     |

### `user_type` values

Source: SocraticLM paper, Appendix B.1 (Student Agent prompt).

| Value | Meaning                                              |
| ----- | ---------------------------------------------------- |
| `(1)` | Student doesn't understand the problem               |
| `(2)` | Student doesn't understand the teacher's explanation |
| `(3)` | Student makes a calculation error                    |
| `(4)` | Student has poor knowledge mastery                   |
| `(5)` | Student has weak thirst for learning                 |
| `(6)` | Student is strong in all aspects                     |

Note: the raw dataset has a small number of malformed labels (e.g. `(3)]`
instead of `(3)`) — these are cleaned to their correct form during
preprocessing.

## Dataset stats (from exploration + preprocessing)

- 10,273 source problems → 35,151 dialogues → 185,602 flattened teacher-turn records
- Split: 148,658 train / 18,385 valid / 18,559 test
