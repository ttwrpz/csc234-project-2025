import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/ai_analysis_failure.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/mood_type.dart';

part 'ai_suggestion_dto.freezed.dart';
part 'ai_suggestion_dto.g.dart';

/// Wire-format DTO matching `AnalyzeMoodTextSuccess` from
/// functions/src/types.ts. Mirrors the server's discriminated-union success
/// branch (`ok: true, ...`).
@freezed
class AiSuggestionDto with _$AiSuggestionDto {
  const AiSuggestionDto._();

  const factory AiSuggestionDto({
    required bool ok,
    required int v,
    required String requestId,
    required String mood,
    required double confidence,
    AiSuggestionAlternativeDto? alternative,
    required String rationale,
    String? flag,
    required int latencyMs,
    required String modelVersion,
  }) = _AiSuggestionDto;

  factory AiSuggestionDto.fromJson(Map<String, Object?> json) =>
      _$AiSuggestionDtoFromJson(json);

  /// Convert the wire DTO to the domain entity. Returns `Err(parseError)` on
  /// any unrecognised mood string (defence-in-depth — the server's
  /// `responseSchema` already constrains the enum, but a future schema-drift
  /// scenario would surface here rather than crashing the UI).
  Result<AiSuggestion, AiAnalysisFailure> toEntity() {
    final MoodType primaryMood;
    try {
      primaryMood = MoodType.values.byName(mood);
    } on ArgumentError {
      return Err(AiAnalysisFailure.parseError('unknown mood: $mood'));
    }

    AiSuggestionAlternative? alt;
    final altDto = alternative;
    if (altDto != null) {
      final MoodType altMood;
      try {
        altMood = MoodType.values.byName(altDto.mood);
      } on ArgumentError {
        return Err(
          AiAnalysisFailure.parseError(
            'unknown alternative mood: ${altDto.mood}',
          ),
        );
      }
      alt = AiSuggestionAlternative(
        mood: altMood,
        confidence: altDto.confidence.clamp(0.0, 1.0),
      );
    }

    final AiSafetyFlag? safety = switch (flag) {
      'self_harm_safety' => AiSafetyFlag.selfHarm,
      _ => null,
    };

    return Ok(
      AiSuggestion(
        mood: primaryMood,
        confidence: confidence.clamp(0.0, 1.0),
        rationale: rationale,
        alternative: alt,
        safetyFlag: safety,
        latency: Duration(milliseconds: latencyMs),
      ),
    );
  }
}

@freezed
class AiSuggestionAlternativeDto with _$AiSuggestionAlternativeDto {
  const factory AiSuggestionAlternativeDto({
    required String mood,
    required double confidence,
  }) = _AiSuggestionAlternativeDto;

  factory AiSuggestionAlternativeDto.fromJson(Map<String, Object?> json) =>
      _$AiSuggestionAlternativeDtoFromJson(json);
}
