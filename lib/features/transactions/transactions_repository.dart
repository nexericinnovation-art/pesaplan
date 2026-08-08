import '../../core/services/supabase_service.dart';

class CategoryRecord {
  CategoryRecord({
    required this.id,
    required this.name,
    required this.type,
    this.userId,
    this.icon,
    this.color,
    this.isDefault = false,
  });

  final String id;
  final String? userId;
  final String name;
  final String type; // 'income' | 'expense'
  final String? icon;
  final String? color;
  final bool isDefault;

  factory CategoryRecord.fromMap(Map<String, dynamic> map) {
    return CategoryRecord(
      id: map['id'].toString(),
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isDefault: map['is_default'] as bool? ?? false,
    );
  }
}

class TransactionRecord {
  TransactionRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.description,
    this.merchant,
    this.notes,
    this.paymentMethod,
  });

  final String id;
  final String userId;
  final String type; // 'income' | 'expense' | 'transfer'
  final num amount;
  final String currency;
  final DateTime transactionDate;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? description;
  final String? merchant;
  final String? notes;
  final String? paymentMethod;

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    final category = map['categories'] as Map<String, dynamic>?;
    return TransactionRecord(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      type: map['type'] as String,
      amount: map['amount'] as num,
      currency: map['currency'] as String? ?? 'KES',
      transactionDate: DateTime.parse(map['transaction_date'].toString()),
      categoryId: map['category_id'] as String?,
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
      description: map['description'] as String?,
      merchant: map['merchant'] as String?,
      notes: map['notes'] as String?,
      paymentMethod: map['payment_method'] as String?,
    );
  }
}

class DashboardSummary {
  DashboardSummary({
    required this.lifetimeBalance,
    required this.monthIncome,
    required this.monthExpenses,
  });

  final num lifetimeBalance;
  final num monthIncome;
  final num monthExpenses;

  num get monthSavings => monthIncome - monthExpenses;

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    return DashboardSummary(
      lifetimeBalance: (map['lifetime_balance'] as num?) ?? 0,
      monthIncome: (map['month_income'] as num?) ?? 0,
      monthExpenses: (map['month_expenses'] as num?) ?? 0,
    );
  }
}

/// All methods here are direct, RLS-protected Supabase client calls — they
/// rely on the Clerk JWT bridge (see ClerkSessionBridge) actually being
/// live. Every write explicitly sets `user_id` to the caller's own Clerk
/// user id; RLS's `with check` clause independently enforces that this
/// can't be spoofed to another user's id (the write is rejected either way
/// if it doesn't match the JWT's `sub`).
class TransactionsRepository {
  /// Computed server-side (see the `get_dashboard_summary` SQL function) so
  /// the dashboard never has to pull full transaction history into the app
  /// just to sum it.
  static Future<DashboardSummary> fetchDashboardSummary({required String clerkUserId}) async {
    final rows = await SupabaseService.client.rpc(
      'get_dashboard_summary',
      params: {'p_user_id': clerkUserId},
    );

    final row = (rows as List).first as Map<String, dynamic>;
    return DashboardSummary.fromMap(row);
  }

  static Future<List<CategoryRecord>> fetchCategories({
    required String clerkUserId,
    String? type,
  }) async {
    var query = SupabaseService.client
        .from('categories')
        .select()
        .or('user_id.eq.$clerkUserId,is_default.eq.true');

    if (type != null) {
      query = query.eq('type', type);
    }

    final rows = await query.order('is_default', ascending: false).order('name');
    return rows.map((row) => CategoryRecord.fromMap(row)).toList();
  }

  static Future<List<TransactionRecord>> fetchTransactions({
    required String clerkUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await SupabaseService.client
        .from('transactions')
        .select('*, categories(name, icon, color)')
        .eq('user_id', clerkUserId)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return rows.map((row) => TransactionRecord.fromMap(row)).toList();
  }

  /// For reports: every transaction in a date range, no pagination limit —
  /// deliberately separate from `fetchTransactions`, which caps at `limit`
  /// for the scrolling list view. A report that silently dropped
  /// transactions past item 50 would be worse than useless.
  static Future<List<TransactionRecord>> fetchTransactionsInRange({
    required String clerkUserId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await SupabaseService.client
        .from('transactions')
        .select('*, categories(name, icon, color)')
        .eq('user_id', clerkUserId)
        .gte('transaction_date', start.toIso8601String().split('T').first)
        .lte('transaction_date', end.toIso8601String().split('T').first)
        .order('transaction_date', ascending: false);

    return rows.map((row) => TransactionRecord.fromMap(row)).toList();
  }

  static Future<TransactionRecord> createTransaction({
    required String clerkUserId,
    required String type,
    required num amount,
    required String currency,
    required DateTime transactionDate,
    String? categoryId,
    String? description,
    String? merchant,
    String? notes,
    String? paymentMethod,
  }) async {
    final row = await SupabaseService.client
        .from('transactions')
        .insert({
          'user_id': clerkUserId,
          'type': type,
          'amount': amount,
          'currency': currency,
          'transaction_date': transactionDate.toIso8601String().split('T').first,
          'category_id': categoryId,
          'description': description,
          'merchant': merchant,
          'notes': notes,
          'payment_method': paymentMethod,
        })
        .select('*, categories(name, icon, color)')
        .single();

    return TransactionRecord.fromMap(row);
  }

  static Future<TransactionRecord> updateTransaction({
    required String id,
    required String clerkUserId,
    required Map<String, dynamic> updates,
  }) async {
    final row = await SupabaseService.client
        .from('transactions')
        .update(updates)
        .eq('id', id)
        .eq('user_id', clerkUserId)
        .select('*, categories(name, icon, color)')
        .single();

    return TransactionRecord.fromMap(row);
  }

  static Future<void> deleteTransaction({required String id, required String clerkUserId}) async {
    await SupabaseService.client.from('transactions').delete().eq('id', id).eq('user_id', clerkUserId);
  }
}