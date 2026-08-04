import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// dart:io is only touched behind `!kIsWeb` below. It compiles fine on web
// (Dart provides a stub), but actually calling File operations there throws
// "Unsupported operation: _Namespace" at runtime — there is no filesystem
// in a browser. Keep every dart:io call inside the `!kIsWeb` branch.
// ignore: avoid_web_libraries_in_flutter
import 'dart:io';

class AppEnvironment {
  /// Loads environment variables.
  ///
  /// On web, this always goes through flutter_dotenv's asset-based loader
  /// (`.env` is declared as a Flutter asset in pubspec.yaml) — there is no
  /// filesystem to read directly.
  ///
  /// On non-web platforms, an absolute/relative path containing a
  /// separator is read directly via `dart:io` first (useful for tests or
  /// local dev pointing at an arbitrary `.env` location), falling back to
  /// the asset-based loader for the plain `.env` case.
  static Future<void> load({String? fileName}) async {
    final name = fileName ?? '.env';

    if (!kIsWeb && name.isNotEmpty && (name.contains('/') || name.contains('\\'))) {
      final directFile = File(name);
      if (await directFile.exists()) {
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
