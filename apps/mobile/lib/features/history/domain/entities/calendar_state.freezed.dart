// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CalendarState {

 DateTime get month; Map<DateTime, DayDot> get dotsByDay;
/// Create a copy of CalendarState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarStateCopyWith<CalendarState> get copyWith => _$CalendarStateCopyWithImpl<CalendarState>(this as CalendarState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarState&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other.dotsByDay, dotsByDay));
}


@override
int get hashCode => Object.hash(runtimeType,month,const DeepCollectionEquality().hash(dotsByDay));

@override
String toString() {
  return 'CalendarState(month: $month, dotsByDay: $dotsByDay)';
}


}

/// @nodoc
abstract mixin class $CalendarStateCopyWith<$Res>  {
  factory $CalendarStateCopyWith(CalendarState value, $Res Function(CalendarState) _then) = _$CalendarStateCopyWithImpl;
@useResult
$Res call({
 DateTime month, Map<DateTime, DayDot> dotsByDay
});




}
/// @nodoc
class _$CalendarStateCopyWithImpl<$Res>
    implements $CalendarStateCopyWith<$Res> {
  _$CalendarStateCopyWithImpl(this._self, this._then);

  final CalendarState _self;
  final $Res Function(CalendarState) _then;

/// Create a copy of CalendarState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? dotsByDay = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as DateTime,dotsByDay: null == dotsByDay ? _self.dotsByDay : dotsByDay // ignore: cast_nullable_to_non_nullable
as Map<DateTime, DayDot>,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarState].
extension CalendarStatePatterns on CalendarState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarState value)  $default,){
final _that = this;
switch (_that) {
case _CalendarState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarState value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime month,  Map<DateTime, DayDot> dotsByDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarState() when $default != null:
return $default(_that.month,_that.dotsByDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime month,  Map<DateTime, DayDot> dotsByDay)  $default,) {final _that = this;
switch (_that) {
case _CalendarState():
return $default(_that.month,_that.dotsByDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime month,  Map<DateTime, DayDot> dotsByDay)?  $default,) {final _that = this;
switch (_that) {
case _CalendarState() when $default != null:
return $default(_that.month,_that.dotsByDay);case _:
  return null;

}
}

}

/// @nodoc


class _CalendarState extends CalendarState {
  const _CalendarState({required this.month, required final  Map<DateTime, DayDot> dotsByDay}): _dotsByDay = dotsByDay,super._();
  

@override final  DateTime month;
 final  Map<DateTime, DayDot> _dotsByDay;
@override Map<DateTime, DayDot> get dotsByDay {
  if (_dotsByDay is EqualUnmodifiableMapView) return _dotsByDay;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dotsByDay);
}


/// Create a copy of CalendarState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarStateCopyWith<_CalendarState> get copyWith => __$CalendarStateCopyWithImpl<_CalendarState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarState&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other._dotsByDay, _dotsByDay));
}


@override
int get hashCode => Object.hash(runtimeType,month,const DeepCollectionEquality().hash(_dotsByDay));

@override
String toString() {
  return 'CalendarState(month: $month, dotsByDay: $dotsByDay)';
}


}

/// @nodoc
abstract mixin class _$CalendarStateCopyWith<$Res> implements $CalendarStateCopyWith<$Res> {
  factory _$CalendarStateCopyWith(_CalendarState value, $Res Function(_CalendarState) _then) = __$CalendarStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime month, Map<DateTime, DayDot> dotsByDay
});




}
/// @nodoc
class __$CalendarStateCopyWithImpl<$Res>
    implements _$CalendarStateCopyWith<$Res> {
  __$CalendarStateCopyWithImpl(this._self, this._then);

  final _CalendarState _self;
  final $Res Function(_CalendarState) _then;

/// Create a copy of CalendarState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? dotsByDay = null,}) {
  return _then(_CalendarState(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as DateTime,dotsByDay: null == dotsByDay ? _self._dotsByDay : dotsByDay // ignore: cast_nullable_to_non_nullable
as Map<DateTime, DayDot>,
  ));
}


}

/// @nodoc
mixin _$DayDot {

 DateTime get day; MoodCategory get dominantCategory; int get totalEntries; String get mostRecentEntryId;
/// Create a copy of DayDot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayDotCopyWith<DayDot> get copyWith => _$DayDotCopyWithImpl<DayDot>(this as DayDot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayDot&&(identical(other.day, day) || other.day == day)&&(identical(other.dominantCategory, dominantCategory) || other.dominantCategory == dominantCategory)&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&(identical(other.mostRecentEntryId, mostRecentEntryId) || other.mostRecentEntryId == mostRecentEntryId));
}


