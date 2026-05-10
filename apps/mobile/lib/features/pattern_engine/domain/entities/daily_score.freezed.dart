// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyScore {

 DateTime get day; double get avgScore; int get entryCount;
/// Create a copy of DailyScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyScoreCopyWith<DailyScore> get copyWith => _$DailyScoreCopyWithImpl<DailyScore>(this as DailyScore, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyScore&&(identical(other.day, day) || other.day == day)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount));
}


@override
int get hashCode => Object.hash(runtimeType,day,avgScore,entryCount);

@override
String toString() {
  return 'DailyScore(day: $day, avgScore: $avgScore, entryCount: $entryCount)';
}


}

/// @nodoc
abstract mixin class $DailyScoreCopyWith<$Res>  {
  factory $DailyScoreCopyWith(DailyScore value, $Res Function(DailyScore) _then) = _$DailyScoreCopyWithImpl;
@useResult
$Res call({
 DateTime day, double avgScore, int entryCount
});




}
/// @nodoc
class _$DailyScoreCopyWithImpl<$Res>
    implements $DailyScoreCopyWith<$Res> {
  _$DailyScoreCopyWithImpl(this._self, this._then);

  final DailyScore _self;
  final $Res Function(DailyScore) _then;

/// Create a copy of DailyScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? avgScore = null,Object? entryCount = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,avgScore: null == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as double,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyScore].
extension DailyScorePatterns on DailyScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyScore value)  $default,){
final _that = this;
switch (_that) {
case _DailyScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyScore value)?  $default,){
final _that = this;
switch (_that) {
case _DailyScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  double avgScore,  int entryCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyScore() when $default != null:
return $default(_that.day,_that.avgScore,_that.entryCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  double avgScore,  int entryCount)  $default,) {final _that = this;
switch (_that) {
case _DailyScore():
return $default(_that.day,_that.avgScore,_that.entryCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  double avgScore,  int entryCount)?  $default,) {final _that = this;
switch (_that) {
case _DailyScore() when $default != null:
return $default(_that.day,_that.avgScore,_that.entryCount);case _:
  return null;

}
}

}

/// @nodoc


class _DailyScore implements DailyScore {
  const _DailyScore({required this.day, required this.avgScore, required this.entryCount});
  

@override final  DateTime day;
@override final  double avgScore;
@override final  int entryCount;

/// Create a copy of DailyScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyScoreCopyWith<_DailyScore> get copyWith => __$DailyScoreCopyWithImpl<_DailyScore>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyScore&&(identical(other.day, day) || other.day == day)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount));
}


@override
int get hashCode => Object.hash(runtimeType,day,avgScore,entryCount);

@override
String toString() {
  return 'DailyScore(day: $day, avgScore: $avgScore, entryCount: $entryCount)';
}


}

/// @nodoc
abstract mixin class _$DailyScoreCopyWith<$Res> implements $DailyScoreCopyWith<$Res> {
  factory _$DailyScoreCopyWith(_DailyScore value, $Res Function(_DailyScore) _then) = __$DailyScoreCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, double avgScore, int entryCount
});




}
/// @nodoc
class __$DailyScoreCopyWithImpl<$Res>
    implements _$DailyScoreCopyWith<$Res> {
  __$DailyScoreCopyWithImpl(this._self, this._then);

  final _DailyScore _self;
  final $Res Function(_DailyScore) _then;

/// Create a copy of DailyScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? avgScore = null,Object? entryCount = null,}) {
  return _then(_DailyScore(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,avgScore: null == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as double,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
