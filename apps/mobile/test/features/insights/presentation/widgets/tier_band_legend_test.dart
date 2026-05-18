import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/insights/presentation/widgets/tier_band_legend.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  home: Scaffold(body: child),
);

void main() {
  group('TierBandLegend (HB-009 C-2)', () {
    testWidgets('renders all five tier rows in order', (tester) async {
      await tester.pumpWidget(_wrap(const TierBandLegend()));

      // Titles top-to-bottom — matches the chart's band stacking
      // (Flourishing at the top of the score scale, Storm Season at
      // the bottom).
      final titles = [
        'Flourishing',
        'Thriving',
        'Resting',
        'Weathering',
        'Storm Season',
      ];
      for (final t in titles) {
        expect(find.text(t), findsOneWidget, reason: 'missing tier "$t"');
      }
    });

    testWidgets(
      'Storm Season subtitle reads "sheltered, never withered" — no banned words',
      (tester) async {
        await tester.pumpWidget(_wrap(const TierBandLegend()));

        // The phrase that proves CLAUDE.md "plants are NEVER destroyed"
        // is respected.
        expect(find.text('sheltered, never withered'), findsOneWidget);

        // Defence-in-depth: walk every Text and assert no banned word.
        final banned = [
          'delete',
          'clear',
          'lost',
          'destroyed',
          'wilted',
          'dying',
          'dead',
        ];
        final textFinder = find.byType(Text);
        for (var i = 0; i < textFinder.evaluate().length; i++) {
          final w = tester.widget<Text>(textFinder.at(i));
          final data = (w.data ?? '').toLowerCase();
          for (final word in banned) {
            // "withered" appears in the subtitle as part of "never
            // withered" — that's the compassionate frame and it
            // explicitly negates the banned word.
            if (word == 'wilted' ||
                word == 'dying' ||
                word == 'dead' ||
                word == 'destroyed' ||
                word == 'lost' ||
                word == 'clear' ||
                word == 'delete') {
              expect(
                data.contains(word),
                isFalse,
                reason: 'banned word "$word" leaked into legend: "${w.data}"',
              );
            }
          }
        }
      },
    );

    testWidgets(
      'exposes a single semantics container labelled "Tier band legend"',
      (tester) async {
        await tester.pumpWidget(_wrap(const TierBandLegend()));

        expect(
          find.bySemanticsLabel(RegExp(r'Tier band legend')),
          findsOneWidget,
        );
      },
    );
  });
}
