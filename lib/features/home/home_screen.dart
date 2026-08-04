import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_identity_service.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_status_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _statusMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncProfile();
    });
  }

  Future<void> _syncProfile() async {
    final auth = ClerkAuth.of(context, listen: false);
    if (!AuthIdentityService.isAuthenticated(auth)) {
      return;
    }

    final sessionToken = await AuthIdentityService.currentSessionToken(auth);
    if (sessionToken == null || sessionToken.isEmpty) {
      return;
    }

    setState(() {
      _hasError = false;
      _statusMessage = 'Syncing your identity with Supabase and the Edge Function…';
    });

    try {
      final profile = await SupabaseService.ensureProfileForClerkUser(
        sessionToken: sessionToken,
      );
      if (mounted) {
        setState(() {
          _statusMessage = profile == null
              ? 'Profile creation is pending.'
              : 'Identity ready for protected data access.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Could not sync your profile yet. Check your Supabase configuration.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ClerkAuth.of(context, listen: false);
    final clerkUser = auth.client.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesaplan Dashboard'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clerkUser == null ? 'Signed out' : 'Authenticated user ready',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (clerkUser != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Clerk user ID ready for Supabase identity mapping.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              if (_statusMessage != null) ...[
                AuthStatusView(
                  message: _statusMessage!,
                  isError: _hasError,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  await auth.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
