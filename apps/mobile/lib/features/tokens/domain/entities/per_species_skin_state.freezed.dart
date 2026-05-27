// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'per_species_skin_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PerSpeciesSkinState {

 Map<FlowerSpecies, Set<String>> get unlocked; Map<FlowerSpecies, String> get equipped;
/// Create a copy of PerSpeciesSkinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerSpeciesSkinStateCopyWith<PerSpeciesSkinState> get copyWith => _$PerSpeciesSkinStateCopyWithImpl<PerSpeciesSkinState>(this as PerSpeciesSkinState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerSpeciesSkinState&&const DeepCollectionEquality().equals(other.unlocked, unlocked)&&const DeepCollectionEquality().equals(other.equipped, equipped));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(unlocked),const DeepCollectionEquality().hash(equipped));

@override
String toString() {
  return 'PerSpeciesSkinState(unlocked: $unlocked, equipped: $equipped)';
}


}

/// @nodoc
abstract mixin class $PerSpeciesSkinStateCopyWith<$Res>  {
  factory $PerSpeciesSkinStateCopyWith(PerSpeciesSkinState value, $Res Function(PerSpeciesSkinState) _then) = _$PerSpeciesSkinStateCopyWithImpl;
@useResult
$Res call({
 Map<FlowerSpecies, Set<String>> unlocked, Map<FlowerSpecies, String> equipped
});




}
/// @nodoc
class _$PerSpeciesSkinStateCopyWithImpl<$Res>
    implements $PerSpeciesSkinStateCopyWith<$Res> {
  _$PerSpeciesSkinStateCopyWithImpl(this._self, this._then);

  final PerSpeciesSkinState _self;
  final $Res Function(PerSpeciesSkinState) _then;

/// Create a copy of PerSpeciesSkinState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unlocked = null,Object? equipped = null,}) {
  return _then(_self.copyWith(
unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, Set<String>>,equipped: null == equipped ? _self.equipped : equipped // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PerSpeciesSkinState].
extension PerSpeciesSkinStatePatterns on PerSpeciesSkinState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerSpeciesSkinState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerSpeciesSkinState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerSpeciesSkinState value)  $default,){
final _that = this;
switch (_that) {
case _PerSpeciesSkinState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerSpeciesSkinState value)?  $default,){
final _that = this;
switch (_that) {
case _PerSpeciesSkinState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<FlowerSpecies, Set<String>> unlocked,  Map<FlowerSpecies, String> equipped)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerSpeciesSkinState() when $default != null:
return $default(_that.unlocked,_that.equipped);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<FlowerSpecies, Set<String>> unlocked,  Map<FlowerSpecies, String> equipped)  $default,) {final _that = this;
switch (_that) {
case _PerSpeciesSkinState():
return $default(_that.unlocked,_that.equipped);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<FlowerSpecies, Set<String>> unlocked,  Map<FlowerSpecies, String> equipped)?  $default,) {final _that = this;
switch (_that) {
case _PerSpeciesSkinState() when $default != null:
return $default(_that.unlocked,_that.equipped);case _:
  return null;

}
}

}

/// @nodoc


class _PerSpeciesSkinState extends PerSpeciesSkinState {
  const _PerSpeciesSkinState({required final  Map<FlowerSpecies, Set<String>> unlocked, required final  Map<FlowerSpecies, String> equipped}): _unlocked = unlocked,_equipped = equipped,super._();
  

 final  Map<FlowerSpecies, Set<String>> _unlocked;
@override Map<FlowerSpecies, Set<String>> get unlocked {
  if (_unlocked is EqualUnmodifiableMapView) return _unlocked;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_unlocked);
}

 final  Map<FlowerSpecies, String> _equipped;
@override Map<FlowerSpecies, String> get equipped {
  if (_equipped is EqualUnmodifiableMapView) return _equipped;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_equipped);
}


/// Create a copy of PerSpeciesSkinState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerSpeciesSkinStateCopyWith<_PerSpeciesSkinState> get copyWith => __$PerSpeciesSkinStateCopyWithImpl<_PerSpeciesSkinState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerSpeciesSkinState&&const DeepCollectionEquality().equals(other._unlocked, _unlocked)&&const DeepCollectionEquality().equals(other._equipped, _equipped));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_unlocked),const DeepCollectionEquality().hash(_equipped));

@override
String toString() {
  return 'PerSpeciesSkinState(unlocked: $unlocked, equipped: $equipped)';
}


}

/// @nodoc
abstract mixin class _$PerSpeciesSkinStateCopyWith<$Res> implements $PerSpeciesSkinStateCopyWith<$Res> {
  factory _$PerSpeciesSkinStateCopyWith(_PerSpeciesSkinState value, $Res Function(_PerSpeciesSkinState) _then) = __$PerSpeciesSkinStateCopyWithImpl;
@override @useResult
$Res call({
 Map<FlowerSpecies, Set<String>> unlocked, Map<FlowerSpecies, String> equipped
});




}
/// @nodoc
class __$PerSpeciesSkinStateCopyWithImpl<$Res>
    implements _$PerSpeciesSkinStateCopyWith<$Res> {
  __$PerSpeciesSkinStateCopyWithImpl(this._self, this._then);

  final _PerSpeciesSkinState _self;
  final $Res Function(_PerSpeciesSkinState) _then;

/// Create a copy of PerSpeciesSkinState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unlocked = null,Object? equipped = null,}) {
  return _then(_PerSpeciesSkinState(
unlocked: null == unlocked ? _self._unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, Set<String>>,equipped: null == equipped ? _self._equipped : equipped // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, String>,
  ));
}


}

// dart format on
