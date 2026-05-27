// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'per_species_skin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PerSpeciesSkin _$PerSpeciesSkinFromJson(Map<String, dynamic> json) =>
    _PerSpeciesSkin(
      id: json['id'] as String,
      species: $enumDecode(_$FlowerSpeciesEnumMap, json['species']),
      displayName: json['displayName'] as String,
      tagline: json['tagline'] as String,
      cost: (json['cost'] as num).toInt(),
      accentArgb: (json['accentArgb'] as num).toInt(),
    );

Map<String, dynamic> _$PerSpeciesSkinToJson(_PerSpeciesSkin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'species': _$FlowerSpeciesEnumMap[instance.species]!,
      'displayName': instance.displayName,
      'tagline': instance.tagline,
      'cost': instance.cost,
      'accentArgb': instance.accentArgb,
    };

const _$FlowerSpeciesEnumMap = {
  FlowerSpecies.sunflower: 'sunflower',
  FlowerSpecies.forgetMeNot: 'forgetMeNot',
  FlowerSpecies.daisy: 'daisy',
  FlowerSpecies.poppy: 'poppy',
  FlowerSpecies.fern: 'fern',
  FlowerSpecies.lavender: 'lavender',
};
