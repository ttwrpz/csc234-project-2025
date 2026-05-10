import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/notifications/data/datasources/notifications_preference_datasource.dart';
import 'package:moodbloom/features/notifications/data/providers.dart';
import 'package:moodbloom/features/notifications/domain/fcm_token_repository.dart';
import 'package:moodbloom/features/notifications/domain/notification_failure.dart';
import 'package:moodbloom/features/notifications/domain/notifications_settings.dart';
import 'package:moodbloom/features/notifications/presentation/widgets/notifications_toggle_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements FcmTokenRepository {
  final List<bool> setEnabledCalls = [];
  final List<String> upsertTokenUids = [];
  Result<void, NotificationFailure> upsertResult = const Ok(null);
  Result<void, NotificationFailure> setEnabledResult = const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> upsertToken({
    required String uid,
  }) async {
    upsertTokenUids.add(uid);
    return upsertResult;
  }

  @override
  Future<Result<void, NotificationFailure>> setEnabled({
    required String uid,
    required bool enabled,
  }) async {
    setEnabledCalls.add(enabled);
    return setEnabledResult;
  }

  @override
  Stream<NotificationsSettings>? watchSettings({required String uid}) {
    return const Stream<NotificationsSettings>.empty();
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeRepo repo,
  AppUser? currentUser,
  Map<String, Object>? prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  final sp = await SharedPreferences.getInstance();

  // Build the container manually so we can pre-warm the auth stream
  // override before the widget tree reads it. Otherwise the
  // StreamProvider remains in AsyncLoading on the first tap and the
  // controller's signed-in branch is skipped.
  final container = ProviderContainer(
    overrides: [
      notificationsPreferenceDatasourceProvider.overrideWithValue(
        NotificationsPreferenceDatasource(sp),
      ),
      fcmTokenRepositoryProvider.overrideWithValue(repo),
      currentUserStreamProvider.overrideWith(
        (_) => Stream<AppUser?>.value(currentUser),
      ),
    ],
  );
  // Listen forces the stream provider to subscribe.
  container.listen(currentUserStreamProvider, (_, _) {});
  // Drain microtasks so Stream.value() actually emits.
  await container.read(currentUserStreamProvider.future);

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: NotificationsToggleTile())),
    ),
  );
  await tester.pump();
}

void main() {
  group('NotificationsToggleTile', () {
    testWidgets('renders the cheer-up reminders title and the switch', (
      tester,
    ) async {
      await _pump(tester, repo: _FakeRepo());

      expect(find.text('Cheer-up reminders'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('default state is disabled (v1.0 polish 2026-05-10)', (
      tester,
    ) async {
      // O13's original rule was "opt-in by default" but the v1.0
      // polish round flipped that to "off by default" so the cheer-up
      // toggle never reports `enabled = true` until the user has
      // explicitly granted notification permission. See
      // `NotificationsPreferenceDatasource` for the rationale.
      await _pump(tester, repo: _FakeRepo());

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
    });

    testWidgets(
      'tapping on → calls setEnabled(true) (v1.0 polish: default-off)',
      (tester) async {
        final repo = _FakeRepo();
        await _pump(
          tester,
          repo: repo,
          currentUser: const AppUser(uid: 'user-1'),
        );

        // The default is now off — first tap turns the toggle ON,
        // which is the only path that requests OS permission and
        // registers an FCM token.
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        expect(repo.setEnabledCalls, [true]);
      },
    );

    testWidgets(
      'permission denied surfaces a compassionate SnackBar and reverts toggle',
      (tester) async {
        final repo = _FakeRepo()
          ..upsertResult = const Err(NotificationFailure.permissionDenied());
        // Persisted off so the initial tap is "turn on".
        await _pump(
          tester,
          repo: repo,
          currentUser: const AppUser(uid: 'user-1'),
          prefs: const {'notifications.cheer_up_enabled': false},
        );

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        // Compassionate copy — no "must" verb.
        expect(
          find.textContaining('Enable notifications in your phone settings'),
          findsOneWidget,
        );
        // Toggle reverted to off.
        final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
        expect(tile.value, isFalse);
      },
    );

    testWidgets(
      'tap when signed-out only updates local mirror, no repo calls',
      (tester) async {
        final repo = _FakeRepo();
        await _pump(tester, repo: repo);

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        expect(repo.setEnabledCalls, isEmpty);
        expect(repo.upsertTokenUids, isEmpty);
      },
    );
  });
}
