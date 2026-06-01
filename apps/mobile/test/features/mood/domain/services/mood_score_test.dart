import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/services/mood_score.dart';

void main() {
  group('computeMoodScore - spec §2.1 examples', () {
    test('happy @ intensity 4 → +0.8, sign +1', () {
      final score = computeMoodScore(MoodType.happy, 4);
      expect(score.value, closeTo(0.8, 1e-9));
      expect(score.sign, 1);
      expect(score.intensity, 4);
    });

    test('anxious @ intensity 3 → -0.6, sign -1', () {
      final score = computeMoodScore(MoodType.anxious, 3);
      expect(score.value, closeTo(-0.6, 1e-9));
      expect(score.sign, -1);
      expect(score.intensity, 3);
    });

    test('calm @ intensity 1 → +0.2, sign +1', () {
      final score = computeMoodScore(MoodType.calm, 1);
      expect(score.value, closeTo(0.2, 1e-9));
      expect(score.sign, 1);
      expect(score.intensity, 1);
    });

    test('angry @ intensity 5 → -1.0, sign -1', () {
      final score = computeMoodScore(MoodType.angry, 5);
      expect(score.value, closeTo(-1.0, 1e-9));
      expect(score.sign, -1);
      expect(score.intensity, 5);
    });
  });

  group('computeMoodScore - okay-flip regression (ADR-0010)', () {
    test('okay @ intensity 1 → +0.2, sign +1 (was -0.2 before the flip)', () {
      final score = computeMoodScore(MoodType.okay, 1);
      expect(score.value, closeTo(0.2, 1e-9));
      expect(score.sign, 1);
    });

    test('okay @ intensity 5 → +1.0, sign +1 (was -1.0 before the flip)', () {
      final score = computeMoodScore(MoodType.okay, 5);
      expect(score.value, closeTo(1.0, 1e-9));
      expect(score.sign, 1);
    });

    test('sad @ intensity 1 → -0.2, sign -1 (unchanged)', () {
      final score = computeMoodScore(MoodType.sad, 1);
      expect(score.value, closeTo(-0.2, 1e-9));
      expect(score.sign, -1);
    });
  });
}
