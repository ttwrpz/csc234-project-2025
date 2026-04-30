import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('MoodType.category mapping', () {
    test('happy maps to positive', () {
      expect(MoodType.happy.category, MoodCategory.positive);
    });

    test('calm maps to positive', () {
      expect(MoodType.calm.category, MoodCategory.positive);
    });

    test('okay maps to negativeMild', () {
      expect(MoodType.okay.category, MoodCategory.negativeMild);
    });

    test('sad maps to negativeMild', () {
      expect(MoodType.sad.category, MoodCategory.negativeMild);
    });

    test('angry maps to negativeStrong', () {
      expect(MoodType.angry.category, MoodCategory.negativeStrong);
    });

    test('anxious maps to negativeStrong', () {
      expect(MoodType.anxious.category, MoodCategory.negativeStrong);
    });
  });
}
