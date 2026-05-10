// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_garden.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyGarden {

 String get weekId; DateTime get weekStart; DateTime get weekEnd; List<MoodEntry> get entries; List<double> get healthHistory; WeeklySummary get summary; DateTime get archivedAt; int get schemaV;
/// Create a copy of WeeklyGarden
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyGardenCopyWith<WeeklyGarden> get copyWith => _$WeeklyGardenCopyWithImpl<WeeklyGarden>(this as WeeklyGarden, _$identity);

  /// Serializes this WeeklyGarden to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyGarden&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.healthHistory, healthHistory)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.schemaV, schemaV) || other.schemaV == schemaV));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekId,weekStart,weekEnd,const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(healthHistory),summary,archivedAt,schemaV);

@override
String toString() {
  return 'WeeklyGarden(weekId: $weekId, weekStart: $weekStart, weekEnd: $weekEnd, entries: $entries, healthHistory: $healthHistory, summary: $summary, archivedAt: $archivedAt, schemaV: $schemaV)';
}


}

/// @nodoc
abstract mixin class $WeeklyGardenCopyWith<$Res>  {
  factory $WeeklyGardenCopyWith(WeeklyGarden value, $Res Function(WeeklyGarden) _then) = _$WeeklyGardenCopyWithImpl;
@useResult
$Res call({
 String weekId, DateTime weekStart, DateTime weekEnd, List<MoodEntry> entries, List<double> healthHistory, WeeklySummary summary, DateTime archivedAt, int schemaV
});


$WeeklySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$WeeklyGardenCopyWithImpl<$Res>
    implements $WeeklyGardenCopyWith<$Res> {
  _$WeeklyGardenCopyWithImpl(this._self, this._then);

  final WeeklyGarden _self;
  final $Res Function(WeeklyGarden) _then;

/// Create a copy of WeeklyGarden
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekId = null,Object? weekStart = null,Object? weekEnd = null,Object? entries = null,Object? healthHistory = null,Object? summary = null,Object? archivedAt = null,Object? schemaV = null,}) {
  return _then(_self.copyWith(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as DateTime,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<MoodEntry>,healthHistory: null == healthHistory ? _self.healthHistory : healthHistory // ignore: cast_nullable_to_non_nullable
as List<double>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as WeeklySummary,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaV: null == schemaV ? _self.schemaV : schemaV // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of WeeklyGarden
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklySummaryCopyWith<$Res> get summary {
  
  return $WeeklySummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [WeeklyGarden].
extension WeeklyGardenPatterns on WeeklyGarden {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyGarden value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyGarden() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyGarden value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyGarden():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyGarden value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyGarden() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekId,  DateTime weekStart,  DateTime weekEnd,  List<MoodEntry> entries,  List<double> healthHistory,  WeeklySummary summary,  DateTime archivedAt,  int schemaV)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyGarden() when $default != null:
return $default(_that.weekId,_that.weekStart,_that.weekEnd,_that.entries,_that.healthHistory,_that.summary,_that.archivedAt,_that.schemaV);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekId,  DateTime weekStart,  DateTime weekEnd,  List<MoodEntry> entries,  List<double> healthHistory,  WeeklySummary summary,  DateTime archivedAt,  int schemaV)  $default,) {final _that = this;
switch (_that) {
case _WeeklyGarden():
return $default(_that.weekId,_that.weekStart,_that.weekEnd,_that.entries,_that.healthHistory,_that.summary,_that.archivedAt,_that.schemaV);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekId,  DateTime weekStart,  DateTime weekEnd,  List<MoodEntry> entries,  List<double> healthHistory,  WeeklySummary summary,  DateTime archivedAt,  int schemaV)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyGarden() when $default != null:
return $default(_that.weekId,_that.weekStart,_that.weekEnd,_that.entries,_that.healthHistory,_that.summary,_that.archivedAt,_that.schemaV);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyGarden implements WeeklyGarden {
  const _WeeklyGarden({required this.weekId, required this.weekStart, required this.weekEnd, required final  List<MoodEntry> entries, required final  List<double> healthHistory, required this.summary, required this.archivedAt, this.schemaV = 1}): _entries = entries,_healthHistory = healthHistory;
  factory _WeeklyGarden.fromJson(Map<String, dynamic> json) => _$WeeklyGardenFromJson(json);

@override final  String weekId;
@override final  DateTime weekStart;
@override final  DateTime weekEnd;
 final  List<MoodEntry> _entries;
@override List<MoodEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<double> _healthHistory;
@override List<double> get healthHistory {
  if (_healthHistory is EqualUnmodifiableListView) return _healthHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_healthHistory);
}

@override final  WeeklySummary summary;
@override final  DateTime archivedAt;
@override@JsonKey() final  int schemaV;

/// Create a copy of WeeklyGarden
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyGardenCopyWith<_WeeklyGarden> get copyWith => __$WeeklyGardenCopyWithImpl<_WeeklyGarden>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyGardenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyGarden&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._healthHistory, _healthHistory)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.schemaV, schemaV) || other.schemaV == schemaV));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekId,weekStart,weekEnd,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_healthHistory),summary,archivedAt,schemaV);

