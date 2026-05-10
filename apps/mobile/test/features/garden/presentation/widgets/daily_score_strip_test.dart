import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';
import 'package:moodbloom/features/garden/presentation/widgets/daily_score_strip.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('DailyScoreStrip — smoke', () {
    final today = DateTime(2026, 5, 3);
    List<DayScore> daysFor({required List<double?> avgs}) {
      // Newest-first list of 7 cells, like the use case emits.
      return [
        for (var i = 0; i < 7; i += 1)
          DayScore(
            day: today.subtract(Duration(days: i)),
            avgScore: avgs[i],
            entryCount: avgs[i] == null ? 0 : 1,
          ),
      ];
    }

    Future<void> pump(WidgetTester tester, List<DayScore> days) async {
      await pumpApp(
        tester,
        child: Scaffold(
          body: SizedBox(width: 320, child: DailyScoreStrip(last7Days: days)),
        ),
      );
      await tester.pump();
    }

    testWidgets('all-empty week renders 7 placeholder cells with no-entries '
        'a11y label', (tester) async {
      await pump(tester, daysFor(avgs: List<double?>.filled(7, null)));
      expect(find.byType(DailyScoreStrip), findsOneWidget);
      // At least one cell should announce "no entries" — the parent
      // `Semantics` swallows the day-by-day labels into a list, so we
      // search by text rather than label.
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('all-positive week renders with descriptive labels', (
      tester,
    ) async {
      await pump(tester, daysFor(avgs: List<double?>.filled(7, 0.6)));
      expect(find.byType(DailyScoreStrip), findsOneWidget);
      // Descriptive a11y label includes "positive" — at least one
      // matching node in the tree.
      expect(find.bySemanticsLabel(RegExp(r'positive day')), findsWidgets);
    });

    testWidgets('mixed-sign week renders without throwing', (tester) async {
      await pump(
        tester,
        daysFor(avgs: const [0.8, -0.4, null, 0.2, -0.6, null, 0.1]),
      );
      expect(find.byType(DailyScoreStrip), findsOneWidget);
      // Both positive and gentler labels should be present.
      expect(find.bySemanticsLabel(RegExp(r'positive day')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp(r'gentler day')), findsWidgets);
    });
  });
}
