import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_identity_service.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_status_view.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Shown once a Clerk session exists. Handles the one-time sequence every
/// signed-in user needs before they see any real screen:
///   1. Ensure a `profiles` row exists (via the Edge Function, which
///      verifies the session token server-side).
///   2. Fetch the full profile directly (RLS-protected, requires the Clerk
///      Third-Party Auth wiring to be live in Supabase).
///   3. Route to onboarding if it hasn't been completed yet, else the
///      dashboard.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  ProfileRecord? _profile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final auth = ClerkAuth.of(context, listen: false);
    final clerkUserId = AuthIdentityService.currentClerkUserId(auth);
    if (!AuthIdentityService.isAuthenticated(auth) || clerkUserId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final sessionToken = await AuthIdentityService.currentSessionToken(auth);
      if (sessionToken == null || sessionToken.isEmpty) {
        throw StateError('No session token available.');
      }

      // Step 1: make sure the row exists (server-verified).
      final ensuredProfile = await SupabaseService.ensureProfileForClerkUser(sessionToken: sessionToken);

      if (!mounted) return;

      if (ensuredProfile != null) {
        setState(() {
          _profile = ensuredProfile;
          _isLoading = false;
        });
        return;
      }

      // Step 2: read the profile through a server-side endpoint so the app
      // does not depend on client-side RLS being fully wired for this flow.
      final profile = await SupabaseService.fetchProfile(sessionToken: sessionToken);

      if (!mounted) return;

      if (profile == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Your profile exists but could not be read directly. '
              'This usually means Clerk is not yet registered as a Supabase '
              'Third-Party Auth provider — see supabase/README.md.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = error is StateError && error.message.isNotEmpty
            ? error.message
            : 'Your profile could not be loaded yet. This usually means the Clerk-to-Supabase connection is not configured correctly.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting things up…'),
            ],
          ),
        ),
      );
    }

    if (_hasError || _profile == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthStatusView(message: _errorMessage ?? 'Something went wrong.', isError: true),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadProfile, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    if (!profile.onboardingCompleted) {
      return OnboardingScreen(
        clerkUserId: profile.clerkUserId,
        onComplete: () {
          // Re-fetch rather than trusting local state, so anything the
          // server computed or defaulted is reflected immediately.
          _loadProfile();
        },
      );
    }

    return HomeScreen(
      clerkUserId: profile.clerkUserId,
      currency: (profile.currency ?? '').isNotEmpty ? profile.currency! : 'KES',
    );
  }
}
