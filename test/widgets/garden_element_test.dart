// Tests for: Garden visual elements (Beta v0.2 upgrade)
// Features covered: plant rendering for positive moods, bug rendering
//   for negative moods, opacity fading, garden element generation
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_entry.dart';
import 'package:user_centric_mobile_app/models/mood_type.dart';
import 'package:user_centric_mobile_app/providers/garden_provider.dart';
import 'package:user_centric_mobile_app/widgets/garden_plant.dart';
import 'package:user_centric_mobile_app/widgets/garden_bug.dart';

void main() {
  group('GardenProvider - Element Generation', () {
    late GardenProvider provider;

    setUp(() {
      provider = GardenProvider();
    });

    test('generates elements from mood entries', () {
      final entries = [
        _createEntry('1', 'happy', 'positive'),
        _createEntry('2', 'sad', 'negative'),
        _createEntry('3', 'tired', 'neutral'),
      ];

      provider.updateGarden(entries);
      expect(provider.elements.length, 3);
    });

    test('positive moods render as non-bug elements', () {
      final entries = [
        _createEntry('1', 'happy', 'positive'),
        _createEntry('2', 'calm', 'positive'),
        _createEntry('3', 'grateful', 'positive'),
      ];

      provider.updateGarden(entries);

      for (final element in provider.elements) {
        expect(element.isBug, false);
      }
    });

    test('negative moods render as bug elements', () {
      final entries = [
        _createEntry('1', 'sad', 'negative'),
        _createEntry('2', 'angry', 'negative'),
        _createEntry('3', 'anxious', 'negative'),
        _createEntry('4', 'stressed', 'negative'),
      ];

      provider.updateGarden(entries);

      for (final element in provider.elements) {
        expect(element.isBug, true);
      }
    });

    test('positive moods have full opacity', () {
      final entries = [
        _createEntry('1', 'happy', 'positive'),
        _createEntry('2', 'calm', 'positive'),
      ];

      provider.updateGarden(entries);

      for (final element in provider.elements) {
        expect(element.opacity, 1.0);
      }
    });

    test('negative moods have reduced opacity based on age', () {
      final entries = [
        _createEntry(
          '1',
          'sad',
          'negative',
          createdAt: DateTime.now().subtract(const Duration(hours: 24)),
        ),
      ];

      provider.setAnimationSpeed(2.0);
      provider.updateGarden(entries);

      final element = provider.elements.first;
      // At 2x speed, fade over 36 hours. At 24 hours old: 1.0 - (24/36) = 0.33
      expect(element.opacity, lessThan(1.0));
      expect(element.opacity, greaterThan(0.0));
    });

    test('higher animation speed causes faster fade', () {
      final entries = [
        _createEntry(
          '1',
          'sad',
          'negative',
          createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        ),
      ];

      // At 1x speed
      provider.setAnimationSpeed(1.0);
      provider.updateGarden(entries);
      final opacity1x = provider.elements.first.opacity;

      // At 5x speed
      provider.setAnimationSpeed(5.0);
      provider.updateGarden(entries);
      final opacity5x = provider.elements.first.opacity;

      // 5x speed should have lower opacity (faster fade)
      expect(opacity5x, lessThan(opacity1x));
    });

    test('element positions are deterministic', () {
      final entries = [
        _createEntry('1', 'happy', 'positive'),
        _createEntry('2', 'sad', 'negative'),
      ];

      provider.updateGarden(entries);
      final positions1 =
          provider.elements.map((e) => e.position).toList();

      provider.updateGarden(entries);
      final positions2 =
          provider.elements.map((e) => e.position).toList();

      // Same entries should produce same positions
      for (int i = 0; i < positions1.length; i++) {
        expect(positions1[i].dx, positions2[i].dx);
        expect(positions1[i].dy, positions2[i].dy);
      }
    });

    test('positive moods positioned lower (ground level)', () {
      final entries = [
        _createEntry('1', 'happy', 'positive'),
      ];

      provider.updateGarden(entries);
      final element = provider.elements.first;
      // Positive moods should be y: 0.4-0.9
      expect(element.position.dy, greaterThanOrEqualTo(0.4));
    });

    test('empty entries clears garden', () {
      final entries = [_createEntry('1', 'happy', 'positive')];
      provider.updateGarden(entries);
      expect(provider.elements.length, 1);

      provider.updateGarden([]);
      expect(provider.elements.length, 0);
    });

    test('invalid mood string is skipped', () {
      final entries = [
        _createEntry('1', 'invalid_mood', 'positive'),
      ];

      provider.updateGarden(entries);
      expect(provider.elements.length, 0);
    });
  });

  group('GardenPlantWidget', () {
    testWidgets('renders for happy mood', (tester) async {
      final element = GardenElement(
        id: 'test-1',
        moodType: MoodType.happy,
        position: const Offset(0.5, 0.7),
        size: 40,
        opacity: 1.0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: GardenPlantWidget(element: element)),
          ),
        ),
      );
      // Advance past the delayed animation start
      await tester.pump(const Duration(seconds: 1));

      // Plant widget should be rendered
      expect(find.byType(GardenPlantWidget), findsOneWidget);
      // Should show the happy emoji
      expect(find.text(MoodType.happy.emoji), findsOneWidget);

      // Dispose properly to avoid pending timer
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('renders for calm mood', (tester) async {
      final element = GardenElement(
        id: 'test-calm',
        moodType: MoodType.calm,
        position: const Offset(0.5, 0.7),
        size: 40,
        opacity: 1.0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: GardenPlantWidget(element: element)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(GardenPlantWidget), findsOneWidget);
      expect(find.text(MoodType.calm.emoji), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('GardenBugWidget', () {
    testWidgets('renders for negative mood', (tester) async {
      final element = GardenElement(
        id: 'test-bug-1',
        moodType: MoodType.sad,
        position: const Offset(0.5, 0.3),
        size: 36,
        opacity: 0.7,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GardenBugWidget(element: element, animationSpeed: 2.0),
            ),
          ),
        ),
      );

      expect(find.byType(GardenBugWidget), findsOneWidget);
      // Dispose properly
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('displays garden emoji text', (tester) async {
      final element = GardenElement(
        id: 'test-bug-2',
        moodType: MoodType.angry,
        position: const Offset(0.5, 0.3),
        size: 36,
        opacity: 1.0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GardenBugWidget(element: element, animationSpeed: 2.0),
            ),
          ),
        ),
      );

      // Should contain the bug garden emoji
      expect(find.text(MoodType.angry.gardenEmoji), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('renders with reduced opacity', (tester) async {
      final element = GardenElement(
        id: 'test-bug-3',
        moodType: MoodType.stressed,
        position: const Offset(0.5, 0.3),
        size: 36,
        opacity: 0.3,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GardenBugWidget(element: element, animationSpeed: 2.0),
            ),
          ),
        ),
      );

      // The AnimatedOpacity widget should have the expected opacity
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 0.3);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

MoodEntry _createEntry(
  String id,
  String mood,
  String category, {
  DateTime? createdAt,
}) {
  return MoodEntry(
    id: id,
    userId: 'test-user',
    mood: mood,
    moodCategory: category,
    text: 'Test entry',
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
