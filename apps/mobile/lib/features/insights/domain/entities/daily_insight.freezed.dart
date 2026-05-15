// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyInsight {

 DateTime get date; double? get avgMoodScore; double? get gardenHealthH; MoodType? get dominantEmotion; int get entryCount; Tier? get triggeredTier; PatternEngineTriggerKind? get triggerReasonKey;
/// Create a copy of DailyInsight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyInsightCopyWith<DailyInsight> get copyWith => _$DailyInsightCopyWithImpl<DailyInsight>(this as DailyInsight, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyInsight&&(identical(other.date, date) || other.date == date)&&(identical(other.avgMoodScore, avgMoodScore) || other.avgMoodScore == avgMoodScore)&&(identical(other.gardenHealthH, gardenHealthH) || other.gardenHealthH == gardenHealthH)&&(identical(other.dominantEmotion, dominantEmotion) || other.dominantEmotion == dominantEmotion)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.triggeredTier, triggeredTier) || other.triggeredTier == triggeredTier)&&(identical(other.triggerReasonKey, triggerReasonKey) || other.triggerReasonKey == triggerReasonKey));
}


@override
int get hashCode => Object.hash(runtimeType,date,avgMoodScore,gardenHealthH,dominantEmotion,entryCount,triggeredTier,triggerReasonKey);

@override
String toString() {
  return 'DailyInsight(date: $date, avgMoodScore: $avgMoodScore, gardenHealthH: $gardenHealthH, dominantEmotion: $dominantEmotion, entryCount: $entryCount, triggeredTier: $triggeredTier, triggerReasonKey: $triggerReasonKey)';
}


}

/// @nodoc
abstract mixin class $DailyInsightCopyWith<$Res>  {
  factory $DailyInsightCopyWith(DailyInsight value, $Res Function(DailyInsight) _then) = _$DailyInsightCopyWithImpl;
@useResult
$Res call({
 DateTime date, double? avgMoodScore, double? gardenHealthH, MoodType? dominantEmotion, int entryCount, Tier? triggeredTier, PatternEngineTriggerKind? triggerReasonKey
});




}
/// @nodoc
class _$DailyInsightCopyWithImpl<$Res>
    implements $DailyInsightCopyWith<$Res> {
  _$DailyInsightCopyWithImpl(this._self, this._then);

  final DailyInsight _self;
  final $Res Function(DailyInsight) _then;

/// Create a copy of DailyInsight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? avgMoodScore = freezed,Object? gardenHealthH = freezed,Object? dominantEmotion = freezed,Object? entryCount = null,Object? triggeredTier = freezed,Object? triggerReasonKey = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,avgMoodScore: freezed == avgMoodScore ? _self.avgMoodScore : avgMoodScore // ignore: cast_nullable_to_non_nullable
as double?,gardenHealthH: freezed == gardenHealthH ? _self.gardenHealthH : gardenHealthH // ignore: cast_nullable_to_non_nullable
as double?,dominantEmotion: freezed == dominantEmotion ? _self.dominantEmotion : dominantEmotion // ignore: cast_nullable_to_non_nullable
as MoodType?,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,triggeredTier: freezed == triggeredTier ? _self.triggeredTier : triggeredTier // ignore: cast_nullable_to_non_nullable
as Tier?,triggerReasonKey: freezed == triggerReasonKey ? _self.triggerReasonKey : triggerReasonKey // ignore: cast_nullable_to_non_nullable
as PatternEngineTriggerKind?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyInsight].
extension DailyInsightPatterns on DailyInsight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyInsight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyInsight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyInsight value)  $default,){
final _that = this;
switch (_that) {
case _DailyInsight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyInsight value)?  $default,){
final _that = this;
switch (_that) {
case _DailyInsight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  double? avgMoodScore,  double? gardenHealthH,  MoodType? dominantEmotion,  int entryCount,  Tier? triggeredTier,  PatternEngineTriggerKind? triggerReasonKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyInsight() when $default != null:
return $default(_that.date,_that.avgMoodScore,_that.gardenHealthH,_that.dominantEmotion,_that.entryCount,_that.triggeredTier,_that.triggerReasonKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  double? avgMoodScore,  double? gardenHealthH,  MoodType? dominantEmotion,  int entryCount,  Tier? triggeredTier,  PatternEngineTriggerKind? triggerReasonKey)  $default,) {final _that = this;
switch (_that) {
case _DailyInsight():
return $default(_that.date,_that.avgMoodScore,_that.gardenHealthH,_that.dominantEmotion,_that.entryCount,_that.triggeredTier,_that.triggerReasonKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  double? avgMoodScore,  double? gardenHealthH,  MoodType? dominantEmotion,  int entryCount,  Tier? triggeredTier,  PatternEngineTriggerKind? triggerReasonKey)?  $default,) {final _that = this;
switch (_that) {
case _DailyInsight() when $default != null:
return $default(_that.date,_that.avgMoodScore,_that.gardenHealthH,_that.dominantEmotion,_that.entryCount,_that.triggeredTier,_that.triggerReasonKey);case _:
  return null;

}
}

}

/// @nodoc


class _DailyInsight implements DailyInsight {
  const _DailyInsight({required this.date, required this.avgMoodScore, required this.gardenHealthH, required this.dominantEmotion, required this.entryCount, required this.triggeredTier, this.triggerReasonKey = null});
  

@override final  DateTime date;
@override final  double? avgMoodScore;
@override final  double? gardenHealthH;
@override final  MoodType? dominantEmotion;
@override final  int entryCount;
@override final  Tier? triggeredTier;
@override@JsonKey() final  PatternEngineTriggerKind? triggerReasonKey;

/// Create a copy of DailyInsight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyInsightCopyWith<_DailyInsight> get copyWith => __$DailyInsightCopyWithImpl<_DailyInsight>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyInsight&&(identical(other.date, date) || other.date == date)&&(identical(other.avgMoodScore, avgMoodScore) || other.avgMoodScore == avgMoodScore)&&(identical(other.gardenHealthH, gardenHealthH) || other.gardenHealthH == gardenHealthH)&&(identical(other.dominantEmotion, dominantEmotion) || other.dominantEmotion == dominantEmotion)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.triggeredTier, triggeredTier) || other.triggeredTier == triggeredTier)&&(identical(other.triggerReasonKey, triggerReasonKey) || other.triggerReasonKey == triggerReasonKey));
}


@override
int get hashCode => Object.hash(runtimeType,date,avgMoodScore,gardenHealthH,dominantEmotion,entryCount,triggeredTier,triggerReasonKey);

@override
String toString() {
  return 'DailyInsight(date: $date, avgMoodScore: $avgMoodScore, gardenHealthH: $gardenHealthH, dominantEmotion: $dominantEmotion, entryCount: $entryCount, triggeredTier: $triggeredTier, triggerReasonKey: $triggerReasonKey)';
}


}

