// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garden_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GardenState {

/// Garden Health for the current week (`H_t`, range [-1, +1]).
/// Resets to 0 at the start of every week (weekly harvest cycle).
 double get gardenHealth;/// 5-tier ecosystem state derived from [gardenHealth].
 PlantTier get plantTier;/// 4-state weather overlay derived from today's mean mood-score.
/// Defaults to `calmSunny` when the user has not yet logged today.
 Atmosphere get atmosphere;/// Last 7 days, newest first (today, yesterday, …, 6 days ago).
/// Always length 7. Drives the daily-score strip below the canvas.
 List<DayScore> get last7Days;/// Total entry count across all of history. Used by the screen for
/// diagnostics ("12 entries this week") and to derive [isEmpty].
 int get totalEntryCount;
/// Create a copy of GardenState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GardenStateCopyWith<GardenState> get copyWith => _$GardenStateCopyWithImpl<GardenState>(this as GardenState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GardenState&&(identical(other.gardenHealth, gardenHealth) || other.gardenHealth == gardenHealth)&&(identical(other.plantTier, plantTier) || other.plantTier == plantTier)&&(identical(other.atmosphere, atmosphere) || other.atmosphere == atmosphere)&&const DeepCollectionEquality().equals(other.last7Days, last7Days)&&(identical(other.totalEntryCount, totalEntryCount) || other.totalEntryCount == totalEntryCount));
}


@override
int get hashCode => Object.hash(runtimeType,gardenHealth,plantTier,atmosphere,const DeepCollectionEquality().hash(last7Days),totalEntryCount);

@override
String toString() {
  return 'GardenState(gardenHealth: $gardenHealth, plantTier: $plantTier, atmosphere: $atmosphere, last7Days: $last7Days, totalEntryCount: $totalEntryCount)';
}


}

/// @nodoc
abstract mixin class $GardenStateCopyWith<$Res>  {
  factory $GardenStateCopyWith(GardenState value, $Res Function(GardenState) _then) = _$GardenStateCopyWithImpl;
@useResult
$Res call({
 double gardenHealth, PlantTier plantTier, Atmosphere atmosphere, List<DayScore> last7Days, int totalEntryCount
});




}
/// @nodoc
class _$GardenStateCopyWithImpl<$Res>
    implements $GardenStateCopyWith<$Res> {
  _$GardenStateCopyWithImpl(this._self, this._then);

  final GardenState _self;
  final $Res Function(GardenState) _then;

/// Create a copy of GardenState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gardenHealth = null,Object? plantTier = null,Object? atmosphere = null,Object? last7Days = null,Object? totalEntryCount = null,}) {
  return _then(_self.copyWith(
gardenHealth: null == gardenHealth ? _self.gardenHealth : gardenHealth // ignore: cast_nullable_to_non_nullable
as double,plantTier: null == plantTier ? _self.plantTier : plantTier // ignore: cast_nullable_to_non_nullable
as PlantTier,atmosphere: null == atmosphere ? _self.atmosphere : atmosphere // ignore: cast_nullable_to_non_nullable
as Atmosphere,last7Days: null == last7Days ? _self.last7Days : last7Days // ignore: cast_nullable_to_non_nullable
as List<DayScore>,totalEntryCount: null == totalEntryCount ? _self.totalEntryCount : totalEntryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GardenState].
extension GardenStatePatterns on GardenState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GardenState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GardenState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GardenState value)  $default,){
final _that = this;
switch (_that) {
case _GardenState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GardenState value)?  $default,){
final _that = this;
switch (_that) {
case _GardenState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double gardenHealth,  PlantTier plantTier,  Atmosphere atmosphere,  List<DayScore> last7Days,  int totalEntryCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GardenState() when $default != null:
return $default(_that.gardenHealth,_that.plantTier,_that.atmosphere,_that.last7Days,_that.totalEntryCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double gardenHealth,  PlantTier plantTier,  Atmosphere atmosphere,  List<DayScore> last7Days,  int totalEntryCount)  $default,) {final _that = this;
switch (_that) {
case _GardenState():
return $default(_that.gardenHealth,_that.plantTier,_that.atmosphere,_that.last7Days,_that.totalEntryCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double gardenHealth,  PlantTier plantTier,  Atmosphere atmosphere,  List<DayScore> last7Days,  int totalEntryCount)?  $default,) {final _that = this;
switch (_that) {
case _GardenState() when $default != null:
return $default(_that.gardenHealth,_that.plantTier,_that.atmosphere,_that.last7Days,_that.totalEntryCount);case _:
  return null;

}
}

}

/// @nodoc


class _GardenState extends GardenState {
  const _GardenState({required this.gardenHealth, required this.plantTier, required this.atmosphere, required final  List<DayScore> last7Days, required this.totalEntryCount}): _last7Days = last7Days,super._();
  

/// Garden Health for the current week (`H_t`, range [-1, +1]).
/// Resets to 0 at the start of every week (weekly harvest cycle).
@override final  double gardenHealth;
/// 5-tier ecosystem state derived from [gardenHealth].
@override final  PlantTier plantTier;
/// 4-state weather overlay derived from today's mean mood-score.
/// Defaults to `calmSunny` when the user has not yet logged today.
@override final  Atmosphere atmosphere;
/// Last 7 days, newest first (today, yesterday, …, 6 days ago).
/// Always length 7. Drives the daily-score strip below the canvas.
 final  List<DayScore> _last7Days;
/// Last 7 days, newest first (today, yesterday, …, 6 days ago).
/// Always length 7. Drives the daily-score strip below the canvas.
@override List<DayScore> get last7Days {
  if (_last7Days is EqualUnmodifiableListView) return _last7Days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_last7Days);
}

/// Total entry count across all of history. Used by the screen for
/// diagnostics ("12 entries this week") and to derive [isEmpty].
@override final  int totalEntryCount;

/// Create a copy of GardenState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GardenStateCopyWith<_GardenState> get copyWith => __$GardenStateCopyWithImpl<_GardenState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GardenState&&(identical(other.gardenHealth, gardenHealth) || other.gardenHealth == gardenHealth)&&(identical(other.plantTier, plantTier) || other.plantTier == plantTier)&&(identical(other.atmosphere, atmosphere) || other.atmosphere == atmosphere)&&const DeepCollectionEquality().equals(other._last7Days, _last7Days)&&(identical(other.totalEntryCount, totalEntryCount) || other.totalEntryCount == totalEntryCount));
}


