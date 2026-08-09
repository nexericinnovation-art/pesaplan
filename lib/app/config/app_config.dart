import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../features/auth/auth_colors.dart';
import 'environment.dart';

class AppConfig {
  static const String appName = 'Pesaplan';
  static const String appTagline = 'Secure personal finance';

  static ClerkAuthConfig get clerkConfig {
    return ClerkAuthConfig(
      publishableKey: AppEnvironment.clerkPublishableKey ?? 'pk_test_placeholder',
      loading: const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AuthColors.primary)),
      ),
      flags: const ClerkSdkFlags(clearCookiesOnSignOut: true),
    );
  }
}
