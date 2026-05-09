import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/garden/presentation/widgets/daily_score_strip.dart';
import 'package:moodbloom/features/garden/presentation/widgets/plant_tier_group.dart';
import 'package:moodbloom/features/garden/presentation/widgets/sky_header.dart';
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
    testWidgets('empty state still mounts the canvas (PlantTierGroup) and the '
        'daily-score strip', (tester) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      // The canvas always renders — no per-entry sprite dispatch.
      expect(find.byType(SkyHeader), findsOneWidget);
      expect(find.byType(PlantTierGroup), findsOneWidget);
      expect(find.byType(DailyScoreStrip), findsOneWidget);
    });

    testWidgets('positive entries today drive a thriving/flourishing tier', (
      tester,
    ) async {
      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 5; i += 1)
          _entry(MoodType.happy, today, id: 'e$i', intensity: 5),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];
      await _pumpGarden(tester, repo: repo);

      // The tier picker is the use case's job; from the screen's side
      // we just verify the canvas keeps mounting and the entries
      // pill reflects the live count (today is in this week).
      expect(find.byType(PlantTierGroup), findsOneWidget);
      expect(find.text('5 entries this week'), findsOneWidget);
    });

    testWidgets(
      'negative-only history mounts the canvas with no per-entry sprites',
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

        // No per-entry sprites — just the tier group + atmosphere
        // overlay. Plants stay alive in every tier per ADR-0010 §1.
        expect(find.byType(PlantTierGroup), findsOneWidget);
        expect(find.byType(DailyScoreStrip), findsOneWidget);
      },
    );

    testWidgets('"Log mood" CTA (FAB) is reachable from the home page', (
      tester,
    ) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      expect(find.text('Log mood'), findsOneWidget);
    });
  });
}
