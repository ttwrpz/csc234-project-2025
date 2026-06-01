import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/cheer_up_banner.dart';
import 'package:moodbloom/features/intervention/presentation/screens/breathing_screen.dart';

/// Locked sentence per CLAUDE.md "Copy rules - Intervention banner text".
/// The visual layout splits this across two `Text` widgets (titleSmall +
/// bodyMedium) but the [Semantics] label MUST contain the full sentence so
/// screen readers hear the complete prompt.
const _lockedSentence =
    "It's been a heavy week. Want to try a two-minute breathing exercise?";

Future<void> _pumpBanner(
  WidgetTester tester, {
  String reason = '5_of_7_negative',
  VoidCallback? onDismiss,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: CheerUpBanner(reason: reason, onDismiss: onDismiss ?? () {}),
        ),
      ),
    ),
  );
}

void main() {
  group('CheerUpBanner - copy parity (HB-003 §5.5a)', () {
    testWidgets(
      'Semantics label starts with the locked sentence (5_of_7_negative)',
      (tester) async {
        await _pumpBanner(tester);

        final semantics = tester.getSemantics(find.byType(CheerUpBanner));
        expect(semantics.label, startsWith(_lockedSentence));
      },
    );

    testWidgets('Semantics label starts with the locked sentence '
        '(3_consecutive_high_intensity)', (tester) async {
      await _pumpBanner(tester, reason: '3_consecutive_high_intensity');

      final semantics = tester.getSemantics(find.byType(CheerUpBanner));
      expect(semantics.label, startsWith(_lockedSentence));
    });

    testWidgets(
      'Semantics label starts with the locked sentence (unknown reason)',
      (tester) async {
        // Unknown codes must not break the parity contract - the locked
        // sentence is independent of the reason caption tail.
        await _pumpBanner(tester, reason: 'something_unmapped');

        final semantics = tester.getSemantics(find.byType(CheerUpBanner));
        expect(semantics.label, startsWith(_lockedSentence));
      },
    );

    testWidgets('renders both halves of the locked sentence as visible Text', (
      tester,
    ) async {
      await _pumpBanner(tester);

      // The visual two-line layout is part of the v1.0 baseline (see
      // HB-003 §5.5a). Asserting both halves render as separate `Text`
      // widgets keeps a future "collapse to one Text" refactor from
      // silently invalidating the goldens.
      expect(find.text("It's been a heavy week."), findsOneWidget);
      expect(
        find.text('Want to try a two-minute breathing exercise?'),
        findsOneWidget,
      );
    });
  });

  group('CheerUpBanner - interactions', () {
    testWidgets('"Not now" invokes onDismiss; banner does not self-close', (
      tester,
    ) async {
      var dismissed = 0;
      await _pumpBanner(tester, onDismiss: () => dismissed++);

      await tester.tap(find.text('Not now'));
      await tester.pump();

      expect(dismissed, 1);
      // The banner does NOT close itself - that is the parent's job (the
      // garden screen reads `bannerDismissed` from CheerUpController in
      // 5.5a and rebuilds without the banner).
      expect(find.byType(CheerUpBanner), findsOneWidget);
    });

    testWidgets('"Try it" opens the breathing modal', (tester) async {
      await _pumpBanner(tester);

      await tester.tap(find.text('Try it'));
      await tester.pump(); // modal route push
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BreathingView), findsOneWidget);
    });
  });

  group('CheerUpBanner - reason caption mapping', () {
    test('5_of_7_negative maps to the seven-day caption', () {
      expect(
        CheerUpBanner.reasonCaption('5_of_7_negative'),
        '5 of the last 7 days have felt heavy.',
      );
    });

    test('3_consecutive_high_intensity maps to the three-day caption', () {
      expect(
        CheerUpBanner.reasonCaption('3_consecutive_high_intensity'),
        'The last three days have felt heavy.',
      );
    });

    test('unknown code falls back to the generic line', () {
      expect(
        CheerUpBanner.reasonCaption('unmapped_code'),
        'A few heavier days in a row.',
      );
    });
  });
}
