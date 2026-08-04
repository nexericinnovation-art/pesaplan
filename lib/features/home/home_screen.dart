import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

/// Dashboard placeholder. By the time this is shown, `RootGate` has already
/// confirmed the user has a synced profile and completed onboarding.
///
/// This is intentionally minimal — real dashboard content (balance,
/// income/expense summary, budget usage, recent transactions, financial
/// health score, etc.) is a separate build once the transactions/budgets
/// features exist. Building it now would mean either showing fake numbers
/// or an empty state pretending to be a finished feature — neither is
/// honest about what's actually implemented yet.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = ClerkAuth.of(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesaplan Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You're all set up.",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Transactions, budgets, and goals are coming in the next build.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
