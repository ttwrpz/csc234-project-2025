import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/breathing_overlay.dart';

/// Sprint 5 Day 3 a11y sweep — Tier 1 (4-7-8) breathing overlay.
///
/// The overlay is the load-bearing Tier 1 intervention surface. The
/// orchestrator's brief flags the timer-driven label as a "soft
/// assertion site" because the `_BreathPhase` state machine fires
/// `setState` on every phase boundary — we verify here that NO
/// per-second tick announces. The Timer's smallest interval is 4 s
/// (in-breath); the implementation never pumps a "01s, 02s..." tick.
///
/// We deliberately do NOT assert the "I'm okay" / dismissal wiring —
/// that's covered by the banner's hard-asserted test. This file only
/// covers semantics + 200% type for the overlay surface itself.

Future<void> _pumpOverlay(
  WidgetTester tester, {
  TextScaler textScaler = const TextScaler.linear(1.0),
  Size surfaceSize = const Size(360, 720),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const Scaffold(body: BreathingOverlay()),
    ),
  );
  // Single frame — do NOT pumpAndSettle (the 4-7-8 timers would force a
  // 19-second wait). Frame 0 captures the in-breath state, which is the
  // visual contract.
  await tester.pump();
  // Drain the pending Timer at teardown so the test framework doesn't
  // complain about a leaked timer. 20 s is just over one full cycle.
  addTearDown(() async => tester.pump(const Duration(seconds: 20)));
}

void main() {
  group('BreathingOverlay — semantics', () {
    testWidgets('close button announces as a button with the locked label',
        (tester) async {
      await _pumpOverlay(tester);

      // The close pill is the only opt-out affordance — its Semantics
      // label must read as a complete action ("Close breathing
      // exercise"), not just "close" or the bare icon code. The
      // production wrap is explicit; this assertion locks it in.
      final closeSem = tester.getSemantics(
        find.bySemanticsLabel('Close breathing exercise'),
      );
      expect(closeSem.label, equals('Close breathing exercise'));
      expect(closeSem.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('"Done" primary button is reachable and announced',
        (tester) async {
      await _pumpOverlay(tester);

      // Two opt-outs (X icon and Done button) both should be reachable
      // — verifying both ensures the user can leave the exercise via
      // whichever affordance falls under their finger.
      final done = tester.getSemantics(find.text('Done'));
      expect(done.label, contains('Done'));
      expect(done.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('initial phase label "Breathe in…" reaches the semantics tree',
        (tester) async {
      await _pumpOverlay(tester);

      // Frame 0 is in-breath. The label must be reachable so a screen
      // reader user knows where in the cycle the animation sits. A
      // future refactor that hides the phase label behind a decoration
      // wrapper would silently fail this assertion.
      expect(find.text('Breathe in…'), findsOneWidget);
      final phase = tester.getSemantics(find.text('Breathe in…'));
      expect(phase.label, equals('Breathe in…'));
    });

    testWidgets('no per-second tick label leaks into the semantics tree',
        (tester) async {
      // The known soft-assertion site from the screens commit: the
      // overlay must NOT announce a "01s, 02s..." ticker every second.
      // The current implementation uses a single Timer per phase (4 / 7
      // / 8 s), so no second-granularity widget exists — this test
      // codifies that and catches a future regression that inserts a
      // ValueListenableBuilder<int seconds> live region.
      await _pumpOverlay(tester);

      // Pump 5 fake seconds to give a hypothetical per-second ticker
      // time to manifest. The 4-second in-breath timer fires at 4 s,
      // so we pump up to 3 s here to stay inside the first phase.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Look for any single- or double-digit seconds label like "01s",
      // "1s", "1 second", "2 seconds", "0:01" — none should exist.
      final secondLikeLabels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where(
            (s) => RegExp(r'^\d{1,2}\s*s$').hasMatch(s) ||
                RegExp(r'^\d{1,2}\s*second').hasMatch(s) ||
                RegExp(r'^0:\d{2}$').hasMatch(s),
          )
          .toList();
      expect(
        secondLikeLabels,
        isEmpty,
        reason:
            'Breathing overlay must not announce a per-second ticker — '
            'phase labels (in / hold / out) and the cycle counter are '
            'the only live regions. Found: $secondLikeLabels',
      );
    });
  });

  group('BreathingOverlay — 200% type readability', () {
    testWidgets('renders without RenderFlex overflow at 200% type',
        (tester) async {
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await _pumpOverlay(tester, textScaler: const TextScaler.linear(2.0));

      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(
        overflows,
        isEmpty,
        reason:
            'BreathingOverlay must not overflow at 200% type. The fixed '
            'SizedBox(260, 260) animation area is constant; only the '
            'caption + Done button scale. Failures: $overflows',
      );

      // Sanity: the phase label and Done button stay on-screen even at
      // 200%. The caption uses a Padding(horizontal: 32) on a
      // textAlign.center Text, which softly wraps on narrow phones.
      expect(find.text('Breathe in…'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });
}
