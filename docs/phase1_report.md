# CogniGuide - Phase 1 Report: Data Preparation & Baseline Agent

**Project:** CogniGuide, a Socratic AI tutor for teenagers (final-year project, CCS3301)
**Phase:** 1 of 3 - Data Preparation & Baseline Agent
**Date:** 16 October 2026
**Status:** Complete. One open item: the reasons for the "other" labels in Section 5.3 are still to be written.

---

## 1. Purpose of Phase 1

The project investigates how Generative AI affects teenagers' critical thinking and builds an agent that guides them to answers with questions instead of giving answers directly. Phase 1 had two goals:

1. Prepare an existing Socratic tutoring dataset so it can support the agent's design and later experiments.
2. Build a simple baseline agent and check how well it behaves, so Phase 2 (the adaptive agent) has a measured starting point.

## 2. Dataset: SocraTeach

| Item | Value |
|---|---|
| Source | SocraticLM (NeurIPS 2024), https://github.com/Ljyustc/SocraticLM |
| File used | `SocraTeach_multi.json` |
| Content | Multi-round Teacher-Student math tutoring dialogues (GSM8K and MAWPS word problems) |
| Problems | 10,273 |
| Dialogues | 35,151 (about 3.4 per problem) |
| Average turns per dialogue | 5.28 (minimum 3, maximum 9) |
| Average teacher message length | 30.3 words |
| Average student message length | 16.3 words |

Each problem holds the question, a worked solution, the final answer, the ideal sequence of guiding sub-questions, and several simulated dialogues. Each dialogue turn has a teacher message and a student reply. The student replies are tagged with one of six simulated cognitive states (`user_type`, from the SocraticLM paper, Appendix B.1):

| Code | Student state | Student turns (after cleaning) |
|---|---|---|
| (1) | Does not understand the problem | 9,792 |
| (2) | Does not understand the teacher's explanation | 8,565 |
| (3) | Makes a calculation error | 40,859 |
| (4) | Poor knowledge mastery | 29,106 |
| (5) | Weak thirst for learning | 9,696 |
| (6) | Strong in all aspects | 52,433 |

The last turn of each dialogue is a closing teacher statement marked `END`, with no student reply.

**Validation.** Our exploration statistics (problem, dialogue and turn counts and average message lengths) matched the published paper almost exactly. This is a sign that the data is complete and uncorrupted.

**Suitability.** The dataset was kept as it is. It was built for Socratic tutoring, is peer-reviewed, is large, and was validated as above. Known limitations: it covers maths only, and the students are AI-simulated, not real teenagers. This is acceptable because evaluation with real teenagers is planned for Phase 3, using our own study.

## 3. Preprocessing

Script: `backend/scripts/preprocess_socrateach.py`

- **Flattening.** Every dialogue is converted into one record per teacher turn. Each record holds the problem, all earlier turns (the context), and the teacher's message for that turn (the target). The target is what a model should learn to produce.
- **Cleaning.** A small number of raw `user_type` labels had formatting artifacts (for example `(3)]` instead of `(3)`). These were corrected to the proper form.
- **Splitting.** The data is split by **problem ID**, not by individual record, so all dialogues of one problem stay in the same split. This avoids leakage between train, validation and test. The split is 80% / 10% / 10% with a fixed random seed (42), so everyone gets the same split.
- **Output.** 185,602 records, saved as JSONL files:

| Split | Records |
|---|---|
| Train | 148,658 |
| Validation | 18,385 |
| Test | 18,559 |

The field-by-field format is documented in `data/README_processed_data.md`.

**Decisions made**
- The closing `END` turn is kept as a valid training example, because it teaches the closing behaviour.
- The full conversation history is used as context, with no cap, because the dialogues are short.
- Raw and processed data are not committed to Git (see `.gitignore`). They are recreated by running the script.

## 4. Baseline Socratic agent

File: `backend/app/models/socratic_agent.py`

- **Approach.** A pre-trained LLM (Google Gemini API) with a strong system prompt. No fine-tuning.
- **Interface.** `socratic_response(problem, conversation_history)` returns the next teacher message.
- **Settings.** Temperature 0.3. The model name is read only from `GEMINI_MODEL` in `.env`, so switching models needs no code change.
- **Rules in the system prompt.**
  1. Never give the final answer directly, especially in the first 2-3 turns.
  2. Respond with a guiding question, not a statement, unless the student lacks a basic concept (then a short explanation followed by a question).
  3. If the student is stuck or wrong, point out that something is off without stating the correct answer, and ask a question that helps them find their mistake.
  4. Give gradually more specific hints if the student struggles across turns, but stop short of the answer.
  5. Encourage reflection.
  6. Sound like a warm human teacher, in 1-3 sentences.
  7. If the student has solved the whole problem correctly, confirm and summarise what they did well.