@override
String toString() {
  return 'WeeklyGarden(weekId: $weekId, weekStart: $weekStart, weekEnd: $weekEnd, entries: $entries, healthHistory: $healthHistory, summary: $summary, archivedAt: $archivedAt, schemaV: $schemaV)';
}


}

/// @nodoc
abstract mixin class _$WeeklyGardenCopyWith<$Res> implements $WeeklyGardenCopyWith<$Res> {
  factory _$WeeklyGardenCopyWith(_WeeklyGarden value, $Res Function(_WeeklyGarden) _then) = __$WeeklyGardenCopyWithImpl;
@override @useResult
$Res call({
 String weekId, DateTime weekStart, DateTime weekEnd, List<MoodEntry> entries, List<double> healthHistory, WeeklySummary summary, DateTime archivedAt, int schemaV
});


@override $WeeklySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$WeeklyGardenCopyWithImpl<$Res>
    implements _$WeeklyGardenCopyWith<$Res> {
  __$WeeklyGardenCopyWithImpl(this._self, this._then);

  final _WeeklyGarden _self;
  final $Res Function(_WeeklyGarden) _then;

/// Create a copy of WeeklyGarden
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekId = null,Object? weekStart = null,Object? weekEnd = null,Object? entries = null,Object? healthHistory = null,Object? summary = null,Object? archivedAt = null,Object? schemaV = null,}) {
  return _then(_WeeklyGarden(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as DateTime,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<MoodEntry>,healthHistory: null == healthHistory ? _self._healthHistory : healthHistory // ignore: cast_nullable_to_non_nullable
as List<double>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as WeeklySummary,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaV: null == schemaV ? _self.schemaV : schemaV // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of WeeklyGarden
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklySummaryCopyWith<$Res> get summary {
  
  return $WeeklySummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// @nodoc
mixin _$WeeklySummary {

 double get averageMoodScore; Map<MoodType, int> get moodCounts; PlantTier get endingPlantTier; int get totalEntryCount; int get triggeredTierCount;
/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklySummaryCopyWith<WeeklySummary> get copyWith => _$WeeklySummaryCopyWithImpl<WeeklySummary>(this as WeeklySummary, _$identity);

  /// Serializes this WeeklySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklySummary&&(identical(other.averageMoodScore, averageMoodScore) || other.averageMoodScore == averageMoodScore)&&const DeepCollectionEquality().equals(other.moodCounts, moodCounts)&&(identical(other.endingPlantTier, endingPlantTier) || other.endingPlantTier == endingPlantTier)&&(identical(other.totalEntryCount, totalEntryCount) || other.totalEntryCount == totalEntryCount)&&(identical(other.triggeredTierCount, triggeredTierCount) || other.triggeredTierCount == triggeredTierCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,averageMoodScore,const DeepCollectionEquality().hash(moodCounts),endingPlantTier,totalEntryCount,triggeredTierCount);

@override
String toString() {
  return 'WeeklySummary(averageMoodScore: $averageMoodScore, moodCounts: $moodCounts, endingPlantTier: $endingPlantTier, totalEntryCount: $totalEntryCount, triggeredTierCount: $triggeredTierCount)';
}


}

/// @nodoc
abstract mixin class $WeeklySummaryCopyWith<$Res>  {
  factory $WeeklySummaryCopyWith(WeeklySummary value, $Res Function(WeeklySummary) _then) = _$WeeklySummaryCopyWithImpl;
@useResult
$Res call({
 double averageMoodScore, Map<MoodType, int> moodCounts, PlantTier endingPlantTier, int totalEntryCount, int triggeredTierCount
});




}
/// @nodoc
class _$WeeklySummaryCopyWithImpl<$Res>
    implements $WeeklySummaryCopyWith<$Res> {
  _$WeeklySummaryCopyWithImpl(this._self, this._then);

  final WeeklySummary _self;
  final $Res Function(WeeklySummary) _then;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? averageMoodScore = null,Object? moodCounts = null,Object? endingPlantTier = null,Object? totalEntryCount = null,Object? triggeredTierCount = null,}) {
  return _then(_self.copyWith(
averageMoodScore: null == averageMoodScore ? _self.averageMoodScore : averageMoodScore // ignore: cast_nullable_to_non_nullable
as double,moodCounts: null == moodCounts ? _self.moodCounts : moodCounts // ignore: cast_nullable_to_non_nullable
as Map<MoodType, int>,endingPlantTier: null == endingPlantTier ? _self.endingPlantTier : endingPlantTier // ignore: cast_nullable_to_non_nullable
as PlantTier,totalEntryCount: null == totalEntryCount ? _self.totalEntryCount : totalEntryCount // ignore: cast_nullable_to_non_nullable
as int,triggeredTierCount: null == triggeredTierCount ? _self.triggeredTierCount : triggeredTierCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklySummary].
extension WeeklySummaryPatterns on WeeklySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklySummary value)  $default,){
final _that = this;
switch (_that) {
case _WeeklySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklySummary value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double averageMoodScore,  Map<MoodType, int> moodCounts,  PlantTier endingPlantTier,  int totalEntryCount,  int triggeredTierCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
return $default(_that.averageMoodScore,_that.moodCounts,_that.endingPlantTier,_that.totalEntryCount,_that.triggeredTierCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double averageMoodScore,  Map<MoodType, int> moodCounts,  PlantTier endingPlantTier,  int totalEntryCount,  int triggeredTierCount)  $default,) {final _that = this;
switch (_that) {
case _WeeklySummary():
return $default(_that.averageMoodScore,_that.moodCounts,_that.endingPlantTier,_that.totalEntryCount,_that.triggeredTierCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double averageMoodScore,  Map<MoodType, int> moodCounts,  PlantTier endingPlantTier,  int totalEntryCount,  int triggeredTierCount)?  $default,) {final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
return $default(_that.averageMoodScore,_that.moodCounts,_that.endingPlantTier,_that.totalEntryCount,_that.triggeredTierCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklySummary implements WeeklySummary {
  const _WeeklySummary({required this.averageMoodScore, required final  Map<MoodType, int> moodCounts, required this.endingPlantTier, required this.totalEntryCount, required this.triggeredTierCount}): _moodCounts = moodCounts;
  factory _WeeklySummary.fromJson(Map<String, dynamic> json) => _$WeeklySummaryFromJson(json);

@override final  double averageMoodScore;
 final  Map<MoodType, int> _moodCounts;
@override Map<MoodType, int> get moodCounts {
  if (_moodCounts is EqualUnmodifiableMapView) return _moodCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_moodCounts);
}

@override final  PlantTier endingPlantTier;
@override final  int totalEntryCount;
@override final  int triggeredTierCount;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklySummaryCopyWith<_WeeklySummary> get copyWith => __$WeeklySummaryCopyWithImpl<_WeeklySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklySummary&&(identical(other.averageMoodScore, averageMoodScore) || other.averageMoodScore == averageMoodScore)&&const DeepCollectionEquality().equals(other._moodCounts, _moodCounts)&&(identical(other.endingPlantTier, endingPlantTier) || other.endingPlantTier == endingPlantTier)&&(identical(other.totalEntryCount, totalEntryCount) || other.totalEntryCount == totalEntryCount)&&(identical(other.triggeredTierCount, triggeredTierCount) || other.triggeredTierCount == triggeredTierCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,averageMoodScore,const DeepCollectionEquality().hash(_moodCounts),endingPlantTier,totalEntryCount,triggeredTierCount);

@override
String toString() {
  return 'WeeklySummary(averageMoodScore: $averageMoodScore, moodCounts: $moodCounts, endingPlantTier: $endingPlantTier, totalEntryCount: $totalEntryCount, triggeredTierCount: $triggeredTierCount)';
}


}

/// @nodoc
abstract mixin class _$WeeklySummaryCopyWith<$Res> implements $WeeklySummaryCopyWith<$Res> {
  factory _$WeeklySummaryCopyWith(_WeeklySummary value, $Res Function(_WeeklySummary) _then) = __$WeeklySummaryCopyWithImpl;
@override @useResult
$Res call({
 double averageMoodScore, Map<MoodType, int> moodCounts, PlantTier endingPlantTier, int totalEntryCount, int triggeredTierCount
});




}
/// @nodoc
class __$WeeklySummaryCopyWithImpl<$Res>
    implements _$WeeklySummaryCopyWith<$Res> {
  __$WeeklySummaryCopyWithImpl(this._self, this._then);

  final _WeeklySummary _self;
  final $Res Function(_WeeklySummary) _then;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? averageMoodScore = null,Object? moodCounts = null,Object? endingPlantTier = null,Object? totalEntryCount = null,Object? triggeredTierCount = null,}) {
  return _then(_WeeklySummary(
averageMoodScore: null == averageMoodScore ? _self.averageMoodScore : averageMoodScore // ignore: cast_nullable_to_non_nullable
as double,moodCounts: null == moodCounts ? _self._moodCounts : moodCounts // ignore: cast_nullable_to_non_nullable
as Map<MoodType, int>,endingPlantTier: null == endingPlantTier ? _self.endingPlantTier : endingPlantTier // ignore: cast_nullable_to_non_nullable
as PlantTier,totalEntryCount: null == totalEntryCount ? _self.totalEntryCount : totalEntryCount // ignore: cast_nullable_to_non_nullable
as int,triggeredTierCount: null == triggeredTierCount ? _self.triggeredTierCount : triggeredTierCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
