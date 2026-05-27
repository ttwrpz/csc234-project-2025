// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'per_species_skin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PerSpeciesSkin {

/// Stable slug, unique across all species. Format `<species>_<name>`,
/// e.g. `sunflower_crystal`. Persisted verbatim to Firestore.
 String get id; FlowerSpecies get species; String get displayName; String get tagline; int get cost;/// Shape language this skin paints the species in - one of the five
/// `MbSkinPlant` styles. `meadow` is the classic silhouette.
 GardenSkinId get style;/// Petal/bud accent colour as a 32-bit ARGB int (e.g. `0xFFF2A93B`).
/// The garden painter applies this in place of the species' built-in
/// petal colour when this skin is equipped.
 int get accentArgb;
/// Create a copy of PerSpeciesSkin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerSpeciesSkinCopyWith<PerSpeciesSkin> get copyWith => _$PerSpeciesSkinCopyWithImpl<PerSpeciesSkin>(this as PerSpeciesSkin, _$identity);

  /// Serializes this PerSpeciesSkin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerSpeciesSkin&&(identical(other.id, id) || other.id == id)&&(identical(other.species, species) || other.species == species)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.style, style) || other.style == style)&&(identical(other.accentArgb, accentArgb) || other.accentArgb == accentArgb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,species,displayName,tagline,cost,style,accentArgb);

@override
String toString() {
  return 'PerSpeciesSkin(id: $id, species: $species, displayName: $displayName, tagline: $tagline, cost: $cost, style: $style, accentArgb: $accentArgb)';
}


}

/// @nodoc
abstract mixin class $PerSpeciesSkinCopyWith<$Res>  {
  factory $PerSpeciesSkinCopyWith(PerSpeciesSkin value, $Res Function(PerSpeciesSkin) _then) = _$PerSpeciesSkinCopyWithImpl;
@useResult
$Res call({
 String id, FlowerSpecies species, String displayName, String tagline, int cost, GardenSkinId style, int accentArgb
});




}
/// @nodoc
class _$PerSpeciesSkinCopyWithImpl<$Res>
    implements $PerSpeciesSkinCopyWith<$Res> {
  _$PerSpeciesSkinCopyWithImpl(this._self, this._then);

  final PerSpeciesSkin _self;
  final $Res Function(PerSpeciesSkin) _then;

/// Create a copy of PerSpeciesSkin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? species = null,Object? displayName = null,Object? tagline = null,Object? cost = null,Object? style = null,Object? accentArgb = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as FlowerSpecies,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as GardenSkinId,accentArgb: null == accentArgb ? _self.accentArgb : accentArgb // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PerSpeciesSkin].
extension PerSpeciesSkinPatterns on PerSpeciesSkin {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerSpeciesSkin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerSpeciesSkin() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerSpeciesSkin value)  $default,){
final _that = this;
switch (_that) {
case _PerSpeciesSkin():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerSpeciesSkin value)?  $default,){
final _that = this;
switch (_that) {
case _PerSpeciesSkin() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  FlowerSpecies species,  String displayName,  String tagline,  int cost,  GardenSkinId style,  int accentArgb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerSpeciesSkin() when $default != null:
return $default(_that.id,_that.species,_that.displayName,_that.tagline,_that.cost,_that.style,_that.accentArgb);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  FlowerSpecies species,  String displayName,  String tagline,  int cost,  GardenSkinId style,  int accentArgb)  $default,) {final _that = this;
switch (_that) {
case _PerSpeciesSkin():
return $default(_that.id,_that.species,_that.displayName,_that.tagline,_that.cost,_that.style,_that.accentArgb);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  FlowerSpecies species,  String displayName,  String tagline,  int cost,  GardenSkinId style,  int accentArgb)?  $default,) {final _that = this;
switch (_that) {
case _PerSpeciesSkin() when $default != null:
return $default(_that.id,_that.species,_that.displayName,_that.tagline,_that.cost,_that.style,_that.accentArgb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerSpeciesSkin implements PerSpeciesSkin {
  const _PerSpeciesSkin({required this.id, required this.species, required this.displayName, required this.tagline, required this.cost, required this.style, required this.accentArgb});
  factory _PerSpeciesSkin.fromJson(Map<String, dynamic> json) => _$PerSpeciesSkinFromJson(json);

/// Stable slug, unique across all species. Format `<species>_<name>`,
/// e.g. `sunflower_crystal`. Persisted verbatim to Firestore.
@override final  String id;
@override final  FlowerSpecies species;
@override final  String displayName;
@override final  String tagline;
@override final  int cost;
/// Shape language this skin paints the species in - one of the five
/// `MbSkinPlant` styles. `meadow` is the classic silhouette.
@override final  GardenSkinId style;
/// Petal/bud accent colour as a 32-bit ARGB int (e.g. `0xFFF2A93B`).
/// The garden painter applies this in place of the species' built-in
/// petal colour when this skin is equipped.
@override final  int accentArgb;

/// Create a copy of PerSpeciesSkin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerSpeciesSkinCopyWith<_PerSpeciesSkin> get copyWith => __$PerSpeciesSkinCopyWithImpl<_PerSpeciesSkin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerSpeciesSkinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerSpeciesSkin&&(identical(other.id, id) || other.id == id)&&(identical(other.species, species) || other.species == species)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.style, style) || other.style == style)&&(identical(other.accentArgb, accentArgb) || other.accentArgb == accentArgb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,species,displayName,tagline,cost,style,accentArgb);

@override
String toString() {
  return 'PerSpeciesSkin(id: $id, species: $species, displayName: $displayName, tagline: $tagline, cost: $cost, style: $style, accentArgb: $accentArgb)';
}


}

/// @nodoc
abstract mixin class _$PerSpeciesSkinCopyWith<$Res> implements $PerSpeciesSkinCopyWith<$Res> {
  factory _$PerSpeciesSkinCopyWith(_PerSpeciesSkin value, $Res Function(_PerSpeciesSkin) _then) = __$PerSpeciesSkinCopyWithImpl;
@override @useResult
$Res call({
 String id, FlowerSpecies species, String displayName, String tagline, int cost, GardenSkinId style, int accentArgb
});




}
/// @nodoc
class __$PerSpeciesSkinCopyWithImpl<$Res>
    implements _$PerSpeciesSkinCopyWith<$Res> {
  __$PerSpeciesSkinCopyWithImpl(this._self, this._then);

  final _PerSpeciesSkin _self;
  final $Res Function(_PerSpeciesSkin) _then;

/// Create a copy of PerSpeciesSkin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? species = null,Object? displayName = null,Object? tagline = null,Object? cost = null,Object? style = null,Object? accentArgb = null,}) {
  return _then(_PerSpeciesSkin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as FlowerSpecies,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as GardenSkinId,accentArgb: null == accentArgb ? _self.accentArgb : accentArgb // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
