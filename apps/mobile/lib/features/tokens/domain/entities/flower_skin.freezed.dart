// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flower_skin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlowerSkin {

 String get skinId; FlowerSpecies get species; String get displayName; int get cost; bool get isDefault; int get paletteSeed;
/// Create a copy of FlowerSkin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlowerSkinCopyWith<FlowerSkin> get copyWith => _$FlowerSkinCopyWithImpl<FlowerSkin>(this as FlowerSkin, _$identity);

  /// Serializes this FlowerSkin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlowerSkin&&(identical(other.skinId, skinId) || other.skinId == skinId)&&(identical(other.species, species) || other.species == species)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.paletteSeed, paletteSeed) || other.paletteSeed == paletteSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skinId,species,displayName,cost,isDefault,paletteSeed);

@override
String toString() {
  return 'FlowerSkin(skinId: $skinId, species: $species, displayName: $displayName, cost: $cost, isDefault: $isDefault, paletteSeed: $paletteSeed)';
}


}

/// @nodoc
abstract mixin class $FlowerSkinCopyWith<$Res>  {
  factory $FlowerSkinCopyWith(FlowerSkin value, $Res Function(FlowerSkin) _then) = _$FlowerSkinCopyWithImpl;
@useResult
$Res call({
 String skinId, FlowerSpecies species, String displayName, int cost, bool isDefault, int paletteSeed
});




}
/// @nodoc
class _$FlowerSkinCopyWithImpl<$Res>
    implements $FlowerSkinCopyWith<$Res> {
  _$FlowerSkinCopyWithImpl(this._self, this._then);

  final FlowerSkin _self;
  final $Res Function(FlowerSkin) _then;

/// Create a copy of FlowerSkin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? skinId = null,Object? species = null,Object? displayName = null,Object? cost = null,Object? isDefault = null,Object? paletteSeed = null,}) {
  return _then(_self.copyWith(
skinId: null == skinId ? _self.skinId : skinId // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as FlowerSpecies,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,paletteSeed: null == paletteSeed ? _self.paletteSeed : paletteSeed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FlowerSkin].
extension FlowerSkinPatterns on FlowerSkin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlowerSkin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlowerSkin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlowerSkin value)  $default,){
final _that = this;
switch (_that) {
case _FlowerSkin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlowerSkin value)?  $default,){
final _that = this;
switch (_that) {
case _FlowerSkin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String skinId,  FlowerSpecies species,  String displayName,  int cost,  bool isDefault,  int paletteSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlowerSkin() when $default != null:
return $default(_that.skinId,_that.species,_that.displayName,_that.cost,_that.isDefault,_that.paletteSeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String skinId,  FlowerSpecies species,  String displayName,  int cost,  bool isDefault,  int paletteSeed)  $default,) {final _that = this;
switch (_that) {
case _FlowerSkin():
return $default(_that.skinId,_that.species,_that.displayName,_that.cost,_that.isDefault,_that.paletteSeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String skinId,  FlowerSpecies species,  String displayName,  int cost,  bool isDefault,  int paletteSeed)?  $default,) {final _that = this;
switch (_that) {
case _FlowerSkin() when $default != null:
return $default(_that.skinId,_that.species,_that.displayName,_that.cost,_that.isDefault,_that.paletteSeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FlowerSkin implements FlowerSkin {
  const _FlowerSkin({required this.skinId, required this.species, required this.displayName, required this.cost, required this.isDefault, required this.paletteSeed});
  factory _FlowerSkin.fromJson(Map<String, dynamic> json) => _$FlowerSkinFromJson(json);

@override final  String skinId;
@override final  FlowerSpecies species;
@override final  String displayName;
@override final  int cost;
@override final  bool isDefault;
@override final  int paletteSeed;

/// Create a copy of FlowerSkin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlowerSkinCopyWith<_FlowerSkin> get copyWith => __$FlowerSkinCopyWithImpl<_FlowerSkin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlowerSkinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlowerSkin&&(identical(other.skinId, skinId) || other.skinId == skinId)&&(identical(other.species, species) || other.species == species)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.paletteSeed, paletteSeed) || other.paletteSeed == paletteSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skinId,species,displayName,cost,isDefault,paletteSeed);

@override
String toString() {
  return 'FlowerSkin(skinId: $skinId, species: $species, displayName: $displayName, cost: $cost, isDefault: $isDefault, paletteSeed: $paletteSeed)';
}


}

/// @nodoc
abstract mixin class _$FlowerSkinCopyWith<$Res> implements $FlowerSkinCopyWith<$Res> {
  factory _$FlowerSkinCopyWith(_FlowerSkin value, $Res Function(_FlowerSkin) _then) = __$FlowerSkinCopyWithImpl;
@override @useResult
$Res call({
 String skinId, FlowerSpecies species, String displayName, int cost, bool isDefault, int paletteSeed
});




}
/// @nodoc
class __$FlowerSkinCopyWithImpl<$Res>
    implements _$FlowerSkinCopyWith<$Res> {
  __$FlowerSkinCopyWithImpl(this._self, this._then);

  final _FlowerSkin _self;
  final $Res Function(_FlowerSkin) _then;

/// Create a copy of FlowerSkin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? skinId = null,Object? species = null,Object? displayName = null,Object? cost = null,Object? isDefault = null,Object? paletteSeed = null,}) {
  return _then(_FlowerSkin(
skinId: null == skinId ? _self.skinId : skinId // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as FlowerSpecies,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,paletteSeed: null == paletteSeed ? _self.paletteSeed : paletteSeed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
