import 'package:flutter/material.dart';

import 'budgets_repository.dart';

class BudgetDetailScreen extends StatefulWidget {
  const BudgetDetailScreen({
    super.key,
    required this.budget,
    required this.clerkUserId,
    required this.currency,
  });

  final BudgetRecord budget;
  final String clerkUserId;
  final String currency;

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  List<BudgetCategoryProgress> _progress = [];
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
      final progress = await BudgetsRepository.fetchBudgetProgress(
        budgetId: widget.budget.id,
        clerkUserId: widget.clerkUserId,
      );
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load this budget's progress.";
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this budget?'),
        content: const Text(
          'This removes the budget and its category allocations. Your transactions are not affected.',
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
      await BudgetsRepository.deleteBudget(budgetId: widget.budget.id, clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete this budget. Try again.")),
      );
    }
  }

  Color _warningColor(String level, BuildContext context) {
    switch (level) {
      case 'exceeded':
        return Theme.of(context).colorScheme.error;
      case 'almost':
        return Colors.orange.shade800;
      case 'approaching':
        return Colors.amber.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  String _warningMessage(String level) {
    switch (level) {
      case 'exceeded':
        return "You've exceeded your budget.";
      case 'almost':
        return "You're almost at your budget limit.";
      case 'approaching':
        return "You're approaching your budget.";
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget.name),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete, tooltip: 'Delete budget'),
        ],
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

    final start = widget.budget.periodStart;
    final end = widget.budget.periodEnd;
    final daysRemaining = end.difference(DateTime.now()).inDays.clamp(0, 1 << 30);

    if (_progress.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No categories in this budget yet.'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} '
            'to ${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')} '
            '• $daysRemaining days remaining',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ..._progress.map((category) {
            final color = _warningColor(category.warningLevel, context);
            final warning = _warningMessage(category.warningLevel);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(category.categoryName, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${widget.currency} ${category.spentAmount.toStringAsFixed(0)} / '
                          '${widget.currency} ${category.allocatedAmount.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: category.percentUsed.clamp(0, 1),
                        minHeight: 8,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(category.percentUsed * 100).toStringAsFixed(0)}% used',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${widget.currency} ${category.remaining.toStringAsFixed(0)} remaining',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (warning.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(warning, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