@override
int get hashCode => Object.hash(runtimeType,gardenHealth,plantTier,atmosphere,const DeepCollectionEquality().hash(_last7Days),totalEntryCount);

@override
String toString() {
  return 'GardenState(gardenHealth: $gardenHealth, plantTier: $plantTier, atmosphere: $atmosphere, last7Days: $last7Days, totalEntryCount: $totalEntryCount)';
}


}

/// @nodoc
abstract mixin class _$GardenStateCopyWith<$Res> implements $GardenStateCopyWith<$Res> {
  factory _$GardenStateCopyWith(_GardenState value, $Res Function(_GardenState) _then) = __$GardenStateCopyWithImpl;
@override @useResult
$Res call({
 double gardenHealth, PlantTier plantTier, Atmosphere atmosphere, List<DayScore> last7Days, int totalEntryCount
});




}
/// @nodoc
class __$GardenStateCopyWithImpl<$Res>
    implements _$GardenStateCopyWith<$Res> {
  __$GardenStateCopyWithImpl(this._self, this._then);

  final _GardenState _self;
  final $Res Function(_GardenState) _then;

/// Create a copy of GardenState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gardenHealth = null,Object? plantTier = null,Object? atmosphere = null,Object? last7Days = null,Object? totalEntryCount = null,}) {
  return _then(_GardenState(
gardenHealth: null == gardenHealth ? _self.gardenHealth : gardenHealth // ignore: cast_nullable_to_non_nullable
as double,plantTier: null == plantTier ? _self.plantTier : plantTier // ignore: cast_nullable_to_non_nullable
as PlantTier,atmosphere: null == atmosphere ? _self.atmosphere : atmosphere // ignore: cast_nullable_to_non_nullable
as Atmosphere,last7Days: null == last7Days ? _self._last7Days : last7Days // ignore: cast_nullable_to_non_nullable
as List<DayScore>,totalEntryCount: null == totalEntryCount ? _self.totalEntryCount : totalEntryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$DayScore {

/// Local-midnight `DateTime` of the day this cell represents (in the
/// user's local time zone).
 DateTime get day;/// Mean of `MoodScore.value` for entries logged on [day]. Range
/// [-1, +1]. `null` when no entry was logged that day - distinct
/// from "neutral 0", which would be a logged Okay×0 (impossible).
 double? get avgScore;/// Number of entries logged on [day]. Used by the strip's a11y
/// label and by callers that want to surface "tap for entries".
 int get entryCount;
/// Create a copy of DayScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayScoreCopyWith<DayScore> get copyWith => _$DayScoreCopyWithImpl<DayScore>(this as DayScore, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayScore&&(identical(other.day, day) || other.day == day)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount));
}


@override
int get hashCode => Object.hash(runtimeType,day,avgScore,entryCount);

@override
String toString() {
  return 'DayScore(day: $day, avgScore: $avgScore, entryCount: $entryCount)';
}


}

/// @nodoc
abstract mixin class $DayScoreCopyWith<$Res>  {
  factory $DayScoreCopyWith(DayScore value, $Res Function(DayScore) _then) = _$DayScoreCopyWithImpl;
@useResult
$Res call({
 DateTime day, double? avgScore, int entryCount
});




}
/// @nodoc
class _$DayScoreCopyWithImpl<$Res>
    implements $DayScoreCopyWith<$Res> {
  _$DayScoreCopyWithImpl(this._self, this._then);

  final DayScore _self;
  final $Res Function(DayScore) _then;

/// Create a copy of DayScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? avgScore = freezed,Object? entryCount = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as double?,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DayScore].
extension DayScorePatterns on DayScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayScore value)  $default,){
final _that = this;
switch (_that) {
case _DayScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayScore value)?  $default,){
final _that = this;
switch (_that) {
case _DayScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  double? avgScore,  int entryCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayScore() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  double? avgScore,  int entryCount)  $default,) {final _that = this;
switch (_that) {
case _DayScore():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  double? avgScore,  int entryCount)?  $default,) {final _that = this;
switch (_that) {
case _DayScore() when $default != null:
return $default(_that.day,_that.avgScore,_that.entryCount);case _:
  return null;

}
}

}

