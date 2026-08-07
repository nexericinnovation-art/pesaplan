import 'package:flutter/material.dart';

import 'add_edit_transaction_screen.dart';
import 'transactions_repository.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionRecord> _transactions = [];
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
      final transactions = await TransactionsRepository.fetchTransactions(clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (transactions): $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your transactions. Check your connection and try again.";
      });
    }
  }

  Future<void> _openAdd() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    if (saved == true) {
      _load();
    }
  }

  Future<void> _openEdit(TransactionRecord transaction) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          clerkUserId: widget.clerkUserId,
          currency: widget.currency,
          existing: transaction,
        ),
      ),
    );
    if (saved == true) {
      _load();
    }
  }

  Future<void> _confirmDelete(TransactionRecord transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          'This will permanently delete this ${transaction.type} of '
          '${transaction.currency} ${transaction.amount}. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await TransactionsRepository.deleteTransaction(id: transaction.id, clerkUserId: widget.clerkUserId);
      _load();
    } catch (e) {
      debugPrint('DELETE FAILED (transaction): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete this transaction. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transactions-fab',
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
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

    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "You haven't added any transactions yet.",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add your first transaction'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          final isIncome = transaction.type == 'income';
          final sign = isIncome ? '+' : (transaction.type == 'expense' ? '-' : '');
          final amountColor = isIncome ? Colors.green.shade700 : Theme.of(context).colorScheme.onSurface;

          return Dismissible(
            key: ValueKey(transaction.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              await _confirmDelete(transaction);
              return false; // we handle removal via reload, not the dismiss animation
            },
            child: ListTile(
              onTap: () => _openEdit(transaction),
              leading: CircleAvatar(child: Text(transaction.categoryName?.substring(0, 1) ?? '?')),
              title: Text(transaction.description?.isNotEmpty == true
                  ? transaction.description!
                  : (transaction.categoryName ?? 'Uncategorized')),
              subtitle: Text(
                '${transaction.categoryName ?? 'Uncategorized'} • '
                '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}-${transaction.transactionDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: Text(
                '$sign${transaction.currency} ${transaction.amount}',
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}