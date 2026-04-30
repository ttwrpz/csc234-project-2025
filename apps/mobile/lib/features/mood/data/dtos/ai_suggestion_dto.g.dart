// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_suggestion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiSuggestionDtoImpl _$$AiSuggestionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$AiSuggestionDtoImpl(
  ok: json['ok'] as bool,
  v: (json['v'] as num).toInt(),
  requestId: json['requestId'] as String,
  mood: json['mood'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  alternative: json['alternative'] == null
      ? null
      : AiSuggestionAlternativeDto.fromJson(
          json['alternative'] as Map<String, dynamic>,
        ),
  rationale: json['rationale'] as String,
  flag: json['flag'] as String?,
  latencyMs: (json['latencyMs'] as num).toInt(),
  modelVersion: json['modelVersion'] as String,
);

Map<String, dynamic> _$$AiSuggestionDtoImplToJson(
  _$AiSuggestionDtoImpl instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'v': instance.v,
  'requestId': instance.requestId,
  'mood': instance.mood,
  'confidence': instance.confidence,
  'alternative': instance.alternative,
  'rationale': instance.rationale,
  'flag': instance.flag,
  'latencyMs': instance.latencyMs,
  'modelVersion': instance.modelVersion,
};

_$AiSuggestionAlternativeDtoImpl _$$AiSuggestionAlternativeDtoImplFromJson(
  Map<String, dynamic> json,
) => _$AiSuggestionAlternativeDtoImpl(
  mood: json['mood'] as String,
  confidence: (json['confidence'] as num).toDouble(),
);

Map<String, dynamic> _$$AiSuggestionAlternativeDtoImplToJson(
  _$AiSuggestionAlternativeDtoImpl instance,
) => <String, dynamic>{
  'mood': instance.mood,
  'confidence': instance.confidence,
};
