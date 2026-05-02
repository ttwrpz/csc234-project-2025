// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intervention_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InterventionState {

 bool get triggered; bool get escalated; String get reason;
/// Create a copy of InterventionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterventionStateCopyWith<InterventionState> get copyWith => _$InterventionStateCopyWithImpl<InterventionState>(this as InterventionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterventionState&&(identical(other.triggered, triggered) || other.triggered == triggered)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,triggered,escalated,reason);

@override
String toString() {
  return 'InterventionState(triggered: $triggered, escalated: $escalated, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $InterventionStateCopyWith<$Res>  {
  factory $InterventionStateCopyWith(InterventionState value, $Res Function(InterventionState) _then) = _$InterventionStateCopyWithImpl;
@useResult
$Res call({
 bool triggered, bool escalated, String reason
});




}
/// @nodoc
class _$InterventionStateCopyWithImpl<$Res>
    implements $InterventionStateCopyWith<$Res> {
  _$InterventionStateCopyWithImpl(this._self, this._then);

  final InterventionState _self;
  final $Res Function(InterventionState) _then;

/// Create a copy of InterventionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? triggered = null,Object? escalated = null,Object? reason = null,}) {
  return _then(_self.copyWith(
triggered: null == triggered ? _self.triggered : triggered // ignore: cast_nullable_to_non_nullable
as bool,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InterventionState].
extension InterventionStatePatterns on InterventionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InterventionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InterventionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InterventionState value)  $default,){
final _that = this;
switch (_that) {
case _InterventionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InterventionState value)?  $default,){
final _that = this;
switch (_that) {
case _InterventionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool triggered,  bool escalated,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InterventionState() when $default != null:
return $default(_that.triggered,_that.escalated,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool triggered,  bool escalated,  String reason)  $default,) {final _that = this;
switch (_that) {
case _InterventionState():
return $default(_that.triggered,_that.escalated,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool triggered,  bool escalated,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _InterventionState() when $default != null:
return $default(_that.triggered,_that.escalated,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _InterventionState implements InterventionState {
  const _InterventionState({required this.triggered, required this.escalated, required this.reason});
  

@override final  bool triggered;
@override final  bool escalated;
@override final  String reason;

/// Create a copy of InterventionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterventionStateCopyWith<_InterventionState> get copyWith => __$InterventionStateCopyWithImpl<_InterventionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InterventionState&&(identical(other.triggered, triggered) || other.triggered == triggered)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,triggered,escalated,reason);

@override
String toString() {
  return 'InterventionState(triggered: $triggered, escalated: $escalated, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$InterventionStateCopyWith<$Res> implements $InterventionStateCopyWith<$Res> {
  factory _$InterventionStateCopyWith(_InterventionState value, $Res Function(_InterventionState) _then) = __$InterventionStateCopyWithImpl;
@override @useResult
$Res call({
 bool triggered, bool escalated, String reason
});




}
/// @nodoc
class __$InterventionStateCopyWithImpl<$Res>
    implements _$InterventionStateCopyWith<$Res> {
  __$InterventionStateCopyWithImpl(this._self, this._then);

  final _InterventionState _self;
  final $Res Function(_InterventionState) _then;

/// Create a copy of InterventionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? triggered = null,Object? escalated = null,Object? reason = null,}) {
  return _then(_InterventionState(
triggered: null == triggered ? _self.triggered : triggered // ignore: cast_nullable_to_non_nullable
as bool,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
