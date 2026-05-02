// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyMoodAggregate {

 DateTime get day; int get totalEntries; Map<MoodCategory, double> get meanIntensityByCategory;
/// Create a copy of DailyMoodAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyMoodAggregateCopyWith<DailyMoodAggregate> get copyWith => _$DailyMoodAggregateCopyWithImpl<DailyMoodAggregate>(this as DailyMoodAggregate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyMoodAggregate&&(identical(other.day, day) || other.day == day)&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&const DeepCollectionEquality().equals(other.meanIntensityByCategory, meanIntensityByCategory));
}


@override
int get hashCode => Object.hash(runtimeType,day,totalEntries,const DeepCollectionEquality().hash(meanIntensityByCategory));

@override
String toString() {
  return 'DailyMoodAggregate(day: $day, totalEntries: $totalEntries, meanIntensityByCategory: $meanIntensityByCategory)';
}


}

/// @nodoc
abstract mixin class $DailyMoodAggregateCopyWith<$Res>  {
  factory $DailyMoodAggregateCopyWith(DailyMoodAggregate value, $Res Function(DailyMoodAggregate) _then) = _$DailyMoodAggregateCopyWithImpl;
@useResult
$Res call({
 DateTime day, int totalEntries, Map<MoodCategory, double> meanIntensityByCategory
});




}
/// @nodoc
class _$DailyMoodAggregateCopyWithImpl<$Res>
    implements $DailyMoodAggregateCopyWith<$Res> {
  _$DailyMoodAggregateCopyWithImpl(this._self, this._then);

  final DailyMoodAggregate _self;
  final $Res Function(DailyMoodAggregate) _then;

/// Create a copy of DailyMoodAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? totalEntries = null,Object? meanIntensityByCategory = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,meanIntensityByCategory: null == meanIntensityByCategory ? _self.meanIntensityByCategory : meanIntensityByCategory // ignore: cast_nullable_to_non_nullable
as Map<MoodCategory, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyMoodAggregate].
extension DailyMoodAggregatePatterns on DailyMoodAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyMoodAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyMoodAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyMoodAggregate value)  $default,){
final _that = this;
switch (_that) {
case _DailyMoodAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyMoodAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _DailyMoodAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  int totalEntries,  Map<MoodCategory, double> meanIntensityByCategory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyMoodAggregate() when $default != null:
return $default(_that.day,_that.totalEntries,_that.meanIntensityByCategory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  int totalEntries,  Map<MoodCategory, double> meanIntensityByCategory)  $default,) {final _that = this;
switch (_that) {
case _DailyMoodAggregate():
return $default(_that.day,_that.totalEntries,_that.meanIntensityByCategory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  int totalEntries,  Map<MoodCategory, double> meanIntensityByCategory)?  $default,) {final _that = this;
switch (_that) {
case _DailyMoodAggregate() when $default != null:
return $default(_that.day,_that.totalEntries,_that.meanIntensityByCategory);case _:
  return null;

}
}

}

/// @nodoc


class _DailyMoodAggregate implements DailyMoodAggregate {
  const _DailyMoodAggregate({required this.day, required this.totalEntries, required final  Map<MoodCategory, double> meanIntensityByCategory}): _meanIntensityByCategory = meanIntensityByCategory;
  

@override final  DateTime day;
@override final  int totalEntries;
 final  Map<MoodCategory, double> _meanIntensityByCategory;
@override Map<MoodCategory, double> get meanIntensityByCategory {
  if (_meanIntensityByCategory is EqualUnmodifiableMapView) return _meanIntensityByCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_meanIntensityByCategory);
}


/// Create a copy of DailyMoodAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyMoodAggregateCopyWith<_DailyMoodAggregate> get copyWith => __$DailyMoodAggregateCopyWithImpl<_DailyMoodAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyMoodAggregate&&(identical(other.day, day) || other.day == day)&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&const DeepCollectionEquality().equals(other._meanIntensityByCategory, _meanIntensityByCategory));
}


@override
int get hashCode => Object.hash(runtimeType,day,totalEntries,const DeepCollectionEquality().hash(_meanIntensityByCategory));

@override
String toString() {
  return 'DailyMoodAggregate(day: $day, totalEntries: $totalEntries, meanIntensityByCategory: $meanIntensityByCategory)';
}


}

