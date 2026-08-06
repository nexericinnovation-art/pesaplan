import 'package:flutter/material.dart';

import 'debts_repository.dart';

class DebtDetailScreen extends StatefulWidget {
  const DebtDetailScreen({super.key, required this.debt, required this.clerkUserId, required this.currency});

  final DebtRecord debt;
  final String clerkUserId;
  final String currency;

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late DebtRecord _debt;
  List<DebtPaymentRecord> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await DebtsRepository.fetchPayments(debtId: _debt.id, clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (debt payments): $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load this debt's payment history.";
      });
    }
  }

  Future<void> _openRecordPaymentDialog() async {
    final amountController = TextEditingController(
      text: _debt.minimumPayment != null ? _debt.minimumPayment!.toStringAsFixed(0) : '',
    );

    final amount = await showDialog<num>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record a payment'),
        content: TextField(
          controller: amountController,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Amount', prefixText: '${widget.currency} '),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, num.tryParse(amountController.text.trim())),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (amount == null || amount <= 0) return;

    try {
      final updated = await DebtsRepository.recordPayment(
        debtId: _debt.id,
        clerkUserId: widget.clerkUserId,
        amount: amount,
      );
      if (!mounted) return;
      setState(() => _debt = updated);
      _loadPayments();
    } catch (e) {
      debugPrint('RECORD PAYMENT FAILED: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't record that payment. Try again.")),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this debt?'),
        content: const Text('This permanently deletes the debt and its payment history.'),
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
      await DebtsRepository.deleteDebt(debtId: _debt.id, clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('DELETE FAILED (debt): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't delete this debt.")));
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _money(num value) => '${widget.currency} ${value.toStringAsFixed(0)}';

  /// A simple linear estimate (balance ÷ minimum payment), deliberately not
  /// interest-aware. An accurate amortization estimate needs the compounding
  /// period and payment-vs-interest relationship modelled carefully — worth
  /// doing as its own reviewed slice rather than folding untested financial
  /// math into this screen.
  int? get _estimatedMonthsRemaining {
    final payment = _debt.minimumPayment;
    if (payment == null || payment <= 0 || _debt.currentBalance <= 0) return null;
    return (_debt.currentBalance / payment).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final monthsRemaining = _estimatedMonthsRemaining;

    return Scaffold(
      appBar: AppBar(
        title: Text(_debt.loanName),
        actions: [
          IconButton(onPressed: _confirmDelete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPayments,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_debt.lender != null) ...[
                        Text(_debt.lender!, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        _debt.isPaidOff ? 'Paid off' : '${_money(_debt.currentBalance)} remaining',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: _debt.percentPaidOff, minHeight: 10),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_debt.percentPaidOff * 100).toStringAsFixed(0)}% paid off '
                        '(${_money(_debt.totalPaid)} of ${_money(_debt.originalAmount)})',
                      ),
                      if (_debt.interestRate != null) ...[
                        const SizedBox(height: 4),
                        Text('Interest rate: ${_debt.interestRate}% per year'),
                      ],
                      if (_debt.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Text('Next due: ${_formatDate(_debt.dueDate!)}'),
                      ],
                      const SizedBox(height: 12),
                      if (_debt.isPaidOff)
                        Text(
                          "This debt is fully paid off.",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700),
                        )
                      else if (monthsRemaining != null)
                        Text(
                          'At your minimum payment, roughly $monthsRemaining month'
                          '${monthsRemaining == 1 ? '' : 's'} remaining. '
                          'This estimate ignores interest — actual payoff time will be longer.',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        )
                      else
                        const Text('Add a minimum payment amount to estimate time remaining.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_debt.isPaidOff)
                FilledButton.icon(
                  onPressed: _openRecordPaymentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Record a payment'),
                ),
              const SizedBox(height: 24),
              Text('Payment history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Text(_errorMessage!)
              else if (_payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No payments recorded yet.'),
                )
              else
                ..._payments.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text(_money(p.amount)),
                      trailing: Text(_formatDate(p.paymentDate)),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
