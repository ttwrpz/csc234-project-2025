import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/widgets/cheer_up_banner.dart';
import 'package:moodbloom/features/intervention/presentation/screens/breathing_screen.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'fakes.dart';

/// Pattern detection → cheer-up banner → breathing exercise → cooldown
/// persistence flow. Closes WBS 7.3b second half.
///
/// Builds on:
///   - 5.5a (CheerUpController + InterventionStateRepository)
///   - 5.5b (CheerUpEventsRepository + sendCheerUpPush CF) for the
///     cheerUpEvents doc-create on first dispatch
///   - 6.3 (FCM toggle scaffolding) for the settings/notifications
///     doc the CF reads
///
/// What this test guarantees:
///   1. Seeding 5 distinct negative days flips the detector's
///      `triggered` flag (5-of-7 rule per `pattern_detector.dart`).
///   2. The garden screen renders a [CheerUpBanner] once `triggered`
///      is observed (the post-frame callback in `_GardenView`
///      dispatches `CheerUpController.onShown` which writes the
///      cooldown anchor).
///   3. The locked CLAUDE.md sentence is visible on the banner —
///      "It's been a heavy week. Want to try a two-minute breathing
///      exercise?" (rendered as two visible Text widgets per the v1.0
///      visual baseline; PR #28 covers the Semantics-label parity).
///   4. Tapping "Try it" pumps the [BreathingOverlay] into the dialog
///      tree.
///   5. After the post-frame callback fires, the SharedPreferences
///      mirror at `intervention.last_triggered_at_iso8601` carries an
///      ISO-8601 timestamp — proves the cooldown write reached at
///      least the offline mirror even when Firestore is unreachable in
///      the test (per ADR-0008's Firestore-primary, mirror-fallback
///      contract).
///
/// **Web parity:** the harness is platform-agnostic; the Web run is a
/// separate `flutter drive` invocation per the kickoff. This file is
/// the Android target.
const String _kLastTriggeredAtKey = 'intervention.last_triggered_at_iso8601';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pattern intervention → cheer-up banner flow', () {
    late IntegrationAuthRepository authRepo;
    late IntegrationMoodRepository moodRepo;

    setUp(() async {
      seedOnboardingComplete();
      // Pre-seed a signed-in user so the router boots straight to
      // /home and we don't redo the auth flow.
      authRepo = IntegrationAuthRepository(
        initialUser: const AppUser(
          uid: 'u-pattern',
          email: 'pattern@example.com',
        ),
      );
      moodRepo = IntegrationMoodRepository();
    });

    tearDown(() async {
      await authRepo.dispose();
      await moodRepo.dispose();
    });

    /// Build five distinct local-midnight days each carrying one
    /// negative entry. Sufficient to fire the 5-of-7 rule per
    /// `pattern_detector.dart::detectPattern`.
    List<MoodEntry> fiveOfSevenNegativeFor(String uid) {
      final today = DateTime.now();
      return [
        for (var i = 0; i < 5; i += 1)
          MoodEntry(
            id: 'pat-$i',
            userId: uid,
            mood: MoodType.sad,
            intensity: 3,
            text: '',
            createdAt: today.subtract(Duration(days: i)),
          ),
      ];
    }

    testWidgets(
      '5-of-7 negative seed → banner renders + cooldown anchor persisted',
      (tester) async {
        // Pre-seed the mood store BEFORE pumping the harness so the
        // detector observes the qualifying entries on first frame.
        // Without this seeding, the 5-of-7 window is empty and the
        // banner never appears.
        moodRepo.seed('u-pattern', fiveOfSevenNegativeFor('u-pattern'));

        final defaults = await defaultIntegrationOverrides();
        addTearDown(() async => defaults.syncManager.dispose());

        await pumpHarness(
          tester,
          overrides: [
            ...defaults.overrides,
            authRepositoryProvider.overrideWithValue(authRepo),
            moodRepositoryProvider.overrideWithValue(moodRepo),
          ],
        );

        // Pump enough frames to settle providers + run the
        // addPostFrameCallback that dispatches CheerUpController.onShown.
        // 8 × 50ms is the same cadence used by the cheer_up_dispatch_test.
        for (var i = 0; i < 8; i += 1) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // 1. Banner renders.
        expect(
          find.byType(CheerUpBanner),
          findsOneWidget,
          reason:
              'detector saw 5-of-7 negative days; the banner must render '
              'once triggered=true reaches the garden screen',
        );

        // 2. Locked CLAUDE.md copy visible (rendered as two Text widgets).
        expect(
          find.text("It's been a heavy week."),
          findsOneWidget,
          reason: 'banner title is locked verbatim per CLAUDE.md "Copy rules"',
        );
        expect(
          find.text('Want to try a two-minute breathing exercise?'),
          findsOneWidget,
          reason:
              'banner body is locked verbatim per CLAUDE.md '
              '"Intervention banner text (5-of-7)"',
        );

        // 3. Cooldown anchor persisted to the SharedPreferences mirror
        // (ADR-0008: Firestore-primary, SharedPrefs offline mirror).
        // The Firestore write may fail in the test environment because
        // the Firestore plugin isn't initialised; the mirror write is
        // the load-bearing observable.
        final prefs = await SharedPreferences.getInstance();
        final lastTriggeredAt = prefs.getString(_kLastTriggeredAtKey);
        expect(
          lastTriggeredAt,
          isNotNull,
          reason:
              'CheerUpController.onShown must write '
              'intervention.last_triggered_at_iso8601 to SharedPrefs '
              'so the 48h cooldown gate survives a cold start',
        );
        // Defense in depth: verify the value is a valid ISO-8601
        // timestamp, not garbage.
        expect(
          () => DateTime.parse(lastTriggeredAt!),
          returnsNormally,
          reason: 'the persisted anchor must round-trip via DateTime.parse',
        );

        // 4. Tap "Try it" → breathing modal opens.
        await tester.tap(find.text('Try it'));
        await tester.pump(); // modal route push
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.byType(BreathingView),
          findsOneWidget,
          reason:
              'tapping "Try it" must open the breathing modal '
              'so the user can act on the cheer-up nudge inline',
        );
      },
    );

    testWidgets('positive-only history → banner does NOT render', (
      tester,
    ) async {
      // A single positive entry today → detector reports
      // triggered=false. The banner must stay hidden so the user is
      // never nudged on a happy day. Belt-and-suspenders against any
      // future regression that fires the cheer-up nudge unconditionally
      // (e.g. a refactor that drops the `triggered` gate).
      moodRepo.seed('u-pattern', [
        MoodEntry(
          id: 'happy-1',
          userId: 'u-pattern',
          mood: MoodType.happy,
          intensity: 3,
          text: '',
          createdAt: DateTime.now(),
        ),
      ]);

      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
          moodRepositoryProvider.overrideWithValue(moodRepo),
        ],
      );

      for (var i = 0; i < 8; i += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.byType(CheerUpBanner),
        findsNothing,
        reason:
            'positive-only history: detector triggered=false; banner '
            'must NOT render. Guards against a regression that fires '
            'the cheer-up nudge on every home visit.',
      );

      // The cooldown anchor must NOT be written either — only a real
      // trigger should consume the cooldown budget.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(_kLastTriggeredAtKey),
        isNull,
        reason:
            'positive-only history: the controller must not write the '
            'cooldown anchor when the detector did not trigger',
      );
    });
  });
}
