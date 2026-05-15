import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/presentation/widgets/pattern_marker_band.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// Sprint 5 Day 3 a11y sweep — pattern marker band (S5-new surface).
///
/// The pattern marker band sits under the InsightsScreen chart and
/// renders one small badge per Pattern Engine trigger. Each badge MUST
/// carry a `Semantics(label: 'Tier N trigger on MMM D')` so screen
/// readers announce "Tier 2 trigger on May 11" rather than a bare dot.
///
/// The existing `pattern_marker_band_test.dart` already asserts the
/// label format — this a11y test duplicates the assertions under the
/// a11y-test name pattern so the suite is greppable for "a11y" coverage
/// (per the Sprint 5 Day 3 brief), and adds two a11y-specific checks:
///
///   1. No-trigger days do NOT carry a stray semantics label (otherwise
///      a 30-day window with 1 trigger would announce 30 placeholder
///      dots).
///   2. The Tooltip message text is also reachable (long-press affordance
///      so sighted-but-low-vision users can read the trigger date).

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(theme: buildLightTheme(), home: Scaffold(body: child)),
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
  group('PatternMarkerBand — a11y label format', () {
    testWidgets(
      'tier-trigger days announce "Tier N trigger on MMM D"',
      (tester) async {
        final insights = [
          _day(DateTime(2026, 5, 10), tier: Tier.one),
          _day(DateTime(2026, 5, 11), tier: Tier.two),
          _day(DateTime(2026, 5, 12), tier: Tier.three),
          _day(DateTime(2026, 5, 13)),
        ];
        await tester.pumpWidget(
          _wrap(PatternMarkerBand(insights: insights)),
        );

        // Duplicated from pattern_marker_band_test.dart — under the a11y
        // test name so a future `grep -r a11y` survey lists this surface.
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

    testWidgets(
      'no-trigger days carry NO trigger semantics label',
      (tester) async {
        final insights = List<DailyInsight>.generate(
          7,
          (i) => _day(DateTime(2026, 5, 1 + i)),
        );
        await tester.pumpWidget(
          _wrap(PatternMarkerBand(insights: insights)),
        );

        // A no-trigger day renders a transparent placeholder Container,
        // NOT a Semantics-wrapped Tooltip. Verify the focus stream is
        // clean — a 30-day window with 1 trigger should produce exactly
        // 1 announcement, not 30.
        expect(
          find.bySemanticsLabel(RegExp(r'trigger on')),
          findsNothing,
          reason:
              'No-trigger days must not produce a "trigger on" label — '
              'placeholder dots are decorative.',
        );
      },
    );

    testWidgets(
      'Tooltip message provides long-press affordance for sighted users',
      (tester) async {
        // Tooltip widget itself adds an accessibility affordance: on
        // long-press it surfaces a textual overlay. Verify the Tooltip
        // is rendered with its message for tier-trigger days.
        final insights = [_day(DateTime(2026, 5, 10), tier: Tier.one)];
        await tester.pumpWidget(
          _wrap(PatternMarkerBand(insights: insights)),
        );

        final tooltips = tester
            .widgetList<Tooltip>(find.byType(Tooltip))
            .toList();
        expect(
          tooltips,
          isNotEmpty,
          reason:
              'Tier-trigger badges must wrap a Tooltip for long-press '
              'affordance.',
        );
        expect(
          tooltips.first.message,
          equals('Tier 1 · May 10'),
          reason:
              'Tooltip message format is "Tier N · MMM D" — keeps the '
              'sighted long-press affordance in lockstep with the '
              'screen-reader Semantics label.',
        );
      },
    );
  });
}
