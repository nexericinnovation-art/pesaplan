import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  static Future<void> load({String? fileName}) async {
    final name = fileName ?? '.env';
    final directFile = File(name);

    if (name.isNotEmpty && (name.contains('/') || name.contains('\\') || await directFile.exists())) {
      try {
        final contents = await directFile.readAsString();
        if (contents.trim().isNotEmpty) {
          dotenv.loadFromString(envString: contents);
          return;
        }
      } catch (_) {
        // Fall back to the asset-based loader below.
      }
    }

    await dotenv.load(fileName: name);
  }

  static String? get clerkPublishableKey => dotenv.env['CLERK_PUBLISHABLE_KEY'];

  static String? get supabaseUrl => dotenv.env['SUPABASE_URL'];

  static String? get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'];

  static bool get hasRequiredClientConfig {
    return (clerkPublishableKey ?? '').isNotEmpty &&
        (supabaseUrl ?? '').isNotEmpty &&
        (supabaseAnonKey ?? '').isNotEmpty;
  }
}
