# Cogniguide

Cogniguide is our final-year research project.

We are investigating how Generative AI affects teenagers’ **critical thinking** and **cognitive development**, and we are building an AI agent that **guides teens to think** instead of giving direct answers. The agent uses **Socratic questioning**, reflective prompts, and step‑by‑step hints to support independent learning. [179]

---

## Project goals

1. **Study impact of GenAI on teens**

   Understand how regular use of GenAI tools influences teenagers’:
   - critical thinking  
   - metacognitive awareness  
   - independent problem‑solving  
   - self‑confidence [179]

2. **Build a Socratic AI agent**

   Create a chat‑based tutor that:
   - asks guiding questions instead of giving solutions  
   - gives hints gradually (scaffolding)  
   - encourages reflection on mistakes and strategies  
   - is safe and age‑appropriate for teenagers [179]

3. **Evaluate the agent with teenagers**

   Run a small controlled study comparing:
   - our Socratic agent vs. a standard direct‑answer AI assistant  
   - using pre/post tests and interaction logs to see changes in thinking skills [179]

---

## System overview

The Cogniguide system has three main parts:

- **Frontend (Flutter)** – mobile/web interface for teenagers: chat screen + simple progress dashboard. [179]  
- **Backend (Flask, Python)** – REST API that talks to the LLM, applies Socratic rules, logs interactions. [179]  
- **Database (Supabase)** – stores anonymised user IDs, chat logs, and metacognitive indicators (e.g. self‑corrections, reflection depth). [179]

In **Phase 1** we mainly focus on **data and baseline agent behaviour**, not the full app. We use the **SocraTeach** dataset from the SocraticLM project, which contains Socratic‑style teaching dialogues for math problems. [176][193]

---

## Project structure

```text
cogniguide/
  README.md
  LICENSE
  .gitignore
  requirements.txt

  data/
    raw/
      socrateach/                # Original SocraTeach files from SocraticLM
    processed/
      socrateach_train.jsonl     # Cleaned + split data (training)
      socrateach_valid.jsonl     # Validation split
      socrateach_test.jsonl      # Test split

  notebooks/
    01_explore_socrateach.ipynb  # Quick dataset exploration (Phase 1)
    02_baseline_prompts.ipynb    # Try simple Socratic prompts + examples

  backend/
    app/
      __init__.py
      api.py                     # Flask REST endpoints (e.g. /chat)
      socratic_agent.py          # Core Socratic agent logic + LLM calls
      config.py                  # Config (keys, model names, settings)
      models/                    # (optional) local / fine‑tuned models
    scripts/
      preprocess_socrateach.py   # Convert raw SocraTeach → train/val/test
      train_baseline.py          # (later) fine‑tune or train baseline agent
      evaluate_baseline.py       # (later) evaluate agent behaviour
    tests/
      test_socratic_agent.py     # Basic tests for agent rules

  frontend/
    lib/
      main.dart                  # Flutter entry point
      screens/                   # Chat screen, dashboard screen, etc.
      widgets/                   # Reusable UI components
    pubspec.yaml

  experiments/
    phase1_baseline/             # Notes/configs/results for Phase 1
    phase2_adaptive_agent/       # For Phase 2 experiments
    phase3_user_study/           # For Phase 3 study setup + analysis

  docs/
    proposal.pdf                 # Fellowship project proposal
    phase1_report.md             # Summary of Phase 1 data + baseline
    phase2_design.md             # Detailed design for full agent
    phase3_protocol.md           # Study protocol, consent, instruments
```

### Folder explanations (simple)

- **`data/`**  
  - `raw/` – original downloaded datasets (no changes).  
  - `processed/` – cleaned and formatted data ready for training and experiments.

- **`notebooks/`**  
  Small Jupyter notebooks for:
  - exploring the SocraTeach dataset,  
  - trying out prompt ideas,  
  - visualising simple statistics. [193]

- **`backend/`**  
  All server‑side code (Python + Flask):
  - `app/` – the actual web API and Socratic agent logic.  
  - `scripts/` – one‑off scripts for preprocessing, training, evaluation.  
  - `tests/` – simple automated checks to make sure the agent follows rules (e.g. “don’t give the final answer immediately”).

- **`frontend/`**  
  Flutter app that teenagers will use:
  - chat interface to talk with the agent,  
  - basic dashboard showing progress and reflections.

- **`experiments/`**  
  A place to save configs, small results, and notes, grouped by project phase.

- **`docs/`**  
  All written documents: proposal, reports, study design, diagrams.

---

## Project phases

### Phase 1 – Data preparation & baseline agent

**Goal:** Use existing datasets to understand Socratic teaching patterns and build a simple baseline agent. [179][193]

Main activities:
- Download and store the **SocraTeach** dataset under `data/raw/socrateach/`. [176][193]  
- Explore and clean the dialogues (remove broken / trivial conversations).  
- Convert them into training pairs where:
  - **input** = student problem + previous turns,  
  - **output** = teacher’s Socratic question or hint. [193]  
- Implement a basic Socratic agent using a pre‑trained LLM + strong system prompt.  
- Manually test small examples to see if it:
  - asks useful questions,  
  - avoids immediate full solutions,  
  - remains understandable for teenagers.

### Phase 2 – Full Cogniguide agent

**Goal:** Turn the baseline into a full adaptive agent that follows our proposal design. [179]

Planned features:
- Adaptive reasoning support (adjust question difficulty based on prior answers).  
- Scaffolding engine that gradually reduces hint detail as the learner improves.  
- Personalised reflection prompts generated from each user’s interaction history.  
- Learner progress dashboard with metacognitive indicators such as self‑correction frequency and reflection depth. [179]

### Phase 3 – Teen user study

**Goal:** Evaluate the impact of Cogniguide on teenagers’ thinking. [179]

Planned steps:
- Ethics approval and consent from parents + teens.  
- Recruit teenagers (13–18) and randomly assign them to:
  - Cogniguide (Socratic agent),  
  - standard direct‑answer AI assistant. [179]  
- Run 3 sessions per week over 4 weeks.  
- Use:
  - Adapted Watson–Glaser Critical Thinking Appraisal (short form),  
  - Metacognitive Awareness Inventory (MAI, adolescent‑adapted),  
  - plus interview data and interaction logs. [179]  
- Analyse pre/post changes and qualitative themes about how teens describe their thinking and AI use.

---

## Development (early stage)

These steps will be refined as we build the project.

### Backend (development)

```bash
# create and activate virtual environment
python -m venv .env
# Windows
.env\Scripts\activate
# Mac/Linux
# source .env/bin/activate

# install Python dependencies
pip install -r requirements.txt

# run Flask app (example – update when api.py entrypoint is set)
python -m backend.app.api
```

### Frontend (development)

```bash
cd frontend
flutter pub get
flutter run
```

### Data preprocessing (SocraTeach – Phase 1)

```bash
python backend/scripts/preprocess_socrateach.py
```

This script should:
- read from `data/raw/socrateach/`,
- create cleaned splits in `data/processed/`,
- and print basic statistics (number of dialogues, avg. turns, etc.). [193]

---

## Notes

- The SocraTeach dataset is mainly math‑focused and not collected directly from teenagers. It is used in **Phase 1 and Phase 2** to learn Socratic dialogue behaviour. [193]  
- The actual impact on teenagers’ cognition will be measured later in **Phase 3** using our own study with real teenage participants. [179]
