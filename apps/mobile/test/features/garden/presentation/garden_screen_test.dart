import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/garden/presentation/widgets/flora_sprite.dart';
import 'package:moodbloom/features/garden/presentation/widgets/rain_cloud.dart';
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
  // The garden-state stream emits asynchronously; flora sprites animate
  // continuously so `pumpAndSettle` would loop forever. Pump enough
  // frames to let the providers settle but stop before animations matter.
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
  group('GardenScreen', () {
    testWidgets('empty state renders no flora sprites', (tester) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      expect(find.byType(Flower), findsNothing);
      expect(find.byType(Bud), findsNothing);
      expect(find.byType(WiltingPlant), findsNothing);
      expect(find.byType(RainCloud), findsNothing);
    });

    testWidgets('positive entries render Flower sprites', (tester) async {
      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 5; i += 1) _entry(MoodType.happy, today, id: 'e$i'),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];
      await _pumpGarden(tester, repo: repo);

      // Each happy@i=3 maps to a Flower (Bud is reserved for intensity 1).
      expect(find.byType(Flower), findsNWidgets(5));
    });

    testWidgets(
      'negative-only history (S4) → wilting plants for i ≤ 3, rain clouds '
      'for i ≥ 4; no flowers',
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

        expect(find.byType(Flower), findsNothing);
        expect(find.byType(WiltingPlant), findsNWidgets(2));
        expect(find.byType(RainCloud), findsOneWidget);
      },
    );

    testWidgets('mixed canvas: positives + negatives render side by side', (
      tester,
    ) async {
      final today = DateTime.now();
      final repo = FakeMoodRepository()
        ..streamedEntries = [
          [
            _entry(MoodType.happy, today, id: 'p1'),
            _entry(MoodType.sad, today, id: 'w1', intensity: 1),
            _entry(MoodType.calm, today, id: 'p2'),
            _entry(MoodType.angry, today, id: 'r1', intensity: 5),
            _entry(MoodType.anxious, today, id: 'r2', intensity: 4),
          ],
        ];
      await _pumpGarden(tester, repo: repo);

      expect(find.byType(Flower), findsNWidgets(2));
      expect(find.byType(WiltingPlant), findsOneWidget);
      expect(find.byType(RainCloud), findsNWidgets(2));
    });

    testWidgets('"Log mood" CTA (FAB) is reachable from the home page', (
      tester,
    ) async {
      // The inline "Log today's mood" button was retired once the FAB
      // and the centred bottom-nav slot covered the same action. The
      // FAB stays — it's the primary mood-logging affordance on Home.
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      expect(find.text('Log mood'), findsOneWidget);
    });
  });
}
