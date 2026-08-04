# Supabase setup for Pesaplan

## Migrations (apply in order)
1. `20260803_create_profiles.sql` — `profiles` table (Clerk user ↔ Supabase row)
2. `20260804_01_profiles_onboarding_settings.sql` — onboarding fields on `profiles` + `user_settings`
3. `20260804_02_categories_accounts.sql` — `categories` (with seeded system defaults) + `accounts`
4. `20260804_03_transactions_budgets.sql` — `transactions`, `budgets`, `budget_categories`
5. `20260804_04_goals_debts_recurring.sql` — `savings_goals`, `goal_contributions`, `debts`, `debt_payments`, `recurring_transactions`
6. `20260804_05_notifications_insights.sql` — `notifications`, `financial_insights`

Every user-owned table has RLS enabled with select/insert/update/delete
policies restricted to `auth.jwt() ->> 'sub' = user_id` (or `clerk_user_id`
on `profiles`).

## CRITICAL: none of this works until Clerk is registered as a Supabase Third-Party Auth provider

RLS policies check `auth.jwt() ->> 'sub'`. That's only populated if:

1. In the **Clerk Dashboard** → Supabase integration setup, activate the
   Supabase integration and copy your Clerk domain.
2. In the **Supabase Dashboard** → Authentication → Sign In / Providers →
   Third-Party Auth, add Clerk and paste that domain.

Until both of these are done, `auth.jwt()` is `null` for every request and
every policy above will correctly reject it — including for legitimate,
signed-in users. This is not a bug; it's RLS behaving correctly with no
verified identity attached to the request.

The Flutter app is already wired for this: `SupabaseService.initialize()`
passes an `accessToken` callback (`ClerkSessionBridge.currentToken`) that
returns the live Clerk session JWT, once `AuthGate` has registered a
`ClerkAuthState` (which happens on first frame after sign-in).

## Profile creation stays server-side

Even with the wiring above, initial profile creation goes through the
`sync-clerk-profile` Edge Function (which independently verifies the
caller's Clerk JWT via JWKS — see `CLERK_JWKS_URL` in
`edge-functions/README.md`), not a direct client insert. This avoids
depending on RLS timing during the very first request after a user's first
sign-in.

## Categories

Income/expense categories are seeded as shared system defaults
(`is_default = true`, `user_id = null`), visible to every user but never
editable or deletable by a client. Users can create their own custom
categories alongside the defaults. Deleting a category that's referenced by
`transactions`, `budget_categories`, or `recurring_transactions` is blocked
at the database level (`on delete restrict`) until those rows are
reassigned or removed.

