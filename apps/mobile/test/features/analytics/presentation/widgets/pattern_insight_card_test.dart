import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/feature_flags.dart';
import 'package:moodbloom/app/providers.dart';
import 'package:moodbloom/features/analytics/domain/entities/pattern_insight.dart';
import 'package:moodbloom/features/analytics/presentation/widgets/pattern_insight_card.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/ai_analysis_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../../mood/domain/fakes/fake_ai_analysis_repository.dart';
import '../../../mood/domain/fakes/fake_mood_repository.dart';

class _StaticFlagSource implements FeatureFlagSource {
  const _StaticFlagSource(this.value);
  final bool value;
  @override
  bool getBool(String key) => value;
}

PatternInsight _insight({
  required PatternInsightKind kind,
  required String text,
  required double confidence,
  int sampleSize = 30,
}) {
  return PatternInsight(
    id: '${kind.name}-1',
    kind: kind,
    text: text,
    confidence: confidence,
    sampleSize: sampleSize,
    generatedAt: DateTime(2026, 5, 1, 10),
  );
}

MoodEntry _entry({String id = 'e'}) => MoodEntry(
  id: id,
  userId: 'u-1',
  mood: MoodType.happy,
  intensity: 3,
  text: '',
  createdAt: DateTime(2026, 5, 1, 9),
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required bool flagOn,
  required FakeMoodRepository repo,
  required FakeAiAnalysisRepository aiRepo,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureFlagSourceProvider.overrideWithValue(_StaticFlagSource(flagOn)),
        moodRepositoryProvider.overrideWithValue(repo),
        aiAnalysisRepositoryProvider.overrideWithValue(aiRepo),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(
            const AppUser(uid: 'u-1', email: 'u@example.com'),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const Scaffold(body: PatternInsightCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PatternInsightCard', () {
    testWidgets('flag off → renders SizedBox.shrink (no header, no copy)', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        flagOn: false,
        repo: FakeMoodRepository()..streamedEntries = [const []],
        aiRepo: FakeAiAnalysisRepository(),
      );
      // The MbCard shell carries the "Insights" header. Flag off means no
      // shell at all is rendered.
      expect(find.byType(MbCard), findsNothing);
      expect(find.text('Insights'), findsNothing);
    });

    testWidgets('flag on + empty entries → renders the empty-state copy', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        flagOn: true,
        repo: FakeMoodRepository()..streamedEntries = [const []],
        aiRepo: FakeAiAnalysisRepository(),
      );
      expect(
        find.text('Keep tending your garden - patterns bloom here as the days fill in.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'flag on + insights returned → renders rows with the insight text',
      (tester) async {
        final aiRepo = FakeAiAnalysisRepository(
          nextPatternResult: Ok([
            _insight(
              kind: PatternInsightKind.weekday,
              text:
                  'Your Monday mood averages 1.8 lower than the rest of the week.',
              confidence: 0.85,
              sampleSize: 42,
            ),
          ]),
        );
        await _pumpCard(
          tester,
          flagOn: true,
          repo: FakeMoodRepository()
            ..streamedEntries = [
              [_entry()],
            ],
          aiRepo: aiRepo,
        );

        // Card shell carries the "AI Insight" header; the row text +
        // sample size are the per-row signals.
        expect(find.text('AI Insight'), findsOneWidget);
        expect(
          find.text(
            'Your Monday mood averages 1.8 lower than the rest of the week.',
          ),
          findsOneWidget,
        );
        expect(find.text('42 samples'), findsOneWidget);
      },
    );

    testWidgets('flag on + repo returns Err → renders the error-state copy', (
      tester,
    ) async {
      final aiRepo = FakeAiAnalysisRepository(
        nextPatternResult: const Err(AiAnalysisFailure.geminiUnavailable()),
      );
      await _pumpCard(
        tester,
        flagOn: true,
        repo: FakeMoodRepository()
          ..streamedEntries = [
            [_entry()],
          ],
        aiRepo: aiRepo,
      );
      expect(
        find.text("We couldn't read your patterns just now."),
        findsOneWidget,
      );
    });

    testWidgets('flag on + repo returns Ok([]) → empty-state copy', (
      tester,
    ) async {
      final aiRepo = FakeAiAnalysisRepository(
        nextPatternResult: const Ok(<PatternInsight>[]),
      );
      await _pumpCard(
        tester,
        flagOn: true,
        repo: FakeMoodRepository()
          ..streamedEntries = [
            [_entry()],
          ],
        aiRepo: aiRepo,
      );
      expect(
        find.text('Keep tending your garden - patterns bloom here as the days fill in.'),
        findsOneWidget,
      );
    });
  });
}
