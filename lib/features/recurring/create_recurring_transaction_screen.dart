import 'package:flutter/material.dart';

import '../transactions/transactions_repository.dart' show CategoryRecord;
import 'recurring_repository.dart';

class CreateRecurringTransactionScreen extends StatefulWidget {
  const CreateRecurringTransactionScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<CreateRecurringTransactionScreen> createState() => _CreateRecurringTransactionScreenState();
}

class _CreateRecurringTransactionScreenState extends State<CreateRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _type = 'expense';
  String _frequency = 'monthly';
  String? _categoryId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  List<CategoryRecord> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _errorMessage;

  static const _frequencies = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await RecurringTransactionsRepository.fetchCategories(clerkUserId: widget.clerkUserId, type: _type);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryId = null;
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (categories): $e');
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = "Couldn't load categories. Check your connection.";
      });
    }
  }

  void _onTypeChanged(String type) {
    setState(() => _type = type);
    _loadCategories();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: isStart ? DateTime.now().subtract(const Duration(days: 365)) : _startDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && !_endDate!.isAfter(_startDate)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await RecurringTransactionsRepository.create(
        clerkUserId: widget.clerkUserId,
        name: _nameController.text.trim(),
        amount: num.parse(_amountController.text.trim()),
        type: _type,
        frequency: _frequency,
        startDate: _startDate,
        categoryId: _categoryId,
        endDate: _endDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('SAVE FAILED (recurring): $e');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = "Couldn't save. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New recurring transaction')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => _onTypeChanged(s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Rent, Netflix, Salary',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Give this a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${widget.currency} ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = num.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isLoadingCategories)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category (optional)', border: OutlineInputBorder()),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1))))
                    .toList(),
                onChanged: (value) => setState(() => _frequency = value ?? _frequency),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date'),
                subtitle: Text(_formatDate(_startDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End date (optional)'),
                subtitle: Text(_endDate == null ? 'No end date — repeats indefinitely' : _formatDate(_endDate!)),
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _endDate = null),
                      )
                    : const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
