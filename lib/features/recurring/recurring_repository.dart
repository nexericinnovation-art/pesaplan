import '../../core/services/supabase_service.dart';
import '../transactions/transactions_repository.dart' show CategoryRecord, TransactionsRepository;

class RecurringTransactionRecord {
  RecurringTransactionRecord({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.nextOccurrence,
    required this.createdAt,
    this.categoryId,
    this.categoryName,
    this.endDate,
  });

  final String id;
  final String name;
  final num amount;
  final String type; // 'income' | 'expense'
  final String? categoryId;
  final String? categoryName;
  final String frequency; // 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextOccurrence;
  final DateTime createdAt;

  bool get isActive => endDate == null || endDate!.isAfter(DateTime.now());

  bool get isDueSoon => nextOccurrence.difference(DateTime.now()).inDays <= 7;

  factory RecurringTransactionRecord.fromMap(Map<String, dynamic> map) {
    // categories is a joined relation when fetched with the select below;
    // it's absent (null) if category_id is null, so this stays optional.
    final category = map['categories'] as Map<String, dynamic>?;
    return RecurringTransactionRecord(
      id: map['id'].toString(),
      name: map['name'] as String,
      amount: (map['amount'] as num?) ?? 0,
      type: map['type'] as String,
      categoryId: map['category_id'] as String?,
      categoryName: category?['name'] as String?,
      frequency: map['frequency'] as String,
      startDate: DateTime.parse(map['start_date'].toString()),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'].toString()) : null,
      nextOccurrence: DateTime.parse(map['next_occurrence'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}

/// Note: this only manages the recurring *template* (name, amount, schedule).
/// Actually generating real transactions on each occurrence, and advancing
/// `next_occurrence` forward automatically, needs a server-side scheduled
/// job (a Supabase Edge Function on a cron trigger) — that's a separate
/// piece of infrastructure, not something a Flutter client can do reliably
/// on its own, and it's deliberately not part of this slice.
class RecurringTransactionsRepository {
  static const _selectWithCategory = '*, categories(name)';

  static Future<List<RecurringTransactionRecord>> fetchAll({required String clerkUserId}) async {
    final rows = await SupabaseService.client
        .from('recurring_transactions')
        .select(_selectWithCategory)
        .eq('user_id', clerkUserId)
        .order('next_occurrence');

    return rows.map((row) => RecurringTransactionRecord.fromMap(row)).toList();
  }

  static Future<RecurringTransactionRecord> create({
    required String clerkUserId,
    required String name,
    required num amount,
    required String type,
    required String frequency,
    required DateTime startDate,
    String? categoryId,
    DateTime? endDate,
  }) async {
    final row = await SupabaseService.client
        .from('recurring_transactions')
        .insert({
          'user_id': clerkUserId,
          'name': name,
          'amount': amount,
          'type': type,
          'category_id': categoryId,
          'frequency': frequency,
          'start_date': startDate.toIso8601String().split('T').first,
          'end_date': endDate?.toIso8601String().split('T').first,
          // A brand new recurring item's first occurrence is its start date;
          // nothing has happened yet to move it forward.
          'next_occurrence': startDate.toIso8601String().split('T').first,
        })
        .select(_selectWithCategory)
        .single();

    return RecurringTransactionRecord.fromMap(row);
  }

  static Future<void> delete({required String id, required String clerkUserId}) async {
    await SupabaseService.client.from('recurring_transactions').delete().eq('id', id).eq('user_id', clerkUserId);
  }

  static Future<List<CategoryRecord>> fetchCategories({required String clerkUserId, String? type}) {
    return TransactionsRepository.fetchCategories(clerkUserId: clerkUserId, type: type);
  }
}
