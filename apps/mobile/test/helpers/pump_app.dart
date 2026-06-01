import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Wraps `child` in `ProviderScope` + `MaterialApp` for widget tests.
///
/// Centralises the rig used across feature widget tests so individual
/// helpers (`_pumpSignIn`, `_pumpLogMood`, `_pumpGarden`) can migrate to
/// it. The existing per-feature helpers are NOT migrated in Sprint 4 -
/// see Sprint 5 follow-up to reduce blast radius now while the test
/// suite is being expanded for WBS 7.2.
///
/// `themeMode` defaults to light to match the existing test posture;
/// pass `ThemeMode.dark` from settings/dark-mode tests once the toggle
/// lands on Day 2.
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themeMode,
        home: child,
      ),
    ),
  );
}
