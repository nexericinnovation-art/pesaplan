import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/environment.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnvironment.load();

  final clerkKey = AppEnvironment.clerkPublishableKey;
  final supabaseUrl = AppEnvironment.supabaseUrl;
  final supabaseAnonKey = AppEnvironment.supabaseAnonKey;

  if ((clerkKey ?? '').isEmpty || (supabaseUrl ?? '').isEmpty || (supabaseAnonKey ?? '').isEmpty) {
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Configuration missing')))));
    return;
  }

  await SupabaseService.initialize();

runApp(
    ProviderScope(
      child: ClerkAuth(
        config: AppConfig.clerkConfig,
        child: const MyApp(),
      ),
    ),
  );
}
