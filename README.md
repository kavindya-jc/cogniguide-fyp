# Cogniguide

Cogniguide is our final-year research project.

We are investigating how Generative AI affects teenagers' **critical thinking** and **cognitive development**, and we are building an AI agent that **guides teens to think** instead of giving direct answers. The agent uses **Socratic questioning**, reflective prompts, and step‑by‑step hints to support independent learning.

## Dataset

**Source:** SocraticLM (NeurIPS 2024) — https://github.com/Ljyustc/SocraticLM  
**File:** `SocraTeach_multi.json`  
**Contents:** 35K multi-round Teacher-Student math tutoring dialogues

**Setup instructions:**
1. Download `SocraTeach_multi.json` from the SocraticLM repository
2. Place it in `data/raw/socrateach/`
3. Run preprocessing: `python backend/scripts/preprocess_socrateach.py`

> **Note:** Raw dataset files are not tracked in Git due to size. Each user must download separately from the source above.

## Project Goals

### Study Impact of GenAI on Teens
Understand how regular use of GenAI tools influences teenagers':
- Critical thinking
- Metacognitive awareness
- Independent problem‑solving
- Self‑confidence

### Build a Socratic AI Agent
Create a chat‑based tutor that:
- Asks guiding questions instead of giving solutions
- Gives hints gradually (scaffolding)
- Encourages reflection on mistakes and strategies
- Is safe and age‑appropriate for teenagers

### Evaluate the Agent with Teenagers
Run a small controlled study comparing:
- Our Socratic agent vs. a standard direct‑answer AI assistant
- Using pre/post tests and interaction logs to see changes in thinking skills

## System Overview

The Cogniguide system has three main parts:

1. **Frontend (Flutter)** – Mobile/web interface for teenagers: chat screen + simple progress dashboard
2. **Backend (Flask, Python)** – REST API that talks to the LLM, applies Socratic rules, logs interactions
3. **Database (Supabase)** – Stores anonymised user IDs, chat logs, and metacognitive indicators (e.g. self‑corrections, reflection depth)

In **Phase 1** we mainly focus on **data and baseline agent behaviour**, not the full app. We use the **SocraTeach** dataset from the SocraticLM project, which contains Socratic‑style teaching dialogues for math problems.

## Project Structure

```
cogniguide/
README.md
LICENSE
.gitignore
requirements.txt

data/
raw/
socrateach/ # Original SocraTeach files from SocraticLM
processed/
socrateach_train.jsonl # Cleaned + split data (training)
socrateach_valid.jsonl # Validation split
socrateach_test.jsonl # Test split

notebooks/
01_explore_socrateach.ipynb # Quick dataset exploration (Phase 1)
02_baseline_prompts.ipynb # Try simple Socratic prompts + examples

backend/
app/
_init_.py
api.py # Flask REST endpoints (e.g. /chat)
socratic_agent.py # Core Socratic agent logic + LLM calls
config.py # Config (keys, model names, settings)
models/ # (optional) local / fine‑tuned models
scripts/
preprocess_socrateach.py # Convert raw SocraTeach → train/val/test
train_baseline.py # (later) fine‑tune or train baseline agent
evaluate_baseline.py # (later) evaluate agent behaviour
tests/
test_socratic_agent.py # Basic tests for agent rules

frontend/
lib/
main.dart # Flutter entry point
screens/ # Chat screen, dashboard screen, etc.
widgets/ # Reusable UI components
pubspec.yaml

experiments/
phase1_baseline/ # Notes/configs/results for Phase 1
phase2_adaptive_agent/ # For Phase 2 experiments
phase3_user_study/ # For Phase 3 study setup + analysis

docs/
proposal.pdf # Fellowship project proposal
phase1_report.md # Summary of Phase 1 data + baseline
phase2_design.md # Detailed design for full agent
phase3_protocol.md # Study protocol, consent, instruments

```

## Folder Explanations

### `data/`
- **raw/** – Original downloaded datasets (no changes)
- **processed/** – Cleaned and formatted data ready for training and experiments

### `notebooks/`
Small Jupyter notebooks for:
- Exploring the SocraTeach dataset
- Trying out prompt ideas
- Visualising simple statistics

### `backend/`
All server‑side code (Python + Flask):
- **app/** – The actual web API and Socratic agent logic
- **scripts/** – One‑off scripts for preprocessing, training, evaluation
- **tests/** – Simple automated checks to make sure the agent follows rules

### `frontend/`
Flutter app that teenagers will use:
- Chat interface to talk with the agent
- Basic dashboard showing progress and reflections

### `experiments/`
A place to save configs, small results, and notes, grouped by project phase.

### `docs/`
All written documents: proposal, reports, study design, diagrams.

## Project Phases

### Phase 1 – Data Preparation & Baseline Agent
**Goal:** Use existing datasets to understand Socratic teaching patterns and build a simple baseline agent.

**Main activities:**
1. Download and store the **SocraTeach** dataset under `data/raw/socrateach/`
2. Explore and clean the dialogues (remove broken / trivial conversations)
3. Convert them into training pairs where:
   - Input = student problem + previous turns
   - Output = teacher's Socratic question or hint
4. Implement a basic Socratic agent using a pre‑trained LLM + strong system prompt
5. Manually test small examples to see if it:
   - Asks useful questions
   - Avoids immediate full solutions
   - Remains understandable for teenagers

### Phase 2 – Full Cogniguide Agent
**Goal:** Turn the baseline into a full adaptive agent that follows our proposal design.

**Planned features:**
- Adaptive reasoning support (adjust question difficulty based on prior answers)
- Scaffolding engine that gradually reduces hint detail as the learner improves
- Personalised reflection prompts generated from each user's interaction history
- Learner progress dashboard with metacognitive indicators

### Phase 3 – Teen User Study
**Goal:** Evaluate the impact of Cogniguide on teenagers' thinking.

**Planned steps:**
1. Ethics approval and consent from parents + teens
2. Recruit teenagers (13–18) and randomly assign them to:
   - Cogniguide (Socratic agent)
   - Standard direct‑answer AI assistant
3. Run 3 sessions per week over 4 weeks
4. Use adapted Watson–Glaser Critical Thinking Appraisal + Metacognitive Awareness Inventory
5. Analyse pre/post changes and qualitative themes

## Getting Started

### Backend (Development)

```bash
# Create and activate virtual environment
python -m venv .env

# Windows
.env\Scripts\activate

# Mac/Linux
# source .env/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Run Flask app (example – update when api.py entrypoint is set)
python -m backend.app.api
```

### Frontend (Development)

```bash
cd frontend
flutter pub get
flutter run
```

### Data Preprocessing (SocraTeach – Phase 1)

```bash
python backend/scripts/preprocess_socrateach.py
```

This script should:
- Read from `data/raw/socrateach/`
- Create cleaned splits in `data/processed/`
- Print basic statistics (number of dialogues, avg. turns, etc.)

## Notes

- The SocraTeach dataset is mainly math‑focused and not collected directly from teenagers. It is used in **Phase 1 and Phase 2** to learn Socratic dialogue behaviour.
- The actual impact on teenagers' cognition will be measured later in **Phase 3** using our own study with real teenage participants.
