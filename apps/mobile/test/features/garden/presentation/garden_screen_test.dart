import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_flower.dart';
import 'package:moodbloom/features/garden/presentation/widgets/rain_cloud.dart';
import 'package:moodbloom/features/garden/presentation/widgets/wilting_plant.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../mood/domain/fakes/fake_mood_repository.dart';

/// Long-lived single-emission stream so `valueOrNull` is set as soon as the
/// provider is first read. Mirrors the pattern in
/// `log_mood_screen_test.dart`.
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
        home: Consumer(
          builder: (context, ref, _) {
            // Subscribe so the user stream is hot before the screen reads it.
            ref.watch(currentUserStreamProvider);
            return const GardenScreen();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
    testWidgets('empty state renders compassionate copy and no flowers', (
      tester,
    ) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      expect(find.text('Plant your first bloom'), findsOneWidget);
      expect(find.text('Your garden is waiting.'), findsOneWidget);
      expect(
        find.text('Log a positive mood to plant your first bloom.'),
        findsOneWidget,
      );
      expect(find.byType(GardenFlower), findsNothing);
    });

    testWidgets('streak header reflects consecutive positive days', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final yesterday = today.subtract(const Duration(days: 1));
      final repo = FakeMoodRepository()
        ..streamedEntries = [
          [
            _entry(MoodType.happy, today, id: 'a'),
            _entry(MoodType.calm, yesterday, id: 'b'),
          ],
        ];
      await _pumpGarden(tester, repo: repo);

      expect(find.text('2 day streak'), findsOneWidget);
      expect(find.text('Plant your first bloom'), findsNothing);
    });

    testWidgets('canvas renders one flower per positive mood, capped at 100', (
      tester,
    ) async {
      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 5; i += 1) _entry(MoodType.happy, today, id: 'e$i'),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];
      await _pumpGarden(tester, repo: repo);

      expect(find.byType(GardenFlower), findsNWidgets(5));
      expect(find.textContaining('and '), findsNothing);
    });

    testWidgets('overflow caption appears when positiveMoodCount exceeds 100', (
      tester,
    ) async {
      final today = DateTime.now();
      final entries = [
        for (var i = 0; i < 105; i += 1)
          _entry(MoodType.happy, today, id: 'e$i'),
      ];
      final repo = FakeMoodRepository()..streamedEntries = [entries];
      await _pumpGarden(tester, repo: repo);

      expect(find.byType(GardenFlower), findsNWidgets(100));
      expect(find.text('and 5 more'), findsOneWidget);
    });

    testWidgets(
      'negative-only history (S4) → wilting plants for i ≤ 3, rain clouds '
      'for i ≥ 4; no flowers, no empty-state copy',
      (tester) async {
        final today = DateTime.now();
        final repo = FakeMoodRepository()
          ..streamedEntries = [
            [
              _entry(MoodType.sad, today, id: 'a', intensity: 2), // wilt
              _entry(MoodType.angry, today, id: 'b', intensity: 3), // wilt
              _entry(MoodType.anxious, today, id: 'c', intensity: 5), // rain
            ],
          ];
        await _pumpGarden(tester, repo: repo);

        expect(find.text('Your garden is waiting.'), findsNothing);
        expect(find.byType(GardenFlower), findsNothing);
        expect(find.byType(WiltingPlant), findsNWidgets(2));
        expect(find.byType(RainCloud), findsOneWidget);
      },
    );

    testWidgets('mixed canvas: positives + negatives render in entry order', (
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

      expect(find.byType(GardenFlower), findsNWidgets(2));
      expect(find.byType(WiltingPlant), findsOneWidget);
      expect(find.byType(RainCloud), findsNWidgets(2));
    });

    testWidgets(
      'rain-cloud animation cap: only first 5 animate; further clouds '
      'render with animate=false',
      (tester) async {
        final today = DateTime.now();
        final entries = [
          for (var i = 0; i < 7; i += 1)
            _entry(MoodType.angry, today, id: 'r$i', intensity: 5),
        ];
        final repo = FakeMoodRepository()..streamedEntries = [entries];
        await _pumpGarden(tester, repo: repo);

        final clouds = tester
            .widgetList<RainCloud>(find.byType(RainCloud))
            .toList();
        expect(clouds, hasLength(7));
        final animatingCount = clouds.where((c) => c.animate).length;
        expect(animatingCount, 5);
      },
    );

    testWidgets('renders an AppBar titled "Your garden"', (tester) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      expect(find.widgetWithText(AppBar, 'Your garden'), findsOneWidget);
    });
  });
}
