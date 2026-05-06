// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cheer_up_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CheerUpUiState {

 bool get bannerDismissed; bool get onShownDispatched;
/// Create a copy of CheerUpUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheerUpUiStateCopyWith<CheerUpUiState> get copyWith => _$CheerUpUiStateCopyWithImpl<CheerUpUiState>(this as CheerUpUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheerUpUiState&&(identical(other.bannerDismissed, bannerDismissed) || other.bannerDismissed == bannerDismissed)&&(identical(other.onShownDispatched, onShownDispatched) || other.onShownDispatched == onShownDispatched));
}


@override
int get hashCode => Object.hash(runtimeType,bannerDismissed,onShownDispatched);

@override
String toString() {
  return 'CheerUpUiState(bannerDismissed: $bannerDismissed, onShownDispatched: $onShownDispatched)';
}


}

/// @nodoc
abstract mixin class $CheerUpUiStateCopyWith<$Res>  {
  factory $CheerUpUiStateCopyWith(CheerUpUiState value, $Res Function(CheerUpUiState) _then) = _$CheerUpUiStateCopyWithImpl;
@useResult
$Res call({
 bool bannerDismissed, bool onShownDispatched
});




}
/// @nodoc
class _$CheerUpUiStateCopyWithImpl<$Res>
    implements $CheerUpUiStateCopyWith<$Res> {
  _$CheerUpUiStateCopyWithImpl(this._self, this._then);

  final CheerUpUiState _self;
  final $Res Function(CheerUpUiState) _then;

/// Create a copy of CheerUpUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bannerDismissed = null,Object? onShownDispatched = null,}) {
  return _then(_self.copyWith(
bannerDismissed: null == bannerDismissed ? _self.bannerDismissed : bannerDismissed // ignore: cast_nullable_to_non_nullable
as bool,onShownDispatched: null == onShownDispatched ? _self.onShownDispatched : onShownDispatched // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CheerUpUiState].
extension CheerUpUiStatePatterns on CheerUpUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheerUpUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheerUpUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheerUpUiState value)  $default,){
final _that = this;
switch (_that) {
case _CheerUpUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheerUpUiState value)?  $default,){
final _that = this;
switch (_that) {
case _CheerUpUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool bannerDismissed,  bool onShownDispatched)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheerUpUiState() when $default != null:
return $default(_that.bannerDismissed,_that.onShownDispatched);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool bannerDismissed,  bool onShownDispatched)  $default,) {final _that = this;
switch (_that) {
case _CheerUpUiState():
return $default(_that.bannerDismissed,_that.onShownDispatched);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool bannerDismissed,  bool onShownDispatched)?  $default,) {final _that = this;
switch (_that) {
case _CheerUpUiState() when $default != null:
return $default(_that.bannerDismissed,_that.onShownDispatched);case _:
  return null;

}
}

}

/// @nodoc


class _CheerUpUiState implements CheerUpUiState {
  const _CheerUpUiState({required this.bannerDismissed, required this.onShownDispatched});
  

@override final  bool bannerDismissed;
@override final  bool onShownDispatched;

/// Create a copy of CheerUpUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheerUpUiStateCopyWith<_CheerUpUiState> get copyWith => __$CheerUpUiStateCopyWithImpl<_CheerUpUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheerUpUiState&&(identical(other.bannerDismissed, bannerDismissed) || other.bannerDismissed == bannerDismissed)&&(identical(other.onShownDispatched, onShownDispatched) || other.onShownDispatched == onShownDispatched));
}


@override
int get hashCode => Object.hash(runtimeType,bannerDismissed,onShownDispatched);

@override
String toString() {
  return 'CheerUpUiState(bannerDismissed: $bannerDismissed, onShownDispatched: $onShownDispatched)';
}


}

/// @nodoc
abstract mixin class _$CheerUpUiStateCopyWith<$Res> implements $CheerUpUiStateCopyWith<$Res> {
  factory _$CheerUpUiStateCopyWith(_CheerUpUiState value, $Res Function(_CheerUpUiState) _then) = __$CheerUpUiStateCopyWithImpl;
@override @useResult
$Res call({
 bool bannerDismissed, bool onShownDispatched
});




}
/// @nodoc
class __$CheerUpUiStateCopyWithImpl<$Res>
    implements _$CheerUpUiStateCopyWith<$Res> {
  __$CheerUpUiStateCopyWithImpl(this._self, this._then);

  final _CheerUpUiState _self;
  final $Res Function(_CheerUpUiState) _then;

/// Create a copy of CheerUpUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bannerDismissed = null,Object? onShownDispatched = null,}) {
  return _then(_CheerUpUiState(
bannerDismissed: null == bannerDismissed ? _self.bannerDismissed : bannerDismissed // ignore: cast_nullable_to_non_nullable
as bool,onShownDispatched: null == onShownDispatched ? _self.onShownDispatched : onShownDispatched // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
