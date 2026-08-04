import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/environment.dart';

class ProfileRecord {
  ProfileRecord({required this.id, required this.clerkUserId, required this.createdAt});

  final String id;
  final String clerkUserId;
  final DateTime createdAt;

  factory ProfileRecord.fromMap(Map<String, dynamic> map) {
    return ProfileRecord(
      id: map['id'].toString(),
      clerkUserId: map['clerk_user_id'].toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}

class SupabaseService {
  static SupabaseClient? _client;

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

  static SupabaseClient get client {
    if (_client != null) {
      return _client!;
    }

    final url = AppEnvironment.supabaseUrl ?? '';
    final publishableKey = AppEnvironment.supabaseAnonKey ?? '';

    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError('Supabase client configuration is incomplete.');
    }

    _client = SupabaseClient(url, publishableKey);
    return _client!;
  }

  static Future<void> initialize() async {
    await AppEnvironment.load();
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl ?? '',
      publishableKey: AppEnvironment.supabaseAnonKey ?? '',
    );
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> syncProfileWithEdgeFunction({
    required String clerkUserId,
=======
  /// [sessionToken] must be the caller's real Clerk session JWT (from
  /// `ClerkAuthState.sessionToken()`), which the Edge Function verifies
  /// server-side. Do not call this with a bare clerkUserId string — the
  /// server no longer trusts a client-supplied id.
  static Future<Map<String, dynamic>> syncProfileWithEdgeFunction({
    required String sessionToken,
>>>>>>> temp-work
    String? overrideUrl,
  }) async {
    final edgeFunctionUrl = buildEdgeFunctionUrl(AppEnvironment.supabaseUrl, overrideUrl);
    if (edgeFunctionUrl.isEmpty) {
      throw StateError('Supabase Edge Function URL is not configured.');
    }

    final response = await http.post(
      Uri.parse(edgeFunctionUrl),
<<<<<<< HEAD
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'clerkUserId': clerkUserId}),
=======
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sessionToken',
      },
>>>>>>> temp-work
    );

    if (response.statusCode >= 400) {
      throw StateError('Edge function request failed with status ${response.statusCode}: ${response.body}');
    }

    final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
    return decodedBody;
  }

<<<<<<< HEAD
  static Future<ProfileRecord?> ensureProfileForClerkUser({required String clerkUserId}) async {
    try {
      final body = await syncProfileWithEdgeFunction(clerkUserId: clerkUserId);
      final profileMap = body['profile'];
      if (profileMap is Map<String, dynamic>) {
        return ProfileRecord.fromMap(profileMap);
      }
    } catch (_) {
      // Fall back to the direct client insert path when the Edge Function is not reachable.
    }

    final response = await client
        .from('profiles')
        .select('id, clerk_user_id, created_at')
        .eq('clerk_user_id', clerkUserId)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return ProfileRecord.fromMap(response);
    }

    final insertResponse = await client
        .from('profiles')
        .insert({'clerk_user_id': clerkUserId})
        .select('id, clerk_user_id, created_at')
        .single();

    return ProfileRecord.fromMap(insertResponse);
=======
  /// Ensures a profile row exists for the currently signed-in Clerk user.
  ///
  /// This always goes through the `sync-clerk-profile` Edge Function, which
  /// independently verifies the caller's Clerk session token before writing.
  /// There is intentionally no direct-client fallback: the Supabase client
  /// here is never issued a Clerk-signed JWT, so `auth.jwt()` is null on
  /// direct calls and the profiles RLS policies would reject them anyway.
  /// Wiring a real Clerk->Supabase JWT (Supabase "Third-Party Auth") is a
  /// prerequisite for adding direct, RLS-protected client reads/writes.
  static Future<ProfileRecord?> ensureProfileForClerkUser({required String sessionToken}) async {
    final body = await syncProfileWithEdgeFunction(sessionToken: sessionToken);
    final profileMap = body['profile'];
    if (profileMap is Map<String, dynamic>) {
      return ProfileRecord.fromMap(profileMap);
    }
    return null;
>>>>>>> temp-work
  }
}
