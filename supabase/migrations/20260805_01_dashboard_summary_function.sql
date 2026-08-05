-- Computes the numbers the dashboard needs without ever pulling full
-- transaction history into the client. SECURITY INVOKER (the default) means
-- this runs with the caller's own privileges, so the existing RLS policy on
-- `transactions` still applies inside the function — passing a mismatched
-- p_user_id simply returns zero rows, it can't be used to read someone
-- else's data.

create or replace function public.get_dashboard_summary(p_user_id text)
returns table (
  lifetime_balance numeric,
  month_income numeric,
  month_expenses numeric
)
language sql
security invoker
stable
as $$
  select
    coalesce(sum(case
      when type = 'income' then amount
      when type = 'expense' then -amount
      else 0
    end), 0) as lifetime_balance,
    coalesce(sum(case
      when type = 'income' and transaction_date >= date_trunc('month', current_date)::date
      then amount else 0
    end), 0) as month_income,
    coalesce(sum(case
      when type = 'expense' and transaction_date >= date_trunc('month', current_date)::date
      then amount else 0
    end), 0) as month_expenses
  from public.transactions
  where user_id = p_user_id;
$$;

grant execute on function public.get_dashboard_summary(text) to authenticated;
