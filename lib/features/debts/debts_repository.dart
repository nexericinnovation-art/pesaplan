import '../../core/services/supabase_service.dart';

class DebtRecord {
  DebtRecord({
    required this.id,
    required this.loanName,
    required this.originalAmount,
    required this.currentBalance,
    required this.createdAt,
    this.lender,
    this.interestRate,
    this.minimumPayment,
    this.paymentFrequency,
    this.dueDate,
    this.startDate,
    this.expectedPayoffDate,
  });

  final String id;
  final String loanName;
  final String? lender;
  final num originalAmount;
  final num currentBalance;
  final num? interestRate;
  final num? minimumPayment;
  final String? paymentFrequency; // 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly'
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? expectedPayoffDate;
  final DateTime createdAt;

  bool get isPaidOff => currentBalance <= 0;

  num get totalPaid => (originalAmount - currentBalance).clamp(0, originalAmount);

  double get percentPaidOff => originalAmount <= 0 ? 0 : (totalPaid / originalAmount).clamp(0, 1).toDouble();

  factory DebtRecord.fromMap(Map<String, dynamic> map) {
    return DebtRecord(
      id: map['id'].toString(),
      loanName: map['loan_name'] as String,
      lender: map['lender'] as String?,
      originalAmount: (map['original_amount'] as num?) ?? 0,
      currentBalance: (map['current_balance'] as num?) ?? 0,
      interestRate: map['interest_rate'] as num?,
      minimumPayment: map['minimum_payment'] as num?,
      paymentFrequency: map['payment_frequency'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'].toString()) : null,
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date'].toString()) : null,
      expectedPayoffDate:
          map['expected_payoff_date'] != null ? DateTime.parse(map['expected_payoff_date'].toString()) : null,
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}

class DebtPaymentRecord {
  DebtPaymentRecord({
    required this.id,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
    this.principalAmount,
    this.interestAmount,
  });

  final String id;
  final num amount;
  final num? principalAmount;
  final num? interestAmount;
  final DateTime paymentDate;
  final DateTime createdAt;

  factory DebtPaymentRecord.fromMap(Map<String, dynamic> map) {
    return DebtPaymentRecord(
      id: map['id'].toString(),
      amount: (map['amount'] as num?) ?? 0,
      principalAmount: map['principal_amount'] as num?,
      interestAmount: map['interest_amount'] as num?,
      paymentDate: DateTime.parse(map['payment_date'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}

/// Direct, RLS-protected Supabase calls. Every write explicitly sets
/// `user_id` to the caller's own Clerk user id; RLS independently enforces
/// that this can't be spoofed to another user's id.
class DebtsRepository {
  static Future<List<DebtRecord>> fetchDebts({required String clerkUserId}) async {
    final rows = await SupabaseService.client
        .from('debts')
        .select()
        .eq('user_id', clerkUserId)
        .order('created_at', ascending: false);

    return rows.map((row) => DebtRecord.fromMap(row)).toList();
  }

  static Future<List<DebtPaymentRecord>> fetchPayments({
    required String debtId,
    required String clerkUserId,
  }) async {
    final rows = await SupabaseService.client
        .from('debt_payments')
        .select()
        .eq('debt_id', debtId)
        .eq('user_id', clerkUserId)
        .order('payment_date', ascending: false);

    return rows.map((row) => DebtPaymentRecord.fromMap(row)).toList();
  }

  static Future<DebtRecord> createDebt({
    required String clerkUserId,
    required String loanName,
    required num originalAmount,
    num? currentBalance,
    String? lender,
    num? interestRate,
    num? minimumPayment,
    String? paymentFrequency,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? expectedPayoffDate,
  }) async {
    final row = await SupabaseService.client
        .from('debts')
        .insert({
          'user_id': clerkUserId,
          'loan_name': loanName,
          'lender': lender,
          'original_amount': originalAmount,
          // Defaults to the full original amount — a brand new debt hasn't
          // had anything paid off yet, unless the user tells us otherwise.
          'current_balance': currentBalance ?? originalAmount,
          'interest_rate': interestRate,
          'minimum_payment': minimumPayment,
          'payment_frequency': paymentFrequency,
          'due_date': dueDate?.toIso8601String().split('T').first,
          'start_date': startDate?.toIso8601String().split('T').first,
          'expected_payoff_date': expectedPayoffDate?.toIso8601String().split('T').first,
        })
        .select()
        .single();

    return DebtRecord.fromMap(row);
  }

  /// Atomically records a payment and reduces the debt's running balance —
  /// see the `add_debt_payment` Postgres function for why this is one RPC
  /// call rather than two separate writes from here.
  static Future<DebtRecord> recordPayment({
    required String debtId,
    required String clerkUserId,
    required num amount,
    num? principalAmount,
    num? interestAmount,
    DateTime? paymentDate,
  }) async {
    final row = await SupabaseService.client.rpc(
      'add_debt_payment',
      params: {
        'p_debt_id': debtId,
        'p_user_id': clerkUserId,
        'p_amount': amount,
        'p_principal_amount': principalAmount,
        'p_interest_amount': interestAmount,
        'p_payment_date': (paymentDate ?? DateTime.now()).toIso8601String().split('T').first,
      },
    );

    return DebtRecord.fromMap(row as Map<String, dynamic>);
  }

  static Future<void> deleteDebt({required String debtId, required String clerkUserId}) async {
    // debt_payments rows are removed automatically via ON DELETE CASCADE.
    await SupabaseService.client.from('debts').delete().eq('id', debtId).eq('user_id', clerkUserId);
  }
}
