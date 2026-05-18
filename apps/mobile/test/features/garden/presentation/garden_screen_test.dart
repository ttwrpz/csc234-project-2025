import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/garden/presentation/widgets/daily_score_strip.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_bed.dart';
import 'package:moodbloom/features/garden/presentation/widgets/sky_header.dart';
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
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
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
  group('GardenScreen — ADR-0010 ecosystem refactor', () {
    testWidgets('empty state still mounts the canvas (GardenBed) and the '
        'daily-score strip', (tester) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      // The canvas always renders — empty state paints ground+grass only,
      // no flowers (closes the wipe-still-shows-3-flowers regression).
      expect(find.byType(SkyHeader), findsOneWidget);
      expect(find.byType(GardenBed), findsOneWidget);
      expect(find.byType(DailyScoreStrip), findsOneWidget);
    });

    testWidgets('positive entries today drive a populated bed', (tester) async {
      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 5; i += 1)
          _entry(MoodType.happy, today, id: 'e$i', intensity: 5),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];
      await _pumpGarden(tester, repo: repo);

      // The tier picker is the use case's job; from the screen's side
      // we verify the bed is mounted with this week's entries forwarded
      // through the SkyHeader.
      final bed = tester.widget<GardenBed>(find.byType(GardenBed));
      expect(bed.entries.length, 5);
      expect(find.text('5 entries this week'), findsOneWidget);
    });

    testWidgets(
      'negative-only history mounts the canvas with the bed populated',
      (tester) async {
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

        final bed = tester.widget<GardenBed>(find.byType(GardenBed));
        expect(bed.entries.length, 3);
        expect(find.byType(DailyScoreStrip), findsOneWidget);
      },
    );

    // GardenScreen used to mount a "Log mood" FAB. That CTA moved to
    // the shell-level bottom nav (`MbBottomNav` center "Add" slot) so
    // the home page no longer owns it — assertions on the shell live
    // in the router-level integration tests.

    testWidgets('wide layout (≥720dp) mounts the bed in a two-column row with '
        'recent moods on the right', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 3; i += 1)
          _entry(MoodType.happy, today, id: 'w$i', intensity: 4),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moodRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider.overrideWith(
              (_) => _userStream(
                const AppUser(uid: 'u-1', email: 'u@example.com'),
              ),
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
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Two-column tree contains a Row that holds both the SkyHeader
      // (left) and the recent-moods list (right). The bed mounts once;
      // the recent-moods preview shows up to 5 tiles.
      expect(find.byType(GardenBed), findsOneWidget);
      expect(find.byType(MoodEntryTile), findsAtLeastNWidgets(1));
    });
  });
}
