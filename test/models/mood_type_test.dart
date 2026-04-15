import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_type.dart';

void main() {
  group('MoodType', () {
    test('has 10 mood types', () {
      expect(MoodType.values.length, 10);
    });

    test('positive moods have correct category', () {
      final positive = [
        MoodType.happy,
        MoodType.calm,
        MoodType.grateful,
        MoodType.excited,
        MoodType.loved,
      ];
      for (final mood in positive) {
        expect(mood.category, MoodCategory.positive,
            reason: '${mood.label} should be positive');
      }
    });

    test('negative moods have correct category', () {
      final negative = [
        MoodType.sad,
        MoodType.angry,
        MoodType.anxious,
        MoodType.stressed,
      ];
      for (final mood in negative) {
        expect(mood.category, MoodCategory.negative,
            reason: '${mood.label} should be negative');
      }
    });

    test('tired is neutral', () {
      expect(MoodType.tired.category, MoodCategory.neutral);
    });

    test('fromString returns correct mood', () {
      expect(MoodType.fromString('happy'), MoodType.happy);
      expect(MoodType.fromString('sad'), MoodType.sad);
      expect(MoodType.fromString('calm'), MoodType.calm);
    });

    test('fromString returns null for invalid string', () {
      expect(MoodType.fromString('nonexistent'), isNull);
      expect(MoodType.fromString(''), isNull);
    });

    test('every mood has non-empty emoji and label', () {
      for (final mood in MoodType.values) {
        expect(mood.emoji, isNotEmpty, reason: '${mood.name} emoji');
        expect(mood.label, isNotEmpty, reason: '${mood.name} label');
        expect(mood.gardenEmoji, isNotEmpty, reason: '${mood.name} garden emoji');
        expect(mood.gardenElement, isNotEmpty, reason: '${mood.name} garden element');
      }
    });
  });
}
