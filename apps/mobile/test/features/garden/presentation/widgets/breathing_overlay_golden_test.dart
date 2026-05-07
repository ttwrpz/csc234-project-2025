@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/presentation/widgets/breathing_overlay.dart';

/// Visual golden for the 4-7-8 breathing overlay. Closes one of the 3
/// missing S5 widget-level scenarios per S5 plan §3a.2.
///
/// The overlay is animation-driven (`_phase` cycles through inBreath →
/// hold → outBreath via a Timer in `initState`). To get a deterministic
/// golden we snapshot **frame 0** — `tester.pump()` once after the
/// first widget frame and BEFORE any phase transition fires. The
/// overlay's `_BreathPhase.inBreath` initial state is what the user
/// sees on open, which is the load-bearing visual contract.
///
/// We do NOT use `pumpAndSettle` because the Timer's 4 / 7 / 8 second
/// durations would force `pumpAndSettle` to time out (10-min default).
void main() {
  testGoldens('BreathingOverlay — initial frame (in-breath phase)', (
    tester,
  ) async {
    // Pump as a regular widget (not via showDialog) so the overlay
    // renders without the dialog scaffolding and we get a clean frame
    // for the snapshot. The overlay's StatefulWidget body is the
    // canonical visual.
    await tester.pumpWidgetBuilder(
      const Center(child: BreathingOverlay()),
      surfaceSize: const Size(400, 700),
    );
    // Single frame — no pumpAndSettle. The Timer is armed but won't
    // fire until +4 seconds, so frame 0 captures the in-breath state.
    await screenMatchesGolden(tester, 'breathing_overlay_initial');
    // Drain the pending Timer so the test framework doesn't complain
    // about a leaked timer at teardown.
    await tester.pump(const Duration(seconds: 20));
  });
}
