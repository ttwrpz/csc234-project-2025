import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/ai_suggestion.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('AiSuggestion', () {
    test('valid construction round-trips', () {
      const suggestion = AiSuggestion(
        mood: MoodType.happy,
        confidence: 0.8,
        rationale: 'Themes of achievement.',
        latency: Duration(milliseconds: 250),
      );
      expect(suggestion.mood, MoodType.happy);
      expect(suggestion.confidence, 0.8);
      expect(suggestion.alternative, isNull);
      expect(suggestion.safetyFlag, isNull);
    });

    test('confidence < 0 fails the assert', () {
      expect(
        () => AiSuggestion(
          mood: MoodType.happy,
          confidence: -0.1,
          rationale: '',
          latency: Duration.zero,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('confidence > 1 fails the assert', () {
      expect(
        () => AiSuggestion(
          mood: MoodType.happy,
          confidence: 1.1,
          rationale: '',
          latency: Duration.zero,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('boundaries 0 and 1 are valid', () {
      const a = AiSuggestion(
        mood: MoodType.okay,
        confidence: 0,
        rationale: '',
        latency: Duration.zero,
      );
      const b = AiSuggestion(
        mood: MoodType.okay,
        confidence: 1,
        rationale: '',
        latency: Duration.zero,
      );
      expect(a.confidence, 0);
      expect(b.confidence, 1);
    });

    test('Freezed equality holds across structurally-equal instances', () {
      const a = AiSuggestion(
        mood: MoodType.calm,
        confidence: 0.5,
        rationale: '',
        latency: Duration.zero,
      );
      const b = AiSuggestion(
        mood: MoodType.calm,
        confidence: 0.5,
        rationale: '',
        latency: Duration.zero,
      );
      expect(a, equals(b));
    });
  });

  group('AiSuggestionAlternative', () {
    test('confidence assertion holds', () {
      expect(
        () => AiSuggestionAlternative(mood: MoodType.sad, confidence: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
