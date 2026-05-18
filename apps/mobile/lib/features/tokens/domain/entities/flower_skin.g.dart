// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flower_skin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlowerSkin _$FlowerSkinFromJson(Map<String, dynamic> json) => _FlowerSkin(
  skinId: json['skinId'] as String,
  species: $enumDecode(_$FlowerSpeciesEnumMap, json['species']),
  displayName: json['displayName'] as String,
  cost: (json['cost'] as num).toInt(),
  isDefault: json['isDefault'] as bool,
  paletteSeed: (json['paletteSeed'] as num).toInt(),
  petalShape:
      $enumDecodeNullable(_$FlowerPetalShapeEnumMap, json['petalShape']) ??
      FlowerPetalShape.classic,
);

Map<String, dynamic> _$FlowerSkinToJson(_FlowerSkin instance) =>
    <String, dynamic>{
      'skinId': instance.skinId,
      'species': _$FlowerSpeciesEnumMap[instance.species]!,
      'displayName': instance.displayName,
      'cost': instance.cost,
      'isDefault': instance.isDefault,
      'paletteSeed': instance.paletteSeed,
      'petalShape': _$FlowerPetalShapeEnumMap[instance.petalShape]!,
    };

const _$FlowerSpeciesEnumMap = {
  FlowerSpecies.sunflower: 'sunflower',
  FlowerSpecies.forgetMeNot: 'forgetMeNot',
  FlowerSpecies.daisy: 'daisy',
  FlowerSpecies.poppy: 'poppy',
  FlowerSpecies.fern: 'fern',
  FlowerSpecies.lavender: 'lavender',
};

const _$FlowerPetalShapeEnumMap = {
  FlowerPetalShape.classic: 'classic',
  FlowerPetalShape.rounded: 'rounded',
  FlowerPetalShape.pointed: 'pointed',
  FlowerPetalShape.star: 'star',
  FlowerPetalShape.heart: 'heart',
};
