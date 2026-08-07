import '../../core/services/supabase_service.dart';

class HealthScoreRecord {
  HealthScoreRecord({
    required this.componentsIncluded,
    this.score,
    this.savingsRate,
    this.savingsRateScore,
    this.expenseRatio,
    this.expenseRatioScore,
    this.budgetAdherenceScore,
    this.debtToIncomeRatio,
    this.debtToIncomeScore,
    this.goalProgressScore,
  });

  /// Null means there wasn't enough real data this month to compute a score
  /// at all — the UI must show "not enough data yet", never a fabricated
  /// number.
  final num? score;
  final int componentsIncluded;
  final num? savingsRate;
  final num? savingsRateScore;
  final num? expenseRatio;
  final num? expenseRatioScore;
  final num? budgetAdherenceScore;
  final num? debtToIncomeRatio;
  final num? debtToIncomeScore;
  final num? goalProgressScore;

  factory HealthScoreRecord.fromMap(Map<String, dynamic> map) {
    return HealthScoreRecord(
      score: map['score'] as num?,
      componentsIncluded: (map['components_included'] as num?)?.toInt() ?? 0,
      savingsRate: map['savings_rate'] as num?,
      savingsRateScore: map['savings_rate_score'] as num?,
      expenseRatio: map['expense_ratio'] as num?,
      expenseRatioScore: map['expense_ratio_score'] as num?,
      budgetAdherenceScore: map['budget_adherence_score'] as num?,
      debtToIncomeRatio: map['debt_to_income_ratio'] as num?,
      debtToIncomeScore: map['debt_to_income_score'] as num?,
      goalProgressScore: map['goal_progress_score'] as num?,
    );
  }

  /// Deterministic, data-driven recommendations — every line here is
  /// derived directly from a real computed value, not written as generic
  /// filler. A component that was excluded (null) simply produces no line,
  /// rather than a guessed one.
  List<String> buildRecommendations() {
    final lines = <String>[];

    if (savingsRateScore != null && savingsRateScore! < 50) {
      final pct = ((savingsRate ?? 0) * 100).clamp(-999, 100).toStringAsFixed(0);
      lines.add("Your savings rate is low — you kept about $pct% of your income this month.");
    }
    if (expenseRatio != null && expenseRatio! >= 1) {
      lines.add("Your spending exceeded your income this month.");
    }
    if (debtToIncomeScore != null && (debtToIncomeRatio ?? 0) > 0.4) {
      final pct = ((debtToIncomeRatio ?? 0) * 100).toStringAsFixed(0);
      lines.add("Your minimum debt payments are about $pct% of your income — high enough to limit flexibility.");
    }
    if (budgetAdherenceScore != null && budgetAdherenceScore! < 70) {
      lines.add("You're over budget in at least one category this month.");
    }
    if (goalProgressScore != null && goalProgressScore! >= 90) {
      lines.add("You're close to hitting one or more of your savings goals — keep going.");
    }
    if (componentsIncluded < 3) {
      lines.add(
        "This score only reflects $componentsIncluded of 5 factors right now — "
        "add budgets, goals, or more transaction history for a fuller picture.",
      );
    }
    if (lines.isEmpty && score != null) {
      lines.add("Nothing concerning stands out this month.");
    }
    return lines;
  }
}

class HealthScoreRepository {
  static Future<HealthScoreRecord> fetch({required String clerkUserId}) async {
    final rows = await SupabaseService.client.rpc(
      'get_financial_health_score',
      params: {'p_user_id': clerkUserId},
    );
    final row = (rows as List).first as Map<String, dynamic>;
    return HealthScoreRecord.fromMap(row);
  }
}
