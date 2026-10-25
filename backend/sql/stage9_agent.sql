-- CogniGuide agent plan, Phase 1 (Step 1.4): what each session is about, and room for the agent's memory.
--
-- Run ONCE in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Safe to run again (it does nothing the second time). Old sessions keep working:
-- they get problem_id = null, status = 'in_progress' and an empty state.
--
--   problem_id  which problem from backend/data/problems.json (null for an old session
--               or a problem the student typed in themselves)
--   status      'in_progress', 'solved' or 'ended'  (filled in by later steps)
--   ended_at    when the session was solved or ended (filled in by later steps)
--   state       the agent's notes about this session, e.g. attempts and hints given
--               (numbers and short labels only, never message text; filled in by later steps)

alter table sessions
    add column if not exists problem_id text,
    add column if not exists status     text not null default 'in_progress',
    add column if not exists ended_at   timestamptz,
    add column if not exists state      jsonb not null default '{}'::jsonb;

-- Only these three status words are allowed.
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'sessions_status_check') then
        alter table sessions
            add constraint sessions_status_check check (status in ('in_progress', 'solved', 'ended'));
    end if;
end $$;

-- Row-level security is already on for sessions (schema.sql); new columns are covered too.
