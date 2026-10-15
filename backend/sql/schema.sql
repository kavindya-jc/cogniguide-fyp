-- CogniGuide database blueprint (Phase 2, Stage 2)
-- Paste this whole file into the Supabase SQL Editor and click Run.
-- Safe to run again: it only creates things that do not exist yet.

-- 1. students: anonymous participants only. NO names, NO emails.
create table if not exists students (
    id          uuid primary key default gen_random_uuid(),
    anon_code   text not null unique,          -- e.g. 'P001'
    created_at  timestamptz not null default now()
);

-- 2. sessions: one row each time a student works on a problem.
create table if not exists sessions (
    id          uuid primary key default gen_random_uuid(),
    student_id  uuid not null references students(id) on delete cascade,
    problem     text not null,
    started_at  timestamptz not null default now()
);

-- 3. messages: every message in a session. Order them by id.
create table if not exists messages (
    id          bigint generated always as identity primary key,
    session_id  uuid not null references sessions(id) on delete cascade,
    role        text not null check (role in ('teacher', 'student')),
    content     text not null,
    created_at  timestamptz not null default now()
);

-- 4. indicators: created now, filled in later (Stages 4 to 6).
--    e.g. indicator_type = 'self_correction', value = 1
create table if not exists indicators (
    id              bigint generated always as identity primary key,
    student_id      uuid not null references students(id) on delete cascade,
    session_id      uuid references sessions(id) on delete cascade,
    indicator_type  text not null,
    value           numeric,
    created_at      timestamptz not null default now()
);

create index if not exists idx_sessions_student on sessions(student_id);
create index if not exists idx_messages_session on messages(session_id, id);
create index if not exists idx_indicators_student on indicators(student_id);

-- Privacy: switch on row-level security with NO public policies.
-- Nobody can read or write these tables from outside.
-- Only our Flask backend can, because it uses the secret service key.
alter table students   enable row level security;
alter table sessions   enable row level security;
alter table messages   enable row level security;
alter table indicators enable row level security;
