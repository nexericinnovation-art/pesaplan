// lib/app/app.dart

import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pesaplan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightClayTheme,
      darkTheme: AppTheme.darkClayTheme,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
