import '../../core/services/supabase_service.dart';

class BudgetRecord {
  BudgetRecord({
    required this.id,
    required this.name,
    required this.periodStart,
    required this.periodEnd,
  });

  final String id;
  final String name;
  final DateTime periodStart;
  final DateTime periodEnd;

  factory BudgetRecord.fromMap(Map<String, dynamic> map) {
    return BudgetRecord(
      id: map['id'].toString(),
      name: map['name'] as String,
      periodStart: DateTime.parse(map['period_start'].toString()),
      periodEnd: DateTime.parse(map['period_end'].toString()),
    );
  }
}

class BudgetCategoryProgress {
  BudgetCategoryProgress({
    required this.categoryId,
    required this.categoryName,
    required this.allocatedAmount,
    required this.spentAmount,
    this.categoryIcon,
    this.categoryColor,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final num allocatedAmount;
  final num spentAmount;

  num get remaining => allocatedAmount - spentAmount;

  double get percentUsed => allocatedAmount <= 0 ? 0 : (spentAmount / allocatedAmount).clamp(0, double.infinity).toDouble();

  /// One of: 'ok', 'approaching' (>=70%), 'almost' (>=90%), 'exceeded' (>=100%).
  String get warningLevel {
    if (percentUsed >= 1.0) return 'exceeded';
    if (percentUsed >= 0.9) return 'almost';
    if (percentUsed >= 0.7) return 'approaching';
    return 'ok';
  }

  factory BudgetCategoryProgress.fromMap(Map<String, dynamic> map) {
    return BudgetCategoryProgress(
      categoryId: map['category_id'].toString(),
      categoryName: map['category_name'] as String,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as String?,
      allocatedAmount: (map['allocated_amount'] as num?) ?? 0,
      spentAmount: (map['spent_amount'] as num?) ?? 0,
    );
  }
}

/// Direct, RLS-protected Supabase calls — every write explicitly sets
/// `user_id` to the caller's own Clerk user id; RLS independently enforces
/// that this can't be spoofed to another user's id.
class BudgetsRepository {
  static Future<List<BudgetRecord>> fetchBudgets({required String clerkUserId}) async {
    final rows = await SupabaseService.client
        .from('budgets')
        .select()
        .eq('user_id', clerkUserId)
        .order('period_start', ascending: false);

    return rows.map((row) => BudgetRecord.fromMap(row)).toList();
  }

  static Future<List<BudgetCategoryProgress>> fetchBudgetProgress({
    required String budgetId,
    required String clerkUserId,
  }) async {
    final rows = await SupabaseService.client.rpc(
      'get_budget_progress',
      params: {'p_budget_id': budgetId, 'p_user_id': clerkUserId},
    );

    return (rows as List)
        .map((row) => BudgetCategoryProgress.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// [allocations] maps categoryId -> allocated amount.
  static Future<BudgetRecord> createBudget({
    required String clerkUserId,
    required String name,
    required DateTime periodStart,
    required DateTime periodEnd,
    required Map<String, num> allocations,
  }) async {
    final budgetRow = await SupabaseService.client
        .from('budgets')
        .insert({
          'user_id': clerkUserId,
          'name': name,
          'period_start': periodStart.toIso8601String().split('T').first,
          'period_end': periodEnd.toIso8601String().split('T').first,
        })
        .select()
        .single();

    final budget = BudgetRecord.fromMap(budgetRow);

    if (allocations.isNotEmpty) {
      await SupabaseService.client.from('budget_categories').insert(
            allocations.entries
                .map((entry) => {
                      'budget_id': budget.id,
                      'category_id': entry.key,
                      'user_id': clerkUserId,
                      'allocated_amount': entry.value,
                    })
                .toList(),
          );
    }

    return budget;
  }

  static Future<void> deleteBudget({required String budgetId, required String clerkUserId}) async {
    // budget_categories rows are removed automatically via ON DELETE CASCADE.
    await SupabaseService.client.from('budgets').delete().eq('id', budgetId).eq('user_id', clerkUserId);
  }
}
