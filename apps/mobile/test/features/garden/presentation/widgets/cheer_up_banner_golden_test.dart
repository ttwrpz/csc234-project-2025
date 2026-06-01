@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/presentation/widgets/cheer_up_banner.dart';

import '../../../../support/golden_fonts.dart';

/// Visual goldens for the cheer-up intervention banner. Restored after
/// commit 8a72f5ad trimmed the golden suite. The `CheerUpBanner` API is
/// unchanged (`reason` + `onDismiss`); the only adaptation vs. the old
/// test is wrapping in a themed `MaterialApp` so the banner's
/// `Theme.of(context)` text styles resolve (the widget reads
/// `theme.textTheme` for every line of copy).
///
/// Three baselines exercise the three reason-caption branches:
///   - 5_of_7_negative                  (most common trigger)
///   - 3_consecutive_high_intensity     (second trigger)
///   - unknown                          (generic fallback caption)
///
/// The locked CLAUDE.md title + body ("It's been a heavy week." / "Want
/// to try a two-minute breathing exercise?") render as stacked Text
/// widgets above the reason caption.
void main() {
  installOfflineGoogleFonts();

  Future<void> pumpBanner(
    WidgetTester tester,
    String reason,
    String goldenName,
  ) async {
    await tester.pumpWidgetBuilder(
      Center(
        child: SizedBox(
          width: 360,
          child: CheerUpBanner(reason: reason, onDismiss: () {}),
        ),
      ),
      wrapper: (child) => MaterialApp(
        theme: buildLightTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: child),
      ),
      surfaceSize: const Size(400, 280),
    );
    await screenMatchesGolden(tester, goldenName);
  }

  testGoldens('CheerUpBanner - 5_of_7_negative reason caption', (tester) async {
    await pumpBanner(tester, '5_of_7_negative', 'cheer_up_banner_5_of_7');
  });

  testGoldens('CheerUpBanner - 3_consecutive_high_intensity reason caption', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      '3_consecutive_high_intensity',
      'cheer_up_banner_3_consec',
    );
  });

  testGoldens('CheerUpBanner - unknown reason falls back to generic caption', (
    tester,
  ) async {
    await pumpBanner(tester, 'something_unmapped', 'cheer_up_banner_unknown');
  });
}
