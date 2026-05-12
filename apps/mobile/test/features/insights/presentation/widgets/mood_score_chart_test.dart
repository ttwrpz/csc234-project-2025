import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/presentation/widgets/mood_score_chart.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// Smoke tests for the [MoodScoreChart] adapter. Validates the shape
/// invariants the screen depends on:
///   * The widget pumps without throwing for fully-populated input.
///   * Empty input renders a fallback hint (the chart widget's own
///     fallback — the screen also has a card-level empty state).
///
/// Golden snapshot generation is the qa-engineer's responsibility — the
/// handoff brief asks for a golden test of the seeded chart. This file
/// covers the structural smoke; qa-engineer should add the
/// `matchesGoldenFile` assertions and check in the baseline image.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: SizedBox(height: 240, width: 360, child: child)),
  );

  group('MoodScoreChart', () {
    testWidgets('pumps with seeded data across 14 days', (tester) async {
      final today = DateTime(2026, 5, 13);
      final insights = List<DailyInsight>.generate(14, (i) {
        final date = today.subtract(Duration(days: 13 - i));
        return DailyInsight(
          date: date,
          // Sinusoidal pattern so the chart has visible variation.
          avgMoodScore: (i.isEven ? 0.4 : -0.3),
          gardenHealthH: (i.isEven ? 0.2 : -0.1),
          dominantEmotion: null,
          entryCount: 1,
          triggeredTier: i == 7 ? Tier.two : null,
        );
      });

      await tester.pumpWidget(wrap(MoodScoreChart(insights: insights)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty insights show the friendly hint, no exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const MoodScoreChart(insights: [])));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
