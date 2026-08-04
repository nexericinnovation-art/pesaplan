-- Onboarding fields on profiles + a dedicated user_settings table.
-- RLS pattern throughout this file (and every migration that follows) relies
-- on Clerk being registered as a Supabase Third-Party Auth provider, so that
-- auth.jwt() ->> 'sub' resolves to the signed-in Clerk user id on every
-- authenticated Postgres request. Without that live dashboard step, these
-- policies will correctly reject every request (auth.jwt() is null), even
-- for legitimate users. See supabase/README.md for the setup steps.

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists country text default 'Kenya',
  add column if not exists currency text default 'KES',
  add column if not exists monthly_income numeric(14, 2),
  add column if not exists income_source text,
  add column if not exists financial_goal text,
  add column if not exists monthly_savings_target numeric(14, 2),
  add column if not exists existing_debt_amount numeric(14, 2),
  add column if not exists preferred_budgeting_method text,
  add column if not exists onboarding_completed boolean not null default false;

create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id text not null unique references public.profiles (clerk_user_id) on delete cascade,
  preferred_currency text not null default 'KES',
  push_notifications_enabled boolean not null default true,
  email_notifications_enabled boolean not null default true,
  in_app_notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_settings enable row level security;

create policy "Users can view their own settings"
  on public.user_settings
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own settings"
  on public.user_settings
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own settings"
  on public.user_settings
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own settings"
  on public.user_settings
  for delete
  using (auth.jwt() ->> 'sub' = user_id);
