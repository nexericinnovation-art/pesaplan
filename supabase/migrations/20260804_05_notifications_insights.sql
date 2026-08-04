create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_id_idx on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications"
  on public.notifications
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own notifications"
  on public.notifications
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own notifications"
  on public.notifications
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own notifications"
  on public.notifications
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

-- financial_insights rows are meant to be produced server-side (Edge
-- Function / scheduled job using the service-role key, which bypasses RLS)
-- from real user data — never written directly by the client with
-- fabricated content. Clients only ever read their own insights.
create table if not exists public.financial_insights (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  insight_type text not null,
  title text not null,
  description text,
  data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists financial_insights_user_id_idx on public.financial_insights (user_id, created_at desc);

alter table public.financial_insights enable row level security;

create policy "Users can view their own financial insights"
  on public.financial_insights
  for select
  using (auth.jwt() ->> 'sub' = user_id);

-- Intentionally no insert/update/delete policy for regular users: insights
-- are computed and written server-side via the service-role key inside an
-- Edge Function, never directly by the client.
