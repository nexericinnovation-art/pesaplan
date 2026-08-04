import 'package:clerk_flutter/clerk_flutter.dart';

/// Supabase's `accessToken` callback (passed to `Supabase.initialize`) has to
/// be registered before `runApp()` builds the widget tree, so it cannot read
/// `ClerkAuth.of(context)` directly — there is no context yet at that point,
/// and the callback needs to keep working for the lifetime of the app.
///
/// This bridge solves that: any widget with access to the live
/// [ClerkAuthState] (see `AuthGate`) registers it once via [register]. The
/// Supabase `accessToken` callback then reads through [currentToken], which
/// always uses whatever [ClerkAuthState] was most recently registered.
///
/// This only matters for *direct* Supabase client calls (e.g.
/// `SupabaseService.client.from('transactions')...`). It has no effect on
/// calls to the `sync-clerk-profile` Edge Function, which independently
/// verify a session token you pass explicitly.
class ClerkSessionBridge {
  ClerkSessionBridge._();

  static ClerkAuthState? _authState;

  static void register(ClerkAuthState authState) {
    _authState = authState;
  }

  /// Used as the Supabase `accessToken` callback. Returns `null` when signed
  /// out, which makes Supabase fall back to the anon key (RLS still applies,
  /// `auth.jwt()` will simply be null — every policy in our schema denies
  /// that case).
  static Future<String?> currentToken() async {
    final authState = _authState;
    if (authState == null || authState.client.user == null) {
      return null;
    }
    final sessionToken = await authState.sessionToken();
    return sessionToken.jwt;
  }
}