/// @nodoc
abstract mixin class _$DailyMoodAggregateCopyWith<$Res> implements $DailyMoodAggregateCopyWith<$Res> {
  factory _$DailyMoodAggregateCopyWith(_DailyMoodAggregate value, $Res Function(_DailyMoodAggregate) _then) = __$DailyMoodAggregateCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, int totalEntries, Map<MoodCategory, double> meanIntensityByCategory
});




}
/// @nodoc
class __$DailyMoodAggregateCopyWithImpl<$Res>
    implements _$DailyMoodAggregateCopyWith<$Res> {
  __$DailyMoodAggregateCopyWithImpl(this._self, this._then);

  final _DailyMoodAggregate _self;
  final $Res Function(_DailyMoodAggregate) _then;

/// Create a copy of DailyMoodAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? totalEntries = null,Object? meanIntensityByCategory = null,}) {
  return _then(_DailyMoodAggregate(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,meanIntensityByCategory: null == meanIntensityByCategory ? _self._meanIntensityByCategory : meanIntensityByCategory // ignore: cast_nullable_to_non_nullable
as Map<MoodCategory, double>,
  ));
}


}

/// @nodoc
mixin _$AnalyticsState {

 MoodWindow get window; List<DailyMoodAggregate> get days;
/// Create a copy of AnalyticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsStateCopyWith<AnalyticsState> get copyWith => _$AnalyticsStateCopyWithImpl<AnalyticsState>(this as AnalyticsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsState&&(identical(other.window, window) || other.window == window)&&const DeepCollectionEquality().equals(other.days, days));
}


@override
int get hashCode => Object.hash(runtimeType,window,const DeepCollectionEquality().hash(days));

@override
String toString() {
  return 'AnalyticsState(window: $window, days: $days)';
}


}

/// @nodoc
abstract mixin class $AnalyticsStateCopyWith<$Res>  {
  factory $AnalyticsStateCopyWith(AnalyticsState value, $Res Function(AnalyticsState) _then) = _$AnalyticsStateCopyWithImpl;
@useResult
$Res call({
 MoodWindow window, List<DailyMoodAggregate> days
});




}
/// @nodoc
class _$AnalyticsStateCopyWithImpl<$Res>
    implements $AnalyticsStateCopyWith<$Res> {
  _$AnalyticsStateCopyWithImpl(this._self, this._then);

  final AnalyticsState _self;
  final $Res Function(AnalyticsState) _then;

/// Create a copy of AnalyticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? days = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as MoodWindow,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<DailyMoodAggregate>,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsState].
extension AnalyticsStatePatterns on AnalyticsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsState value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsState value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MoodWindow window,  List<DailyMoodAggregate> days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsState() when $default != null:
return $default(_that.window,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MoodWindow window,  List<DailyMoodAggregate> days)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsState():
return $default(_that.window,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MoodWindow window,  List<DailyMoodAggregate> days)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsState() when $default != null:
return $default(_that.window,_that.days);case _:
  return null;

}
}

}

/// @nodoc


class _AnalyticsState extends AnalyticsState {
  const _AnalyticsState({required this.window, required final  List<DailyMoodAggregate> days}): _days = days,super._();
  

@override final  MoodWindow window;
 final  List<DailyMoodAggregate> _days;
@override List<DailyMoodAggregate> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}


/// Create a copy of AnalyticsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsStateCopyWith<_AnalyticsState> get copyWith => __$AnalyticsStateCopyWithImpl<_AnalyticsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsState&&(identical(other.window, window) || other.window == window)&&const DeepCollectionEquality().equals(other._days, _days));
}


@override
int get hashCode => Object.hash(runtimeType,window,const DeepCollectionEquality().hash(_days));

@override
String toString() {
  return 'AnalyticsState(window: $window, days: $days)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsStateCopyWith<$Res> implements $AnalyticsStateCopyWith<$Res> {
  factory _$AnalyticsStateCopyWith(_AnalyticsState value, $Res Function(_AnalyticsState) _then) = __$AnalyticsStateCopyWithImpl;
@override @useResult
$Res call({
 MoodWindow window, List<DailyMoodAggregate> days
});




}
/// @nodoc
class __$AnalyticsStateCopyWithImpl<$Res>
    implements _$AnalyticsStateCopyWith<$Res> {
  __$AnalyticsStateCopyWithImpl(this._self, this._then);

  final _AnalyticsState _self;
  final $Res Function(_AnalyticsState) _then;

/// Create a copy of AnalyticsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? days = null,}) {
  return _then(_AnalyticsState(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as MoodWindow,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<DailyMoodAggregate>,
  ));
}


}

// dart format on
