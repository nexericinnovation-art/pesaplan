import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../transactions/add_edit_transaction_screen.dart';
import '../transactions/transactions_repository.dart';
import '../transactions/transactions_screen.dart';

/// The real dashboard. Every number here is computed from the user's actual
/// transactions (via the `get_dashboard_summary` SQL function) — no fake or
/// placeholder figures. Budget usage, debt balance, financial health score,
/// and goal progress are intentionally left out until those features exist
/// with real data behind them.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardSummary? _summary;
  List<TransactionRecord> _recentTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        TransactionsRepository.fetchDashboardSummary(clerkUserId: widget.clerkUserId),
        TransactionsRepository.fetchTransactions(clerkUserId: widget.clerkUserId, limit: 5),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as DashboardSummary;
        _recentTransactions = results[1] as List<TransactionRecord>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your dashboard. Check your connection and try again.";
      });
    }
  }

  Future<void> _openAddTransaction() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    if (saved == true) {
      _load();
    }
  }

  Future<void> _openAllTransactions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    // Numbers may have changed while the user was on the transactions screen.
    _load();
  }

  String _money(num value) {
    final isNegative = value < 0;
    final formatted = value.abs().toStringAsFixed(2);
    return '${isNegative ? '-' : ''}${widget.currency} $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ClerkAuth.of(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesaplan Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async => auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final summary = _summary!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current balance', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    _money(summary.lifetimeBalance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: summary.lifetimeBalance < 0
                              ? Theme.of(context).colorScheme.error
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Income this month',
                  value: _money(summary.monthIncome),
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Expenses this month',
                  value: _money(summary.monthExpenses),
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            label: 'Savings this month',
            value: _money(summary.monthSavings),
            color: summary.monthSavings >= 0 ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
            fullWidth: true,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
              TextButton(onPressed: _openAllTransactions, child: const Text('View all')),
            ],
          ),
          if (_recentTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "You haven't added any transactions yet.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _openAddTransaction,
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first transaction'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: _recentTransactions.map((transaction) {
                  final isIncome = transaction.type == 'income';
                  final sign = isIncome ? '+' : (transaction.type == 'expense' ? '-' : '');
                  return ListTile(
                    leading: CircleAvatar(child: Text(transaction.categoryName?.substring(0, 1) ?? '?')),
                    title: Text(
                      transaction.description?.isNotEmpty == true
                          ? transaction.description!
                          : (transaction.categoryName ?? 'Uncategorized'),
                    ),
                    subtitle: Text(
                      '${transaction.transactionDate.year}-'
                      '${transaction.transactionDate.month.toString().padLeft(2, '0')}-'
                      '${transaction.transactionDate.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: Text(
                      '$sign${transaction.currency} ${transaction.amount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green.shade700 : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.color, this.fullWidth = false});

  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