/// @nodoc


class _DayScore implements DayScore {
  const _DayScore({required this.day, required this.avgScore, required this.entryCount});
  

/// Local-midnight `DateTime` of the day this cell represents (in the
/// user's local time zone).
@override final  DateTime day;
/// Mean of `MoodScore.value` for entries logged on [day]. Range
/// [-1, +1]. `null` when no entry was logged that day - distinct
/// from "neutral 0", which would be a logged Okay×0 (impossible).
@override final  double? avgScore;
/// Number of entries logged on [day]. Used by the strip's a11y
/// label and by callers that want to surface "tap for entries".
@override final  int entryCount;

/// Create a copy of DayScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayScoreCopyWith<_DayScore> get copyWith => __$DayScoreCopyWithImpl<_DayScore>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayScore&&(identical(other.day, day) || other.day == day)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount));
}


@override
int get hashCode => Object.hash(runtimeType,day,avgScore,entryCount);

@override
String toString() {
  return 'DayScore(day: $day, avgScore: $avgScore, entryCount: $entryCount)';
}


}

/// @nodoc
abstract mixin class _$DayScoreCopyWith<$Res> implements $DayScoreCopyWith<$Res> {
  factory _$DayScoreCopyWith(_DayScore value, $Res Function(_DayScore) _then) = __$DayScoreCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, double? avgScore, int entryCount
});




}
/// @nodoc
class __$DayScoreCopyWithImpl<$Res>
    implements _$DayScoreCopyWith<$Res> {
  __$DayScoreCopyWithImpl(this._self, this._then);

  final _DayScore _self;
  final $Res Function(_DayScore) _then;

/// Create a copy of DayScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? avgScore = freezed,Object? entryCount = null,}) {
  return _then(_DayScore(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as double?,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
