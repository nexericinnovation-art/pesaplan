import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/profile_provider.dart';
import '../../core/services/auth_identity_service.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/auth_status_view.dart';
import '../../features/budgets/budgets_screen.dart';
import '../../features/goals/savings_goals_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/root/root_navigation_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import 'router_refresh_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) {
      final hasClerkAuth = context.findAncestorWidgetOfExactType<ClerkAuth>() != null;
      if (!hasClerkAuth) return null; // matches the pre-existing "Welcome" fallback

      final auth = ClerkAuth.of(context, listen: false);
      final isAuthed = AuthIdentityService.isAuthenticated(auth);
      final loc = state.matchedLocation;

      if (!isAuthed) {
        return loc == '/auth' ? null : '/auth';
      }
      if (loc == '/auth') return '/loading';

      final profileState = ref.read(profileControllerProvider);

      return profileState.when(
        loading: () => loc == '/loading' ? null : '/loading',
        error: (_, __) => loc == '/loading' ? null : '/loading',
        data: (profile) {
          if (profile == null) {
            // First time we've seen this authenticated user: kick off the
            // load. Guarded by the `data: null` check, so it only fires once
            // — subsequent redirects see AsyncLoading above and stop here.
            Future.microtask(() async {
              final token = await AuthIdentityService.currentSessionToken(auth);
              if (token != null) {
                ref.read(profileControllerProvider.notifier).load(sessionToken: token);
              }
            });
            return loc == '/loading' ? null : '/loading';
          }
          if (!profile.onboardingCompleted) {
            return loc == '/onboarding' ? null : '/onboarding';
          }
          if (loc == '/onboarding' || loc == '/loading' || loc == '/auth') {
            return '/home';
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/loading',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final profileState = ref.watch(profileControllerProvider);
            return profileState.when(
              data: (_) => const _LoadingScaffold(message: 'Setting things up…'),
              loading: () => const _LoadingScaffold(message: 'Setting things up…'),
              error: (error, _) => _ErrorScaffold(
                message: error is StateError
                    ? error.message
                    : 'Your profile could not be loaded yet. This usually means the '
                        'Clerk-to-Supabase connection is not configured correctly.',
                onRetry: () async {
                  final auth = ClerkAuth.of(context, listen: false);
                  final token = await AuthIdentityService.currentSessionToken(auth);
                  if (token != null) {
                    ref.read(profileControllerProvider.notifier).load(sessionToken: token);
                  }
                },
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final profile = ref.watch(profileControllerProvider).valueOrNull;
            if (profile == null) return const _LoadingScaffold(message: 'Setting things up…');
            return OnboardingScreen(
              clerkUserId: profile.clerkUserId,
              onComplete: () async {
                final auth = ClerkAuth.of(context, listen: false);
                final token = await AuthIdentityService.currentSessionToken(auth);
                if (token != null) {
                  await ref.read(profileControllerProvider.notifier).load(sessionToken: token);
                }
              },
            );
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootNavigationScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => Consumer(builder: (context, ref, _) {
                final profile = ref.watch(profileControllerProvider).valueOrNull;
                return HomeScreen(
                  clerkUserId: profile?.clerkUserId ?? '',
                  currency: (profile?.currency ?? '').isEmpty ? 'KES' : profile!.currency!,
                  onTabChanged: (index) => const [
                    '/home', '/transactions', '/budgets', '/goals', '/profile',
                  ][index].let((path) => context.go(path)),
                );
              }),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => Consumer(builder: (context, ref, _) {
                final profile = ref.watch(profileControllerProvider).valueOrNull;
                return TransactionsScreen(
                  clerkUserId: profile?.clerkUserId ?? '',
                  currency: (profile?.currency ?? '').isEmpty ? 'KES' : profile!.currency!,
                );
              }),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/budgets',
              builder: (context, state) => Consumer(builder: (context, ref, _) {
                final profile = ref.watch(profileControllerProvider).valueOrNull;
                return BudgetsScreen(
                  clerkUserId: profile?.clerkUserId ?? '',
                  currency: (profile?.currency ?? '').isEmpty ? 'KES' : profile!.currency!,
                );
              }),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/goals',
              builder: (context, state) => Consumer(builder: (context, ref, _) {
                final profile = ref.watch(profileControllerProvider).valueOrNull;
                return SavingsGoalsScreen(
                  clerkUserId: profile?.clerkUserId ?? '',
                  currency: (profile?.currency ?? '').isEmpty ? 'KES' : profile!.currency!,
                );
              }),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(message)],
          ),
        ),
      );
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthStatusView(message: message, isError: true),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
}