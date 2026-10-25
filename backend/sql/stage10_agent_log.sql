-- CogniGuide agent plan, Phase 3: a log of every tutor decision (for the research).
--
-- Run ONCE in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run.
-- IMPORTANT: the dropdown next to "Save" (top right of the editor) must say "Database".
-- Safe to run again (it does nothing the second time).
--
-- One row per tutor reply: what the check saw and what the tutor chose, and why.
-- Labels and numbers only: never message text, never names.
-- Until this file is run, the chat still works; the server only logs "saving the decision failed".

create table if not exists agent_turns (
    id             bigint generated always as identity primary key,
    session_id     uuid not null references sessions(id) on delete cascade,
    student_id     uuid not null references students(id) on delete cascade,
    problem_id     text,                 -- bank problem, or null for a typed-in problem
    action         text not null,        -- policy.py action, e.g. GIVE_SMALL_HINT
    reason         text,                 -- why that action was chosen
    needed_level   smallint,             -- help the student needed (1-3)
    hint_level     smallint,             -- help really given after the scaffold limit (1-3)
    scaffold_level smallint,             -- most help allowed (1-3)
    intent         text,                 -- from the student check (null on the opening turn)
    correctness    text,
    mistake_id     text,
    answer_check   text,                 -- correct / partial / wrong / not_found / null
    check_source   text,                 -- llm (Gemini) or fallback (word rules)
    guard          text,                 -- ok / rewritten / safe_reply / gemini_busy
    latency_ms     integer,              -- how long the whole turn took on the server
    created_at     timestamptz not null default now()
);

create index if not exists idx_agent_turns_session on agent_turns(session_id, id);

-- Privacy: no public access; only the Flask backend (service key) can read or write.
alter table agent_turns enable row level security;
