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

/// Total number of positive mood entries in the user's history. Drives
/// the canvas density: more positives → more flowers.
 int get positiveMoodCount;/// Total number of negative-mood entries at intensity 1–3 (gentler
/// negatives). Rendered as wilting plants on the garden canvas.
 int get wiltingMoodCount;/// Total number of negative-mood entries at intensity 4–5 (stormier
/// negatives). Rendered as rain clouds that drift and fade on their own
/// — the user is never asked to clean them up.
 int get rainCloudMoodCount;/// Consecutive days, ending today, on which the user logged at least one
/// positive mood. Empty days break the streak silently — there is no
/// streak-shaming copy. **Wilting and rain-cloud days do NOT contribute
/// to the streak**, by design (see ADR-0006).
 int get currentStreakDays;/// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
/// length 7. Drives the weekly bloom bar.
 List<DayBloom> get last7Days;
/// Create a copy of GardenState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GardenStateCopyWith<GardenState> get copyWith => _$GardenStateCopyWithImpl<GardenState>(this as GardenState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GardenState&&(identical(other.positiveMoodCount, positiveMoodCount) || other.positiveMoodCount == positiveMoodCount)&&(identical(other.wiltingMoodCount, wiltingMoodCount) || other.wiltingMoodCount == wiltingMoodCount)&&(identical(other.rainCloudMoodCount, rainCloudMoodCount) || other.rainCloudMoodCount == rainCloudMoodCount)&&(identical(other.currentStreakDays, currentStreakDays) || other.currentStreakDays == currentStreakDays)&&const DeepCollectionEquality().equals(other.last7Days, last7Days));
}


@override
int get hashCode => Object.hash(runtimeType,positiveMoodCount,wiltingMoodCount,rainCloudMoodCount,currentStreakDays,const DeepCollectionEquality().hash(last7Days));

@override
String toString() {
  return 'GardenState(positiveMoodCount: $positiveMoodCount, wiltingMoodCount: $wiltingMoodCount, rainCloudMoodCount: $rainCloudMoodCount, currentStreakDays: $currentStreakDays, last7Days: $last7Days)';
}


}

