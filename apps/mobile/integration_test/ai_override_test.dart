import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/analytics/domain/entities/pattern_insight.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/ai_analysis_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/ai_suggestion.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/repositories/ai_analysis_repository.dart';
import 'package:moodbloom/features/mood/presentation/controllers/ai_suggestion_controller.dart';

import 'app_harness.dart';
import 'fakes.dart';

/// Recording fake of [AIAnalysisRepository]. The `analyzeMoodText` Cloud
/// Function (S3 — `analyzeMoodText.ts`) is intercepted here so the test
/// never reaches Firebase: every call lands in [analyzeMoodTextCalls] and
/// returns the test-seeded [nextSuggestion].
///
/// `analyzePatterns` is wired with a benign Ok(empty) so any unrelated
/// caller (e.g. the Patterns tab) does not throw on an "unimplemented"
/// path. The override path tested here never touches that method.
class _FakeAiAnalysisRepository implements AIAnalysisRepository {
  _FakeAiAnalysisRepository({required this.nextSuggestion});

  AiSuggestion nextSuggestion;

  final List<String> analyzeMoodTextCalls = <String>[];

  @override
  bool get isEnabled => true;

  @override
  Future<Result<AiSuggestion, AiAnalysisFailure>> analyzeMoodText({
    required String text,
    String? locale,
  }) async {
    analyzeMoodTextCalls.add(text);
    return Ok(nextSuggestion);
  }

  @override
  Future<Result<List<PatternInsight>, AiAnalysisFailure>> analyzePatterns({
    required List<MoodEntry> history,
    int windowDays = 90,
  }) async {
    return const Ok(<PatternInsight>[]);
  }
}

/// WBS 8.3 Test 3 — AI override flow.
///
/// Validates the user-override contract for `analyzeMoodText` (S3 feature,
/// HB-002): the AI is a SUGGESTER, never a chooser. The user can ignore
/// the suggestion and pick a different mood; the saved [MoodEntry] reflects
/// the user's pick byte-for-byte.
///
/// Contract under test:
///   1. Open /log-mood, type into the journal field.
///   2. The fake [AIAnalysisRepository] returns `suggestedMood: sadness`,
///      `confidence: 0.85`.
///   3. The AI suggestion pill renders with the "AI suggests" leading
///      label + a "Dismiss" button + an "Accept" button (see
///      `ai_suggestion_pill.dart`).
///   4. The user OVERRIDES — taps the `happy` mood tile (NOT "Accept"),
///      then taps Save.
///   5. The repository sees a save with `mood: happy`. The AI's pick
///      lost; the user's pick won.
///
/// **Cloud Function interception:** the `_FakeAiAnalysisRepository`
/// replaces `aiAnalysisRepositoryProvider` so the production
/// `AiAnalysisFunctionsDatasource` (which wraps `FirebaseFunctions
/// .httpsCallable('analyzeMoodText')`) is never reached. No actual
/// `FirebaseFunctions` instance is constructed during the test.
///
/// Domain purity: tests-only file; touches no production code.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI override flow (WBS 8.3 — Test 3)', () {
    late IntegrationAuthRepository authRepo;
    late IntegrationMoodRepository moodRepo;
    late _FakeAiAnalysisRepository aiRepo;

    setUp(() async {
      seedOnboardingComplete();
      authRepo = IntegrationAuthRepository(
        initialUser: const AppUser(
          uid: 'u-override',
          email: 'override@example.com',
        ),
      );
      moodRepo = IntegrationMoodRepository();
      // Seed Gemini's "best guess" as `sad` at 85% confidence — the
      // confidence stays in the "high" band so the pill renders the
      // strong-suggestion variant.
      aiRepo = _FakeAiAnalysisRepository(
        nextSuggestion: const AiSuggestion(
          mood: MoodType.sad,
          confidence: 0.85,
          rationale: 'words like "terrible" suggest sadness',
          latency: Duration(milliseconds: 120),
          intensity: 4,
        ),
      );
    });

    tearDown(() async {
      await authRepo.dispose();
      await moodRepo.dispose();
    });

    testWidgets(
      'AI suggests "sad" — user overrides with "happy" — save honors the user',
      (tester) async {
        final defaults = await defaultIntegrationOverrides();
        addTearDown(() async => defaults.syncManager.dispose());

        await pumpHarness(
          tester,
          overrides: [
            ...defaults.overrides,
            authRepositoryProvider.overrideWithValue(authRepo),
            moodRepositoryProvider.overrideWithValue(moodRepo),
            aiAnalysisRepositoryProvider.overrideWithValue(aiRepo),
            // Shrink the debounce so the AI fires inside the test
            // budget instead of waiting for the production 600ms.
            aiSuggestionDebounceWindowProvider.overrideWithValue(
              const Duration(milliseconds: 20),
            ),
            // The production min-char threshold is 12 chars; we keep
            // it that way (our seeded text is 16 chars) so the test
            // exercises the real fire condition, not a corner-case.
          ],
        );

        // 1. Navigate to /log-mood.
        await tester.tap(find.text('Log mood'));
        await tester.pumpAndSettle();
        expect(find.text('How are you?'), findsOneWidget);

        // 2. Type a long-enough note to clear the 12-char min and
        // trigger the debounced AI fire.
        await tester.enterText(find.byType(TextField), 'I feel terrible today');
        // Pump the debounce duration + a little slack so the timer
        // fires and the use case resolves. The fake is synchronous so
        // pumpAndSettle is enough once the timer fires.
        await tester.pump(const Duration(milliseconds: 30));
        await tester.pumpAndSettle();

        // 3. The AI suggestion pill rendered. The "AI suggests"
        // leading label is the load-bearing anchor (see
        // ai_suggestion_pill.dart::_SuggestionBody).
        expect(
          find.text('AI suggests'),
          findsOneWidget,
          reason:
              'after the debounce fires the AISuggestionPill must show '
              'the "AI suggests" leading caption',
        );
        // Defence-in-depth: the fake recorded exactly one call with
        // the user's typed text.
        expect(
          aiRepo.analyzeMoodTextCalls,
          hasLength(1),
          reason:
              'the AI use case must fire exactly once for the seeded '
              'text after a single debounce window',
        );
        expect(
          aiRepo.analyzeMoodTextCalls.single,
          equals('I feel terrible today'),
          reason: 'the typed note must be forwarded to the AI verbatim',
        );

        // 4. OVERRIDE — tap the `happy` mood tile instead of the
        // pill's "Accept" button. The mood tiles render the mood
        // names; the AI suggestion does NOT echo the word "happy" so
        // this finder is unambiguous.
        await tester.tap(find.text('happy'));
        await tester.pumpAndSettle();

        // 5. Save the entry.
        final saveButton = find.widgetWithText(FilledButton, 'Save entry');
        expect(
          saveButton,
          findsOneWidget,
          reason: 'save bar must read "Save entry" once a mood is picked',
        );
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // 6. Hard assertion — the user's pick won, the AI's lost.
        expect(
          moodRepo.saveCalls,
          hasLength(1),
          reason: 'tap Save must invoke MoodRepository.save exactly once',
        );
        final saved = moodRepo.saveCalls.single;
        expect(
          saved.mood,
          equals(MoodType.happy),
          reason:
              'AI suggested SAD with 85% confidence; the user picked HAPPY. '
              'The saved entry must honour the user pick — the AI is a '
              'suggester, never a chooser (HB-002 + S3 contract).',
        );
        expect(
          saved.userId,
          equals('u-override'),
          reason: 'the signed-in uid must reach the repository',
        );
      },
    );
  });
}
