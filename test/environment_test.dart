import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesaplan/app/config/environment.dart';

void main() {
  group('AppEnvironment', () {
    test('loads configuration from a custom .env path', () async {
      final tempDir = await Directory.systemTemp.createTemp('pesaplan_env_test');
      final tempFile = File('${tempDir.path}/.env.test');

      await tempFile.writeAsString(
        'CLERK_PUBLISHABLE_KEY=test-clerk-key\n'
        'SUPABASE_URL=https://example.supabase.co\n'
        'SUPABASE_ANON_KEY=test-anon-key\n',
      );

      addTearDown(() async {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      await AppEnvironment.load(fileName: tempFile.path);

      expect(AppEnvironment.clerkPublishableKey, 'test-clerk-key');
      expect(AppEnvironment.supabaseUrl, 'https://example.supabase.co');
      expect(AppEnvironment.supabaseAnonKey, 'test-anon-key');
    });
  });
}
