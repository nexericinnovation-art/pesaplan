import 'package:flutter/material.dart';

import 'create_recurring_transaction_screen.dart';
import 'recurring_repository.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  List<RecurringTransactionRecord> _items = [];
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
      final items = await RecurringTransactionsRepository.fetchAll(clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (recurring): $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load recurring transactions. Check your connection and try again.";
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateRecurringTransactionScreen(clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _confirmDelete(RecurringTransactionRecord item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this recurring transaction?'),
        content: Text('"${item.name}" will stop appearing here. This does not affect past transactions already recorded.'),
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
      await RecurringTransactionsRepository.delete(id: item.id, clerkUserId: widget.clerkUserId);
      _load();
    } catch (e) {
      debugPrint('DELETE FAILED (recurring): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete this. Try again.")),
      );
    }
  }

  String _money(num value) => '${widget.currency} ${value.toStringAsFixed(0)}';

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _frequencyLabel(String frequency) => frequency[0].toUpperCase() + frequency.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recurring-fab',
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New recurring'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Builder(builder: (context) {
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
            if (_items.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "No recurring transactions yet — rent, salary, subscriptions.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _openCreate,
                              icon: const Icon(Icons.add),
                              label: const Text('Add one'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final dueSoon = _items.where((i) => i.isActive && i.isDueSoon).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (dueSoon.isNotEmpty) ...[
                  Text('Upcoming in the next 7 days', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final item in dueSoon)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('Due ${_formatDate(item.nextOccurrence)}'),
                        trailing: Text(
                          '${item.type == 'income' ? '+' : '-'}${_money(item.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item.type == 'income' ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
                Text('All recurring transactions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final item in _items)
                  Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${_frequencyLabel(item.frequency)} · ${item.categoryName ?? 'Uncategorized'}'
                        '${item.isActive ? '' : ' · Ended'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.type == 'income' ? '+' : '-'}${_money(item.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: item.type == 'income' ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _confirmDelete(item),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
