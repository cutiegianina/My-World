-- Saved state per account: look, names, the friend, who you play, and where you were standing.
-- Run this in the Supabase dashboard (SQL editor). It is safe to run more than once.
-- Until it has run, the app keeps working and simply remembers things on this device only.

create table if not exists public.profiles (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  state      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- one small document per account (re-added on every run, so it also lands on a table that already existed)
alter table public.profiles drop constraint if exists profiles_state_small;
alter table public.profiles add constraint profiles_state_small check (pg_column_size(state) < 4096);

alter table public.profiles enable row level security;

-- let signed-in people use the table through the API at all. (Newer Supabase projects do not do this for tables made in the SQL editor,
-- and without it every read fails with "permission denied", so nothing is ever saved. Harmless if it was already granted.)
grant usage on schema public to authenticated;
grant select, insert, update on public.profiles to authenticated;

-- each signed-in person can read and write only their own row
drop policy if exists "profiles: read own"   on public.profiles;
drop policy if exists "profiles: insert own" on public.profiles;
drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: read own"   on public.profiles for select using (auth.uid() = user_id);
create policy "profiles: insert own" on public.profiles for insert with check (auth.uid() = user_id);
create policy "profiles: update own" on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
