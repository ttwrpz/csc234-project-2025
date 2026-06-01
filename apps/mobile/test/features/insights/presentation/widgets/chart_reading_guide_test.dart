import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/insights/presentation/widgets/chart_reading_guide.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  home: Scaffold(body: child),
);

void main() {
  group('ChartReadingGuide (HB-009 C-1)', () {
    testWidgets(
      'phone default (alwaysExpanded:false) collapses the body behind a tap',
      (tester) async {
        await tester.pumpWidget(_wrap(const ChartReadingGuide()));

        // The title is always visible (in the expansion tile header).
        expect(find.text('What am I looking at?'), findsOneWidget);
        // Body content stays out of the tree until the user expands.
        expect(find.textContaining('The solid line'), findsNothing);

        await tester.tap(find.text('What am I looking at?'));
        await tester.pumpAndSettle();

        expect(find.textContaining('The solid line'), findsOneWidget);
        expect(find.textContaining('rolling rhythm'), findsOneWidget);
        expect(
          find.textContaining('Storm Season is sheltered'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tablet/desktop (alwaysExpanded:true) renders the body unconditionally',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const ChartReadingGuide(alwaysExpanded: true)),
        );

        expect(find.text('What am I looking at?'), findsOneWidget);
        // Body visible immediately - no expansion tile.
        expect(find.textContaining('The solid line'), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNothing);
      },
    );

    testWidgets('copy contains no CLAUDE.md banned words for the garden', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ChartReadingGuide(alwaysExpanded: true)),
      );

      // Iterate every Text in the tree and assert each banned token
      // is absent. Captures any future edit that slips in a regression.
      final banned = [
        'delete',
        'clear',
        'lost',
        'destroyed',
        'wilted',
        'wilting',
        'dead',
        'dying',
      ];
      final textFinder = find.byType(Text);
      for (var i = 0; i < textFinder.evaluate().length; i++) {
        final widget = tester.widget<Text>(textFinder.at(i));
        final data = widget.data ?? '';
        for (final word in banned) {
          expect(
            data.toLowerCase().contains(word),
            isFalse,
            reason: 'banned word "$word" leaked into guide copy: "$data"',
          );
        }
      }
    });
  });
}
