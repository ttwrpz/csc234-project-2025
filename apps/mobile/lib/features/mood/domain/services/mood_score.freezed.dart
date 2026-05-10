// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MoodScore {

 double get value; int get sign; int get intensity;
/// Create a copy of MoodScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodScoreCopyWith<MoodScore> get copyWith => _$MoodScoreCopyWithImpl<MoodScore>(this as MoodScore, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodScore&&(identical(other.value, value) || other.value == value)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}


@override
int get hashCode => Object.hash(runtimeType,value,sign,intensity);

@override
String toString() {
  return 'MoodScore(value: $value, sign: $sign, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $MoodScoreCopyWith<$Res>  {
  factory $MoodScoreCopyWith(MoodScore value, $Res Function(MoodScore) _then) = _$MoodScoreCopyWithImpl;
@useResult
$Res call({
 double value, int sign, int intensity
});




}
/// @nodoc
class _$MoodScoreCopyWithImpl<$Res>
    implements $MoodScoreCopyWith<$Res> {
  _$MoodScoreCopyWithImpl(this._self, this._then);

  final MoodScore _self;
  final $Res Function(MoodScore) _then;

/// Create a copy of MoodScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? sign = null,Object? intensity = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as int,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MoodScore].
extension MoodScorePatterns on MoodScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoodScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoodScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoodScore value)  $default,){
final _that = this;
switch (_that) {
case _MoodScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoodScore value)?  $default,){
final _that = this;
switch (_that) {
case _MoodScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double value,  int sign,  int intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoodScore() when $default != null:
return $default(_that.value,_that.sign,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double value,  int sign,  int intensity)  $default,) {final _that = this;
switch (_that) {
case _MoodScore():
return $default(_that.value,_that.sign,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double value,  int sign,  int intensity)?  $default,) {final _that = this;
switch (_that) {
case _MoodScore() when $default != null:
return $default(_that.value,_that.sign,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc


class _MoodScore implements MoodScore {
  const _MoodScore({required this.value, required this.sign, required this.intensity});
  

@override final  double value;
@override final  int sign;
@override final  int intensity;

/// Create a copy of MoodScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoodScoreCopyWith<_MoodScore> get copyWith => __$MoodScoreCopyWithImpl<_MoodScore>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoodScore&&(identical(other.value, value) || other.value == value)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}


@override
int get hashCode => Object.hash(runtimeType,value,sign,intensity);

@override
String toString() {
  return 'MoodScore(value: $value, sign: $sign, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$MoodScoreCopyWith<$Res> implements $MoodScoreCopyWith<$Res> {
  factory _$MoodScoreCopyWith(_MoodScore value, $Res Function(_MoodScore) _then) = __$MoodScoreCopyWithImpl;
@override @useResult
$Res call({
 double value, int sign, int intensity
});




}
/// @nodoc
class __$MoodScoreCopyWithImpl<$Res>
    implements _$MoodScoreCopyWith<$Res> {
  __$MoodScoreCopyWithImpl(this._self, this._then);

  final _MoodScore _self;
  final $Res Function(_MoodScore) _then;

/// Create a copy of MoodScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? sign = null,Object? intensity = null,}) {
  return _then(_MoodScore(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as int,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