/// @nodoc
abstract mixin class _$DailyInsightCopyWith<$Res> implements $DailyInsightCopyWith<$Res> {
  factory _$DailyInsightCopyWith(_DailyInsight value, $Res Function(_DailyInsight) _then) = __$DailyInsightCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, double? avgMoodScore, double? gardenHealthH, MoodType? dominantEmotion, int entryCount, Tier? triggeredTier, PatternEngineTriggerKind? triggerReasonKey
});




}
/// @nodoc
class __$DailyInsightCopyWithImpl<$Res>
    implements _$DailyInsightCopyWith<$Res> {
  __$DailyInsightCopyWithImpl(this._self, this._then);

  final _DailyInsight _self;
  final $Res Function(_DailyInsight) _then;

/// Create a copy of DailyInsight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? avgMoodScore = freezed,Object? gardenHealthH = freezed,Object? dominantEmotion = freezed,Object? entryCount = null,Object? triggeredTier = freezed,Object? triggerReasonKey = freezed,}) {
  return _then(_DailyInsight(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,avgMoodScore: freezed == avgMoodScore ? _self.avgMoodScore : avgMoodScore // ignore: cast_nullable_to_non_nullable
as double?,gardenHealthH: freezed == gardenHealthH ? _self.gardenHealthH : gardenHealthH // ignore: cast_nullable_to_non_nullable
as double?,dominantEmotion: freezed == dominantEmotion ? _self.dominantEmotion : dominantEmotion // ignore: cast_nullable_to_non_nullable
as MoodType?,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,triggeredTier: freezed == triggeredTier ? _self.triggeredTier : triggeredTier // ignore: cast_nullable_to_non_nullable
as Tier?,triggerReasonKey: freezed == triggerReasonKey ? _self.triggerReasonKey : triggerReasonKey // ignore: cast_nullable_to_non_nullable
as PatternEngineTriggerKind?,
  ));
}


}

// dart format on
