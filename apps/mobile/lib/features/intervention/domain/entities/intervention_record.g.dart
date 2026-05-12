// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InterventionRecord _$InterventionRecordFromJson(Map<String, dynamic> json) =>
    _InterventionRecord(
      dispatchId: json['dispatchId'] as String,
      tier: $enumDecode(_$TierEnumMap, json['tier']),
      dispatchedAt: DateTime.parse(json['dispatchedAt'] as String),
      quoteId: json['quoteId'] as String,
      cooldownUntil: DateTime.parse(json['cooldownUntil'] as String),
      optedOut: json['optedOut'] as bool? ?? false,
      schemaV: (json['schemaV'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$InterventionRecordToJson(_InterventionRecord instance) =>
    <String, dynamic>{
      'dispatchId': instance.dispatchId,
      'tier': _$TierEnumMap[instance.tier]!,
      'dispatchedAt': instance.dispatchedAt.toIso8601String(),
      'quoteId': instance.quoteId,
      'cooldownUntil': instance.cooldownUntil.toIso8601String(),
      'optedOut': instance.optedOut,
      'schemaV': instance.schemaV,
    };

const _$TierEnumMap = {Tier.one: 'one', Tier.two: 'two', Tier.three: 'three'};
