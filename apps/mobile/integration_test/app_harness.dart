import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/bootstrap.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/presentation/controllers/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Shared rig for `integration_test/`. Builds a `ProviderScope` with the
/// production [MoodBloomApp] inside it, plus the caller's [overrides] —
/// all Firebase-touching providers MUST be overridden by the caller so
/// the test never reaches a real backend.
///
/// Sprint 5 (WBS 7.3a) expanded the harness with [defaultIntegrationOverrides]
/// to cover the always-needed scaffolding (theme controller, biometric
/// capability, sync manager). Per-flow overrides (auth repo, mood repo,
/// intervention storage) sit on top.
///
/// **Web parity:** the harness is platform-agnostic. The four real flows
/// must pass on Android emulator AND `flutter test integration_test/<file>.dart -d chrome`
/// per the kickoff acceptance bar.
Future<void> pumpHarness(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const MoodBloomApp()),
  );
  // One extra settle pass so router redirects + first stream emissions
  // resolve before the test starts asserting.
  await tester.pumpAndSettle();
}

/// Returns the always-needed overrides for an integration test that boots
/// the production [MoodBloomApp]. Adds:
///
///   - `themeModeControllerProvider` — the production provider throws if
///     not seeded (see `theme_mode_controller.dart` doc); we feed it a
///     real controller backed by the mock SharedPreferences.
///   - `biometricCapabilityProvider` — non-shouldGate so the router
///     does not insert the biometric gate between sign-in and `/home`.
///   - `moodSyncManagerProvider` — a [FakeSyncManager] so the router's
///     `ref.read(moodSyncManagerProvider)` on auth-state transitions does
///     not drag in real Firestore / Drift / connectivity_plus.
///
/// Caller is responsible for disposing the returned [FakeSyncManager] in
/// `tearDown` to avoid leaking timers and the in-memory Drift connection.
///
/// `SharedPreferences.setMockInitialValues` is called by the caller (so
/// the test can pre-seed keys like `onboarding_complete`); this helper
/// only resolves the existing mock instance.
Future<({List<Override> overrides, FakeSyncManager syncManager})>
defaultIntegrationOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  final themeStorage = ThemeModeStorage(prefs);
  final syncManager = await FakeSyncManager.create();

  return (
    overrides: [
      themeModeControllerProvider.overrideWith(
        () => ThemeModeController(storage: themeStorage),
      ),
      biometricCapabilityProvider.overrideWith(
        (ref) async => const BiometricCapability(
          isAvailable: false,
          hasEnrolledBiometrics: false,
          userOptedIn: false,
        ),
      ),
      moodSyncManagerProvider.overrideWithValue(syncManager),
    ],
    syncManager: syncManager,
  );
}

/// Convenience: ensure the onboarding gate is bypassed so the router lands
/// on `/sign-in` (or `/home` if the user is non-null) on first frame.
/// Called from setUp in every integration flow that exercises auth-state
/// transitions — onboarding adds a screen-pump that the flow tests don't
/// need to revisit.
void seedOnboardingComplete() {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
}
