import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MoodBloomColors', () {
    test('surfaceCream is the prototype cream (#FBFAF6)', () {
      expect(MoodBloomColors.surfaceCream, const Color(0xFFFBFAF6));
    });

    test('surfaceCreamDark is the prototype navy (#161F2C)', () {
      expect(MoodBloomColors.surfaceCreamDark, const Color(0xFF161F2C));
    });
  });

  group('MbColors.light()', () {
    test('bg matches the prototype cream surface', () {
      expect(MbColors.light().bg, MoodBloomColors.surfaceCream);
    });

    test('lerp returns the start color at t=0', () {
      final a = MbColors.light();
      final b = MbColors.dark();
      expect(a.lerp(b, 0).bg, a.bg);
    });

    test('lerp returns the end color at t=1', () {
      final a = MbColors.light();
      final b = MbColors.dark();
      expect(a.lerp(b, 1).bg, b.bg);
    });
  });

  group('MbMoodPalette.shared', () {
    test('maps the 6 moods to the prototype hex', () {
      final p = MbMoodPalette.shared;
      expect(p.colorOf(MbMoodKind.happy), MoodBloomColors.moodHappy);
      expect(p.colorOf(MbMoodKind.calm), MoodBloomColors.moodCalm);
      expect(p.colorOf(MbMoodKind.okay), MoodBloomColors.moodOkay);
      expect(p.colorOf(MbMoodKind.sad), MoodBloomColors.moodSad);
      expect(p.colorOf(MbMoodKind.angry), MoodBloomColors.moodAngry);
      expect(p.colorOf(MbMoodKind.anxious), MoodBloomColors.moodAnxious);
    });

    test('emoji map matches the brief', () {
      final p = MbMoodPalette.shared;
      expect(p.emojiOf(MbMoodKind.happy), '🌻');
      expect(p.emojiOf(MbMoodKind.calm), '🌱');
      expect(p.emojiOf(MbMoodKind.okay), '🌿');
      expect(p.emojiOf(MbMoodKind.sad), '💧');
      expect(p.emojiOf(MbMoodKind.angry), '⛈️');
      expect(p.emojiOf(MbMoodKind.anxious), '🌾');
    });
  });

  group('buildLightTheme', () {
    testWidgets('uses Brightness.light (regression guard)', (tester) async {
      late ThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Builder(
            builder: (context) {
              captured = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured.brightness, Brightness.light);
      expect(captured.useMaterial3, isTrue);
    });

    testWidgets('uses the prototype cream surface (#FBFAF6)', (tester) async {
      late ThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Builder(
            builder: (context) {
              captured = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured.colorScheme.surface, MoodBloomColors.surfaceCream);
    });

    testWidgets('registers MbColors and MbMoodPalette extensions', (
      tester,
    ) async {
      late ThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Builder(
            builder: (context) {
              captured = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final colors = captured.extension<MbColors>();
      final palette = captured.extension<MbMoodPalette>();
      expect(colors, isNotNull);
      expect(colors!.bg, MoodBloomColors.surfaceCream);
      expect(palette, isNotNull);
      expect(palette!.colorOf(MbMoodKind.happy), MoodBloomColors.moodHappy);
    });
  });

  group('buildDarkTheme', () {
    testWidgets('uses Brightness.dark on a navy surface', (tester) async {
      late ThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDarkTheme(),
          home: Builder(
            builder: (context) {
              captured = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured.brightness, Brightness.dark);
      expect(captured.useMaterial3, isTrue);
      expect(captured.colorScheme.surface, MoodBloomColors.surfaceCreamDark);
      expect(
        captured.scaffoldBackgroundColor,
        MoodBloomColors.surfaceCreamDark,
      );
    });

    testWidgets('registers MbColors and MbMoodPalette extensions', (
      tester,
    ) async {
      late ThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDarkTheme(),
          home: Builder(
            builder: (context) {
              captured = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final colors = captured.extension<MbColors>();
      final palette = captured.extension<MbMoodPalette>();
      expect(colors, isNotNull);
      expect(colors!.bg, MoodBloomColors.surfaceCreamDark);
      expect(palette, isNotNull);
      expect(palette!.colorOf(MbMoodKind.sad), MoodBloomColors.moodSad);
    });
  });
}
