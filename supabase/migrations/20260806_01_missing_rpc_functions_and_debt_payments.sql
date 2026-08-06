-- This migration fixes two pre-existing bugs and adds one new function:
--
-- 1. `get_budget_progress` was called from budgets_repository.dart but was
--    never actually created — every budget detail view has been failing
--    with "function does not exist".
-- 2. `add_goal_contribution` was called from savings_goals_repository.dart
--    with the same problem — adding/withdrawing money on a goal has been
--    failing the same way.
-- 3. `add_debt_payment` is new, for the debt management feature, following
--    the same pattern as (2): atomically insert the payment row and update
--    the running balance in one transaction, instead of two separate
--    round-trips from the client that could partially fail.
--
-- All three use SECURITY INVOKER (the default) so the existing RLS policies
-- on the underlying tables still apply inside the function — a mismatched
-- p_user_id can't be used to read or write someone else's data, RLS blocks
-- it the same way it would a direct query.

create or replace function public.get_budget_progress(p_budget_id uuid, p_user_id text)
returns table (
  category_id uuid,
  category_name text,
  category_icon text,
  category_color text,
  allocated_amount numeric,
  spent_amount numeric
)
language sql
security invoker
stable
as $$
  select
    bc.category_id,
    c.name as category_name,
    c.icon as category_icon,
    c.color as category_color,
    bc.allocated_amount,
    coalesce((
      select sum(t.amount)
      from public.transactions t
      where t.category_id = bc.category_id
        and t.user_id = p_user_id
        and t.type = 'expense'
        and t.transaction_date >= b.period_start
        and t.transaction_date <= b.period_end
    ), 0) as spent_amount
  from public.budget_categories bc
  join public.budgets b on b.id = bc.budget_id
  join public.categories c on c.id = bc.category_id
  where bc.budget_id = p_budget_id
    and bc.user_id = p_user_id
    and b.user_id = p_user_id;
$$;

grant execute on function public.get_budget_progress(uuid, text) to authenticated;

create or replace function public.add_goal_contribution(
  p_goal_id uuid,
  p_user_id text,
  p_amount numeric,
  p_contribution_type text,
  p_note text default null
)
returns public.savings_goals
language plpgsql
security invoker
as $$
declare
  v_goal public.savings_goals;
begin
  if p_contribution_type not in ('deposit', 'withdrawal') then
    raise exception 'Invalid contribution_type: %', p_contribution_type;
  end if;

  select * into v_goal
  from public.savings_goals
  where id = p_goal_id and user_id = p_user_id
  for update;

  if not found then
    raise exception 'Goal not found.';
  end if;

  if p_contribution_type = 'withdrawal' and p_amount > v_goal.current_amount then
    raise exception 'Cannot withdraw more than the current goal balance.';
  end if;

  insert into public.goal_contributions (goal_id, user_id, amount, contribution_type, note)
  values (p_goal_id, p_user_id, p_amount, p_contribution_type, p_note);

  update public.savings_goals
  set current_amount = current_amount + (case when p_contribution_type = 'deposit' then p_amount else -p_amount end),
      updated_at = now()
  where id = p_goal_id and user_id = p_user_id
  returning * into v_goal;

  return v_goal;
end;
$$;

grant execute on function public.add_goal_contribution(uuid, text, numeric, text, text) to authenticated;

create or replace function public.add_debt_payment(
  p_debt_id uuid,
  p_user_id text,
  p_amount numeric,
  p_principal_amount numeric default null,
  p_interest_amount numeric default null,
  p_payment_date date default current_date
)
returns public.debts
language plpgsql
security invoker
as $$
declare
  v_debt public.debts;
  v_principal numeric;
begin
  select * into v_debt
  from public.debts
  where id = p_debt_id and user_id = p_user_id
  for update;

  if not found then
    raise exception 'Debt not found.';
  end if;

  -- If the payment isn't broken down into principal/interest, assume the
  -- whole amount reduces the balance. A payment can't reduce the balance
  -- below zero — an overpayment just closes it out at zero rather than
  -- erroring, since overpaying a debt isn't a user mistake worth blocking.
  v_principal := least(coalesce(p_principal_amount, p_amount), v_debt.current_balance);

  insert into public.debt_payments (debt_id, user_id, amount, principal_amount, interest_amount, payment_date)
  values (p_debt_id, p_user_id, p_amount, p_principal_amount, p_interest_amount, p_payment_date);

  update public.debts
  set current_balance = current_balance - v_principal,
      updated_at = now()
  where id = p_debt_id and user_id = p_user_id
  returning * into v_debt;

  return v_debt;
end;
$$;

grant execute on function public.add_debt_payment(uuid, text, numeric, numeric, numeric, date) to authenticated;
