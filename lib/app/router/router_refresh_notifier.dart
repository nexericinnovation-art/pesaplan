import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/profile_provider.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(profileControllerProvider, (_, __) => notifyListeners());
  }

  /// Called from `MyApp` every time Clerk's ClerkAuthBuilder fires (sign in,
  /// sign out, or initial load), since GoRouter has no other way to know
  /// Clerk's state changed.
  void tick() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});