import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../transactions/transactions_repository.dart';
import 'report_export_service.dart';

enum _Period { thisMonth, lastMonth, thisYear, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Period _period = _Period.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  List<TransactionRecord>? _transactions;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) _rangeFor(_Period period) {
    final now = DateTime.now();
    switch (period) {
      case _Period.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case _Period.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return (lastMonth, lastDayOfLastMonth);
      case _Period.thisYear:
        return (DateTime(now.year, 1, 1), now);
      case _Period.custom:
        return (_customStart ?? DateTime(now.year, now.month, 1), _customEnd ?? now);
    }
  }

  String _periodLabel() {
    final (start, end) = _rangeFor(_period);
    String fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${fmt(start)} to ${fmt(end)}';
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final (start, end) = _rangeFor(_period);
      final transactions = await TransactionsRepository.fetchTransactionsInRange(
        clerkUserId: widget.clerkUserId,
        start: start,
        end: end,
      );
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (reports): $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load transactions for this period. Check your connection and try again.";
      });
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (range == null) return;
    setState(() {
      _period = _Period.custom;
      _customStart = range.start;
      _customEnd = range.end;
    });
    _load();
  }

  Future<void> _export({required bool asPdf}) async {
    final transactions = _transactions;
    if (transactions == null) return;

    setState(() => _isExporting = true);
    try {
      final summary = ReportSummary.fromTransactions(transactions);
      final file = asPdf
          ? await ReportExportService.exportPdf(
              transactions: transactions,
              summary: summary,
              currency: widget.currency,
              title: 'PesaPlan Transaction Report',
              periodLabel: _periodLabel(),
              fileNamePrefix: 'pesaplan_report',
            )
          : await ReportExportService.exportCsv(
              transactions: transactions,
              fileNamePrefix: 'pesaplan_transactions',
            );

      if (!mounted) return;
      setState(() => _isExporting = false);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('EXPORT FAILED (${asPdf ? 'pdf' : 'csv'}): $e');
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't create the ${asPdf ? 'PDF' : 'CSV'}. Try again.")),
      );
    }
  }

  String _money(num value) => '${widget.currency} ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final summary = _transactions != null ? ReportSummary.fromTransactions(_transactions!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('This month'),
                    selected: _period == _Period.thisMonth,
                    onSelected: (_) {
                      setState(() => _period = _Period.thisMonth);
                      _load();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Last month'),
                    selected: _period == _Period.lastMonth,
                    onSelected: (_) {
                      setState(() => _period = _Period.lastMonth);
                      _load();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('This year'),
                    selected: _period == _Period.thisYear,
                    onSelected: (_) {
                      setState(() => _period = _Period.thisYear);
                      _load();
                    },
                  ),
                  ActionChip(
                    label: Text(_period == _Period.custom ? 'Custom: ${_periodLabel()}' : 'Custom range'),
                    onPressed: _pickCustomRange,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Builder(builder: (context) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    );
                  }

                  final transactions = _transactions!;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${transactions.length} transaction${transactions.length == 1 ? '' : 's'}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Income: ${_money(summary!.totalIncome)}',
                                        style: TextStyle(color: Colors.green.shade700)),
                                    Text('Expenses: ${_money(summary.totalExpense)}',
                                        style: TextStyle(color: Colors.red.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Net: ${_money(summary.net)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: (_isExporting || transactions.isEmpty) ? null : () => _export(asPdf: false),
                                icon: const Icon(Icons.table_chart_outlined),
                                label: const Text('Export CSV'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: (_isExporting || transactions.isEmpty) ? null : () => _export(asPdf: true),
                                icon: _isExporting
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('Export PDF'),
                              ),
                            ),
                          ],
                        ),
                        if (transactions.isEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'No transactions in this period — nothing to export yet.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
