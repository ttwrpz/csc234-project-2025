// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pattern_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PatternResult _$PatternResultFromJson(Map<String, dynamic> json) =>
    _PatternResult(
      dateId: json['dateId'] as String,
      mannKendallZ: (json['mannKendallZ'] as num?)?.toDouble(),
      slidingNegCount: (json['slidingNegCount'] as num).toInt(),
      consecutiveHighIntensity: (json['consecutiveHighIntensity'] as num)
          .toInt(),
      zScoreToday: (json['zScoreToday'] as num?)?.toDouble(),
      cusumC: (json['cusumC'] as num).toDouble(),
      triggeredTier: $enumDecodeNullable(_$TierEnumMap, json['triggeredTier']),
      schemaV: (json['schemaV'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$PatternResultToJson(_PatternResult instance) =>
    <String, dynamic>{
      'dateId': instance.dateId,
      'mannKendallZ': instance.mannKendallZ,
      'slidingNegCount': instance.slidingNegCount,
      'consecutiveHighIntensity': instance.consecutiveHighIntensity,
      'zScoreToday': instance.zScoreToday,
      'cusumC': instance.cusumC,
      'triggeredTier': _$TierEnumMap[instance.triggeredTier],
      'schemaV': instance.schemaV,
    };

const _$TierEnumMap = {Tier.one: 'one', Tier.two: 'two', Tier.three: 'three'};
