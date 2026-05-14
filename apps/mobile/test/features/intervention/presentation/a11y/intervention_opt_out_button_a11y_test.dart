import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/intervention_opt_out_button.dart';

/// Sprint 5 Day 3 a11y sweep — InterventionOptOutButton.
///
/// The opt-out button is shared by Tier 1 / 2 / 3 screens AND the banner.
/// It must announce with a meaningful action-context label so screen
/// readers don't say bare "Button" or merely "I'm okay" (which can read
/// dismissive at acute tiers).
///
/// Covered:
///   1. Default label "I'm okay" → semantics label = "I'm okay, dismiss
///      this reminder".
///   2. Custom label "I'm okay for now" → semantics label = "I'm okay
///      for now, dismiss this reminder" (Tier 3 surface uses this).
///   3. Tap fires controller.optOut() exactly once + invokes onTapped
///      callback (the wiring is also covered in intervention_banner_test;
///      duplicated here so the button file owns its own a11y contract).

class _CountingController extends InterventionController {
  int optOutCalls = 0;

  @override
  InterventionControllerState build() => const InterventionIdle();

  @override
  Future<void> optOut() async {
    optOutCalls += 1;
  }
}

Future<void> _pumpButton(
  WidgetTester tester, {
  required _CountingController controller,
  String? label,
  VoidCallback? onTapped,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        interventionControllerProvider.overrideWith(() => controller),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: label == null
                ? InterventionOptOutButton(onTapped: onTapped)
                : InterventionOptOutButton(label: label, onTapped: onTapped),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('InterventionOptOutButton — semantics labels', () {
    testWidgets(
      'default label "I\'m okay" → announces with dismiss-context fragment',
      (tester) async {
        final controller = _CountingController();
        await _pumpButton(tester, controller: controller);

        // The Semantics wrapper around the OutlinedButton composes
        // "$label, dismiss this reminder". Screen readers will read
        // "I'm okay, dismiss this reminder, button" — explicit about
        // what the tap will do.
        expect(
          find.bySemanticsLabel("I'm okay, dismiss this reminder"),
          findsOneWidget,
          reason:
              'Default label MUST include the dismiss-action context; '
              'a curt "I\'m okay" reads dismissive without it.',
        );
      },
    );

    testWidgets(
      'custom label propagates to the semantics tree verbatim',
      (tester) async {
        final controller = _CountingController();
        await _pumpButton(
          tester,
          controller: controller,
          label: "I'm okay for now",
        );

        // Tier 3 crisis screen passes "I'm okay for now". The same
        // composed-label rule applies.
        expect(
          find.bySemanticsLabel(
            "I'm okay for now, dismiss this reminder",
          ),
          findsOneWidget,
          reason: 'Custom label must propagate into the Semantics wrapper.',
        );
      },
    );

    testWidgets(
      'semantic node carries the button role flag',
      (tester) async {
        final controller = _CountingController();
        await _pumpButton(tester, controller: controller);

        // Both the inner OutlinedButton and the wrapping Semantics carry
        // the button flag. Verify via the visible button text — the
        // resolved semantics on the OutlinedButton carries isButton: true.
        final btn = tester.getSemantics(
          find.byType(OutlinedButton),
        );
        expect(btn.hasFlag(SemanticsFlag.isButton), isTrue);
      },
    );
  });

  group('InterventionOptOutButton — tap behavior', () {
    testWidgets(
      'tap calls controller.optOut() exactly once + onTapped after',
      (tester) async {
        final controller = _CountingController();
        var callbackHits = 0;
        await _pumpButton(
          tester,
          controller: controller,
          onTapped: () => callbackHits += 1,
        );

        await tester.tap(find.byType(OutlinedButton));
        // The button awaits optOut() then calls onTapped. Drain the
        // micro-task queue.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          controller.optOutCalls,
          equals(1),
          reason: 'optOut must fire exactly once per tap.',
        );
        expect(
          callbackHits,
          equals(1),
          reason: 'onTapped must run AFTER optOut resolves.',
        );
      },
    );
  });
}
