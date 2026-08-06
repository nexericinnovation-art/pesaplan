import 'package:flutter/material.dart';

import 'debts_repository.dart';

class CreateDebtScreen extends StatefulWidget {
  const CreateDebtScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<CreateDebtScreen> createState() => _CreateDebtScreenState();
}

class _CreateDebtScreenState extends State<CreateDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanNameController = TextEditingController();
  final _lenderController = TextEditingController();
  final _originalAmountController = TextEditingController();
  final _currentBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _minimumPaymentController = TextEditingController();
  String? _paymentFrequency;
  DateTime? _dueDate;

  bool _isSaving = false;
  String? _errorMessage;

  static const _frequencies = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  void dispose() {
    _loanNameController.dispose();
    _lenderController.dispose();
    _originalAmountController.dispose();
    _currentBalanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
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
      await DebtsRepository.createDebt(
        clerkUserId: widget.clerkUserId,
        loanName: _loanNameController.text.trim(),
        lender: _lenderController.text.trim().isEmpty ? null : _lenderController.text.trim(),
        originalAmount: num.parse(_originalAmountController.text.trim()),
        currentBalance: num.tryParse(_currentBalanceController.text.trim()),
        interestRate: num.tryParse(_interestRateController.text.trim()),
        minimumPayment: num.tryParse(_minimumPaymentController.text.trim()),
        paymentFrequency: _paymentFrequency,
        dueDate: _dueDate,
        startDate: DateTime.now(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('SAVE FAILED (debt): $e');
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
      appBar: AppBar(title: const Text('Add a debt')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _loanNameController,
                decoration: const InputDecoration(labelText: 'Loan name', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Give this debt a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lenderController,
                decoration: const InputDecoration(labelText: 'Lender (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originalAmountController,
                decoration: InputDecoration(
                  labelText: 'Original amount',
                  prefixText: '${widget.currency} ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = num.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid original amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentBalanceController,
                decoration: InputDecoration(
                  labelText: 'Current balance (optional — defaults to original amount)',
                  prefixText: '${widget.currency} ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestRateController,
                decoration: const InputDecoration(
                  labelText: 'Interest rate % (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minimumPaymentController,
                decoration: InputDecoration(
                  labelText: 'Minimum payment (optional)',
                  prefixText: '${widget.currency} ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentFrequency,
                decoration: const InputDecoration(
                  labelText: 'Payment frequency (optional)',
                  border: OutlineInputBorder(),
                ),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1))))
                    .toList(),
                onChanged: (value) => setState(() => _paymentFrequency = value),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Next due date (optional)'),
                subtitle: Text(_dueDate == null ? 'No due date set' : _formatDate(_dueDate!)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDueDate,
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
                    : const Text('Add debt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
