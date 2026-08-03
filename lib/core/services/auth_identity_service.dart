import 'package:clerk_flutter/clerk_flutter.dart';

class AuthIdentityService {
  static String? currentClerkUserId(ClerkAuthState auth) {
    return auth.client.user?.id;
  }

  static String? currentClerkEmail(ClerkAuthState auth) {
    return auth.client.user?.email;
  }

  static bool isAuthenticated(ClerkAuthState auth) {
    return auth.client.user != null;
  }
}
