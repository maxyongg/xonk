-- xonk accounts schema — paste into Supabase: SQL Editor -> New query -> Run.
-- Safe to re-run.

create extension if not exists pgcrypto;

-- one profile per account; username is the public identity
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique not null,
  created_at timestamptz not null default now(),
  constraint username_format check (username ~ '^[a-z0-9_]{3,20}$')
);

-- editable identity for the profile page; both optional, username is the fallback
alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists tagline text;

-- every rated/logged piece of media, all users, one table
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  kind text not null check (kind in ('films','games','tv','books')),
  name text not null,
  cover_url text,
  creator text,          -- director / developer / network / author
  year int,              -- release / first-season / publication year
  date_logged text,      -- date watched/played/read (text: partial dates exist in old data)
  rx int check (rx between -100 and 100),   -- enjoyment
  ry int check (ry between -100 and 100),   -- quality
  summary text,          -- short description pulled from TMDB/RAWG/Open Library
  genre text,
  in_progress boolean not null default false,
  extra jsonb not null default '{}'::jsonb, -- seasons, console, studio, misc leftovers
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists items_user_idx on public.items(user_id);
create index if not exists items_kind_idx on public.items(kind);

-- auto-create a profile from the username chosen at sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'username',''),
                           'user_' || left(replace(new.id::text,'-',''), 8)))
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.items    enable row level security;

-- usernames are public; you can only change your own profile
drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles for select using (true);
drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles for update using (auth.uid() = id);

-- People directory in one row per account, so listing everybody no longer means
-- downloading everybody's library. Ratings live in ry (the JSON import converted
-- the old per-kind `rating` scale to ry at import time), so "rated" is simply a
-- non-null ry, and no per-kind scale conversion is needed here.
-- security invoker, so RLS still applies: profiles are public, items need a session.
create or replace function public.people_directory()
returns table (
  id uuid, username text, display_name text, tagline text, created_at timestamptz,
  works int, rated int, avg_e float8, avg_q float8
)
language sql stable security invoker set search_path = public as $$
  select p.id, p.username, p.display_name, p.tagline, p.created_at,
         count(i.id)::int,
         count(i.ry)::int,
         (avg(i.rx) filter (where i.rx is not null and i.ry is not null))::float8,
         (avg(i.ry))::float8
  from public.profiles p
  left join public.items i on i.user_id = p.id
  group by p.id, p.username, p.display_name, p.tagline, p.created_at
  order by count(i.id) desc, p.username;
$$;
grant execute on function public.people_directory() to authenticated;

-- any signed-in user can READ all items (this powers cross-user comparison);
-- writes are strictly your own rows
drop policy if exists "items readable" on public.items;
create policy "items readable" on public.items for select to authenticated using (true);
drop policy if exists "insert own items" on public.items;
create policy "insert own items" on public.items for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "update own items" on public.items;
create policy "update own items" on public.items for update to authenticated using (auth.uid() = user_id);
drop policy if exists "delete own items" on public.items;
create policy "delete own items" on public.items for delete to authenticated using (auth.uid() = user_id);
