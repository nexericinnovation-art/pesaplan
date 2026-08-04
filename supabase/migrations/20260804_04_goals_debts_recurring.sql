create table if not exists public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  name text not null,
  target_amount numeric(14, 2) not null check (target_amount > 0),
  current_amount numeric(14, 2) not null default 0 check (current_amount >= 0),
  deadline date,
  status text not null default 'active' check (status in ('active', 'paused', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists savings_goals_user_id_idx on public.savings_goals (user_id);

alter table public.savings_goals enable row level security;

create policy "Users can view their own savings goals"
  on public.savings_goals
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own savings goals"
  on public.savings_goals
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own savings goals"
  on public.savings_goals
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own savings goals"
  on public.savings_goals
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

create table if not exists public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.savings_goals (id) on delete cascade,
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  amount numeric(14, 2) not null check (amount > 0),
  contribution_type text not null check (contribution_type in ('deposit', 'withdrawal')),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists goal_contributions_user_id_idx on public.goal_contributions (user_id);
create index if not exists goal_contributions_goal_id_idx on public.goal_contributions (goal_id);

alter table public.goal_contributions enable row level security;

create policy "Users can view their own goal contributions"
  on public.goal_contributions
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own goal contributions"
  on public.goal_contributions
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own goal contributions"
  on public.goal_contributions
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own goal contributions"
  on public.goal_contributions
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

create table if not exists public.debts (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  loan_name text not null,
  lender text,
  original_amount numeric(14, 2) not null check (original_amount > 0),
  current_balance numeric(14, 2) not null check (current_balance >= 0),
  interest_rate numeric(6, 3),
  minimum_payment numeric(14, 2),
  payment_frequency text check (payment_frequency in ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
  due_date date,
  start_date date,
  expected_payoff_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists debts_user_id_idx on public.debts (user_id);

alter table public.debts enable row level security;

create policy "Users can view their own debts"
  on public.debts
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own debts"
  on public.debts
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own debts"
  on public.debts
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own debts"
  on public.debts
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

create table if not exists public.debt_payments (
  id uuid primary key default gen_random_uuid(),
  debt_id uuid not null references public.debts (id) on delete cascade,
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  amount numeric(14, 2) not null check (amount > 0),
  principal_amount numeric(14, 2),
  interest_amount numeric(14, 2),
  payment_date date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists debt_payments_user_id_idx on public.debt_payments (user_id);
create index if not exists debt_payments_debt_id_idx on public.debt_payments (debt_id);

alter table public.debt_payments enable row level security;

create policy "Users can view their own debt payments"
  on public.debt_payments
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own debt payments"
  on public.debt_payments
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own debt payments"
  on public.debt_payments
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own debt payments"
  on public.debt_payments
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

create table if not exists public.recurring_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  name text not null,
  amount numeric(14, 2) not null check (amount > 0),
  type text not null check (type in ('income', 'expense')),
  category_id uuid references public.categories (id) on delete restrict,
  frequency text not null check (frequency in ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
  start_date date not null,
  end_date date,
  next_occurrence date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint recurring_transactions_end_after_start check (end_date is null or end_date > start_date)
);

create index if not exists recurring_transactions_user_id_idx on public.recurring_transactions (user_id);
create index if not exists recurring_transactions_next_occurrence_idx on public.recurring_transactions (user_id, next_occurrence);

alter table public.recurring_transactions enable row level security;

create policy "Users can view their own recurring transactions"
  on public.recurring_transactions
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own recurring transactions"
  on public.recurring_transactions
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own recurring transactions"
  on public.recurring_transactions
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own recurring transactions"
  on public.recurring_transactions
  for delete
  using (auth.jwt() ->> 'sub' = user_id);
