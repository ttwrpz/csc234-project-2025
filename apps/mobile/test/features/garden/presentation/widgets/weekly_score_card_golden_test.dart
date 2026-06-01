@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/app/theme.dart';
import 'package:moodbloom/features/garden/presentation/widgets/weekly_score_card.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../../../support/golden_fonts.dart';

/// NEW goldens for the "THIS WEEK" overview card (`WeeklyScoreCard`).
/// This card had no golden coverage before. It is a pure
/// `StatelessWidget` that buckets [weekEntries] into a 7-bar Mon..Sun
/// mini chart and a signed weekly average - fully deterministic with no
/// animations and no providers, so it is an ideal golden target.
///
/// We feed a fixed week of entries (a positive lean Mon-Wed, two empty
/// days, a negative dip Fri-Sat) so the goldens lock the
/// positive-up / negative-down bar split, the empty-day pills, and the
/// dominant-mood tinting. Light + dark both ship because the bar
/// baseline + card surface differ by theme brightness.
void main() {
  installOfflineGoogleFonts();

  // Fixed Monday so the bucketing + Mon..Sun labels are stable.
  final weekStart = DateTime(2026, 5, 4);

  MoodEntry entry(int dayOffset, MoodType mood, int intensity) => MoodEntry(
    id: 'e-$dayOffset',
    userId: 'u-1',
    mood: mood,
    intensity: intensity,
    text: '',
    createdAt: weekStart.add(Duration(days: dayOffset, hours: 10)),
  );

  // Mon/Tue/Wed positive, Thu/Sun empty, Fri/Sat negative.
  final weekEntries = <MoodEntry>[
    entry(0, MoodType.happy, 4),
    entry(1, MoodType.calm, 3),
    entry(2, MoodType.okay, 2),
    entry(4, MoodType.sad, 4),
    entry(5, MoodType.anxious, 3),
  ];

  Future<void> pumpCard(
    WidgetTester tester, {
    required ThemeData theme,
    required String goldenName,
  }) async {
    await tester.pumpWidgetBuilder(
      WeeklyScoreCard(weekEntries: weekEntries, weekStart: weekStart),
      wrapper: (child) => MaterialApp(
        theme: theme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
      surfaceSize: const Size(400, 280),
    );
    await screenMatchesGolden(tester, goldenName);
  }

  testGoldens('WeeklyScoreCard - mixed week, light theme', (tester) async {
    await pumpCard(
      tester,
      theme: buildLightTheme(),
      goldenName: 'weekly_score_card_light',
    );
  });

  testGoldens('WeeklyScoreCard - mixed week, dark theme', (tester) async {
    await pumpCard(
      tester,
      theme: buildDarkTheme(),
      goldenName: 'weekly_score_card_dark',
    );
  });
}
