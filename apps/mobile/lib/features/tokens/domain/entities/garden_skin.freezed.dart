// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garden_skin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GardenSkin {

 GardenSkinId get id; String get displayName; String get tagline; int get cost; bool get requiresFlourishingTier;
/// Create a copy of GardenSkin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GardenSkinCopyWith<GardenSkin> get copyWith => _$GardenSkinCopyWithImpl<GardenSkin>(this as GardenSkin, _$identity);

  /// Serializes this GardenSkin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GardenSkin&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.requiresFlourishingTier, requiresFlourishingTier) || other.requiresFlourishingTier == requiresFlourishingTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,tagline,cost,requiresFlourishingTier);

@override
String toString() {
  return 'GardenSkin(id: $id, displayName: $displayName, tagline: $tagline, cost: $cost, requiresFlourishingTier: $requiresFlourishingTier)';
}


}

/// @nodoc
abstract mixin class $GardenSkinCopyWith<$Res>  {
  factory $GardenSkinCopyWith(GardenSkin value, $Res Function(GardenSkin) _then) = _$GardenSkinCopyWithImpl;
@useResult
$Res call({
 GardenSkinId id, String displayName, String tagline, int cost, bool requiresFlourishingTier
});




}
/// @nodoc
class _$GardenSkinCopyWithImpl<$Res>
    implements $GardenSkinCopyWith<$Res> {
  _$GardenSkinCopyWithImpl(this._self, this._then);

  final GardenSkin _self;
  final $Res Function(GardenSkin) _then;

/// Create a copy of GardenSkin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? tagline = null,Object? cost = null,Object? requiresFlourishingTier = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GardenSkinId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,requiresFlourishingTier: null == requiresFlourishingTier ? _self.requiresFlourishingTier : requiresFlourishingTier // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GardenSkin].
extension GardenSkinPatterns on GardenSkin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GardenSkin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GardenSkin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GardenSkin value)  $default,){
final _that = this;
switch (_that) {
case _GardenSkin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GardenSkin value)?  $default,){
final _that = this;
switch (_that) {
case _GardenSkin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GardenSkinId id,  String displayName,  String tagline,  int cost,  bool requiresFlourishingTier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GardenSkin() when $default != null:
return $default(_that.id,_that.displayName,_that.tagline,_that.cost,_that.requiresFlourishingTier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GardenSkinId id,  String displayName,  String tagline,  int cost,  bool requiresFlourishingTier)  $default,) {final _that = this;
switch (_that) {
case _GardenSkin():
return $default(_that.id,_that.displayName,_that.tagline,_that.cost,_that.requiresFlourishingTier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GardenSkinId id,  String displayName,  String tagline,  int cost,  bool requiresFlourishingTier)?  $default,) {final _that = this;
switch (_that) {
case _GardenSkin() when $default != null:
return $default(_that.id,_that.displayName,_that.tagline,_that.cost,_that.requiresFlourishingTier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GardenSkin implements GardenSkin {
  const _GardenSkin({required this.id, required this.displayName, required this.tagline, required this.cost, this.requiresFlourishingTier = false});
  factory _GardenSkin.fromJson(Map<String, dynamic> json) => _$GardenSkinFromJson(json);

@override final  GardenSkinId id;
@override final  String displayName;
@override final  String tagline;
@override final  int cost;
@override@JsonKey() final  bool requiresFlourishingTier;

/// Create a copy of GardenSkin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GardenSkinCopyWith<_GardenSkin> get copyWith => __$GardenSkinCopyWithImpl<_GardenSkin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GardenSkinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GardenSkin&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.requiresFlourishingTier, requiresFlourishingTier) || other.requiresFlourishingTier == requiresFlourishingTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,tagline,cost,requiresFlourishingTier);

@override
String toString() {
  return 'GardenSkin(id: $id, displayName: $displayName, tagline: $tagline, cost: $cost, requiresFlourishingTier: $requiresFlourishingTier)';
}


}

/// @nodoc
abstract mixin class _$GardenSkinCopyWith<$Res> implements $GardenSkinCopyWith<$Res> {
  factory _$GardenSkinCopyWith(_GardenSkin value, $Res Function(_GardenSkin) _then) = __$GardenSkinCopyWithImpl;
@override @useResult
$Res call({
 GardenSkinId id, String displayName, String tagline, int cost, bool requiresFlourishingTier
});




}
/// @nodoc
class __$GardenSkinCopyWithImpl<$Res>
    implements _$GardenSkinCopyWith<$Res> {
  __$GardenSkinCopyWithImpl(this._self, this._then);

  final _GardenSkin _self;
  final $Res Function(_GardenSkin) _then;

/// Create a copy of GardenSkin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? tagline = null,Object? cost = null,Object? requiresFlourishingTier = null,}) {
  return _then(_GardenSkin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GardenSkinId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,requiresFlourishingTier: null == requiresFlourishingTier ? _self.requiresFlourishingTier : requiresFlourishingTier // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
