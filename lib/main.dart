import 'dart:io';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/environment.dart';
import 'core/services/supabase_service.dart';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = CustomHttpOverrides();
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