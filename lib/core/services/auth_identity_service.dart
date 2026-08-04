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
<<<<<<< HEAD
=======

  /// Fetches the current Clerk session JWT for the signed-in user. This must
  /// be sent to any backend endpoint that needs to know who the caller is —
  /// never send `currentClerkUserId` alone, since a raw id string can be
  /// spoofed by anyone calling the endpoint directly.
  static Future<String?> currentSessionToken(ClerkAuthState auth) async {
    final sessionToken = await auth.sessionToken();
    return sessionToken.jwt;
  }
>>>>>>> temp-work
}