@override
int get hashCode => Object.hash(runtimeType,day,dominantCategory,totalEntries,mostRecentEntryId);

@override
String toString() {
  return 'DayDot(day: $day, dominantCategory: $dominantCategory, totalEntries: $totalEntries, mostRecentEntryId: $mostRecentEntryId)';
}


}

/// @nodoc
abstract mixin class $DayDotCopyWith<$Res>  {
  factory $DayDotCopyWith(DayDot value, $Res Function(DayDot) _then) = _$DayDotCopyWithImpl;
@useResult
$Res call({
 DateTime day, MoodCategory dominantCategory, int totalEntries, String mostRecentEntryId
});




}
/// @nodoc
class _$DayDotCopyWithImpl<$Res>
    implements $DayDotCopyWith<$Res> {
  _$DayDotCopyWithImpl(this._self, this._then);

  final DayDot _self;
  final $Res Function(DayDot) _then;

/// Create a copy of DayDot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? dominantCategory = null,Object? totalEntries = null,Object? mostRecentEntryId = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,dominantCategory: null == dominantCategory ? _self.dominantCategory : dominantCategory // ignore: cast_nullable_to_non_nullable
as MoodCategory,totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,mostRecentEntryId: null == mostRecentEntryId ? _self.mostRecentEntryId : mostRecentEntryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DayDot].
extension DayDotPatterns on DayDot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayDot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayDot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayDot value)  $default,){
final _that = this;
switch (_that) {
case _DayDot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayDot value)?  $default,){
final _that = this;
switch (_that) {
case _DayDot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  MoodCategory dominantCategory,  int totalEntries,  String mostRecentEntryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayDot() when $default != null:
return $default(_that.day,_that.dominantCategory,_that.totalEntries,_that.mostRecentEntryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  MoodCategory dominantCategory,  int totalEntries,  String mostRecentEntryId)  $default,) {final _that = this;
switch (_that) {
case _DayDot():
return $default(_that.day,_that.dominantCategory,_that.totalEntries,_that.mostRecentEntryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  MoodCategory dominantCategory,  int totalEntries,  String mostRecentEntryId)?  $default,) {final _that = this;
switch (_that) {
case _DayDot() when $default != null:
return $default(_that.day,_that.dominantCategory,_that.totalEntries,_that.mostRecentEntryId);case _:
  return null;

}
}

}

/// @nodoc


class _DayDot implements DayDot {
  const _DayDot({required this.day, required this.dominantCategory, required this.totalEntries, required this.mostRecentEntryId});
  

@override final  DateTime day;
@override final  MoodCategory dominantCategory;
@override final  int totalEntries;
@override final  String mostRecentEntryId;

/// Create a copy of DayDot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayDotCopyWith<_DayDot> get copyWith => __$DayDotCopyWithImpl<_DayDot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayDot&&(identical(other.day, day) || other.day == day)&&(identical(other.dominantCategory, dominantCategory) || other.dominantCategory == dominantCategory)&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&(identical(other.mostRecentEntryId, mostRecentEntryId) || other.mostRecentEntryId == mostRecentEntryId));
}


@override
int get hashCode => Object.hash(runtimeType,day,dominantCategory,totalEntries,mostRecentEntryId);

@override
String toString() {
  return 'DayDot(day: $day, dominantCategory: $dominantCategory, totalEntries: $totalEntries, mostRecentEntryId: $mostRecentEntryId)';
}


}

/// @nodoc
abstract mixin class _$DayDotCopyWith<$Res> implements $DayDotCopyWith<$Res> {
  factory _$DayDotCopyWith(_DayDot value, $Res Function(_DayDot) _then) = __$DayDotCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, MoodCategory dominantCategory, int totalEntries, String mostRecentEntryId
});




}
/// @nodoc
class __$DayDotCopyWithImpl<$Res>
    implements _$DayDotCopyWith<$Res> {
  __$DayDotCopyWithImpl(this._self, this._then);

  final _DayDot _self;
  final $Res Function(_DayDot) _then;

/// Create a copy of DayDot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? dominantCategory = null,Object? totalEntries = null,Object? mostRecentEntryId = null,}) {
  return _then(_DayDot(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,dominantCategory: null == dominantCategory ? _self.dominantCategory : dominantCategory // ignore: cast_nullable_to_non_nullable
as MoodCategory,totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,mostRecentEntryId: null == mostRecentEntryId ? _self.mostRecentEntryId : mostRecentEntryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
