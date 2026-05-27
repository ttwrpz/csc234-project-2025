// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skin_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkinState {

 GardenSkinId get equippedSkinId; Set<GardenSkinId> get unlockedSkinIds;
/// Create a copy of SkinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkinStateCopyWith<SkinState> get copyWith => _$SkinStateCopyWithImpl<SkinState>(this as SkinState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkinState&&(identical(other.equippedSkinId, equippedSkinId) || other.equippedSkinId == equippedSkinId)&&const DeepCollectionEquality().equals(other.unlockedSkinIds, unlockedSkinIds));
}


@override
int get hashCode => Object.hash(runtimeType,equippedSkinId,const DeepCollectionEquality().hash(unlockedSkinIds));

@override
String toString() {
  return 'SkinState(equippedSkinId: $equippedSkinId, unlockedSkinIds: $unlockedSkinIds)';
}


}

/// @nodoc
abstract mixin class $SkinStateCopyWith<$Res>  {
  factory $SkinStateCopyWith(SkinState value, $Res Function(SkinState) _then) = _$SkinStateCopyWithImpl;
@useResult
$Res call({
 GardenSkinId equippedSkinId, Set<GardenSkinId> unlockedSkinIds
});




}
/// @nodoc
class _$SkinStateCopyWithImpl<$Res>
    implements $SkinStateCopyWith<$Res> {
  _$SkinStateCopyWithImpl(this._self, this._then);

  final SkinState _self;
  final $Res Function(SkinState) _then;

/// Create a copy of SkinState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? equippedSkinId = null,Object? unlockedSkinIds = null,}) {
  return _then(_self.copyWith(
equippedSkinId: null == equippedSkinId ? _self.equippedSkinId : equippedSkinId // ignore: cast_nullable_to_non_nullable
as GardenSkinId,unlockedSkinIds: null == unlockedSkinIds ? _self.unlockedSkinIds : unlockedSkinIds // ignore: cast_nullable_to_non_nullable
as Set<GardenSkinId>,
  ));
}

}


/// Adds pattern-matching-related methods to [SkinState].
extension SkinStatePatterns on SkinState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkinState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkinState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkinState value)  $default,){
final _that = this;
switch (_that) {
case _SkinState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkinState value)?  $default,){
final _that = this;
switch (_that) {
case _SkinState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GardenSkinId equippedSkinId,  Set<GardenSkinId> unlockedSkinIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkinState() when $default != null:
return $default(_that.equippedSkinId,_that.unlockedSkinIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GardenSkinId equippedSkinId,  Set<GardenSkinId> unlockedSkinIds)  $default,) {final _that = this;
switch (_that) {
case _SkinState():
return $default(_that.equippedSkinId,_that.unlockedSkinIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GardenSkinId equippedSkinId,  Set<GardenSkinId> unlockedSkinIds)?  $default,) {final _that = this;
switch (_that) {
case _SkinState() when $default != null:
return $default(_that.equippedSkinId,_that.unlockedSkinIds);case _:
  return null;

}
}

}

/// @nodoc


class _SkinState extends SkinState {
  const _SkinState({required this.equippedSkinId, required final  Set<GardenSkinId> unlockedSkinIds}): _unlockedSkinIds = unlockedSkinIds,super._();
  

@override final  GardenSkinId equippedSkinId;
 final  Set<GardenSkinId> _unlockedSkinIds;
@override Set<GardenSkinId> get unlockedSkinIds {
  if (_unlockedSkinIds is EqualUnmodifiableSetView) return _unlockedSkinIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_unlockedSkinIds);
}


/// Create a copy of SkinState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkinStateCopyWith<_SkinState> get copyWith => __$SkinStateCopyWithImpl<_SkinState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkinState&&(identical(other.equippedSkinId, equippedSkinId) || other.equippedSkinId == equippedSkinId)&&const DeepCollectionEquality().equals(other._unlockedSkinIds, _unlockedSkinIds));
}


@override
int get hashCode => Object.hash(runtimeType,equippedSkinId,const DeepCollectionEquality().hash(_unlockedSkinIds));

@override
String toString() {
  return 'SkinState(equippedSkinId: $equippedSkinId, unlockedSkinIds: $unlockedSkinIds)';
}


}

/// @nodoc
abstract mixin class _$SkinStateCopyWith<$Res> implements $SkinStateCopyWith<$Res> {
  factory _$SkinStateCopyWith(_SkinState value, $Res Function(_SkinState) _then) = __$SkinStateCopyWithImpl;
@override @useResult
$Res call({
 GardenSkinId equippedSkinId, Set<GardenSkinId> unlockedSkinIds
});




}
/// @nodoc
class __$SkinStateCopyWithImpl<$Res>
    implements _$SkinStateCopyWith<$Res> {
  __$SkinStateCopyWithImpl(this._self, this._then);

  final _SkinState _self;
  final $Res Function(_SkinState) _then;

/// Create a copy of SkinState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? equippedSkinId = null,Object? unlockedSkinIds = null,}) {
  return _then(_SkinState(
equippedSkinId: null == equippedSkinId ? _self.equippedSkinId : equippedSkinId // ignore: cast_nullable_to_non_nullable
as GardenSkinId,unlockedSkinIds: null == unlockedSkinIds ? _self._unlockedSkinIds : unlockedSkinIds // ignore: cast_nullable_to_non_nullable
as Set<GardenSkinId>,
  ));
}


}

// dart format on
