import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/dtos/ai_suggestion_dto.dart';
import 'package:moodbloom/features/mood/domain/ai_analysis_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/ai_suggestion.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  Map<String, Object?> validPayload({
    String mood = 'happy',
    double confidence = 0.8,
    Map<String, Object?>? alternative,
    String? flag,
  }) {
    return {
      'ok': true,
      'v': 1,
      'requestId': '00000000-0000-0000-0000-000000000000',
      'mood': mood,
      'confidence': confidence,
      'alternative': alternative,
      'rationale': 'Themes of achievement.',
      'flag': flag,
      'latencyMs': 250,
      'modelVersion': 'gemini-2.5-flash',
    };
  }

  group('AiSuggestionDto.toEntity', () {
    test('valid payload → Ok(AiSuggestion)', () {
      final dto = AiSuggestionDto.fromJson(validPayload());
      final result = dto.toEntity();
      expect(result, isA<Ok<AiSuggestion, AiAnalysisFailure>>());
      final entity = (result as Ok<AiSuggestion, AiAnalysisFailure>).value;
      expect(entity.mood, MoodType.happy);
      expect(entity.confidence, 0.8);
      expect(entity.latency, const Duration(milliseconds: 250));
    });

    test('mood not in six-enum → Err(parseError)', () {
      final dto = AiSuggestionDto.fromJson(validPayload(mood: 'melancholy'));
      final result = dto.toEntity();
      expect(result, isA<Err<AiSuggestion, AiAnalysisFailure>>());
      final failure = (result as Err<AiSuggestion, AiAnalysisFailure>).failure;
      expect(failure.runtimeType.toString(), contains('ParseError'));
    });

    test('confidence > 1 is clamped to 1.0', () {
      final dto = AiSuggestionDto.fromJson(validPayload(confidence: 1.4));
      final result = dto.toEntity();
      final entity = (result as Ok<AiSuggestion, AiAnalysisFailure>).value;
      expect(entity.confidence, 1.0);
    });

    test('confidence < 0 is clamped to 0.0', () {
      final dto = AiSuggestionDto.fromJson(validPayload(confidence: -0.3));
      final result = dto.toEntity();
      final entity = (result as Ok<AiSuggestion, AiAnalysisFailure>).value;
      expect(entity.confidence, 0.0);
    });

    test('flag=self_harm_safety → safetyFlag=selfHarm', () {
      final dto = AiSuggestionDto.fromJson(
        validPayload(flag: 'self_harm_safety'),
      );
      final result = dto.toEntity();
      final entity = (result as Ok<AiSuggestion, AiAnalysisFailure>).value;
      expect(entity.safetyFlag, AiSafetyFlag.selfHarm);
    });

    test('alternative round-trips with clamping', () {
      final dto = AiSuggestionDto.fromJson(
        validPayload(alternative: {'mood': 'calm', 'confidence': 1.2}),
      );
      final result = dto.toEntity();
      final entity = (result as Ok<AiSuggestion, AiAnalysisFailure>).value;
      expect(entity.alternative, isNotNull);
      expect(entity.alternative!.mood, MoodType.calm);
      expect(entity.alternative!.confidence, 1.0);
    });

    test('alternative with bogus mood → parseError', () {
      final dto = AiSuggestionDto.fromJson(
        validPayload(alternative: {'mood': 'melancholy', 'confidence': 0.3}),
      );
      final result = dto.toEntity();
      expect(result, isA<Err<AiSuggestion, AiAnalysisFailure>>());
    });
  });
}
