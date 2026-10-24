-- CogniGuide Stage 7c: sign up and log in (anonymous code + password).
--
-- Run ONCE in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Safe to run again (it does nothing the second time).
--
-- Only a scrambled version of the password is stored ("hash"), never the
-- password itself. Students made before this change (test codes) have no
-- password_hash, so they cannot log in; make new test accounts in the app.

alter table students
    add column if not exists password_hash text;
