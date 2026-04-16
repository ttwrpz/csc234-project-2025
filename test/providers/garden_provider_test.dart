// Tests for: F15 Living Garden Canvas, F16 Plant Growth, F17 Bug Fade,
//   F40 Garden Element Positioning, F41 Mood-to-Element Mapping
// Features covered: mood-to-garden-element mapping, fade opacity calculation,
//   animation speed effects, deterministic positioning, element filtering
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_entry.dart';
import 'package:user_centric_mobile_app/models/mood_type.dart';
import 'package:user_centric_mobile_app/providers/garden_provider.dart';

void main() {
  group('GardenProvider', () {
    late GardenProvider provider;

    setUp(() {
      provider = GardenProvider();
    });

    group('mood-to-element mapping', () {
      test('positive moods map to plant elements (isBug = false)', () {
        final positiveMoods = ['happy', 'calm', 'grateful', 'excited', 'loved'];
        final entries = positiveMoods
            .asMap()
            .entries
            .map((e) => _createEntry('${e.key}', e.value, 'positive'))
            .toList();

        provider.updateGarden(entries);

        expect(provider.elements.length, 5);
        for (final element in provider.elements) {
          expect(element.isBug, false,
              reason: '${element.moodType.name} should be a plant, not a bug');
        }
      });

      test('negative moods map to bug elements (isBug = true)', () {
        final negativeMoods = ['sad', 'angry', 'anxious', 'stressed'];
        final entries = negativeMoods
            .asMap()
            .entries
            .map((e) => _createEntry('${e.key}', e.value, 'negative'))
            .toList();

        provider.updateGarden(entries);

        expect(provider.elements.length, 4);
        for (final element in provider.elements) {
          expect(element.isBug, true,
              reason: '${element.moodType.name} should be a bug');
        }
      });

      test('tired mood maps to neutral category (not a bug)', () {
        final entries = [_createEntry('1', 'tired', 'neutral')];
        provider.updateGarden(entries);

        expect(provider.elements.length, 1);
        expect(provider.elements.first.isBug, false);
        expect(provider.elements.first.moodType, MoodType.tired);
      });

      test('invalid mood strings are skipped', () {
        final entries = [
          _createEntry('1', 'happy', 'positive'),
          _createEntry('2', 'nonexistent', 'unknown'),
          _createEntry('3', 'calm', 'positive'),
        ];

        provider.updateGarden(entries);
        expect(provider.elements.length, 2);
      });

      test('each mood type maps to correct MoodType enum', () {
        for (final mood in MoodType.values) {
          final entries = [_createEntry('1', mood.name, mood.category.name)];
          provider.updateGarden(entries);
          expect(provider.elements.first.moodType, mood);
        }
      });
    });

    group('fade opacity calculation', () {
      test('positive moods always have full opacity', () {
        final entries = [
          _createEntry('1', 'happy', 'positive',
              createdAt: DateTime.now().subtract(const Duration(hours: 48))),
          _createEntry('2', 'calm', 'positive',
              createdAt: DateTime.now().subtract(const Duration(hours: 100))),
        ];

        provider.updateGarden(entries);

        for (final element in provider.elements) {
          expect(element.opacity, 1.0,
              reason: 'Positive moods should not fade');
        }
      });

      test('recent negative moods have high opacity', () {
        final entries = [
          _createEntry('1', 'sad', 'negative',
              createdAt: DateTime.now().subtract(const Duration(hours: 1))),
        ];

        provider.setAnimationSpeed(2.0);
        provider.updateGarden(entries);

        // At 2x speed, fade over 36 hours. At 1 hour old: 1.0 - (1/36) = ~0.97
        expect(provider.elements.first.opacity, greaterThan(0.9));
      });

      test('old negative moods have low opacity (clamped to 0.1)', () {
        final entries = [
          _createEntry('1', 'sad', 'negative',
              createdAt: DateTime.now().subtract(const Duration(hours: 70))),
        ];

        provider.setAnimationSpeed(2.0);
        provider.updateGarden(entries);

        // At 2x speed, fade over 36 hours. At 70 hours: 1.0 - (70/36) < 0 → clamped to 0.1
        expect(provider.elements.first.opacity, 0.1);
      });

      test('at speed 2x, 24-hour-old entry has reduced opacity', () {
        final entries = [
          _createEntry('1', 'angry', 'negative',
              createdAt: DateTime.now().subtract(const Duration(hours: 24))),
        ];

        provider.setAnimationSpeed(2.0);
        provider.updateGarden(entries);

        // fadeHours = 72/2 = 36. opacity = 1.0 - (24/36) = 0.333
        final opacity = provider.elements.first.opacity;
        expect(opacity, closeTo(0.333, 0.05));
      });

      test('at speed 5x, 10-hour-old entry fades faster than at 1x', () {
        final entries = [
          _createEntry('1', 'anxious', 'negative',
              createdAt: DateTime.now().subtract(const Duration(hours: 10))),
        ];

        provider.setAnimationSpeed(1.0);
        provider.updateGarden(entries);
        final opacity1x = provider.elements.first.opacity;

        provider.setAnimationSpeed(5.0);
        provider.updateGarden(entries);
        final opacity5x = provider.elements.first.opacity;

        expect(opacity5x, lessThan(opacity1x),
            reason: 'Higher speed should cause faster fade');
      });

      test('at speed 5x, 3-hour-old entry has correct opacity', () {
        final entries = [
          _createEntry('1', 'stressed', 'negative',
              createdAt: DateTime.now().subtract(const Duration(hours: 3))),
        ];

        provider.setAnimationSpeed(5.0);
        provider.updateGarden(entries);

        // fadeHours = 72/5 = 14.4 → rounded to 14. opacity = 1.0 - (3/14) ≈ 0.786
        final opacity = provider.elements.first.opacity;
        expect(opacity, greaterThan(0.7));
        expect(opacity, lessThan(0.9));
      });
    });

    group('element positioning', () {
      test('positions are deterministic (seeded random)', () {
        final entries = [
          _createEntry('1', 'happy', 'positive'),
          _createEntry('2', 'sad', 'negative'),
          _createEntry('3', 'tired', 'neutral'),
        ];

        provider.updateGarden(entries);
        final positions1 = provider.elements.map((e) => e.position).toList();

        provider.updateGarden(entries);
        final positions2 = provider.elements.map((e) => e.position).toList();

        for (int i = 0; i < positions1.length; i++) {
          expect(positions1[i].dx, positions2[i].dx);
          expect(positions1[i].dy, positions2[i].dy);
        }
      });

      test('positive moods positioned on ground (y >= 0.4)', () {
        final entries = [
          _createEntry('1', 'happy', 'positive'),
          _createEntry('2', 'calm', 'positive'),
          _createEntry('3', 'grateful', 'positive'),
        ];

        provider.updateGarden(entries);

        for (final element in provider.elements) {
          expect(element.position.dy, greaterThanOrEqualTo(0.4),
              reason: 'Positive moods should be at ground level');
          expect(element.position.dy, lessThanOrEqualTo(0.9));
        }
      });

      test('negative moods can fly higher (y >= 0.1)', () {
        final entries = [
          _createEntry('1', 'sad', 'negative'),
          _createEntry('2', 'angry', 'negative'),
        ];

        provider.updateGarden(entries);

        for (final element in provider.elements) {
          expect(element.position.dy, greaterThanOrEqualTo(0.1));
        }
      });

      test('all elements within canvas bounds (0..1)', () {
        final entries = List.generate(
          20,
          (i) => _createEntry('$i', 'happy', 'positive'),
        );

        provider.updateGarden(entries);

        for (final element in provider.elements) {
          expect(element.position.dx, greaterThanOrEqualTo(0.0));
          expect(element.position.dx, lessThanOrEqualTo(1.0));
          expect(element.position.dy, greaterThanOrEqualTo(0.0));
          expect(element.position.dy, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('garden lifecycle', () {
      test('empty entries clears garden', () {
        provider.updateGarden([
          _createEntry('1', 'happy', 'positive'),
        ]);
        expect(provider.elements.length, 1);

        provider.updateGarden([]);
        expect(provider.elements.length, 0);
      });

      test('updateGarden replaces all elements', () {
        provider.updateGarden([
          _createEntry('1', 'happy', 'positive'),
          _createEntry('2', 'sad', 'negative'),
        ]);
        expect(provider.elements.length, 2);

        provider.updateGarden([
          _createEntry('3', 'calm', 'positive'),
        ]);
        expect(provider.elements.length, 1);
        expect(provider.elements.first.id, '3');
      });

      test('setAnimationSpeed updates and notifies listeners', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setAnimationSpeed(3.0);
        expect(provider.animationSpeed, 3.0);
        expect(notifyCount, 1);

        provider.setAnimationSpeed(5.0);
        expect(provider.animationSpeed, 5.0);
        expect(notifyCount, 2);
      });

      test('updateGarden notifies listeners', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.updateGarden([_createEntry('1', 'happy', 'positive')]);
        expect(notifyCount, 1);
      });
    });

    group('GardenElement', () {
      test('isBug returns true for negative category moods', () {
        final element = GardenElement(
          id: '1',
          moodType: MoodType.sad,
          position: const Offset(0.5, 0.5),
          createdAt: DateTime.now(),
        );
        expect(element.isBug, true);
      });

      test('isBug returns false for positive category moods', () {
        final element = GardenElement(
          id: '1',
          moodType: MoodType.happy,
          position: const Offset(0.5, 0.5),
          createdAt: DateTime.now(),
        );
        expect(element.isBug, false);
      });

      test('isBug returns false for neutral category moods', () {
        final element = GardenElement(
          id: '1',
          moodType: MoodType.tired,
          position: const Offset(0.5, 0.5),
          createdAt: DateTime.now(),
        );
        expect(element.isBug, false);
      });

      test('default size is 40', () {
        final element = GardenElement(
          id: '1',
          moodType: MoodType.happy,
          position: const Offset(0.5, 0.5),
          createdAt: DateTime.now(),
        );
        expect(element.size, 40);
      });

      test('default opacity is 1.0', () {
        final element = GardenElement(
          id: '1',
          moodType: MoodType.happy,
          position: const Offset(0.5, 0.5),
          createdAt: DateTime.now(),
        );
        expect(element.opacity, 1.0);
      });
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
