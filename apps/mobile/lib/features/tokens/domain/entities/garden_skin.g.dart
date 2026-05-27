// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'garden_skin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GardenSkin _$GardenSkinFromJson(Map<String, dynamic> json) => _GardenSkin(
  id: $enumDecode(_$GardenSkinIdEnumMap, json['id']),
  displayName: json['displayName'] as String,
  tagline: json['tagline'] as String,
  cost: (json['cost'] as num).toInt(),
  requiresFlourishingTier: json['requiresFlourishingTier'] as bool? ?? false,
);

Map<String, dynamic> _$GardenSkinToJson(_GardenSkin instance) =>
    <String, dynamic>{
      'id': _$GardenSkinIdEnumMap[instance.id]!,
      'displayName': instance.displayName,
      'tagline': instance.tagline,
      'cost': instance.cost,
      'requiresFlourishingTier': instance.requiresFlourishingTier,
    };

const _$GardenSkinIdEnumMap = {
  GardenSkinId.meadow: 'meadow',
  GardenSkinId.origami: 'origami',
  GardenSkinId.lantern: 'lantern',
  GardenSkinId.constellation: 'constellation',
  GardenSkinId.crystal: 'crystal',
};
