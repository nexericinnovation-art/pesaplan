# Supabase Edge Functions for Pesaplan

The sync-clerk-profile function is intended to create or upsert a profile row in Supabase using the Clerk user ID.

## Required server-side environment variables
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY

Do not expose these values in the Flutter app.