- **Error handling.** If the API call fails, the agent returns a short fallback message and does not crash.

## 5. Evaluation

### 5.1 Manual testing (Stage 4)

Three held-out problems (Joshua bottles, Pam and Rena ages, erasers) were tried in live conversations with the agent, using the earlier model `gemini-3.6-flash`. Findings:

- The agent gave step-by-step guidance and avoided direct answers.
- When the student was stuck, it rephrased with a concrete analogy instead of repeating itself.
- When the student guessed wrongly, it asked them to check their own guess, which teaches a checking method.
- It recognised a red herring (an irrelevant number in the problem) and praised the student for focusing on the right numbers.
- It confirmed correct final answers and added a reflection question.

Practical problems: occasional 503 "high demand" errors (the fallback worked), and a 429 quota error. That model's free tier allowed only about 20 requests per day, which is too small for a larger evaluation.

### 5.2 Baseline evaluation (Stage 5)

- **Model:** `gemini-3.1-flash-lite` (chosen for its larger free-tier allowance).
- **Notebook:** `notebooks/02_baseline_prompts.ipynb`
- **Examples:** 15 test-set records, each from a different problem, never a closing turn, picked with a fixed seed (42). Five of the 15 were first turns of a conversation and ten came from later turns.
- **Method:** For each record the agent was given the problem and the earlier conversation and produced the next teacher reply. One team member read each reply next to the reference teacher reply from the dataset and gave it one label.
- **Labels:** good Socratic, too vague, gives answer too soon, other.
- **Raw data:** `experiments/phase1_baseline/baseline_eval_results.json`

### 5.3 Results

| Label | Count | Share |
|---|---|---|
| Good Socratic | 4 | 27% |
| Too vague | 4 | 27% |
| Gives answer too soon | 2 | 13% |
| Other | 5 | 33% |
| **Total** | **15** | |

**Reading the results**
- The agent rarely gave the answer away (2 of 15). This is the behaviour the project cares most about, and it is a reasonable baseline.
- Only 4 of 15 replies were judged fully good, so there is clear room for improvement in Phase 2.
- The "other" group is the largest. **The reasons for each of these 5 replies still need to be written down here** (for example: too wordy, did not confirm a correct step, unclear). Until then, this group is not explained.

### 5.4 Limitations of this evaluation

- Small sample (15), one model, one person labelling. The numbers are a first check and not proof.
- The labels are subjective. A second person labelling the same 15 replies would let us measure agreement.
- Only the agent's single next reply was judged, not whole conversations.
- The free tier limits how many calls we can make per day, which limits the size of any evaluation.

## 6. Conclusions and next steps

**Conclusions**
- The data is validated, cleaned and split, and the pipeline is reproducible.
- The baseline agent follows the Socratic rules well enough to avoid direct answers, but too many replies are vague or otherwise unsatisfactory.
- A flat system prompt is not enough, which supports the proposal's plan for adaptive support, scaffolding and personalised reflection.

**Next steps (Phase 2)**
1. Record the reasons for the "other" labels and, if possible, have a second person label the same 15.
2. Continue the Phase 2 build: Flask API, Supabase, logging, then the adaptive and scaffolding features.
3. Re-run this evaluation on the adaptive agent and compare it with this baseline, using the same 15 examples.

## Appendix: key files

| File | Purpose |
|---|---|
| `backend/scripts/preprocess_socrateach.py` | Flatten, clean and split the dataset |
| `data/README_processed_data.md` | Format of the processed records |
| `backend/app/models/socratic_agent.py` | Baseline agent |
| `experiments/phase1_baseline/manual_test_notes.md` | Stage 4 manual test notes |
| `notebooks/02_baseline_prompts.ipynb` | Stage 5 evaluation notebook |
| `experiments/phase1_baseline/baseline_eval_results.json` | Raw evaluation results |
| `experiments/phase1_baseline/baseline_eval_notes.md` | Label tally |
