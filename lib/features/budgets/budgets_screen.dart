import 'package:flutter/material.dart';

import 'budget_detail_screen.dart';
import 'budgets_repository.dart';
import 'create_budget_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<BudgetRecord> _budgets = [];
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
      final budgets = await BudgetsRepository.fetchBudgets(clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your budgets. Check your connection and try again.";
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateBudgetScreen(clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    if (created == true) {
      _load();
    }
  }

  Future<void> _openDetail(BudgetRecord budget) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BudgetDetailScreen(
          budget: budget,
          clerkUserId: widget.clerkUserId,
          currency: widget.currency,
        ),
      ),
    );
    if (changed == true) {
      _load();
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'budgets-fab',
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New budget'),
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

    if (_budgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Create a budget to take control of your spending.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: _openCreate, icon: const Icon(Icons.add), label: const Text('Create a budget')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96, top: 8),
        itemCount: _budgets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final budget = _budgets[index];
          return ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: Text(budget.name),
            subtitle: Text('${_formatDate(budget.periodStart)} to ${_formatDate(budget.periodEnd)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openDetail(budget),
          );
        },
      ),
    );
  }
}
