import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_flower.dart';
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

MoodEntry _entry(MoodType mood, DateTime createdAt, {String id = 'e'}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: 3,
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
      'negative-only history → empty canvas, NO wilting/rain-cloud icons',
      (tester) async {
        final today = DateTime.now();
        final repo = FakeMoodRepository()
          ..streamedEntries = [
            [
              _entry(MoodType.sad, today, id: 'a'),
              _entry(MoodType.angry, today, id: 'b'),
              _entry(MoodType.anxious, today, id: 'c'),
            ],
          ];
        await _pumpGarden(tester, repo: repo);

        // S3 does not visualise negatives — empty state must show.
        expect(find.text('Your garden is waiting.'), findsOneWidget);
        expect(find.byType(GardenFlower), findsNothing);
        // S4 sentinels must not have leaked in.
        expect(find.byIcon(Icons.cloud), findsNothing);
        expect(find.byIcon(Icons.water_drop), findsNothing);
      },
    );

    testWidgets('renders an AppBar titled "Your garden"', (tester) async {
      final repo = FakeMoodRepository()..streamedEntries = [const []];
      await _pumpGarden(tester, repo: repo);

      expect(find.widgetWithText(AppBar, 'Your garden'), findsOneWidget);
    });
  });
}
