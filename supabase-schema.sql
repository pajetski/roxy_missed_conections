-- ============================================================
-- ROXY ENCINITAS — MISSED CONNECTIONS
-- Supabase Schema
-- Run this in your Supabase SQL editor
-- ============================================================

-- PROFILES TABLE
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null unique,
  avatar_emoji text default '🌊',
  instagram text,
  email_notifications boolean default true,
  created_at timestamptz default now()
);

-- CONNECTIONS TABLE
create table if not exists public.connections (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete set null,
  -- Guest fields (used when profile_id is null)
  guest_name text,
  guest_email text,
  -- Post content
  night text not null,
  night_key text not null check (night_key in ('fri','sat','sun','thurs','other')),
  vibe text not null,
  message text not null,
  contact text,
  -- Metadata
  hearts integer default 0,
  is_approved boolean default true,
  created_at timestamptz default now()
);

-- HEARTS TABLE (deduplicated by session)
create table if not exists public.hearts (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid references public.connections(id) on delete cascade,
  session_id text not null,
  created_at timestamptz default now(),
  unique(connection_id, session_id)
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.connections enable row level security;
alter table public.hearts enable row level security;

-- Profiles: anyone can insert, only owner can update
create policy "Anyone can create a profile"
  on public.profiles for insert with check (true);

create policy "Profiles are publicly readable"
  on public.profiles for select using (true);

-- Connections: publicly readable, anyone can insert
create policy "Connections are publicly readable"
  on public.connections for select using (is_approved = true);

create policy "Anyone can post a connection"
  on public.connections for insert with check (true);

-- Hearts: anyone can insert/read, deduped by unique constraint
create policy "Hearts are publicly readable"
  on public.hearts for select using (true);

create policy "Anyone can heart"
  on public.hearts for insert with check (true);

-- ============================================================
-- FUNCTION: increment hearts count atomically
-- ============================================================
create or replace function increment_hearts(conn_id uuid, sid text)
returns void
language plpgsql
as $$
begin
  insert into public.hearts (connection_id, session_id)
  values (conn_id, sid);

  update public.connections
  set hearts = hearts + 1
  where id = conn_id;

exception when unique_violation then
  -- Already hearted from this session, do nothing
  null;
end;
$$;

-- ============================================================
-- SEED DATA (optional — comment out in production)
-- ============================================================

insert into public.connections
  (guest_name, night, night_key, vibe, message, contact, hearts)
values
  (
    'Tall Guy by the Jukebox',
    'Last Saturday', 'sat',
    'Eye contact across the bar',
    'You had a laugh that made the whole room turn around. You were with two friends, I was pretending to look at the menu. I was not looking at the menu.',
    '@tallguyroxy',
    34
  ),
  (
    'Mezcal Girl, Green Jacket',
    'Last Friday', 'fri',
    'Talked for an hour, then lost you',
    'We talked about your road trip to Baja for like 45 minutes and I never got your name. You left while I was in the bathroom. Classic me. If this is you, I owe you a drink.',
    'DM @mezcalgirl_encinitas',
    61
  ),
  (
    'The Door Holder',
    'Some Tuesday', 'other',
    'You held the door, I panicked',
    'You held the door and said "after you" and I said "no after you" and then we both stood there for four seconds that felt like a year. I think about this constantly.',
    'Ask the bartender',
    129
  ),
  (
    'Sunday Wine Person',
    'Last Sunday', 'sun',
    'Dance floor adjacent situation',
    'You were sipping something red, swaying slightly, completely unbothered. The song was bad and you were vibing harder than anyone there. I respect it. I respect you. Reach out.',
    '@sundayroseperson',
    47
  ),
  (
    'Bearded Guy, Back Booth',
    'Last Friday', 'fri',
    'Shared a barstool (accidentally)',
    'We literally sat on the same barstool for a second because the bar was packed and neither of us noticed and then we both did at the same time. You were very gracious about it.',
    'Venmo @beardedguy for emotional damages',
    88
  );
