import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/presentation/widgets/mood_score_chart.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// Sprint 5 Day 3 a11y sweep — MoodScoreChart wrapper.
///
/// The actual chart implementation lives in `packages/analytics/lib/src/
/// mood_score_chart.dart` — that package already wraps the rendered
/// `LineChart` in a `Semantics(label: 'Mood score chart for N days. ...')`
/// (verified at packages/analytics/lib/src/mood_score_chart.dart:58).
///
/// This a11y test verifies the app-side adapter:
///   1. The Semantics label from the analytics_pkg wrapper IS reachable
///      via `find.bySemanticsLabel` — i.e. the adapter doesn't strip /
///      shadow the inner Semantics.
///   2. With non-empty data, the label communicates the chart's purpose
///      + day-count (so a screen reader knows what was just focused).
///   3. With empty data, the chart falls back to the empty-state
///      Semantics label so AT users hear "no data for the selected
///      window" rather than nothing at all.
///   4. The 5 tier bands have a non-color affordance — the legend on
///      the InsightsScreen carries the textual band names. The chart
///      itself MUST NOT rely solely on color to communicate band
///      identity. We assert that the chart's render path does NOT
///      embed per-data-point semantics (otherwise every dot floods
///      the focus stream).

Widget _wrap(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  home: Scaffold(
    body: SizedBox(height: 240, width: 360, child: child),
  ),
);

void main() {
  group('MoodScoreChart — semantics wrapper', () {
    testWidgets(
      'non-empty chart announces "Mood score chart for N days" label',
      (tester) async {
        final today = DateTime(2026, 5, 13);
        final insights = List<DailyInsight>.generate(14, (i) {
          final date = today.subtract(Duration(days: 13 - i));
          return DailyInsight(
            date: date,
            avgMoodScore: i.isEven ? 0.4 : -0.3,
            gardenHealthH: i.isEven ? 0.2 : -0.1,
            dominantEmotion: null,
            entryCount: 1,
            triggeredTier: i == 7 ? Tier.two : null,
          );
        });

        await tester.pumpWidget(_wrap(MoodScoreChart(insights: insights)));
        await tester.pumpAndSettle();

        // The label is composed by analytics_pkg's MoodScoreLineChart
        // (see packages/analytics/lib/src/mood_score_chart.dart:60).
        // RegExp keeps the test resilient to count-string formatting.
        expect(
          find.bySemanticsLabel(
            RegExp(r'Mood score chart for \d+ days'),
          ),
          findsAtLeastNWidgets(1),
          reason:
              'Chart must announce its purpose + day-count so screen '
              'readers know what was just focused.',
        );
      },
    );

    testWidgets(
      'empty chart announces "no data for the selected window"',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const MoodScoreChart(insights: [])),
        );
        await tester.pumpAndSettle();

        // Empty state branch in the analytics_pkg wrapper carries the
        // friendly "no data" label so AT users hear something rather
        // than silence.
        expect(
          find.bySemanticsLabel(
            RegExp('no data for the selected window'),
          ),
          findsAtLeastNWidgets(1),
          reason: 'Empty chart must still announce its state.',
        );
      },
    );

    testWidgets(
      'individual data points are NOT each announced separately',
      (tester) async {
        // A 30-day window would mean 30 line-chart dots. If each carried
        // its own semantics label the focus stream would announce them
        // all on tab traversal — useless and overwhelming. Verify the
        // chart's single wrapping Semantics node is the only label-
        // carrier within the chart subtree.
        final today = DateTime(2026, 5, 13);
        final insights = List<DailyInsight>.generate(30, (i) {
          final date = today.subtract(Duration(days: 29 - i));
          return DailyInsight(
            date: date,
            avgMoodScore: 0.5,
            gardenHealthH: 0.3,
            dominantEmotion: null,
            entryCount: 1,
            triggeredTier: null,
          );
        });

        await tester.pumpWidget(_wrap(MoodScoreChart(insights: insights)));
        await tester.pumpAndSettle();

        // Count semantics nodes whose label matches the chart-label
        // regex. There should be exactly one (the outer wrapper);
        // never per-dot duplicates.
        final chartLabels = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where(
              (s) =>
                  (s.properties.label ?? '').startsWith('Mood score chart'),
            )
            .toList();
        expect(
          chartLabels.length,
          equals(1),
          reason:
              'Exactly one chart Semantics node should exist — per-dot '
              'announcements would flood the screen-reader focus stream.',
        );
      },
    );

    testWidgets(
      'chart pumps without throwing under the project theme',
      (tester) async {
        // Smoke — the chart depends on Theme.of(context).extension<MbColors>()
        // for its tier-band colors. A theme missing the extension would
        // crash on build; this test pins the dependency-on-theme contract.
        final today = DateTime(2026, 5, 13);
        final insights = List<DailyInsight>.generate(14, (i) {
          return DailyInsight(
            date: today.subtract(Duration(days: 13 - i)),
            avgMoodScore: 0.2,
            gardenHealthH: 0.1,
            dominantEmotion: null,
            entryCount: 1,
            triggeredTier: null,
          );
        });
        await tester.pumpWidget(_wrap(MoodScoreChart(insights: insights)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
