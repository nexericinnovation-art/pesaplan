import 'package:flutter/material.dart';

import 'create_debt_screen.dart';
import 'debt_detail_screen.dart';
import 'debts_repository.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<DebtRecord> _debts = [];
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
      final debts = await DebtsRepository.fetchDebts(clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (debts): $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your debts. Check your connection and try again.";
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateDebtScreen(clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _openDetail(DebtRecord debt) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DebtDetailScreen(debt: debt, clerkUserId: widget.clerkUserId, currency: widget.currency),
      ),
    );
    _load();
  }

  String _money(num value) => '${widget.currency} ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debts')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debts-fab',
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New debt'),
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
            if (_debts.isEmpty) {
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
                              "You don't have any debts tracked yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _openCreate,
                              icon: const Icon(Icons.add),
                              label: const Text('Add a debt'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _debts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final debt = _debts[index];
                return Card(
                  child: ListTile(
                    onTap: () => _openDetail(debt),
                    title: Text(debt.loanName),
                    subtitle: Text(
                      debt.isPaidOff
                          ? 'Paid off'
                          : '${_money(debt.currentBalance)} of ${_money(debt.originalAmount)} remaining',
                    ),
                    trailing: SizedBox(
                      width: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: debt.percentPaidOff, minHeight: 6),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
