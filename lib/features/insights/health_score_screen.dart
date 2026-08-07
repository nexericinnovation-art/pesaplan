import 'package:flutter/material.dart';

import 'health_score_repository.dart';

class HealthScoreScreen extends StatefulWidget {
  const HealthScoreScreen({super.key, required this.clerkUserId});

  final String clerkUserId;

  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen> {
  HealthScoreRecord? _record;
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
      final record = await HealthScoreRepository.fetch(clerkUserId: widget.clerkUserId);
      if (!mounted) return;
      setState(() {
        _record = record;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (health score): $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your health score. Check your connection and try again.";
      });
    }
  }

  Color _scoreColor(num score) {
    if (score >= 70) return Colors.green.shade600;
    if (score >= 40) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PesaPlan Financial Health Score')),
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

            final record = _record!;
            if (record.score == null) {
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
                            const Icon(Icons.query_stats_rounded, size: 48, color: Colors.black38),
                            const SizedBox(height: 16),
                            const Text(
                              "Not enough data yet to calculate a score.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Add some transactions this month — the score is based on real "
                              "income, spending, budgets, debts, and goals, so there's nothing "
                              "to show until there's real activity to measure.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final recommendations = record.buildRecommendations();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: (record.score! / 100).clamp(0, 1).toDouble(),
                                strokeWidth: 12,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(_scoreColor(record.score!)),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  record.score!.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: _scoreColor(record.score!),
                                  ),
                                ),
                                const Text('out of 100', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Based on ${record.componentsIncluded} of 5 factors this month',
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('What this is based on', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (record.savingsRateScore != null)
                  _buildComponentRow('Savings rate', record.savingsRateScore!),
                if (record.expenseRatioScore != null)
                  _buildComponentRow('Spending vs. income', record.expenseRatioScore!),
                if (record.budgetAdherenceScore != null)
                  _buildComponentRow('Budget adherence', record.budgetAdherenceScore!),
                if (record.debtToIncomeScore != null)
                  _buildComponentRow('Debt-to-income', record.debtToIncomeScore!),
                if (record.goalProgressScore != null)
                  _buildComponentRow('Goal progress', record.goalProgressScore!),
                if (recommendations.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final line in recommendations)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(line)),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'This is the PesaPlan Financial Health Score — a general, educational '
                  'indicator based on your own data, not a credit score or official '
                  'financial rating, and not personalized financial advice.',
                  style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildComponentRow(String label, num score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_scoreColor(score)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 36, child: Text(score.toStringAsFixed(0), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
