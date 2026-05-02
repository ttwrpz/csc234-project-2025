// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pattern_insight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PatternInsight _$PatternInsightFromJson(Map<String, dynamic> json) =>
    _PatternInsight(
      id: json['id'] as String,
      kind: $enumDecode(_$PatternInsightKindEnumMap, json['kind']),
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      sampleSize: (json['sampleSize'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$PatternInsightToJson(_PatternInsight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$PatternInsightKindEnumMap[instance.kind]!,
      'text': instance.text,
      'confidence': instance.confidence,
      'sampleSize': instance.sampleSize,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };

const _$PatternInsightKindEnumMap = {
  PatternInsightKind.weekday: 'weekday',
  PatternInsightKind.streak: 'streak',
  PatternInsightKind.trend: 'trend',
  PatternInsightKind.gemini: 'gemini',
};
