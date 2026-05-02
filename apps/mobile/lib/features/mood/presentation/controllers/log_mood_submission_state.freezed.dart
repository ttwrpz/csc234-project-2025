// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_mood_submission_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LogMoodSubmissionState {

 bool get isSubmitting; String? get errorMessage;
/// Create a copy of LogMoodSubmissionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogMoodSubmissionStateCopyWith<LogMoodSubmissionState> get copyWith => _$LogMoodSubmissionStateCopyWithImpl<LogMoodSubmissionState>(this as LogMoodSubmissionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogMoodSubmissionState&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isSubmitting,errorMessage);

@override
String toString() {
  return 'LogMoodSubmissionState(isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $LogMoodSubmissionStateCopyWith<$Res>  {
  factory $LogMoodSubmissionStateCopyWith(LogMoodSubmissionState value, $Res Function(LogMoodSubmissionState) _then) = _$LogMoodSubmissionStateCopyWithImpl;
@useResult
$Res call({
 bool isSubmitting, String? errorMessage
});




}
/// @nodoc
class _$LogMoodSubmissionStateCopyWithImpl<$Res>
    implements $LogMoodSubmissionStateCopyWith<$Res> {
  _$LogMoodSubmissionStateCopyWithImpl(this._self, this._then);

  final LogMoodSubmissionState _self;
  final $Res Function(LogMoodSubmissionState) _then;

/// Create a copy of LogMoodSubmissionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSubmitting = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LogMoodSubmissionState].
extension LogMoodSubmissionStatePatterns on LogMoodSubmissionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogMoodSubmissionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogMoodSubmissionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogMoodSubmissionState value)  $default,){
final _that = this;
switch (_that) {
case _LogMoodSubmissionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogMoodSubmissionState value)?  $default,){
final _that = this;
switch (_that) {
case _LogMoodSubmissionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSubmitting,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogMoodSubmissionState() when $default != null:
return $default(_that.isSubmitting,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSubmitting,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _LogMoodSubmissionState():
return $default(_that.isSubmitting,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSubmitting,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _LogMoodSubmissionState() when $default != null:
return $default(_that.isSubmitting,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _LogMoodSubmissionState implements LogMoodSubmissionState {
  const _LogMoodSubmissionState({this.isSubmitting = false, this.errorMessage});
  

@override@JsonKey() final  bool isSubmitting;
@override final  String? errorMessage;

/// Create a copy of LogMoodSubmissionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogMoodSubmissionStateCopyWith<_LogMoodSubmissionState> get copyWith => __$LogMoodSubmissionStateCopyWithImpl<_LogMoodSubmissionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogMoodSubmissionState&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isSubmitting,errorMessage);

@override
String toString() {
  return 'LogMoodSubmissionState(isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$LogMoodSubmissionStateCopyWith<$Res> implements $LogMoodSubmissionStateCopyWith<$Res> {
  factory _$LogMoodSubmissionStateCopyWith(_LogMoodSubmissionState value, $Res Function(_LogMoodSubmissionState) _then) = __$LogMoodSubmissionStateCopyWithImpl;
@override @useResult
$Res call({
 bool isSubmitting, String? errorMessage
});




}
/// @nodoc
class __$LogMoodSubmissionStateCopyWithImpl<$Res>
    implements _$LogMoodSubmissionStateCopyWith<$Res> {
  __$LogMoodSubmissionStateCopyWithImpl(this._self, this._then);

  final _LogMoodSubmissionState _self;
  final $Res Function(_LogMoodSubmissionState) _then;

/// Create a copy of LogMoodSubmissionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSubmitting = null,Object? errorMessage = freezed,}) {
  return _then(_LogMoodSubmissionState(
isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
