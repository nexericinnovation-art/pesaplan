import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'router/router_refresh_notifier.dart';
import 'theme/app_theme.dart';
import '../core/services/clerk_session_bridge.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    Widget buildRouterApp() => MaterialApp.router(
          title: 'Pesaplan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightClayTheme,
          darkTheme: AppTheme.darkClayTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
        );

    final hasClerkAuth = context.findAncestorWidgetOfExactType<ClerkAuth>() != null;
    if (!hasClerkAuth) {
      return const MaterialApp(home: Scaffold(body: Center(child: Text('Welcome to Pesaplan'))));
    }

    return ClerkAuthBuilder(
      signedInBuilder: (context, auth) => _registerAndTick(ref, auth, buildRouterApp),
      signedOutBuilder: (context, auth) => _registerAndTick(ref, auth, buildRouterApp),
      builder: (context, auth) => _registerAndTick(ref, auth, buildRouterApp),
    );
  }

  Widget _registerAndTick(WidgetRef ref, ClerkAuthState auth, Widget Function() build) {
    ClerkSessionBridge.register(auth);
    // GoRouter's redirect reads Clerk's auth state via context, but has no
    // way to know it changed on its own — this tells it to re-check.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routerRefreshProvider).tick();
    });
    return build();
  }
}