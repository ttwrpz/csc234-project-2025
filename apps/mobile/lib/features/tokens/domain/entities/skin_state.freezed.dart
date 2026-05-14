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

 Map<FlowerSpecies, Set<String>> get unlockedBySpecies; Map<FlowerSpecies, String> get selectedBySpecies;
/// Create a copy of SkinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkinStateCopyWith<SkinState> get copyWith => _$SkinStateCopyWithImpl<SkinState>(this as SkinState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkinState&&const DeepCollectionEquality().equals(other.unlockedBySpecies, unlockedBySpecies)&&const DeepCollectionEquality().equals(other.selectedBySpecies, selectedBySpecies));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(unlockedBySpecies),const DeepCollectionEquality().hash(selectedBySpecies));

@override
String toString() {
  return 'SkinState(unlockedBySpecies: $unlockedBySpecies, selectedBySpecies: $selectedBySpecies)';
}


}

/// @nodoc
abstract mixin class $SkinStateCopyWith<$Res>  {
  factory $SkinStateCopyWith(SkinState value, $Res Function(SkinState) _then) = _$SkinStateCopyWithImpl;
@useResult
$Res call({
 Map<FlowerSpecies, Set<String>> unlockedBySpecies, Map<FlowerSpecies, String> selectedBySpecies
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
@pragma('vm:prefer-inline') @override $Res call({Object? unlockedBySpecies = null,Object? selectedBySpecies = null,}) {
  return _then(_self.copyWith(
unlockedBySpecies: null == unlockedBySpecies ? _self.unlockedBySpecies : unlockedBySpecies // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, Set<String>>,selectedBySpecies: null == selectedBySpecies ? _self.selectedBySpecies : selectedBySpecies // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<FlowerSpecies, Set<String>> unlockedBySpecies,  Map<FlowerSpecies, String> selectedBySpecies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkinState() when $default != null:
return $default(_that.unlockedBySpecies,_that.selectedBySpecies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<FlowerSpecies, Set<String>> unlockedBySpecies,  Map<FlowerSpecies, String> selectedBySpecies)  $default,) {final _that = this;
switch (_that) {
case _SkinState():
return $default(_that.unlockedBySpecies,_that.selectedBySpecies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<FlowerSpecies, Set<String>> unlockedBySpecies,  Map<FlowerSpecies, String> selectedBySpecies)?  $default,) {final _that = this;
switch (_that) {
case _SkinState() when $default != null:
return $default(_that.unlockedBySpecies,_that.selectedBySpecies);case _:
  return null;

}
}

}

/// @nodoc


class _SkinState extends SkinState {
  const _SkinState({required final  Map<FlowerSpecies, Set<String>> unlockedBySpecies, required final  Map<FlowerSpecies, String> selectedBySpecies}): _unlockedBySpecies = unlockedBySpecies,_selectedBySpecies = selectedBySpecies,super._();
  

 final  Map<FlowerSpecies, Set<String>> _unlockedBySpecies;
@override Map<FlowerSpecies, Set<String>> get unlockedBySpecies {
  if (_unlockedBySpecies is EqualUnmodifiableMapView) return _unlockedBySpecies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_unlockedBySpecies);
}

 final  Map<FlowerSpecies, String> _selectedBySpecies;
@override Map<FlowerSpecies, String> get selectedBySpecies {
  if (_selectedBySpecies is EqualUnmodifiableMapView) return _selectedBySpecies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selectedBySpecies);
}


/// Create a copy of SkinState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkinStateCopyWith<_SkinState> get copyWith => __$SkinStateCopyWithImpl<_SkinState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkinState&&const DeepCollectionEquality().equals(other._unlockedBySpecies, _unlockedBySpecies)&&const DeepCollectionEquality().equals(other._selectedBySpecies, _selectedBySpecies));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_unlockedBySpecies),const DeepCollectionEquality().hash(_selectedBySpecies));

@override
String toString() {
  return 'SkinState(unlockedBySpecies: $unlockedBySpecies, selectedBySpecies: $selectedBySpecies)';
}


}

/// @nodoc
abstract mixin class _$SkinStateCopyWith<$Res> implements $SkinStateCopyWith<$Res> {
  factory _$SkinStateCopyWith(_SkinState value, $Res Function(_SkinState) _then) = __$SkinStateCopyWithImpl;
@override @useResult
$Res call({
 Map<FlowerSpecies, Set<String>> unlockedBySpecies, Map<FlowerSpecies, String> selectedBySpecies
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
@override @pragma('vm:prefer-inline') $Res call({Object? unlockedBySpecies = null,Object? selectedBySpecies = null,}) {
  return _then(_SkinState(
unlockedBySpecies: null == unlockedBySpecies ? _self._unlockedBySpecies : unlockedBySpecies // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, Set<String>>,selectedBySpecies: null == selectedBySpecies ? _self._selectedBySpecies : selectedBySpecies // ignore: cast_nullable_to_non_nullable
as Map<FlowerSpecies, String>,
  ));
}


}

// dart format on
