import 'package:flutter/material.dart';

import '../transactions/transactions_repository.dart';
import 'budgets_repository.dart';

class _AllocationRow {
  _AllocationRow({this.categoryId, this.amountController});
  String? categoryId;
  final TextEditingController? amountController;
}

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final _nameController = TextEditingController();
  late DateTime _periodStart;
  late DateTime _periodEnd;

  List<CategoryRecord> _expenseCategories = [];
  bool _isLoadingCategories = true;
  final List<_AllocationRow> _rows = [_AllocationRow(amountController: TextEditingController())];

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodStart = DateTime(now.year, now.month, 1);
    _periodEnd = DateTime(now.year, now.month + 1, 0);
    _nameController.text = _monthLabel(now);
    _loadCategories();
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year} Budget';
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await TransactionsRepository.fetchCategories(
        clerkUserId: widget.clerkUserId,
        type: 'expense',
      );
      if (!mounted) return;
      setState(() {
        _expenseCategories = categories;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = "Couldn't load categories.";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _rows) {
      row.amountController?.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPeriodStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _periodStart = picked;
        if (!_periodEnd.isAfter(_periodStart)) {
          _periodEnd = _periodStart.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickPeriodEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodEnd.isAfter(_periodStart) ? _periodEnd : _periodStart.add(const Duration(days: 1)),
      firstDate: _periodStart.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _periodEnd = picked);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Give this budget a name.');
      return;
    }

    final allocations = <String, num>{};
    for (final row in _rows) {
      final categoryId = row.categoryId;
      final amountText = row.amountController?.text.trim() ?? '';
      if (categoryId == null || amountText.isEmpty) continue;
      final amount = num.tryParse(amountText);
      if (amount == null || amount <= 0) continue;
      allocations[categoryId] = amount;
    }

    if (allocations.isEmpty) {
      setState(() => _errorMessage = 'Add at least one category with an amount.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await BudgetsRepository.createBudget(
        clerkUserId: widget.clerkUserId,
        name: name,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        allocations: allocations,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = "Couldn't save this budget. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create budget')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Budget name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('From'),
                    subtitle: Text(_formatDate(_periodStart)),
                    onTap: _pickPeriodStart,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('To'),
                    subtitle: Text(_formatDate(_periodEnd)),
                    onTap: _pickPeriodEnd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Category budgets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_isLoadingCategories)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator())
            else
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: row.categoryId,
                          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                          items: _expenseCategories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (value) => setState(() => row.categoryId = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: row.amountController,
                          decoration: InputDecoration(
                            labelText: widget.currency,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _rows.length == 1
                            ? null
                            : () {
                                setState(() {
                                  row.amountController?.dispose();
                                  _rows.removeAt(index);
                                });
                              },
                      ),
                    ],
                  ),
                );
              }),
            TextButton.icon(
              onPressed: () => setState(() => _rows.add(_AllocationRow(amountController: TextEditingController()))),
              icon: const Icon(Icons.add),
              label: const Text('Add another category'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create budget'),
            ),
          ],
        ),
      ),
    );
  }
}
