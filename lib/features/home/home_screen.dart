import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../transactions/transactions_screen.dart';

/// Dashboard placeholder. By the time this is shown, `RootGate` has already
/// confirmed the user has a synced profile and completed onboarding.
///
/// This is intentionally minimal — real dashboard content (balance,
/// income/expense summary, budget usage, recent transactions, financial
/// health score, etc.) is a separate build once there's enough transaction
/// history to compute it honestly. Building it now would mean either
/// showing fake numbers or an empty state pretending to be a finished
/// feature — neither is honest about what's actually implemented yet.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

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
                'Budgets, goals, and reports are coming in the next build.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TransactionsScreen(clerkUserId: clerkUserId, currency: currency),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Transactions'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
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
