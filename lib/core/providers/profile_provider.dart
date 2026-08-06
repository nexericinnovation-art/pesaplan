import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase_service.dart';

class ProfileController extends AsyncNotifier<ProfileRecord?> {
  @override
  Future<ProfileRecord?> build() async => null;

  /// Idempotent by design: the router's redirect only calls this when the
  /// current state is still `data: null` (i.e. never attempted). Once this
  /// starts, state flips to `loading`, so re-entrant calls are harmless but
  /// avoided anyway.
  Future<void> load({required String sessionToken}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final ensured =
          await SupabaseService.ensureProfileForClerkUser(sessionToken: sessionToken);
      if (ensured != null) return ensured;

      final fetched = await SupabaseService.fetchProfile(sessionToken: sessionToken);
      if (fetched == null) {
        throw StateError(
          'Your profile exists but could not be read directly. This usually '
          'means Clerk is not yet registered as a Supabase Third-Party Auth '
          'provider — see supabase/README.md.',
        );
      }
      return fetched;
    });
  }

  void reset() => state = const AsyncValue.data(null);
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileRecord?>(ProfileController.new);