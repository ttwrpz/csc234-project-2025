import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/history/presentation/widgets/mood_entry_tile.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/presentation/controllers/ai_suggestion_controller.dart';

import 'app_harness.dart';
import 'fakes.dart';

/// Mood-log → history → detail integration flow. Drives the production
/// app from a signed-in /home through the FAB to /log-mood, picks a sad
/// mood at intensity 3, types a short note, saves, then taps the new
/// entry from the history list and asserts the detail screen renders the
/// mood, intensity, and text we entered.
///
/// Step 2 of WBS 7.3a - pumps real screens (no widget-level shortcuts) so
/// the router transitions, controller resets, and Riverpod stream
/// plumbing are exercised end-to-end against the same fakes the auth
/// flow uses.
///
/// **Web parity:** the harness is platform-agnostic, but per the S5
/// kickoff the Web run is a separate `flutter drive` invocation. This
/// file is the Android target; Chrome verification follows in a later
/// step.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mood log → history → detail flow', () {
    late IntegrationAuthRepository authRepo;
    late IntegrationMoodRepository moodRepo;

    setUp(() async {
      seedOnboardingComplete();
      // Pre-seed a signed-in user so the router boots straight to /home
      // and the test focuses on the log → history transition rather than
      // re-running the auth flow that auth_flow_test.dart already covers.
      authRepo = IntegrationAuthRepository(
        initialUser: const AppUser(uid: 'u-mood', email: 'user@example.com'),
      );
      moodRepo = IntegrationMoodRepository();
    });

    tearDown(() async {
      await authRepo.dispose();
      await moodRepo.dispose();
    });

    testWidgets(
      'logs sad@3 with note then detail screen renders all three fields',
      (tester) async {
        final defaults = await defaultIntegrationOverrides();
        addTearDown(() async => defaults.syncManager.dispose());

        await pumpHarness(
          tester,
          overrides: [
            ...defaults.overrides,
            authRepositoryProvider.overrideWithValue(authRepo),
            moodRepositoryProvider.overrideWithValue(moodRepo),
            // Force the AI suggestion debounce far past any pumpAndSettle
            // window so the controller's timer never fires during the
            // test. Without this, typing a note triggers a real
            // `analyzeMoodTextUseCase` call that hits Cloud Functions.
            // The pill stays at `data(null)` (a `SizedBox.shrink`) for
            // the duration of the flow.
            aiSuggestionDebounceWindowProvider.overrideWithValue(
              const Duration(days: 1),
            ),
          ],
        );

        // Sanity: the home screen's "Log mood" FAB is the documented
        // entry point. Anchoring on its label rather than a tooltip or a
        // type lookup keeps the assertion stable if the icon changes.
        expect(
          find.text('Log mood'),
          findsOneWidget,
          reason: 'home FAB must render the "Log mood" CTA on first frame',
        );

        // 1. FAB → /log-mood.
        await tester.tap(find.text('Log mood'));
        await tester.pumpAndSettle();

        expect(
          find.text('How are you?'),
          findsOneWidget,
          reason: 'tapping the FAB must land us on the LogMood screen',
        );

        // 2. Pick the "sad" mood tile. The tile is keyed on its
        // semantics label which mirrors `${type.name}, mood selector
        // tile` in mood_type_tile.dart - tapping the visible text label
        // is enough because each tile renders the mood name uniquely.
        await tester.tap(find.text('sad'));
        await tester.pumpAndSettle();

        // 3. Intensity defaults to 3 (see MoodDraft.empty()), so the
        // test deliberately does NOT drag the slider - slider drag-
        // distance → integer rounding is brittle in integration_test
        // because the rendered viewport varies by host. We assert the
        // "n / 5" header echoes the expected value instead, which is
        // the load-bearing visible signal that the draft holds 3.
        expect(
          find.text('3 / 5'),
          findsOneWidget,
          reason: 'default intensity is 3 - the header must reflect it',
        );

        // 4. Type the note. The screen has exactly one TextField (the
        // multi-line MoodTextField); media-picker controls are buttons,
        // not text inputs, so this finder is unambiguous.
        await tester.enterText(find.byType(TextField), 'long day');
        await tester.pumpAndSettle();

        // 5. Save. MbPrimaryButton wraps a FilledButton; matching by
        // label keeps the finder resilient to the design-system
        // refactors that touched the wrapper class twice already this
        // sprint.
        final saveButton = find.widgetWithText(FilledButton, 'Save entry');
        expect(
          saveButton,
          findsOneWidget,
          reason:
              'Save bar label flips between "Pick a feeling…" and '
              '"Save entry" - once a mood is picked, the latter must '
              'be visible',
        );
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // 6. The fake repo records the save.
        expect(
          moodRepo.saveCalls,
          hasLength(1),
          reason: 'tapping Save must invoke MoodRepository.save exactly once',
        );
        final saved = moodRepo.saveCalls.single;
        expect(saved.mood, equals(MoodType.sad));
        expect(saved.intensity, equals(3));
        expect(saved.text, equals('long day'));
        expect(
          saved.userId,
          equals('u-mood'),
          reason:
              'the save use case must thread the signed-in uid through to '
              'the repository - guards against future "anon save" regressions',
        );

        // 7. Save success routes to /history. The list view header
        // "History" anchors the assertion.
        expect(
          find.text('History'),
          findsOneWidget,
          reason:
              'after a successful save the create flow lands on /history '
              '(see LogMoodScreen._onSave)',
        );

        // 8. The freshly-saved entry shows up in the list. We find the
        // single MoodEntryTile (the seed has zero entries before the
        // save, so exactly one tile is expected).
        final tile = find.byType(MoodEntryTile);
        expect(
          tile,
          findsOneWidget,
          reason:
              'the new sad@3 entry must appear in the History list - the '
              'IntegrationMoodRepository broadcast stream feeds '
              'myMoodsStreamProvider live, no manual refresh required',
        );
        // The list tile renders the mood name as plain text. There may
        // be more than one "sad" rendered later (filter chips don't
        // match this label), but the tile is the only one in this seed.
        expect(
          find.descendant(of: tile, matching: find.text('sad')),
          findsOneWidget,
          reason: 'tile must render the mood name "sad"',
        );

        // 9. Tap the tile → /history/<id>.
        await tester.tap(tile);
        await tester.pumpAndSettle();

        // 10. Detail screen renders the mood, intensity caption, and
        // the user-typed note. The "Entry" header anchors the
        // post-condition that we are on EntryDetailScreen specifically
        // and not on a tile re-render of HistoryScreen.
        expect(
          find.text('Entry'),
          findsOneWidget,
          reason: 'detail screen header must be visible',
        );
        expect(
          find.text('sad'),
          findsAtLeastNWidgets(1),
          reason: 'detail Card title must render the mood name',
        );
        expect(
          find.text('intensity 3 / 5'),
          findsOneWidget,
          reason:
              'detail screen renders the intensity caption '
              '"intensity <n> / 5" - locked into the prototype copy',
        );
        expect(
          find.text('long day'),
          findsOneWidget,
          reason: 'the user-typed note must be rendered verbatim on detail',
        );
      },
    );
  });
}
