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
  String _strategy = 'snowball'; // 'snowball' | 'avalanche'

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

  /// Snowball orders by smallest balance first (fastest visible wins, for
  /// motivation). Avalanche orders by highest interest rate first (least
  /// total interest paid, mathematically optimal). Debts with no interest
  /// rate on file sort last under avalanche, since we can't rank what we
  /// don't know.
  List<DebtRecord> _ordered(List<DebtRecord> debts, String strategy) {
    final sorted = List<DebtRecord>.from(debts);
    if (strategy == 'snowball') {
      sorted.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
    } else {
      sorted.sort((a, b) {
        final rateA = a.interestRate;
        final rateB = b.interestRate;
        if (rateA == null && rateB == null) return 0;
        if (rateA == null) return 1;
        if (rateB == null) return -1;
        return rateB.compareTo(rateA);
      });
    }
    return sorted;
  }

  Widget _buildStrategyCard(List<DebtRecord> unpaidDebts) {
    final ordered = _ordered(unpaidDebts, _strategy);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payoff order', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'snowball', label: Text('Snowball')),
                ButtonSegment(value: 'avalanche', label: Text('Avalanche')),
              ],
              selected: {_strategy},
              onSelectionChanged: (selection) => setState(() => _strategy = selection.first),
            ),
            const SizedBox(height: 12),
            Text(
              _strategy == 'snowball'
                  ? 'Pay off smallest balances first for quick, motivating wins.'
                  : 'Pay off highest interest rates first to minimize total interest paid.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < ordered.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(ordered[i].loanName)),
                    Text(
                      _strategy == 'avalanche' && ordered[i].interestRate != null
                          ? '${ordered[i].interestRate}%'
                          : _money(ordered[i].currentBalance),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'This is general educational information, not personalized financial advice. '
              'Consider your own situation, or speak with a qualified advisor, before deciding.',
              style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

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
            final unpaidDebts = _debts.where((d) => !d.isPaidOff).toList();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (unpaidDebts.length >= 2) ...[
                  _buildStrategyCard(unpaidDebts),
                  const SizedBox(height: 20),
                ],
                for (final debt in _debts) ...[
                  Card(
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
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}
