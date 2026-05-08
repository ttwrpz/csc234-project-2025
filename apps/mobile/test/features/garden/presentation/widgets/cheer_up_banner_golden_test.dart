@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/presentation/widgets/cheer_up_banner.dart';

/// Visual goldens for the cheer-up banner. Closes one of the 3 missing
/// S5 widget-level scenarios per S5 plan §3a.2 (the other two are
/// breathing_overlay + hotline_footer in sibling files).
///
/// Three baselines:
///   - 5_of_7_negative — the most common trigger reason
///   - 3_consecutive_high_intensity — the second trigger
///   - unknown reason — exercises the fallback caption path
///
/// The locked CLAUDE.md sentence ("It's been a heavy week. Want to try
/// a two-minute breathing exercise?") is rendered as two stacked Text
/// widgets per the v1.0 visual baseline. PR #28 covers the Semantics
/// label parity; these goldens cover the visual rendering.
void main() {
  testGoldens('CheerUpBanner — 5_of_7_negative reason caption', (tester) async {
    await tester.pumpWidgetBuilder(
      Center(
        child: SizedBox(
          width: 360,
          child: CheerUpBanner(reason: '5_of_7_negative', onDismiss: () {}),
        ),
      ),
      surfaceSize: const Size(400, 260),
    );
    await screenMatchesGolden(tester, 'cheer_up_banner_5_of_7');
  });

  testGoldens('CheerUpBanner — 3_consecutive_high_intensity reason caption', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      Center(
        child: SizedBox(
          width: 360,
          child: CheerUpBanner(
            reason: '3_consecutive_high_intensity',
            onDismiss: () {},
          ),
        ),
      ),
      surfaceSize: const Size(400, 260),
    );
    await screenMatchesGolden(tester, 'cheer_up_banner_3_consec');
  });

  testGoldens('CheerUpBanner — unknown reason falls back to generic caption', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      Center(
        child: SizedBox(
          width: 360,
          child: CheerUpBanner(reason: 'something_unmapped', onDismiss: () {}),
        ),
      ),
      surfaceSize: const Size(400, 260),
    );
    await screenMatchesGolden(tester, 'cheer_up_banner_unknown');
  });
}
