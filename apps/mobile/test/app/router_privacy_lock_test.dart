import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/app/router.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/mood/data/datasources/mood_firestore_datasource.dart';
import 'package:moodbloom/features/mood/data/dtos/mood_entry_dto.dart';
import 'package:moodbloom/features/mood/data/local/mood_database.dart';
import 'package:moodbloom/features/mood/data/mappers/mood_entry_mapper.dart';
import 'package:moodbloom/features/mood/data/providers.dart' as mood_providers;
import 'package:moodbloom/features/mood/data/sync/mood_sync_manager.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/presentation/controllers/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Router redirect behaviour matrix for the unified Privacy Lock gate.
///
/// Covers the four cases called out in the merge plan (§9):
///   (a) cold boot with Privacy Lock OFF → lands on /home, no gate
///   (b) cold boot with Privacy Lock ON but unlocked → lands on /home
///   (c) cold boot with Privacy Lock ON and not unlocked → /privacy-lock
///   (d) sign-out resets the session-unlocked flag
///
/// Drives the production [routerProvider] through `MaterialApp.router`
/// rather than computing redirect strings in isolation - the redirect
/// closure depends on a `refreshListenable` whose value is set by the
/// `ref.listen` on the auth-state stream, which only runs inside a
/// container with a real Riverpod scope.
void main() {
  // Stub MoodSyncManager so the router's auth-state listener doesn't
  // touch Firebase/Drift on sign-in. Mirrors the pattern in
  // `integration_test/app_harness.dart::defaultIntegrationOverrides()`.
  late _FakeMoodSyncManager fakeSyncManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    fakeSyncManager = await _FakeMoodSyncManager.create();
  });

  tearDown(() async {
    await fakeSyncManager.dispose();
  });

  /// Pumps a minimal `MaterialApp.router` wired to the production router
  /// with the given Privacy Lock state seeded synchronously.
  ///
  /// Returns the router so callers can inspect the matched location.
  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    required AppUser? user,
    required bool privacyLockEnabled,
    required bool sessionUnlocked,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final themeStorage = ThemeModeStorage(prefs);
    late GoRouter router;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeControllerProvider.overrideWith(
            () => ThemeModeController(storage: themeStorage),
          ),
          currentUserStreamProvider.overrideWith(
            (_) => Stream<AppUser?>.value(user),
          ),
          biometricCapabilityProvider.overrideWith(
            (ref) async => const BiometricCapability(
              isAvailable: false,
              hasEnrolledBiometrics: false,
              userOptedIn: false,
            ),
          ),
          privacyLockEnabledProvider.overrideWith(
            () => SeededPrivacyLockEnabledNotifier(privacyLockEnabled),
          ),
          privacyLockUnlockedThisSessionProvider.overrideWith(
            (_) => sessionUnlocked,
          ),
          mood_providers.moodSyncManagerProvider.overrideWithValue(
            fakeSyncManager,
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    // Drain the initial frame + the post-build redirect pass. The
    // routed screens (GardenScreen, HistoryScreen, …) may throw during
    // their build because their feature providers aren't overridden in
    // this rig - we don't care, the assertion is on routing only.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Drain any framework error captured during the initial paint so
    // the next test starts clean. The router redirect runs BEFORE the
    // routed widget builds, so any exception here is from the routed
    // screen and is harmless for routing assertions.
    tester.takeException();
    return router;
  }

  group('Router - Privacy Lock cold-boot gate', () {
    testWidgets('(a) signed in + Privacy Lock OFF → /home, no gate', (
      tester,
    ) async {
      final router = await pumpRouter(
        tester,
        user: const AppUser(uid: 'u-1', email: 'tester@example.com'),
        privacyLockEnabled: false,
        sessionUnlocked: false,
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/home',
        reason: 'Privacy Lock disabled → router lands on /home, no detour',
      );
    });

    testWidgets(
      '(b) signed in + Privacy Lock ON but already unlocked → /home',
      (tester) async {
        final router = await pumpRouter(
          tester,
          user: const AppUser(uid: 'u-1', email: 'tester@example.com'),
          privacyLockEnabled: true,
          sessionUnlocked: true,
        );
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/home',
          reason:
              'Already-unlocked session must bypass the gate - same session, '
              'no double-prompt.',
        );
      },
    );

    testWidgets(
      '(c) signed in + Privacy Lock ON + not unlocked → /privacy-lock',
      (tester) async {
        final router = await pumpRouter(
          tester,
          user: const AppUser(uid: 'u-1', email: 'tester@example.com'),
          privacyLockEnabled: true,
          sessionUnlocked: false,
        );
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/privacy-lock',
          reason:
              'Privacy Lock ON and not yet unlocked must redirect to the '
              'cold-boot unlock screen.',
        );
      },
    );

    testWidgets(
      '(c2) cold-boot redirect threads returnTo through the unlock screen',
      (tester) async {
        final router = await pumpRouter(
          tester,
          user: const AppUser(uid: 'u-1', email: 'tester@example.com'),
          privacyLockEnabled: true,
          sessionUnlocked: false,
        );
        final uri = router.routerDelegate.currentConfiguration.uri;
        expect(uri.path, '/privacy-lock');
        // returnTo on cold boot is the initial /home location so the
        // user lands where they intended after unlock.
        expect(uri.queryParameters['returnTo'], '/home');
      },
    );
  });

  group('Router - sign-out resets the session-unlocked flag', () {
    testWidgets(
      '(d) flipping currentUserStreamProvider non-null → null clears the '
      'session-unlocked flag',
      (tester) async {
        // Drive the auth stream with a controller so the test can flip
        // signed-in → signed-out and observe the listener side effect.
        // Stream is created lazily by the provider override so the
        // initial `add(user)` arrives AFTER the router subscribes.
        final controller = StreamController<AppUser?>.broadcast();
        addTearDown(controller.close);

        final prefs = await SharedPreferences.getInstance();
        final themeStorage = ThemeModeStorage(prefs);

        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              themeModeControllerProvider.overrideWith(
                () => ThemeModeController(storage: themeStorage),
              ),
              currentUserStreamProvider.overrideWith((_) => controller.stream),
              biometricCapabilityProvider.overrideWith(
                (ref) async => const BiometricCapability(
                  isAvailable: false,
                  hasEnrolledBiometrics: false,
                  userOptedIn: false,
                ),
              ),
              privacyLockEnabledProvider.overrideWith(
                () => SeededPrivacyLockEnabledNotifier(true),
              ),
              privacyLockUnlockedThisSessionProvider.overrideWith((_) => true),
              mood_providers.moodSyncManagerProvider.overrideWithValue(
                fakeSyncManager,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                final router = ref.watch(routerProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );

        // Initial signed-in event (router subscribed during first build).
        controller.add(const AppUser(uid: 'u-1', email: 'tester@example.com'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        tester.takeException();

        // Flag started true (via override) - confirm it's observable.
        expect(container.read(privacyLockUnlockedThisSessionProvider), isTrue);

        // Sign out: emit a null user. The router's auth-state listener
        // should clear the session-unlocked flag.
        controller.add(null);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        tester.takeException();

        expect(
          container.read(privacyLockUnlockedThisSessionProvider),
          isFalse,
          reason:
              'Sign-out (non-null → null) must reset the session-unlocked '
              'flag so a future re-sign-in re-prompts at the cold-boot gate.',
        );
      },
    );
  });
}

/// No-op stand-in for [MoodSyncManager] - the router's auth-state
/// listener reads `moodSyncManagerProvider` on every sign-in/-out
/// transition (skipped on web). The bootstrap/shutdown methods are
/// no-ops because these tests assert on routing behaviour, not on
/// sync lifecycle. Mirrors the `FakeSyncManager` pattern in
/// `integration_test/fakes.dart`.
class _FakeMoodSyncManager extends MoodSyncManager {
  _FakeMoodSyncManager._({
    required super.moodDao,
    required super.syncQueueDao,
    required super.remote,
    required super.connectivity,
    required super.deviceIdGetter,
    required super.prefs,
  }) : super(mapper: const MoodEntryMapper());

  static Future<_FakeMoodSyncManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    final db = MoodDatabase.forTesting(NativeDatabase.memory());
    final connectivity = StreamController<bool>.broadcast();
    final manager = _FakeMoodSyncManager._(
      moodDao: db.moodDao,
      syncQueueDao: db.syncQueueDao,
      remote: _NoopFirestoreDatasource(),
      connectivity: connectivity.stream,
      deviceIdGetter: () => 'test-device',
      prefs: prefs,
    );
    manager._db = db;
    manager._connectivity = connectivity;
    return manager;
  }

  late final MoodDatabase _db;
  late final StreamController<bool> _connectivity;

  @override
  void kick() {}

  @override
  Future<void> bootstrap(String uid) async {}

  @override
  Future<void> shutdown() async {
    await super.shutdown();
  }

  Future<void> dispose() async {
    await shutdown();
    await _connectivity.close();
    await _db.close();
  }
}

class _NoopFirestoreDatasource implements MoodFirestoreDatasource {
  @override
  Stream<List<MoodEntryDto>> watchAll(String userId) =>
      const Stream<List<MoodEntryDto>>.empty();

  @override
  Future<MoodEntryDto?> findById({
    required String userId,
    required String id,
  }) async => null;

  @override
  Future<MoodEntryDto> create(MoodEntryDto dto) async => dto;

  @override
  Future<MoodEntryDto> update(MoodEntryDto dto) async => dto;

  @override
  Future<void> delete({required String userId, required String id}) async {}
}
