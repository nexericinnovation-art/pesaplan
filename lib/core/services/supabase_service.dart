import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/environment.dart';
import 'clerk_session_bridge.dart';

class ProfileRecord {
  ProfileRecord({
    required this.id,
    required this.clerkUserId,
    required this.createdAt,
    this.fullName,
    this.country,
    this.currency,
    this.monthlyIncome,
    this.incomeSource,
    this.financialGoal,
    this.monthlySavingsTarget,
    this.existingDebtAmount,
    this.preferredBudgetingMethod,
    this.onboardingCompleted = false,
  });

  final String id;
  final String clerkUserId;
  final DateTime createdAt;
  final String? fullName;
  final String? country;
  final String? currency;
  final num? monthlyIncome;
  final String? incomeSource;
  final String? financialGoal;
  final num? monthlySavingsTarget;
  final num? existingDebtAmount;
  final String? preferredBudgetingMethod;
  final bool onboardingCompleted;

  factory ProfileRecord.fromMap(Map<String, dynamic> map) {
    return ProfileRecord(
      id: map['id'].toString(),
      clerkUserId: map['clerk_user_id'].toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      fullName: map['full_name'] as String?,
      country: map['country'] as String?,
      currency: map['currency'] as String?,
      monthlyIncome: map['monthly_income'] as num?,
      incomeSource: map['income_source'] as String?,
      financialGoal: map['financial_goal'] as String?,
      monthlySavingsTarget: map['monthly_savings_target'] as num?,
      existingDebtAmount: map['existing_debt_amount'] as num?,
      preferredBudgetingMethod: map['preferred_budgeting_method'] as String?,
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
    );
  }
}

class SupabaseService {
  /// The single, properly-configured Supabase client — always use this
  /// (never construct a separate `SupabaseClient(...)`), since it's the one
  /// wired up with the Clerk `accessToken` callback in [initialize]. A
  /// second, manually-constructed client would silently carry no JWT and
  /// every RLS policy in the schema would reject it.
  static SupabaseClient get client => Supabase.instance.client;

  static String buildEdgeFunctionUrl(String? supabaseUrl, String? overrideUrl) {
    if ((overrideUrl ?? '').isNotEmpty) {
      return overrideUrl!;
    }

    final normalizedBaseUrl = (supabaseUrl ?? '').trim().replaceAll(RegExp(r'/+$'), '');
    if (normalizedBaseUrl.isEmpty) {
      return '';
    }

    return '$normalizedBaseUrl/functions/v1/sync-clerk-profile';
  }

  static Future<void> initialize() async {
    await AppEnvironment.load();
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl ?? '',
      publishableKey: AppEnvironment.supabaseAnonKey ?? '',
      accessToken: ClerkSessionBridge.currentToken,
    );
  }

  /// [sessionToken] must be the caller's real Clerk session JWT (from
  /// `ClerkAuthState.sessionToken()`), which the Edge Function verifies
  /// server-side. Do not call this with a bare clerkUserId string — the
  /// server no longer trusts a client-supplied id.
  static Future<Map<String, dynamic>> syncProfileWithEdgeFunction({
    required String sessionToken,
    String? overrideUrl,
  }) async {
    final edgeFunctionUrl = buildEdgeFunctionUrl(AppEnvironment.supabaseUrl, overrideUrl);
    if (edgeFunctionUrl.isEmpty) {
      throw StateError('Supabase Edge Function URL is not configured.');
    }

    final response = await http.post(
      Uri.parse(edgeFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sessionToken',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode >= 400) {
      throw StateError('Edge function request failed with status ${response.statusCode}: ${response.body}');
    }

    final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
    return decodedBody;
  }

  /// Ensures a profile row exists for the currently signed-in Clerk user.
  ///
  /// This always goes through the `sync-clerk-profile` Edge Function, which
  /// independently verifies the caller's Clerk session token before writing.
  /// Even though [client] now carries a Clerk JWT via [ClerkSessionBridge]
  /// (once Clerk is registered as a Supabase Third-Party Auth provider —
  /// see supabase/README.md), profile creation is kept behind the Edge
  /// Function deliberately: it's the one action every signed-in user must
  /// be able to perform exactly once, and centralizing it server-side avoids
  /// relying on client-side RLS timing during the first request after login.
  static Future<ProfileRecord?> ensureProfileForClerkUser({required String sessionToken}) async {
    final body = await syncProfileWithEdgeFunction(sessionToken: sessionToken);
    final profileMap = body['profile'];
    if (profileMap is Map<String, dynamic>) {
      return ProfileRecord.fromMap(profileMap);
    }
    return null;
  }

  /// Direct, RLS-protected read of the full profile row (including
  /// onboarding fields) for the given Clerk user. Relies on [client]
  /// carrying a live Clerk JWT (see [ClerkSessionBridge]) — if Clerk isn't
  /// registered as a Supabase Third-Party Auth provider yet, this will
  /// return null even for the user's own row, because `auth.jwt()` is null
  /// and every RLS policy denies the read.
  static Future<ProfileRecord?> fetchProfile({required String clerkUserId}) async {
    final row = await client
        .from('profiles')
        .select()
        .eq('clerk_user_id', clerkUserId)
        .maybeSingle();

    if (row == null) {
      return null;
    }
    return ProfileRecord.fromMap(row);
  }

  /// Direct, RLS-protected update of the caller's own profile row — used by
  /// the onboarding screen. [updates] should only ever contain the
  /// onboarding-related columns; never pass `id` or `clerk_user_id` here.
  static Future<ProfileRecord> updateProfile({
    required String clerkUserId,
    required Map<String, dynamic> updates,
  }) async {
    final row = await client
        .from('profiles')
        .update(updates)
        .eq('clerk_user_id', clerkUserId)
        .select()
        .single();

    return ProfileRecord.fromMap(row);
  }
}
