import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/presentation/widgets/pattern_marker_band.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

Widget wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: child),
  ),
);

DailyInsight _day(DateTime date, {Tier? tier}) => DailyInsight(
  date: date,
  avgMoodScore: null,
  gardenHealthH: null,
  dominantEmotion: null,
  entryCount: 0,
  triggeredTier: tier,
);

void main() {
  group('PatternMarkerBand', () {
    testWidgets('renders one slot per day, even on no-trigger days', (
      tester,
    ) async {
      final insights = List<DailyInsight>.generate(
        7,
        (i) => _day(DateTime(2026, 5, 1 + i)),
      );
      await tester.pumpWidget(wrap(PatternMarkerBand(insights: insights)));
      // Every slot is an `Expanded` so the band stays X-aligned with
      // the chart's date ticks regardless of how few tiers fired.
      expect(find.byType(Expanded), findsNWidgets(7));
    });

    testWidgets(
      'tier-trigger days have a Semantics label "Tier N trigger on …"',
      (tester) async {
        final insights = [
          _day(DateTime(2026, 5, 10), tier: Tier.one),
          _day(DateTime(2026, 5, 11), tier: Tier.two),
          _day(DateTime(2026, 5, 12), tier: Tier.three),
          _day(DateTime(2026, 5, 13)),
        ];
        await tester.pumpWidget(wrap(PatternMarkerBand(insights: insights)));
        // The label uses the short-date format MMM D.
        expect(
          find.bySemanticsLabel(RegExp(r'^Tier 1 trigger on May 10$')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'^Tier 2 trigger on May 11$')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'^Tier 3 trigger on May 12$')),
          findsOneWidget,
        );
      },
    );
  });
}
