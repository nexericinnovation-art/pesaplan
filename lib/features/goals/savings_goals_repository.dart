import '../../core/services/supabase_service.dart';

class SavingsGoalRecord {
  SavingsGoalRecord({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    required this.createdAt,
    this.deadline,
  });

  final String id;
  final String name;
  final num targetAmount;
  final num currentAmount;
  final String status; // 'active' | 'paused' | 'completed'
  final DateTime createdAt;
  final DateTime? deadline;

  num get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  double get percentComplete => targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1).toDouble();

  /// Required monthly amount to hit the target by the deadline, from today.
  /// Null if there's no deadline, or the deadline has passed.
  num? get requiredMonthlyAmount {
    final deadline = this.deadline;
    if (deadline == null) return null;
    final now = DateTime.now();
    if (!deadline.isAfter(now)) return null;
    final monthsRemaining = _monthsBetween(now, deadline).clamp(1, 1 << 30);
    return remaining / monthsRemaining;
  }

  /// Average pace so far, computed from real data (current_amount over the
  /// time since the goal was created) — not a fabricated estimate.
  num get averageMonthlyPaceSoFar {
    final monthsElapsed = _monthsBetween(createdAt, DateTime.now()).clamp(1, 1 << 30);
    return currentAmount / monthsElapsed;
  }

  /// Null when there's no deadline to be "on track" against.
  bool? get isOnTrack {
    final required = requiredMonthlyAmount;
    if (required == null) return null;
    return averageMonthlyPaceSoFar >= required;
  }

  static int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  factory SavingsGoalRecord.fromMap(Map<String, dynamic> map) {
    return SavingsGoalRecord(
      id: map['id'].toString(),
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num?) ?? 0,
      currentAmount: (map['current_amount'] as num?) ?? 0,
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'].toString()),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'].toString()) : null,
    );
  }
}

class GoalContributionRecord {
  GoalContributionRecord({
    required this.id,
    required this.amount,
    required this.contributionType,
    required this.createdAt,
    this.note,
  });

  final String id;
  final num amount;
  final String contributionType; // 'deposit' | 'withdrawal'
  final DateTime createdAt;
  final String? note;

  factory GoalContributionRecord.fromMap(Map<String, dynamic> map) {
    return GoalContributionRecord(
      id: map['id'].toString(),
      amount: (map['amount'] as num?) ?? 0,
      contributionType: map['contribution_type'] as String,
      createdAt: DateTime.parse(map['created_at'].toString()),
      note: map['note'] as String?,
    );
  }
}

/// Direct, RLS-protected Supabase calls. Every write explicitly sets
/// `user_id` to the caller's own Clerk user id; RLS independently enforces
/// that this can't be spoofed.
class SavingsGoalsRepository {
  static Future<List<SavingsGoalRecord>> fetchGoals({required String clerkUserId}) async {
    final rows = await SupabaseService.client
        .from('savings_goals')
        .select()
        .eq('user_id', clerkUserId)
        .order('created_at', ascending: false);

    return rows.map((row) => SavingsGoalRecord.fromMap(row)).toList();
  }

  static Future<List<GoalContributionRecord>> fetchContributions({
    required String goalId,
    required String clerkUserId,
  }) async {
    final rows = await SupabaseService.client
        .from('goal_contributions')
        .select()
        .eq('goal_id', goalId)
        .eq('user_id', clerkUserId)
        .order('created_at', ascending: false);

    return rows.map((row) => GoalContributionRecord.fromMap(row)).toList();
  }

  static Future<SavingsGoalRecord> createGoal({
    required String clerkUserId,
    required String name,
    required num targetAmount,
    num initialAmount = 0,
    DateTime? deadline,
  }) async {
    final row = await SupabaseService.client
        .from('savings_goals')
        .insert({
          'user_id': clerkUserId,
          'name': name,
          'target_amount': targetAmount,
          'current_amount': initialAmount,
          'deadline': deadline?.toIso8601String().split('T').first,
        })
        .select()
        .single();

    return SavingsGoalRecord.fromMap(row);
  }

  static Future<SavingsGoalRecord> setStatus({
    required String goalId,
    required String clerkUserId,
    required String status,
  }) async {
    final row = await SupabaseService.client
        .from('savings_goals')
        .update({'status': status})
        .eq('id', goalId)
        .eq('user_id', clerkUserId)
        .select()
        .single();

    return SavingsGoalRecord.fromMap(row);
  }

  static Future<SavingsGoalRecord> addContribution({
    required String goalId,
    required String clerkUserId,
    required num amount,
    required String contributionType,
    String? note,
  }) async {
    final row = await SupabaseService.client.rpc(
      'add_goal_contribution',
      params: {
        'p_goal_id': goalId,
        'p_user_id': clerkUserId,
        'p_amount': amount,
        'p_contribution_type': contributionType,
        'p_note': note,
      },
    );

    // Postgres functions returning a single row come back as a Map when
    // called via .rpc(), not a List.
    return SavingsGoalRecord.fromMap(row as Map<String, dynamic>);
  }

  static Future<void> deleteGoal({required String goalId, required String clerkUserId}) async {
    await SupabaseService.client.from('savings_goals').delete().eq('id', goalId).eq('user_id', clerkUserId);
  }
}
