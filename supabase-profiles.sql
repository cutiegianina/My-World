-- Saved state per account: look, names, the friend, who you play, and where you were standing.
-- Run this once in the Supabase dashboard (SQL editor). Until it has run, the app keeps working and
-- simply remembers things on this device only.

create table if not exists public.profiles (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  state      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint profiles_state_small check (pg_column_size(state) < 4096)
);

alter table public.profiles enable row level security;

-- each signed-in person can read and write only their own row
create policy "profiles: read own"   on public.profiles for select using (auth.uid() = user_id);
create policy "profiles: insert own" on public.profiles for insert with check (auth.uid() = user_id);
create policy "profiles: update own" on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
