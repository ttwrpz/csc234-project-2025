@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/app/theme.dart';
import 'package:moodbloom/features/garden/presentation/widgets/hotline_footer.dart';

import '../../../../support/golden_fonts.dart';

/// Visual goldens for the Hotline 1323 footer. Restored after commit
/// 8a72f5ad trimmed the golden suite. `HotlineFooter` is a const
/// stateless widget with no constructor args - unchanged API. It reads
/// `MbColors.softCoral` (theme extension) so both light + dark are part
/// of the visual contract.
///
/// CLAUDE.md "Copy rules" lock the body: "If it helps to talk, the Thai
/// Mental Health Hotline is free at 1323, 24 hours." - footer-only,
/// never a primary CTA.
void main() {
  installOfflineGoogleFonts();

  testGoldens('HotlineFooter - light theme', (tester) async {
    await tester.pumpWidgetBuilder(
      const Padding(padding: EdgeInsets.all(24), child: HotlineFooter()),
      wrapper: (child) => MaterialApp(
        theme: buildLightTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: child),
      ),
      surfaceSize: const Size(400, 200),
    );
    await screenMatchesGolden(tester, 'hotline_footer_light');
  });

  testGoldens('HotlineFooter - dark theme', (tester) async {
    await tester.pumpWidgetBuilder(
      const Padding(padding: EdgeInsets.all(24), child: HotlineFooter()),
      wrapper: (child) => MaterialApp(
        theme: buildDarkTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: child),
      ),
      surfaceSize: const Size(400, 200),
    );
    await screenMatchesGolden(tester, 'hotline_footer_dark');
  });
}
