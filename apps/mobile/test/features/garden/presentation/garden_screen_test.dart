import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/garden/presentation/widgets/dominant_emotions_card.dart';
import 'package:moodbloom/features/garden/presentation/widgets/gentle_nudge_card.dart';
import 'package:moodbloom/features/garden/presentation/widgets/sky_header.dart';
import 'package:moodbloom/features/garden/presentation/widgets/sky_plot_strip.dart';
import 'package:moodbloom/features/garden/presentation/widgets/this_weeks_tier_card.dart';
import 'package:moodbloom/features/garden/presentation/widgets/today_moods_card.dart';
import 'package:moodbloom/features/garden/presentation/widgets/weekly_score_card.dart';
import 'package:moodbloom/features/history/presentation/widgets/mood_entry_tile.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../mood/domain/fakes/fake_mood_repository.dart';

Stream<AppUser?> _userStream(AppUser? user) {
  final controller = StreamController<AppUser?>();
  controller.add(user);
  return controller.stream;
}

Future<void> _pumpGarden(
  WidgetTester tester, {
  required FakeMoodRepository repo,
  Size surface = const Size(800, 1600),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        moodRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider.overrideWith(
          (_) => _userStream(const AppUser(uid: 'u-1', email: 'u@example.com')),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: Consumer(
          builder: (context, ref, _) {
            ref.watch(currentUserStreamProvider);
            return const GardenScreen();
          },
        ),
      ),
    ),
  );
  // The garden-state stream emits asynchronously; atmosphere overlay
  // animates continuously so `pumpAndSettle` would loop forever. Pump
  // a few frames to let the providers settle, then stop before
  // animations matter.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

MoodEntry _entry(
  MoodType mood,
  DateTime createdAt, {
  String id = 'e',
  int intensity = 3,
}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: intensity,
    text: '',
    createdAt: createdAt,
  );
}

void main() {
  group('GardenScreen - v1.6 ecosystem composition', () {
    testWidgets('empty state mounts the SkyHeader hero + plot strip + '
        '"DAILY SCORE" card', (tester) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      // The canvas always renders - empty state paints ground+grass
      // and the strip shows 7 empty-seedling plots.
      expect(find.byType(SkyHeader), findsOneWidget);
      expect(find.byType(SkyPlotStrip), findsOneWidget);
      // Per the v1.6 prototype the score card carries the
      // "DAILY SCORE" eyebrow + "weekly average" caption + the
      // locked footer line.
      expect(find.byType(WeeklyScoreCard), findsOneWidget);
      expect(find.text('DAILY SCORE'), findsOneWidget);
      expect(find.text('Mood is weather. The ecosystem holds.'),
          findsOneWidget);
    });

    testWidgets('populated week forwards the week entries to the strip',
        (tester) async {
      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 5; i += 1)
          _entry(MoodType.happy, today, id: 'e$i', intensity: 5),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];
      await _pumpGarden(tester, repo: repo);

      final strip = tester.widget<SkyPlotStrip>(find.byType(SkyPlotStrip));
      expect(strip.weekEntries.length, 5);
    });

    testWidgets('tier card + dominant emotions + gentle nudge render alongside '
        'the recent-moods preview', (tester) async {
      final today = DateTime.now();
      final repo = FakeMoodRepository()
        ..streamedEntries = [
          [
            _entry(MoodType.sad, today, id: 'a', intensity: 2),
            _entry(MoodType.angry, today, id: 'b', intensity: 3),
            _entry(MoodType.anxious, today, id: 'c', intensity: 5),
          ],
        ];
      await _pumpGarden(tester, repo: repo);

      expect(find.byType(ThisWeeksTierCard), findsOneWidget);
      expect(find.byType(TodayMoodsCard), findsOneWidget);
      expect(find.byType(DominantEmotionsCard), findsOneWidget);
      expect(find.byType(GentleNudgeCard), findsOneWidget);
      expect(find.text("THIS WEEK'S TIER"), findsOneWidget);
      expect(find.text('DOMINANT EMOTIONS'), findsOneWidget);
      expect(find.text('GENTLE NUDGE'), findsOneWidget);
    });

    testWidgets('wide layout (>=720dp) mounts the two-column flow with the '
        'recent-moods preview on the right', (tester) async {
      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 3; i += 1)
          _entry(MoodType.happy, today, id: 'w$i', intensity: 4),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];

      await _pumpGarden(
        tester,
        repo: repo,
        surface: const Size(1280, 900),
      );

      // Two-column tree contains a Row that holds both the SkyHeader
      // (left) and the recent-moods list (right). The strip mounts
      // once; the recent-moods preview shows up to 4 tiles.
      expect(find.byType(SkyPlotStrip), findsOneWidget);
      expect(find.byType(MoodEntryTile), findsAtLeastNWidgets(1));
    });
  });
}
