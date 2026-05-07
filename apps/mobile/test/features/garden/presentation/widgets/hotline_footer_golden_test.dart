@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/app/theme.dart';
import 'package:moodbloom/features/garden/presentation/widgets/hotline_footer.dart';

/// Visual golden for the 10-day Hotline 1323 escalation footer. Closes
/// one of the 3 missing S5 widget-level scenarios per S5 plan §3a.2.
///
/// Two baselines (light + dark) — the footer renders against
/// MbColors.softCoral which differs by theme brightness, so both are
/// part of the visual contract. CLAUDE.md "Copy rules" lock the body:
/// "If it helps to talk, the Thai Mental Health Hotline is free at
/// 1323, 24 hours."
void main() {
  testGoldens('HotlineFooter — light theme', (tester) async {
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

  testGoldens('HotlineFooter — dark theme', (tester) async {
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
