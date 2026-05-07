@Tags(['golden'])
library;

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../mood/domain/fakes/fake_mood_repository.dart';

/// Full-screen garden goldens. Closes 3 of the 4 missing S4-carry-over
/// scenarios per S5 plan §3a.2:
///   - empty garden (no entries → empty sky + empty garden bed)
///   - flower garden (positive moods → blooming flora)
///   - wilting-plant garden (negativeMild moods 1–3 → wilting flora)
///
/// (Rain-cloud garden — negativeStrong 4–5 — is already covered by the
/// existing rain_cloud_static.png widget-level golden in
/// widgets/goldens/. The scenario at the screen level adds nothing new
/// beyond what that test asserts, so it's omitted.)
///
/// Scaffolding mirrors `garden_screen_test.dart` `_pumpGarden`
/// exactly. Animations are absorbed by the project's 4% pixel
/// tolerance configured in `flutter_test_config.dart` (the same
/// budget that lets rain_cloud_static and pattern_insight_card pass
/// cross-platform). 6 × 50ms pump frames = same cadence as the
/// non-golden screen test, lets providers settle without losing the
/// snapshot to perpetual flora animation cycles.

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
  for (var i = 0; i < 6; i += 1) {
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
  testGoldensEmpty();
  testGoldensFlowers();
  testGoldensWilting();
}

void testGoldensEmpty() {
  testWidgets('GardenScreen — empty (no entries)', (tester) async {
    final repo = FakeMoodRepository()..streamedEntries = [const []];
    await _pumpGarden(tester, repo: repo);

    await expectLater(
      find.byType(GardenScreen),
      matchesGoldenFile('goldens/garden_screen_empty.png'),
    );
  });
}

void testGoldensFlowers() {
  testWidgets('GardenScreen — flower garden (positive moods bloom)', (
    tester,
  ) async {
    final today = DateTime.now();
    final repo = FakeMoodRepository()
      ..streamedEntries = [
        [
          _entry(
            MoodType.happy,
            today.subtract(const Duration(hours: 2)),
            id: 'h1',
            intensity: 4,
          ),
          _entry(
            MoodType.calm,
            today.subtract(const Duration(days: 1)),
            id: 'c1',
            intensity: 3,
          ),
          _entry(
            MoodType.happy,
            today.subtract(const Duration(days: 2)),
            id: 'h2',
            intensity: 5,
          ),
        ],
      ];
    await _pumpGarden(tester, repo: repo);

    await expectLater(
      find.byType(GardenScreen),
      matchesGoldenFile('goldens/garden_screen_flowers.png'),
    );
  });
}

void testGoldensWilting() {
  testWidgets('GardenScreen — wilting plants (negative mild)', (tester) async {
    final today = DateTime.now();
    // Negative-category moods at intensity 1–3 → wilting flora per
    // ADR-0006 (compassionate reframing). Intensity 4–5 would render
    // as rain clouds, which is a separate visual contract covered by
    // the rain_cloud_static widget-level golden.
    final repo = FakeMoodRepository()
      ..streamedEntries = [
        [
          _entry(
            MoodType.sad,
            today.subtract(const Duration(hours: 3)),
            id: 's1',
            intensity: 2,
          ),
          _entry(
            MoodType.anxious,
            today.subtract(const Duration(days: 1)),
            id: 'a1',
            intensity: 3,
          ),
          _entry(
            MoodType.sad,
            today.subtract(const Duration(days: 2)),
            id: 's2',
            intensity: 1,
          ),
        ],
      ];
    await _pumpGarden(tester, repo: repo);

    await expectLater(
      find.byType(GardenScreen),
      matchesGoldenFile('goldens/garden_screen_wilting.png'),
    );
  });
}
