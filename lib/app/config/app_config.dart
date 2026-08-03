import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import 'environment.dart';

class AppConfig {
  static const String appName = 'Pesaplan';
  static const String appTagline = 'Secure personal finance';

  static ClerkAuthConfig get clerkConfig {
    return ClerkAuthConfig(
      publishableKey: AppEnvironment.clerkPublishableKey ?? 'pk_test_placeholder',
      loading: const Center(child: CircularProgressIndicator()),
      flags: const ClerkSdkFlags(clearCookiesOnSignOut: true),
    );
  }
}
