import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/hotline_footer.dart';

/// Sprint 5 Day 3 a11y sweep — Tier 3 hotline footer.
///
/// The hotline is footer-only (CLAUDE.md copy rule — "never a primary
/// CTA"), so its semantics gate is different from action surfaces: the
/// screen reader must hear the full gentle-note sentence (including the
/// "1323" number and the "24 hours" availability) as a single label,
/// without misreading "1323" as four separate digits.

Future<void> _pumpFooter(
  WidgetTester tester, {
  TextScaler textScaler = const TextScaler.linear(1.0),
  Size surfaceSize = const Size(360, 720),
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? buildDarkTheme()
          : buildLightTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: HotlineFooter(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('HotlineFooter — semantics', () {
    testWidgets(
      'announces the full hotline sentence including the 1323 number',
      (tester) async {
        await _pumpFooter(tester);

        // The Semantics(label:) on the wrapping container must carry
        // the complete sentence so screen readers hear it once,
        // contiguously. Breaking it into RichText spans without a
        // parent label would make TalkBack re-announce "1323" with
        // unpredictable digit grouping.
        final footer = tester.getSemantics(find.byType(HotlineFooter));
        expect(footer.label, contains('1323'));
        expect(footer.label, contains('Thai Mental Health Hotline'));
        expect(footer.label, contains('24 hours'));
        expect(footer.label, contains('If it helps'));
      },
    );

    testWidgets(
      'remains a non-interactive note (no button flag — CLAUDE.md '
      '"never a primary CTA")',
      (tester) async {
        // CLAUDE.md "Copy rules — Hotline 1323 footer-only": the footer
        // must read as a note, NOT a button. A screen reader user who
        // hears "Button: Hotline" would be misled into thinking the
        // widget dials the number. Verifying the absence of the
        // `isButton` flag locks this in.
        await _pumpFooter(tester);

        final footer = tester.getSemantics(find.byType(HotlineFooter));
        expect(
          footer.hasFlag(SemanticsFlag.isButton),
          isFalse,
          reason: 'hotline footer must be a passive note, never an action',
        );
      },
    );
  });

  group('HotlineFooter — 200% type readability', () {
    testWidgets('renders without RenderFlex overflow at 200% type',
        (tester) async {
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await _pumpFooter(tester, textScaler: const TextScaler.linear(2.0));

      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(
        overflows,
        isEmpty,
        reason:
            'HotlineFooter wraps its body in a Column with Text.rich — '
            'should wrap naturally. Failures: $overflows',
      );

      expect(find.text('A gentle note'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark theme at 200% type',
        (tester) async {
      // Tier 3 surfaces must pass a11y in both themes — Sprint 5 spec
      // §7. The softCoral background flips to a deep navy-coral on
      // dark; we re-run the overflow check there because text shadows
      // and color contrast differ.
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await _pumpFooter(
        tester,
        textScaler: const TextScaler.linear(2.0),
        brightness: Brightness.dark,
      );

      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(overflows, isEmpty);
    });
  });
}
