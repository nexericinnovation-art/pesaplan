import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../app/config/environment.dart';
import 'auth_status_view.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasConfig = AppEnvironment.hasRequiredClientConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Pesaplan'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: hasConfig
              ? const ClerkAuthentication()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthStatusView(
                      message: 'Missing public configuration. Configure Clerk and Supabase before continuing.',
                      isError: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Use values from your public environment configuration only.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
