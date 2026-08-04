# Supabase setup for Pesaplan

## Profiles table

Apply the migration in [migrations/20260803_create_profiles.sql](migrations/20260803_create_profiles.sql) to create the user-owned profile table.

The table stores:
- id
- clerk_user_id
- created_at
- updated_at

Row Level Security is enabled and policies enforce that a user can only access their own profile row.
