create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  type text not null check (type in ('income', 'expense', 'transfer')),
  amount numeric(14, 2) not null check (amount > 0),
  currency text not null default 'KES',
  category_id uuid references public.categories (id) on delete restrict,
  account_id uuid references public.accounts (id) on delete set null,
  description text,
  merchant text,
  notes text,
  payment_method text check (payment_method in ('cash', 'mpesa', 'bank', 'card', 'mobile_money', 'other')),
  transaction_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists transactions_user_date_idx on public.transactions (user_id, transaction_date desc);
create index if not exists transactions_user_category_idx on public.transactions (user_id, category_id);
create index if not exists transactions_user_type_idx on public.transactions (user_id, type);

alter table public.transactions enable row level security;

create policy "Users can view their own transactions"
  on public.transactions
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own transactions"
  on public.transactions
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own transactions"
  on public.transactions
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own transactions"
  on public.transactions
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

-- Budgets: a named period (e.g. "August 2026"); budget_categories holds the
-- per-category allocation within that period.
create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  name text not null,
  period_start date not null,
  period_end date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint budgets_period_valid check (period_end > period_start)
);

create index if not exists budgets_user_id_idx on public.budgets (user_id);

alter table public.budgets enable row level security;

create policy "Users can view their own budgets"
  on public.budgets
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own budgets"
  on public.budgets
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own budgets"
  on public.budgets
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own budgets"
  on public.budgets
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

create table if not exists public.budget_categories (
  id uuid primary key default gen_random_uuid(),
  budget_id uuid not null references public.budgets (id) on delete cascade,
  category_id uuid not null references public.categories (id) on delete restrict,
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  allocated_amount numeric(14, 2) not null check (allocated_amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (budget_id, category_id)
);

create index if not exists budget_categories_user_id_idx on public.budget_categories (user_id);
create index if not exists budget_categories_budget_id_idx on public.budget_categories (budget_id);

alter table public.budget_categories enable row level security;

create policy "Users can view their own budget categories"
  on public.budget_categories
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own budget categories"
  on public.budget_categories
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own budget categories"
  on public.budget_categories
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own budget categories"
  on public.budget_categories
  for delete
  using (auth.jwt() ->> 'sub' = user_id);
