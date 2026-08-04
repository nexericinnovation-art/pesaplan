import 'package:flutter/material.dart';

import 'transactions_repository.dart';

const _paymentMethods = ['cash', 'mpesa', 'bank', 'card', 'mobile_money', 'other'];

const _paymentMethodLabels = {
  'cash': 'Cash',
  'mpesa': 'M-Pesa',
  'bank': 'Bank',
  'card': 'Card',
  'mobile_money': 'Mobile Money',
  'other': 'Other',
};

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    required this.clerkUserId,
    required this.currency,
    this.existing,
  });

  final String clerkUserId;
  final String currency;
  final TransactionRecord? existing;

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'expense';
  DateTime _date = DateTime.now();
  String? _paymentMethod;
  String? _categoryId;

  List<CategoryRecord> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _amountController.text = existing.amount.toString();
      _descriptionController.text = existing.description ?? '';
      _merchantController.text = existing.merchant ?? '';
      _notesController.text = existing.notes ?? '';
      _date = existing.transactionDate;
      _paymentMethod = existing.paymentMethod;
      _categoryId = existing.categoryId;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await TransactionsRepository.fetchCategories(
        clerkUserId: widget.clerkUserId,
        type: _type == 'transfer' ? null : _type,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        if (_categoryId != null && !categories.any((c) => c.id == _categoryId)) {
          _categoryId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = "Couldn't load categories. Check your connection.";
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final amount = num.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Enter a valid amount.';
      });
      return;
    }

    try {
      if (_isEditing) {
        await TransactionsRepository.updateTransaction(
          id: widget.existing!.id,
          clerkUserId: widget.clerkUserId,
          updates: {
            'type': _type,
            'amount': amount,
            'transaction_date': _date.toIso8601String().split('T').first,
            'category_id': _categoryId,
            'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            'merchant': _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            'payment_method': _paymentMethod,
          },
        );
      } else {
        await TransactionsRepository.createTransaction(
          clerkUserId: widget.clerkUserId,
          type: _type,
          amount: amount,
          currency: widget.currency,
          transactionDate: _date,
          categoryId: _categoryId,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          paymentMethod: _paymentMethod,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = "Couldn't save this transaction. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit transaction' : 'Add transaction')),
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
                  ButtonSegment(value: 'transfer', label: Text('Transfer')),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    _categoryId = null;
                    _isLoadingCategories = true;
                  });
                  _loadCategories();
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                autofocus: !_isEditing,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${widget.currency} ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = num.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_type != 'transfer') ...[
                _isLoadingCategories
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (value) => setState(() => _categoryId = value),
                      ),
                const SizedBox(height: 16),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder()),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(_paymentMethodLabels[m]!)))
                    .toList(),
                onChanged: (value) => setState(() => _paymentMethod = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(labelText: 'Merchant (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                maxLines: 2,
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
                    : Text(_isEditing ? 'Save changes' : 'Add transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
