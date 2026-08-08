import 'package:flutter/material.dart';

import '../recurring/recurring_repository.dart';
import '../transactions/transactions_repository.dart';
import 'insights_repository.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.clerkUserId, required this.currency});

  final String clerkUserId;
  final String currency;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<String>? _insights;
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
      final results = await Future.wait([
        TransactionsRepository.fetchDashboardSummary(clerkUserId: widget.clerkUserId),
        InsightsRepository.fetchCategoryChanges(clerkUserId: widget.clerkUserId),
        InsightsRepository.fetchBudgetRisks(clerkUserId: widget.clerkUserId),
        RecurringTransactionsRepository.fetchAll(clerkUserId: widget.clerkUserId),
      ]);

      final summary = results[0] as DashboardSummary;
      final categoryChanges = results[1] as List<CategorySpendingChange>;
      final budgetRisks = results[2] as List<BudgetRiskCategory>;
      final recurringItems = results[3] as List<RecurringTransactionRecord>;

      final insights = InsightsRepository.buildInsights(
        summary: summary,
        categoryChanges: categoryChanges,
        budgetRisks: budgetRisks,
        recurringItems: recurringItems,
        currency: widget.currency,
      );

      if (!mounted) return;
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAILED (insights): $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your insights. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
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

            final insights = _insights ?? [];
            if (insights.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.insights_rounded, size: 48, color: Colors.black38),
                            SizedBox(height: 16),
                            Text(
                              "Nothing stands out yet.",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Insights show up once there's enough real activity to compare — "
                              "spending changes, budget risk, and upcoming bills.",
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

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: insights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 20, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(child: Text(insights[index])),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
