import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
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

/// Sprint 5 Day 3 a11y sweep - per-tier notification toggle tile.
///
/// Covered:
///   1. Each of the 3 tiles announces title + subtitle (the
///      compassionate-imperatives copy from CLAUDE.md).
///   2. Subtitles follow the locked copy strings - "Quiet reminders…",
///      "A nudge to write…", "If something feels heavy…" + the
///      Hotline 1323 reference on the Tier 3 tile.
///   3. The switch's value is reachable in the semantics tree (the
///      SwitchListTile composes the on/off state into a toggleable
///      role; Material's merge strategy varies across versions so we
///      verify via the SwitchListTile.value getter, not the raw flag).
///   4. 200% type: 3 stacked tiles render without RenderFlex overflow.

class _StubRepo implements FcmTokenRepository {
  @override
  Future<Result<void, NotificationFailure>> upsertToken({
    required String uid,
  }) async => const Ok(null);
  @override
  Future<Result<void, NotificationFailure>> setEnabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);
  @override
  Future<Result<void, NotificationFailure>> setTier1Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);
  @override
  Future<Result<void, NotificationFailure>> setTier2Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);
  @override
  Future<Result<void, NotificationFailure>> setTier3Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);
  @override
  Stream<NotificationsSettings>? watchSettings({required String uid}) {
    return Stream<NotificationsSettings>.value(
      const NotificationsSettings(
        cheerUpEnabled: true,
        tier1Enabled: true,
        tier2Enabled: true,
        tier3Enabled: true,
      ),
    );
  }
}

Future<void> _pumpThreeTiles(
  WidgetTester tester, {
  TextScaler textScaler = const TextScaler.linear(1.0),
  Size surfaceSize = const Size(420, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  SharedPreferences.setMockInitialValues(const {});
  final sp = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsPreferenceDatasourceProvider.overrideWithValue(
          NotificationsPreferenceDatasource(sp),
        ),
        fcmTokenRepositoryProvider.overrideWithValue(_StubRepo()),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(
            const AppUser(uid: 'u-1', email: 't@example.com'),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const Scaffold(
          body: Column(
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
  // Drain the watchSettings stream so the switches reflect the seed.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('TierToggleTile - semantics labels (compassionate copy)', () {
    testWidgets('Tier 1 announces "Gentle nudges" + compassionate subtitle', (
      tester,
    ) async {
      await _pumpThreeTiles(tester);
      expect(find.text('Gentle nudges'), findsOneWidget);
      // Subtitle follows CLAUDE.md "compassionate imperatives" + the
      // ecosystem "weathering" copy convention.
      expect(
        find.text(
          'Quiet reminders when the garden has been weathering for a while.',
        ),
        findsOneWidget,
        reason:
            'Tier 1 subtitle MUST use the locked compassionate-copy '
            'phrasing - any reword needs copy-reviewer sign-off.',
      );
    });

    testWidgets(
      'Tier 2 announces "Journaling check-ins" + writing-prompt subtitle',
      (tester) async {
        await _pumpThreeTiles(tester);
        expect(find.text('Journaling check-ins'), findsOneWidget);
        expect(
          find.text(
            'A nudge to write things down when several rainy days stack up.',
          ),
          findsOneWidget,
          reason:
              'Tier 2 subtitle MUST use the locked "rainy days" phrasing - '
              'no clinical language per CLAUDE.md copy rules.',
        );
      },
    );

    testWidgets(
      'Tier 3 announces "Support reminders" + Hotline 1323 reference',
      (tester) async {
        await _pumpThreeTiles(tester);
        expect(find.text('Support reminders'), findsOneWidget);
        // The brief requires Tier 3 to name Hotline 1323 explicitly so
        // users know what they're disabling, framed as a caring message
        // with helpline details rather than a clinical crisis line.
        expect(
          find.textContaining('Hotline 1323'),
          findsOneWidget,
          reason:
              'Tier 3 subtitle must name Hotline 1323 explicitly - users '
              'need to know what they\'re opting out of.',
        );
        expect(
          find.textContaining('caring message'),
          findsOneWidget,
          reason:
              'Tier 3 subtitle uses gentle "caring message" framing per '
              'CLAUDE.md compassionate imperatives.',
        );
      },
    );

    testWidgets(
      'each switch announces its on/off state via the SwitchListTile',
      (tester) async {
        await _pumpThreeTiles(tester);
        // The remote seed has all 3 tiers enabled. Verify the
        // SwitchListTile widget exposes value: true so the underlying
        // Switch semantics carries the toggled state.
        final tiles = tester
            .widgetList<SwitchListTile>(find.byType(SwitchListTile))
            .toList();
        expect(tiles, hasLength(3));
        // SwitchListTile composes the on/off state into a toggleable
        // Semantics node. We don't introspect the raw flag (Material's
        // merge strategy varies by version, per the baseline
        // notifications_toggle_tile_a11y_test rationale) - instead we
        // pin the value getter directly.
        expect(tiles[0].value, isTrue);
        expect(tiles[1].value, isTrue);
        expect(tiles[2].value, isTrue);
      },
    );
  });

  group('TierToggleTile - 200% type readability', () {
    testWidgets(
      '3 stacked tiles render without RenderFlex overflow at 200% type',
      (tester) async {
        final exceptions = <Object>[];
        FlutterError.onError = (details) => exceptions.add(details.exception);
        addTearDown(
          () => FlutterError.onError = FlutterError.dumpErrorToConsole,
        );

        // Generous height so 3 tiles can stack vertically at 2x type.
        // The Tier 3 subtitle is the longest - at 200% it wraps to 3
        // lines on a narrow phone.
        await _pumpThreeTiles(
          tester,
          textScaler: const TextScaler.linear(2.0),
          surfaceSize: const Size(420, 1400),
        );

        final overflows = exceptions
            .map((e) => e.toString())
            .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
            .toList();
        expect(
          overflows,
          isEmpty,
          reason:
              'Three stacked TierToggleTiles must not overflow at 200%. '
              'Got: $overflows',
        );

        // Sanity - all three titles are still reachable.
        expect(find.text('Gentle nudges'), findsOneWidget);
        expect(find.text('Journaling check-ins'), findsOneWidget);
        expect(find.text('Support reminders'), findsOneWidget);
      },
    );
  });
}
