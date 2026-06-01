@Tags(['golden'])
library;

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/app/feature_flags.dart';
import 'package:moodbloom/app/providers.dart';
import 'package:moodbloom/features/analytics/domain/entities/pattern_insight.dart';
import 'package:moodbloom/features/analytics/presentation/widgets/pattern_insight_card.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../../../support/golden_fonts.dart';
import '../../../mood/domain/fakes/fake_ai_analysis_repository.dart';
import '../../../mood/domain/fakes/fake_mood_repository.dart';

/// Visual goldens for the analytics `PatternInsightCard`. Restored after
/// commit 8a72f5ad trimmed the golden suite, then re-wired to the
/// CURRENT provider graph:
///   * flag is read through `featureFlagsProvider` -> we override
///     `featureFlagSourceProvider` with a static stub (matches the live
///     `pattern_insight_card_test.dart`).
///   * card data comes from `myMoodsStreamProvider`
///     (`currentUserStreamProvider` + `moodRepositoryProvider`) feeding
///     `aiAnalysisRepositoryProvider.analyzePatterns`.
/// The old `_StaticFlagSource` + override set is preserved verbatim; the
/// confidence-band baselines (low / medium / high / disabled) still map
/// onto `MbConfidenceBadge` tones.

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
  required FakeAiAnalysisRepository aiRepo,
}) async {
  final repo = FakeMoodRepository()
    ..streamedEntries = [
      [_entry()],
    ];
  await tester.binding.setSurfaceSize(const Size(420, 240));
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
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: PatternInsightCard(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  installOfflineGoogleFonts();

  testGoldens('PatternInsightCard - low confidence chip', (tester) async {
    final aiRepo = FakeAiAnalysisRepository(
      nextPatternResult: Ok([
        _insight(
          kind: PatternInsightKind.weekday,
          text:
              'Your Monday mood averages 0.4 lower than the rest of the week.',
          confidence: 0.3,
          sampleSize: 12,
        ),
      ]),
    );
    await _pumpCard(tester, flagOn: true, aiRepo: aiRepo);
    await screenMatchesGolden(tester, 'pattern_insight_card_low');
  });

  testGoldens('PatternInsightCard - medium confidence chip', (tester) async {
    final aiRepo = FakeAiAnalysisRepository(
      nextPatternResult: Ok([
        _insight(
          kind: PatternInsightKind.streak,
          text: "You've had three or more heavy days in a row.",
          confidence: 0.65,
          sampleSize: 5,
        ),
      ]),
    );
    await _pumpCard(tester, flagOn: true, aiRepo: aiRepo);
    await screenMatchesGolden(tester, 'pattern_insight_card_medium');
  });

  testGoldens('PatternInsightCard - high confidence chip', (tester) async {
    final aiRepo = FakeAiAnalysisRepository(
      nextPatternResult: Ok([
        _insight(
          kind: PatternInsightKind.weekday,
          text:
              'Your Monday mood averages 1.8 lower than the rest of the week.',
          confidence: 0.92,
          sampleSize: 42,
        ),
      ]),
    );
    await _pumpCard(tester, flagOn: true, aiRepo: aiRepo);
    await screenMatchesGolden(tester, 'pattern_insight_card_high');
  });

  testGoldens('PatternInsightCard - disabled (flag off -> shrink)', (
    tester,
  ) async {
    final aiRepo = FakeAiAnalysisRepository(
      nextPatternResult: Ok([
        _insight(
          kind: PatternInsightKind.weekday,
          text: 'This text would render if the flag were on.',
          confidence: 0.85,
          sampleSize: 20,
        ),
      ]),
    );
    await _pumpCard(tester, flagOn: false, aiRepo: aiRepo);
    await screenMatchesGolden(tester, 'pattern_insight_card_disabled');
  });
}
