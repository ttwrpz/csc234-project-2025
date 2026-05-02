// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MoodEntry _$MoodEntryFromJson(Map<String, dynamic> json) => _MoodEntry(
  id: json['id'] as String,
  userId: json['userId'] as String,
  mood: $enumDecode(_$MoodTypeEnumMap, json['mood']),
  intensity: (json['intensity'] as num).toInt(),
  text: json['text'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  mediaRefs:
      (json['mediaRefs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$MoodEntryToJson(_MoodEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'mood': _$MoodTypeEnumMap[instance.mood]!,
      'intensity': instance.intensity,
      'text': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'mediaRefs': instance.mediaRefs,
    };

const _$MoodTypeEnumMap = {
  MoodType.happy: 'happy',
  MoodType.calm: 'calm',
  MoodType.okay: 'okay',
  MoodType.sad: 'sad',
  MoodType.angry: 'angry',
  MoodType.anxious: 'anxious',
};
