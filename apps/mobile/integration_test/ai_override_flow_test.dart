import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/presentation/controllers/ai_suggestion_controller.dart';
import 'package:moodbloom/features/mood/presentation/widgets/ai_suggestion_pill.dart';

import 'app_harness.dart';
import 'fakes.dart';

/// AI suggestion → user override → save flow. Closes WBS 7.3b.
///
/// The contract this exercises:
///   1. User opens /log-mood and types into the journal field.
///   2. The AI suggestion pill debounces, calls `analyzeMoodText`, and
///      surfaces a suggestion (here we script a high-confidence
///      "anxious" via [IntegrationAiAnalysisRepository]).
///   3. User taps a DIFFERENT mood tile ("sad") — disagreeing with the
///      AI even when the model is confident.
///   4. Save → the persisted [MoodEntry] carries the user's pick, NOT
///      the AI's. The fake mood repo's `saveCalls` makes this assertable.
///
/// **Web parity:** the harness is platform-agnostic; the Web run is a
/// separate `flutter drive` invocation per the kickoff. This file is
/// the Android target.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI override flow', () {
    late IntegrationAuthRepository authRepo;
    late IntegrationMoodRepository moodRepo;
    late IntegrationAiAnalysisRepository aiRepo;

    setUp(() async {
      seedOnboardingComplete();
      authRepo = IntegrationAuthRepository(
        initialUser: const AppUser(
          uid: 'u-override',
          email: 'override@example.com',
        ),
      );
      moodRepo = IntegrationMoodRepository();
      aiRepo = IntegrationAiAnalysisRepository();
    });

    tearDown(() async {
      await authRepo.dispose();
      await moodRepo.dispose();
    });

    testWidgets('user picks a different mood than the AI suggests; saved entry '
        'uses the user pick', (tester) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
          moodRepositoryProvider.overrideWithValue(moodRepo),
          aiAnalysisRepositoryProvider.overrideWithValue(aiRepo),
          // Shrink the debounce window so the AI call fires inside
          // pumpAndSettle. 30ms is well under any human typing
          // cadence and well above zero (zero would race the
          // setState that arms the timer).
          aiSuggestionDebounceWindowProvider.overrideWithValue(
            const Duration(milliseconds: 30),
          ),
        ],
      );

      // 1. Open /log-mood from the home FAB.
      expect(
        find.text('Log mood'),
        findsOneWidget,
        reason: 'home FAB must render the "Log mood" CTA on first frame',
      );
      await tester.tap(find.text('Log mood'));
      await tester.pumpAndSettle();

      expect(
        find.text('How are you?'),
        findsOneWidget,
        reason: 'tapping the FAB must land us on the LogMood screen',
      );

      // 2. Type the journal note. The screen has exactly one TextField
      // (the multi-line MoodTextField); media-picker controls are
      // buttons, not text inputs, so this finder is unambiguous.
      await tester.enterText(find.byType(TextField), 'long day at work');

      // Pump past the debounce window plus the (synchronous) fake
      // analyzeMoodText call. 8 × 50ms is the same cadence used by
      // the cheer-up dispatch test and gives the controller time to
      // transition loading → data without flake.
      for (var i = 0; i < 8; i += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 3. The suggestion pill renders the AI's pick.
      expect(
        find.byType(AISuggestionPill),
        findsOneWidget,
        reason: 'AISuggestionPill must mount on the LogMood screen',
      );
      expect(
        find.text('AI suggests'),
        findsOneWidget,
        reason:
            'the AI suggestion card must surface its "AI suggests" '
            'header once the controller resolves data(suggestion)',
      );
      // The fake's default suggestion is `anxious`. The pill renders
      // the mood name with a leading-uppercase display name.
      expect(
        find.text('Anxious'),
        findsAtLeastNWidgets(1),
        reason:
            'the suggestion card must surface the AI mood — display '
            'name is leading-uppercase per AISuggestionPill._SuggestionBody',
      );
      expect(
        aiRepo.analyzeMoodTextCalls,
        contains('long day at work'),
        reason:
            'analyzeMoodText must be called with the user-typed text — '
            'a regression that drops the call would silently disable '
            'the suggestion path without failing the visible assertions',
      );

      // 4. The user disagrees and taps a DIFFERENT mood tile. The
      // tiles render mood names in lowercase per mood_type_tile.dart.
      // We pick "sad" — a different category from the AI's "anxious"
      // — to make the divergence loud.
      await tester.tap(find.text('sad'));
      await tester.pumpAndSettle();

      // The selected mood drives the save header label transition.
      expect(
        find.text('3 / 5'),
        findsOneWidget,
        reason:
            'default intensity is 3 — the "n / 5" header must echo the '
            'draft state once a mood is picked',
      );

      // 5. Save. MbPrimaryButton wraps a FilledButton; matching by
      // label keeps the finder resilient to design-system refactors.
      final saveButton = find.widgetWithText(FilledButton, 'Save entry');
      expect(
        saveButton,
        findsOneWidget,
        reason: 'Save bar must show "Save entry" once a mood is picked',
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 6. The fake repo records the save with the USER's pick, not
      // the AI's. This is the load-bearing assertion of the override
      // contract — the AI confidence (0.86 anxious) does NOT leak
      // into the saved entry.
      expect(
        moodRepo.saveCalls,
        hasLength(1),
        reason: 'tapping Save must invoke MoodRepository.save exactly once',
      );
      final saved = moodRepo.saveCalls.single;
      expect(
        saved.mood,
        equals(MoodType.sad),
        reason:
            'the saved entry must use the user-picked mood (sad), '
            'NOT the AI suggestion (anxious). This is the load-bearing '
            'override invariant.',
      );
      expect(saved.intensity, equals(3));
      expect(saved.text, equals('long day at work'));
      expect(
        saved.userId,
        equals('u-override'),
        reason:
            'the save use case must thread the signed-in uid through '
            'to the repository — guards against future "anon save" '
            'regressions',
      );
    });

    testWidgets(
      'override path is independent of the AI mood — happy override of '
      'an anxious suggestion saves happy',
      (tester) async {
        // Belt-and-suspenders against any accidental coupling between
        // the AI suggestion's category and the user-picked mood. Same
        // contract as the first test but with the user override moving
        // the entry to "happy" — a category opposite of the AI's
        // suggestion.
        final defaults = await defaultIntegrationOverrides();
        addTearDown(() async => defaults.syncManager.dispose());

        await pumpHarness(
          tester,
          overrides: [
            ...defaults.overrides,
            authRepositoryProvider.overrideWithValue(authRepo),
            moodRepositoryProvider.overrideWithValue(moodRepo),
            aiAnalysisRepositoryProvider.overrideWithValue(aiRepo),
            aiSuggestionDebounceWindowProvider.overrideWithValue(
              const Duration(milliseconds: 30),
            ),
          ],
        );

        await tester.tap(find.text('Log mood'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'meh, fine I guess');
        for (var i = 0; i < 8; i += 1) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.byType(AISuggestionPill), findsOneWidget);

        await tester.tap(find.text('happy'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Save entry'));
        await tester.pumpAndSettle();

        expect(moodRepo.saveCalls, hasLength(1));
        expect(
          moodRepo.saveCalls.single.mood,
          equals(MoodType.happy),
          reason:
              'opposite-category override path: user-picked happy still '
              'wins on save against an anxious suggestion. Belt-and-'
              'suspenders for the override invariant.',
        );
      },
    );
  });
}