/// @nodoc
abstract mixin class $GardenStateCopyWith<$Res>  {
  factory $GardenStateCopyWith(GardenState value, $Res Function(GardenState) _then) = _$GardenStateCopyWithImpl;
@useResult
$Res call({
 int positiveMoodCount, int wiltingMoodCount, int rainCloudMoodCount, int currentStreakDays, List<DayBloom> last7Days
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
@pragma('vm:prefer-inline') @override $Res call({Object? positiveMoodCount = null,Object? wiltingMoodCount = null,Object? rainCloudMoodCount = null,Object? currentStreakDays = null,Object? last7Days = null,}) {
  return _then(_self.copyWith(
positiveMoodCount: null == positiveMoodCount ? _self.positiveMoodCount : positiveMoodCount // ignore: cast_nullable_to_non_nullable
as int,wiltingMoodCount: null == wiltingMoodCount ? _self.wiltingMoodCount : wiltingMoodCount // ignore: cast_nullable_to_non_nullable
as int,rainCloudMoodCount: null == rainCloudMoodCount ? _self.rainCloudMoodCount : rainCloudMoodCount // ignore: cast_nullable_to_non_nullable
as int,currentStreakDays: null == currentStreakDays ? _self.currentStreakDays : currentStreakDays // ignore: cast_nullable_to_non_nullable
as int,last7Days: null == last7Days ? _self.last7Days : last7Days // ignore: cast_nullable_to_non_nullable
as List<DayBloom>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int positiveMoodCount,  int wiltingMoodCount,  int rainCloudMoodCount,  int currentStreakDays,  List<DayBloom> last7Days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GardenState() when $default != null:
return $default(_that.positiveMoodCount,_that.wiltingMoodCount,_that.rainCloudMoodCount,_that.currentStreakDays,_that.last7Days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int positiveMoodCount,  int wiltingMoodCount,  int rainCloudMoodCount,  int currentStreakDays,  List<DayBloom> last7Days)  $default,) {final _that = this;
switch (_that) {
case _GardenState():
return $default(_that.positiveMoodCount,_that.wiltingMoodCount,_that.rainCloudMoodCount,_that.currentStreakDays,_that.last7Days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int positiveMoodCount,  int wiltingMoodCount,  int rainCloudMoodCount,  int currentStreakDays,  List<DayBloom> last7Days)?  $default,) {final _that = this;
switch (_that) {
case _GardenState() when $default != null:
return $default(_that.positiveMoodCount,_that.wiltingMoodCount,_that.rainCloudMoodCount,_that.currentStreakDays,_that.last7Days);case _:
  return null;

}
}

}

/// @nodoc


class _GardenState extends GardenState {
  const _GardenState({required this.positiveMoodCount, required this.wiltingMoodCount, required this.rainCloudMoodCount, required this.currentStreakDays, required final  List<DayBloom> last7Days}): _last7Days = last7Days,super._();
  

/// Total number of positive mood entries in the user's history. Drives
/// the canvas density: more positives → more flowers.
@override final  int positiveMoodCount;
/// Total number of negative-mood entries at intensity 1–3 (gentler
/// negatives). Rendered as wilting plants on the garden canvas.
@override final  int wiltingMoodCount;
/// Total number of negative-mood entries at intensity 4–5 (stormier
/// negatives). Rendered as rain clouds that drift and fade on their own
/// — the user is never asked to clean them up.
@override final  int rainCloudMoodCount;
/// Consecutive days, ending today, on which the user logged at least one
/// positive mood. Empty days break the streak silently — there is no
/// streak-shaming copy. **Wilting and rain-cloud days do NOT contribute
/// to the streak**, by design (see ADR-0006).
@override final  int currentStreakDays;
/// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
/// length 7. Drives the weekly bloom bar.
 final  List<DayBloom> _last7Days;
/// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
/// length 7. Drives the weekly bloom bar.
@override List<DayBloom> get last7Days {
  if (_last7Days is EqualUnmodifiableListView) return _last7Days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_last7Days);
}


/// Create a copy of GardenState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GardenStateCopyWith<_GardenState> get copyWith => __$GardenStateCopyWithImpl<_GardenState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GardenState&&(identical(other.positiveMoodCount, positiveMoodCount) || other.positiveMoodCount == positiveMoodCount)&&(identical(other.wiltingMoodCount, wiltingMoodCount) || other.wiltingMoodCount == wiltingMoodCount)&&(identical(other.rainCloudMoodCount, rainCloudMoodCount) || other.rainCloudMoodCount == rainCloudMoodCount)&&(identical(other.currentStreakDays, currentStreakDays) || other.currentStreakDays == currentStreakDays)&&const DeepCollectionEquality().equals(other._last7Days, _last7Days));
}


@override
int get hashCode => Object.hash(runtimeType,positiveMoodCount,wiltingMoodCount,rainCloudMoodCount,currentStreakDays,const DeepCollectionEquality().hash(_last7Days));

@override
String toString() {
  return 'GardenState(positiveMoodCount: $positiveMoodCount, wiltingMoodCount: $wiltingMoodCount, rainCloudMoodCount: $rainCloudMoodCount, currentStreakDays: $currentStreakDays, last7Days: $last7Days)';
}


}

/// @nodoc
abstract mixin class _$GardenStateCopyWith<$Res> implements $GardenStateCopyWith<$Res> {
  factory _$GardenStateCopyWith(_GardenState value, $Res Function(_GardenState) _then) = __$GardenStateCopyWithImpl;
@override @useResult
$Res call({
 int positiveMoodCount, int wiltingMoodCount, int rainCloudMoodCount, int currentStreakDays, List<DayBloom> last7Days
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
@override @pragma('vm:prefer-inline') $Res call({Object? positiveMoodCount = null,Object? wiltingMoodCount = null,Object? rainCloudMoodCount = null,Object? currentStreakDays = null,Object? last7Days = null,}) {
  return _then(_GardenState(
positiveMoodCount: null == positiveMoodCount ? _self.positiveMoodCount : positiveMoodCount // ignore: cast_nullable_to_non_nullable
as int,wiltingMoodCount: null == wiltingMoodCount ? _self.wiltingMoodCount : wiltingMoodCount // ignore: cast_nullable_to_non_nullable
as int,rainCloudMoodCount: null == rainCloudMoodCount ? _self.rainCloudMoodCount : rainCloudMoodCount // ignore: cast_nullable_to_non_nullable
as int,currentStreakDays: null == currentStreakDays ? _self.currentStreakDays : currentStreakDays // ignore: cast_nullable_to_non_nullable
as int,last7Days: null == last7Days ? _self._last7Days : last7Days // ignore: cast_nullable_to_non_nullable
as List<DayBloom>,
  ));
}


}

/// @nodoc
mixin _$DayBloom {

/// Midnight of the day in the user's local time zone.
 DateTime get day; DayBloomKind get kind;
/// Create a copy of DayBloom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayBloomCopyWith<DayBloom> get copyWith => _$DayBloomCopyWithImpl<DayBloom>(this as DayBloom, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayBloom&&(identical(other.day, day) || other.day == day)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,day,kind);

@override
String toString() {
  return 'DayBloom(day: $day, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $DayBloomCopyWith<$Res>  {
  factory $DayBloomCopyWith(DayBloom value, $Res Function(DayBloom) _then) = _$DayBloomCopyWithImpl;
@useResult
$Res call({
 DateTime day, DayBloomKind kind
});




}
/// @nodoc
class _$DayBloomCopyWithImpl<$Res>
    implements $DayBloomCopyWith<$Res> {
  _$DayBloomCopyWithImpl(this._self, this._then);

  final DayBloom _self;
  final $Res Function(DayBloom) _then;

/// Create a copy of DayBloom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? kind = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DayBloomKind,
  ));
}

}


/// Adds pattern-matching-related methods to [DayBloom].
extension DayBloomPatterns on DayBloom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayBloom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayBloom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayBloom value)  $default,){
final _that = this;
switch (_that) {
case _DayBloom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayBloom value)?  $default,){
final _that = this;
switch (_that) {
case _DayBloom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  DayBloomKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayBloom() when $default != null:
return $default(_that.day,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  DayBloomKind kind)  $default,) {final _that = this;
switch (_that) {
case _DayBloom():
return $default(_that.day,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  DayBloomKind kind)?  $default,) {final _that = this;
switch (_that) {
case _DayBloom() when $default != null:
return $default(_that.day,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _DayBloom implements DayBloom {
  const _DayBloom({required this.day, required this.kind});
  

/// Midnight of the day in the user's local time zone.
@override final  DateTime day;
@override final  DayBloomKind kind;

/// Create a copy of DayBloom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayBloomCopyWith<_DayBloom> get copyWith => __$DayBloomCopyWithImpl<_DayBloom>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayBloom&&(identical(other.day, day) || other.day == day)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,day,kind);

@override
String toString() {
  return 'DayBloom(day: $day, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$DayBloomCopyWith<$Res> implements $DayBloomCopyWith<$Res> {
  factory _$DayBloomCopyWith(_DayBloom value, $Res Function(_DayBloom) _then) = __$DayBloomCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, DayBloomKind kind
});




}
/// @nodoc
class __$DayBloomCopyWithImpl<$Res>
    implements _$DayBloomCopyWith<$Res> {
  __$DayBloomCopyWithImpl(this._self, this._then);

  final _DayBloom _self;
  final $Res Function(_DayBloom) _then;

/// Create a copy of DayBloom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? kind = null,}) {
  return _then(_DayBloom(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DayBloomKind,
  ));
}


}

// dart format on
