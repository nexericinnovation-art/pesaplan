-- Categories: user-owned rows AND shared system-default rows (user_id null).
-- Accounts: cash/mpesa/bank/card/mobile_money wallets a user tracks balances in.

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id text references public.profiles (clerk_user_id) on delete cascade,
  name text not null,
  type text not null check (type in ('income', 'expense')),
  icon text,
  color text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_default_has_no_owner check (
    (is_default = true and user_id is null) or (is_default = false and user_id is not null)
  )
);

create index if not exists categories_user_id_idx on public.categories (user_id);

alter table public.categories enable row level security;

-- Everyone can see system defaults; users can additionally see their own custom categories.
create policy "Users can view default and own categories"
  on public.categories
  for select
  using (is_default = true or auth.jwt() ->> 'sub' = user_id);

-- Users may only ever insert their own, non-default categories.
create policy "Users can insert their own categories"
  on public.categories
  for insert
  with check (is_default = false and auth.jwt() ->> 'sub' = user_id);

-- Users may only edit/delete their own, non-default categories — system
-- defaults can never be edited or removed by a client.
create policy "Users can update their own categories"
  on public.categories
  for update
  using (is_default = false and auth.jwt() ->> 'sub' = user_id)
  with check (is_default = false and auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own categories"
  on public.categories
  for delete
  using (is_default = false and auth.jwt() ->> 'sub' = user_id);

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles (clerk_user_id) on delete cascade,
  name text not null,
  type text not null check (type in ('cash', 'mpesa', 'bank', 'card', 'mobile_money', 'other')),
  currency text not null default 'KES',
  balance numeric(14, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists accounts_user_id_idx on public.accounts (user_id);

alter table public.accounts enable row level security;

create policy "Users can view their own accounts"
  on public.accounts
  for select
  using (auth.jwt() ->> 'sub' = user_id);

create policy "Users can insert their own accounts"
  on public.accounts
  for insert
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can update their own accounts"
  on public.accounts
  for update
  using (auth.jwt() ->> 'sub' = user_id)
  with check (auth.jwt() ->> 'sub' = user_id);

create policy "Users can delete their own accounts"
  on public.accounts
  for delete
  using (auth.jwt() ->> 'sub' = user_id);

-- Seed system-default categories (shared across all users, never editable by clients).
insert into public.categories (name, type, icon, color, is_default, user_id)
values
  ('Salary', 'income', 'work', '#2E7D32', true, null),
  ('Business', 'income', 'business_center', '#2E7D32', true, null),
  ('Freelance', 'income', 'laptop_mac', '#2E7D32', true, null),
  ('Investment', 'income', 'trending_up', '#2E7D32', true, null),
  ('Rental Income', 'income', 'home_work', '#2E7D32', true, null),
  ('Gifts', 'income', 'card_giftcard', '#2E7D32', true, null),
  ('Other', 'income', 'more_horiz', '#2E7D32', true, null),
  ('Food', 'expense', 'restaurant', '#D84315', true, null),
  ('Transport', 'expense', 'directions_bus', '#D84315', true, null),
  ('Rent', 'expense', 'apartment', '#D84315', true, null),
  ('Utilities', 'expense', 'bolt', '#D84315', true, null),
  ('Airtime', 'expense', 'phone_android', '#D84315', true, null),
  ('Internet', 'expense', 'wifi', '#D84315', true, null),
  ('Shopping', 'expense', 'shopping_bag', '#D84315', true, null),
  ('Entertainment', 'expense', 'movie', '#D84315', true, null),
  ('Health', 'expense', 'local_hospital', '#D84315', true, null),
  ('Education', 'expense', 'school', '#D84315', true, null),
  ('Insurance', 'expense', 'shield', '#D84315', true, null),
  ('Debt Payment', 'expense', 'payments', '#D84315', true, null),
  ('Family', 'expense', 'family_restroom', '#D84315', true, null),
  ('Travel', 'expense', 'flight', '#D84315', true, null),
  ('Personal Care', 'expense', 'spa', '#D84315', true, null),
  ('Other', 'expense', 'more_horiz', '#D84315', true, null)
on conflict do nothing;
