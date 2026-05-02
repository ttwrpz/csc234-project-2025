import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildLightTheme', () {
    test('uses Brightness.light (regression guard)', () {
      expect(buildLightTheme().brightness, Brightness.light);
    });

    test('uses the cream-light surface', () {
      expect(
        buildLightTheme().colorScheme.surface,
        MoodBloomColors.surfaceCream,
      );
    });

    test('uses Material 3', () {
      expect(buildLightTheme().useMaterial3, isTrue);
    });
  });

  group('buildDarkTheme', () {
    test('uses Brightness.dark', () {
      expect(buildDarkTheme().brightness, Brightness.dark);
    });

    test('uses the cream-dark surface', () {
      expect(
        buildDarkTheme().colorScheme.surface,
        MoodBloomColors.surfaceCreamDark,
      );
    });

    test('uses Material 3', () {
      expect(buildDarkTheme().useMaterial3, isTrue);
    });

    test(
      'scaffold background matches the dark surface (no flash-of-light)',
      () {
        expect(
          buildDarkTheme().scaffoldBackgroundColor,
          MoodBloomColors.surfaceCreamDark,
        );
      },
    );
  });
}
