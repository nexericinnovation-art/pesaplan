import '../../core/services/supabase_service.dart';
import '../recurring/recurring_repository.dart';
import '../transactions/transactions_repository.dart';

class CategorySpendingChange {
  CategorySpendingChange({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
  });

  final String categoryName;
  final num currentAmount;
  final num previousAmount;

  num get absoluteChange => currentAmount - previousAmount;

  /// Null when there's nothing meaningful to divide by (previous month was
  /// zero) — callers must handle that as its own case ("new spending"),
  /// not as a fake 0% or a divide-by-zero.
  double? get percentChange => previousAmount > 0 ? (absoluteChange / previousAmount) * 100 : null;

  factory CategorySpendingChange.fromMap(Map<String, dynamic> map) {
    return CategorySpendingChange(
      categoryName: map['category_name'] as String,
      currentAmount: (map['current_amount'] as num?) ?? 0,
      previousAmount: (map['previous_amount'] as num?) ?? 0,
    );
  }
}

class BudgetRiskCategory {
  BudgetRiskCategory({
    required this.categoryName,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.percentUsed,
    required this.periodEnd,
  });

  final String categoryName;
  final num allocatedAmount;
  final num spentAmount;
  final num percentUsed;
  final DateTime periodEnd;

  factory BudgetRiskCategory.fromMap(Map<String, dynamic> map) {
    return BudgetRiskCategory(
      categoryName: map['category_name'] as String,
      allocatedAmount: (map['allocated_amount'] as num?) ?? 0,
      spentAmount: (map['spent_amount'] as num?) ?? 0,
      percentUsed: (map['percent_used'] as num?) ?? 0,
      periodEnd: DateTime.parse(map['period_end'].toString()),
    );
  }
}

class InsightsRepository {
  static Future<List<CategorySpendingChange>> fetchCategoryChanges({required String clerkUserId}) async {
    final rows = await SupabaseService.client.rpc(
      'get_category_spending_changes',
      params: {'p_user_id': clerkUserId},
    ) as List;
    return rows.map((row) => CategorySpendingChange.fromMap(row as Map<String, dynamic>)).toList();
  }

  static Future<List<BudgetRiskCategory>> fetchBudgetRisks({required String clerkUserId}) async {
    final rows = await SupabaseService.client.rpc(
      'get_budget_risk_categories',
      params: {'p_user_id': clerkUserId},
    ) as List;
    return rows.map((row) => BudgetRiskCategory.fromMap(row as Map<String, dynamic>)).toList();
  }

  /// Assembles every insight from real, already-fetched values — nothing in
  /// this method invents a number. A category change below the noise
  /// threshold, or a budget under 70% used, simply produces no line.
  static List<String> buildInsights({
    required DashboardSummary summary,
    required List<CategorySpendingChange> categoryChanges,
    required List<BudgetRiskCategory> budgetRisks,
    required List<RecurringTransactionRecord> recurringItems,
    required String currency,
  }) {
    final lines = <String>[];
    String money(num v) => '$currency ${v.toStringAsFixed(0)}';

    // Income vs. expenses this month — reuses the same DashboardSummary the
    // Home screen already fetched.
    if (summary.monthIncome > 0 || summary.monthExpenses > 0) {
      if (summary.monthExpenses > summary.monthIncome) {
        lines.add('Your expenses exceeded your income this month, by ${money(summary.monthExpenses - summary.monthIncome)}.');
      } else if (summary.monthIncome > 0) {
        lines.add('Your income exceeded your expenses this month by ${money(summary.monthSavings)}.');
      }
    }

    // Category spending changes — only surface changes large enough to be
    // meaningful, not noise from small categories swinging wildly in %.
    const minMeaningfulAmount = 500;
    final movers = categoryChanges.where((c) {
      final big = c.currentAmount >= minMeaningfulAmount || c.previousAmount >= minMeaningfulAmount;
      if (!big) return false;
      if (c.previousAmount == 0) return c.currentAmount >= minMeaningfulAmount;
      final pct = c.percentChange;
      return pct != null && pct.abs() >= 15;
    }).toList()
      ..sort((a, b) => b.absoluteChange.abs().compareTo(a.absoluteChange.abs()));

    for (final change in movers.take(3)) {
      if (change.previousAmount == 0) {
        lines.add('New spending in ${change.categoryName} this month: ${money(change.currentAmount)}.');
      } else if (change.currentAmount == 0) {
        lines.add('No ${change.categoryName} spending this month, down from ${money(change.previousAmount)} last month.');
      } else {
        final pct = change.percentChange!;
        final direction = pct > 0 ? 'more' : 'less';
        lines.add(
          'You spent ${pct.abs().toStringAsFixed(0)}% $direction on ${change.categoryName} '
          'this month than last month.',
        );
      }
    }

    // Budget risk — already pre-filtered to >=70% used by the SQL function.
    for (final risk in budgetRisks.take(3)) {
      final daysLeft = risk.periodEnd.difference(DateTime.now()).inDays;
      if (risk.percentUsed >= 100) {
        lines.add(
          "You've exceeded your ${risk.categoryName} budget by ${money(risk.spentAmount - risk.allocatedAmount)}.",
        );
      } else if (risk.percentUsed >= 90) {
        lines.add(
          "You're almost at your ${risk.categoryName} budget limit "
          "(${risk.percentUsed.toStringAsFixed(0)}% used, ${daysLeft.clamp(0, 999)} day"
          "${daysLeft == 1 ? '' : 's'} left).",
        );
      } else {
        lines.add(
          "You're approaching your ${risk.categoryName} budget "
          "(${risk.percentUsed.toStringAsFixed(0)}% used).",
        );
      }
    }

    // Upcoming recurring payments — reuses RecurringTransactionRecord's
    // existing isDueSoon/isActive logic rather than re-deriving it.
    final dueSoon = recurringItems.where((r) => r.isActive && r.isDueSoon).length;
    if (dueSoon > 0) {
      lines.add('You have $dueSoon recurring payment${dueSoon == 1 ? '' : 's'} scheduled within the next 7 days.');
    }

    return lines;
  }
}
