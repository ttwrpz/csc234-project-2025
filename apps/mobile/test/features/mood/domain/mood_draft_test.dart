import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_draft.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('MoodDraft.isReadyToSave', () {
    test('empty draft is not ready (no mood)', () {
      final draft = MoodDraft.empty();
      expect(draft.isReadyToSave, isFalse);
    });

    test('draft with mood and intensity 3 is ready', () {
      const draft = MoodDraft(mood: MoodType.happy, intensity: 3);
      expect(draft.isReadyToSave, isTrue);
    });

    test('draft with intensity 0 is not ready', () {
      const draft = MoodDraft(mood: MoodType.happy, intensity: 0);
      expect(draft.isReadyToSave, isFalse);
    });

    test('draft with intensity 6 is not ready', () {
      const draft = MoodDraft(mood: MoodType.happy, intensity: 6);
      expect(draft.isReadyToSave, isFalse);
    });

    test('draft with text length 501 is not ready', () {
      final draft = MoodDraft(
        mood: MoodType.happy,
        intensity: 3,
        text: 'a' * 501,
      );
      expect(draft.isReadyToSave, isFalse);
    });
  });
}
