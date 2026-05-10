// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_garden.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyGarden _$WeeklyGardenFromJson(Map<String, dynamic> json) =>
    _WeeklyGarden(
      weekId: json['weekId'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      healthHistory: (json['healthHistory'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      summary: WeeklySummary.fromJson(json['summary'] as Map<String, dynamic>),
      archivedAt: DateTime.parse(json['archivedAt'] as String),
      schemaV: (json['schemaV'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$WeeklyGardenToJson(_WeeklyGarden instance) =>
    <String, dynamic>{
      'weekId': instance.weekId,
      'weekStart': instance.weekStart.toIso8601String(),
      'weekEnd': instance.weekEnd.toIso8601String(),
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'healthHistory': instance.healthHistory,
      'summary': instance.summary.toJson(),
      'archivedAt': instance.archivedAt.toIso8601String(),
      'schemaV': instance.schemaV,
    };

_WeeklySummary _$WeeklySummaryFromJson(Map<String, dynamic> json) =>
    _WeeklySummary(
      averageMoodScore: (json['averageMoodScore'] as num).toDouble(),
      moodCounts: (json['moodCounts'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$MoodTypeEnumMap, k), (e as num).toInt()),
      ),
      endingPlantTier: $enumDecode(_$PlantTierEnumMap, json['endingPlantTier']),
      totalEntryCount: (json['totalEntryCount'] as num).toInt(),
      triggeredTierCount: (json['triggeredTierCount'] as num).toInt(),
    );

Map<String, dynamic> _$WeeklySummaryToJson(_WeeklySummary instance) =>
    <String, dynamic>{
      'averageMoodScore': instance.averageMoodScore,
      'moodCounts': instance.moodCounts.map(
        (k, e) => MapEntry(_$MoodTypeEnumMap[k]!, e),
      ),
      'endingPlantTier': _$PlantTierEnumMap[instance.endingPlantTier]!,
      'totalEntryCount': instance.totalEntryCount,
      'triggeredTierCount': instance.triggeredTierCount,
    };

const _$MoodTypeEnumMap = {
  MoodType.happy: 'happy',
  MoodType.calm: 'calm',
  MoodType.okay: 'okay',
  MoodType.sad: 'sad',
  MoodType.angry: 'angry',
  MoodType.anxious: 'anxious',
};

const _$PlantTierEnumMap = {
  PlantTier.flourishing: 'flourishing',
  PlantTier.thriving: 'thriving',
  PlantTier.resting: 'resting',
  PlantTier.weathering: 'weathering',
  PlantTier.stormSeason: 'stormSeason',
};
