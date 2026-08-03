create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  clerk_user_id text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile"
  on public.profiles
  for select
  using (auth.jwt() ->> 'sub' = clerk_user_id);

create policy "Users can insert their own profile"
  on public.profiles
  for insert
  with check (auth.jwt() ->> 'sub' = clerk_user_id);

create policy "Users can update their own profile"
  on public.profiles
  for update
  using (auth.jwt() ->> 'sub' = clerk_user_id)
  with check (auth.jwt() ->> 'sub' = clerk_user_id);

create policy "Users can delete their own profile"
  on public.profiles
  for delete
  using (auth.jwt() ->> 'sub' = clerk_user_id);
