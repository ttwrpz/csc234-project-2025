import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/disclaimer/data/providers.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_copy.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_failure.dart';
import 'package:moodbloom/features/disclaimer/domain/repositories/disclaimer_repository.dart';
import 'package:moodbloom/features/disclaimer/presentation/widgets/disclaimer_ack_dialog.dart';

/// Sprint 5 Day 3 a11y sweep — disclaimer ack dialog.
///
/// The spec's explicit checkpoint (Sprint 4–5 plan TC-36 + Sprint 5 D3
/// plan): the disclaimer dialog must be **readable at 200% type without
/// overflow** and must announce its primary action ("I understand") with
/// a meaningful semantic label. The dialog is also the load-bearing
/// "barrier-non-dismissible" surface — its semantics must NOT include an
/// implicit "tap outside to close" affordance.

class _StubDisclaimerRepo implements DisclaimerRepository {
  @override
  Future<Result<void, DisclaimerFailure>> ack({required String userId}) async =>
      const Ok(null);

  @override
  Stream<bool> watchAckState({required String userId}) =>
      const Stream<bool>.empty();
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  TextScaler textScaler = const TextScaler.linear(1.0),
  Size surfaceSize = const Size(360, 720),
  Brightness brightness = Brightness.light,
}) async {
  // Set the surface explicitly so the 200% type test runs against a
  // realistic small-phone viewport (Pixel 5-ish portrait). Bigger
  // surfaces hide the overflow this test is designed to catch.
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disclaimerRepositoryProvider.overrideWithValue(_StubDisclaimerRepo()),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? buildDarkTheme()
            : buildLightTheme(),
        // Apply the text scaler at the MaterialApp root so every
        // descendant (the AlertDialog included) inherits it through the
        // MediaQuery chain.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    DisclaimerAckDialog.show(context, userId: 'u-1'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('DisclaimerAckDialog — semantics', () {
    testWidgets(
      '"I understand" button is announced as a button with its label',
      (tester) async {
        await _pumpDialog(tester);

        final semantics = tester.getSemantics(
          find.widgetWithText(FilledButton, DisclaimerCopy.ackButton),
        );
        // The button must announce its action — the label IS the action
        // verb, no separate Semantics wrapper needed. Verifying both the
        // label and the `button` flag protects against a future refactor
        // that drops the FilledButton for an InkWell without restoring the
        // semantic role.
        expect(semantics.label, equals(DisclaimerCopy.ackButton));
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      },
    );

    testWidgets('disclaimer body text is reachable in the semantics tree', (
      tester,
    ) async {
      await _pumpDialog(tester);

      // The full disclaimer must be readable by screen readers — it is
      // a regulatory surface (CLAUDE.md §9). If the Text were ever
      // wrapped in ExcludeSemantics it would silently fail this gate.
      final body = tester.getSemantics(find.text(DisclaimerCopy.full));
      expect(body.label, equals(DisclaimerCopy.full));
    });
  });

  group('DisclaimerAckDialog — 200% type readability', () {
    testWidgets('renders without RenderFlex overflow at 200% type', (
      tester,
    ) async {
      // Capture pump-time exceptions explicitly so an overflow surfaces
      // as a test failure rather than a red console banner. We use the
      // smallest realistic phone width (360 dp) — at this width plus
      // 200% scaling the AlertDialog's default non-scrollable layout
      // would overflow vertically. The `scrollable: true` fix verified
      // here keeps the content inside a SingleChildScrollView.
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await _pumpDialog(tester, textScaler: const TextScaler.linear(2.0));

      // Filter to overflow / layout failures so unrelated runtime
      // exceptions (e.g. a flaky paint shader load) don't poison this
      // assertion. The class name `FlutterError` is shared, but the
      // message contains the diagnostic word "overflowed" only for
      // layout overflows.
      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(
        overflows,
        isEmpty,
        reason:
            'AlertDialog must not overflow at 200% type — `scrollable: true` '
            'is the fix. Failures here: $overflows',
      );

      // Sanity: both the ack button and the body must still be on-screen.
      expect(find.text(DisclaimerCopy.ackButton), findsOneWidget);
      expect(find.text(DisclaimerCopy.full), findsOneWidget);
    });

    testWidgets('content is wrapped in a scrollable so 200% type can scroll', (
      tester,
    ) async {
      // Asserts the structural fix landed inline: AlertDialog
      // `scrollable: true` wraps the content+actions in a
      // SingleChildScrollView. Without it the dialog would clip its tail
      // on small phones at large dynamic-type settings.
      await _pumpDialog(tester, textScaler: const TextScaler.linear(2.0));

      final scrollable = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SingleChildScrollView),
      );
      expect(
        scrollable,
        findsAtLeastNWidgets(1),
        reason:
            'AlertDialog(scrollable: true) must inject a scroll view '
            'so 200% type does not clip',
      );
    });
  });
}
