import 'package:flutter_test/flutter_test.dart';
import 'package:pesaplan/core/services/supabase_service.dart';

void main() {
  group('SupabaseService edge function URL', () {
    test('builds the edge function URL from the Supabase project URL by default', () {
      expect(
        SupabaseService.buildEdgeFunctionUrl('https://example.supabase.co', null),
        'https://example.supabase.co/functions/v1/sync-clerk-profile',
      );
    });

    test('uses an explicit edge function override when provided', () {
      expect(
        SupabaseService.buildEdgeFunctionUrl(
          'https://example.supabase.co',
          'https://custom.example.com/functions/v1/sync-clerk-profile',
        ),
        'https://custom.example.com/functions/v1/sync-clerk-profile',
      );
    });
  });
}
