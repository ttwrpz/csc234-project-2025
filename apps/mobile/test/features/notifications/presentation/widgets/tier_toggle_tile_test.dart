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
import 'package:moodbloom/features/notifications/presentation/widgets/tier_toggle_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements FcmTokenRepository {
  final List<bool> tier1Calls = [];
  final List<bool> tier2Calls = [];
  final List<bool> tier3Calls = [];
  final List<bool> setEnabledCalls = [];
  final List<String> upsertTokenUids = [];
  Result<void, NotificationFailure> tierResult = const Ok(null);
  NotificationsSettings? remoteSeed;

  @override
  Future<Result<void, NotificationFailure>> upsertToken({
    required String uid,
  }) async {
    upsertTokenUids.add(uid);
    return const Ok(null);
  }

  @override
  Future<Result<void, NotificationFailure>> setEnabled({
    required String uid,
    required bool enabled,
  }) async {
    setEnabledCalls.add(enabled);
    return const Ok(null);
  }

  @override
  Future<Result<void, NotificationFailure>> setTier1Enabled({
    required String uid,
    required bool enabled,
  }) async {
    tier1Calls.add(enabled);
    return tierResult;
  }

  @override
  Future<Result<void, NotificationFailure>> setTier2Enabled({
    required String uid,
    required bool enabled,
  }) async {
    tier2Calls.add(enabled);
    return tierResult;
  }

  @override
  Future<Result<void, NotificationFailure>> setTier3Enabled({
    required String uid,
    required bool enabled,
  }) async {
    tier3Calls.add(enabled);
    return tierResult;
  }

  @override
  Stream<NotificationsSettings>? watchSettings({required String uid}) {
    final seed = remoteSeed;
    if (seed == null) return const Stream<NotificationsSettings>.empty();
    return Stream<NotificationsSettings>.value(seed);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeRepo repo,
  AppUser? currentUser,
  Widget? child,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  final sp = await SharedPreferences.getInstance();

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
  container.listen(currentUserStreamProvider, (_, _) {});
  await container.read(currentUserStreamProvider.future);

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body:
              child ??
              const Column(
                children: [
                  TierToggleTile(tier: InterventionTier.one),
                  TierToggleTile(tier: InterventionTier.two),
                  TierToggleTile(tier: InterventionTier.three),
                ],
              ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TierToggleTile', () {
    testWidgets('renders three tiles with their compassionate labels', (
      tester,
    ) async {
      await _pump(tester, repo: _FakeRepo());

      // Tier 1
      expect(find.text('Gentle nudges'), findsOneWidget);
      expect(
        find.text(
          'Quiet reminders when the garden has been weathering for a while.',
        ),
        findsOneWidget,
      );

      // Tier 2
      expect(find.text('Journaling check-ins'), findsOneWidget);
      expect(
        find.text(
          'A nudge to write things down when several rainy days stack up.',
        ),
        findsOneWidget,
      );

      // Tier 3 - must mention Hotline 1323 per the brief.
      expect(find.text('Support reminders'), findsOneWidget);
      expect(find.textContaining('Hotline 1323'), findsOneWidget);

      expect(find.byType(SwitchListTile), findsNWidgets(3));
    });

    testWidgets(
      'toggling tier 1 calls setTier1Enabled exactly once; other tiers stay quiet',
      (tester) async {
        final repo = _FakeRepo();
        await _pump(
          tester,
          repo: repo,
          currentUser: const AppUser(uid: 'user-1'),
        );

        // The first SwitchListTile in render order corresponds to Tier 1.
        await tester.tap(find.byType(SwitchListTile).at(0));
        await tester.pumpAndSettle();

        expect(repo.tier1Calls, [false]);
        expect(repo.tier2Calls, isEmpty);
        expect(repo.tier3Calls, isEmpty);
      },
    );

    testWidgets(
      'toggling tier 3 calls setTier3Enabled; tier 1 + 2 stay quiet',
      (tester) async {
        final repo = _FakeRepo();
        await _pump(
          tester,
          repo: repo,
          currentUser: const AppUser(uid: 'user-1'),
        );

        await tester.tap(find.byType(SwitchListTile).at(2));
        await tester.pumpAndSettle();

        expect(repo.tier3Calls, [false]);
        expect(repo.tier1Calls, isEmpty);
        expect(repo.tier2Calls, isEmpty);
      },
    );

    testWidgets(
      'each switch reads its own flag - partial opt-out renders mixed state',
      (tester) async {
        final repo = _FakeRepo()
          ..remoteSeed = const NotificationsSettings(
            cheerUpEnabled: true,
            tier1Enabled: false,
            tier2Enabled: true,
            tier3Enabled: false,
          );
        await _pump(
          tester,
          repo: repo,
          currentUser: const AppUser(uid: 'user-1'),
        );
        // Let the watchSettings stream emit.
        await tester.pumpAndSettle();

        final tiles = tester
            .widgetList<SwitchListTile>(find.byType(SwitchListTile))
            .toList();
        expect(tiles[0].value, isFalse); // Tier 1
        expect(tiles[1].value, isTrue); // Tier 2
        expect(tiles[2].value, isFalse); // Tier 3
      },
    );
  });
}
