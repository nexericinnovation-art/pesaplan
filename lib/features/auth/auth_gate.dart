import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../core/services/clerk_session_bridge.dart';
import '../root/root_gate.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final hasClerkAuth = context.findAncestorWidgetOfExactType<ClerkAuth>() != null;

    if (!hasClerkAuth) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Welcome to Pesaplan'),
          ),
        ),
      );
    }

    return ClerkAuthBuilder(
      signedInBuilder: (context, auth) {
        ClerkSessionBridge.register(auth);
        return const RootGate();
      },
      signedOutBuilder: (context, auth) {
        ClerkSessionBridge.register(auth);
        return const AuthScreen();
      },
      builder: (context, auth) {
        ClerkSessionBridge.register(auth);
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking your authentication state…'),
              ],
            ),
          ),
        );
      },
    );
  }
}
