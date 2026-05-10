// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pattern_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PatternResult {

 String get dateId; double? get mannKendallZ; int get slidingNegCount; int get consecutiveHighIntensity; double? get zScoreToday; double get cusumC; Tier? get triggeredTier; int get schemaV;
/// Create a copy of PatternResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatternResultCopyWith<PatternResult> get copyWith => _$PatternResultCopyWithImpl<PatternResult>(this as PatternResult, _$identity);

  /// Serializes this PatternResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatternResult&&(identical(other.dateId, dateId) || other.dateId == dateId)&&(identical(other.mannKendallZ, mannKendallZ) || other.mannKendallZ == mannKendallZ)&&(identical(other.slidingNegCount, slidingNegCount) || other.slidingNegCount == slidingNegCount)&&(identical(other.consecutiveHighIntensity, consecutiveHighIntensity) || other.consecutiveHighIntensity == consecutiveHighIntensity)&&(identical(other.zScoreToday, zScoreToday) || other.zScoreToday == zScoreToday)&&(identical(other.cusumC, cusumC) || other.cusumC == cusumC)&&(identical(other.triggeredTier, triggeredTier) || other.triggeredTier == triggeredTier)&&(identical(other.schemaV, schemaV) || other.schemaV == schemaV));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dateId,mannKendallZ,slidingNegCount,consecutiveHighIntensity,zScoreToday,cusumC,triggeredTier,schemaV);

@override
String toString() {
  return 'PatternResult(dateId: $dateId, mannKendallZ: $mannKendallZ, slidingNegCount: $slidingNegCount, consecutiveHighIntensity: $consecutiveHighIntensity, zScoreToday: $zScoreToday, cusumC: $cusumC, triggeredTier: $triggeredTier, schemaV: $schemaV)';
}


}

/// @nodoc
abstract mixin class $PatternResultCopyWith<$Res>  {
  factory $PatternResultCopyWith(PatternResult value, $Res Function(PatternResult) _then) = _$PatternResultCopyWithImpl;
@useResult
$Res call({
 String dateId, double? mannKendallZ, int slidingNegCount, int consecutiveHighIntensity, double? zScoreToday, double cusumC, Tier? triggeredTier, int schemaV
});




}
/// @nodoc
class _$PatternResultCopyWithImpl<$Res>
    implements $PatternResultCopyWith<$Res> {
  _$PatternResultCopyWithImpl(this._self, this._then);

  final PatternResult _self;
  final $Res Function(PatternResult) _then;

/// Create a copy of PatternResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dateId = null,Object? mannKendallZ = freezed,Object? slidingNegCount = null,Object? consecutiveHighIntensity = null,Object? zScoreToday = freezed,Object? cusumC = null,Object? triggeredTier = freezed,Object? schemaV = null,}) {
  return _then(_self.copyWith(
dateId: null == dateId ? _self.dateId : dateId // ignore: cast_nullable_to_non_nullable
as String,mannKendallZ: freezed == mannKendallZ ? _self.mannKendallZ : mannKendallZ // ignore: cast_nullable_to_non_nullable
as double?,slidingNegCount: null == slidingNegCount ? _self.slidingNegCount : slidingNegCount // ignore: cast_nullable_to_non_nullable
as int,consecutiveHighIntensity: null == consecutiveHighIntensity ? _self.consecutiveHighIntensity : consecutiveHighIntensity // ignore: cast_nullable_to_non_nullable
as int,zScoreToday: freezed == zScoreToday ? _self.zScoreToday : zScoreToday // ignore: cast_nullable_to_non_nullable
as double?,cusumC: null == cusumC ? _self.cusumC : cusumC // ignore: cast_nullable_to_non_nullable
as double,triggeredTier: freezed == triggeredTier ? _self.triggeredTier : triggeredTier // ignore: cast_nullable_to_non_nullable
as Tier?,schemaV: null == schemaV ? _self.schemaV : schemaV // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PatternResult].
extension PatternResultPatterns on PatternResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatternResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatternResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatternResult value)  $default,){
final _that = this;
switch (_that) {
case _PatternResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatternResult value)?  $default,){
final _that = this;
switch (_that) {
case _PatternResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dateId,  double? mannKendallZ,  int slidingNegCount,  int consecutiveHighIntensity,  double? zScoreToday,  double cusumC,  Tier? triggeredTier,  int schemaV)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatternResult() when $default != null:
return $default(_that.dateId,_that.mannKendallZ,_that.slidingNegCount,_that.consecutiveHighIntensity,_that.zScoreToday,_that.cusumC,_that.triggeredTier,_that.schemaV);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dateId,  double? mannKendallZ,  int slidingNegCount,  int consecutiveHighIntensity,  double? zScoreToday,  double cusumC,  Tier? triggeredTier,  int schemaV)  $default,) {final _that = this;
switch (_that) {
case _PatternResult():
return $default(_that.dateId,_that.mannKendallZ,_that.slidingNegCount,_that.consecutiveHighIntensity,_that.zScoreToday,_that.cusumC,_that.triggeredTier,_that.schemaV);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dateId,  double? mannKendallZ,  int slidingNegCount,  int consecutiveHighIntensity,  double? zScoreToday,  double cusumC,  Tier? triggeredTier,  int schemaV)?  $default,) {final _that = this;
switch (_that) {
case _PatternResult() when $default != null:
return $default(_that.dateId,_that.mannKendallZ,_that.slidingNegCount,_that.consecutiveHighIntensity,_that.zScoreToday,_that.cusumC,_that.triggeredTier,_that.schemaV);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatternResult implements PatternResult {
  const _PatternResult({required this.dateId, required this.mannKendallZ, required this.slidingNegCount, required this.consecutiveHighIntensity, required this.zScoreToday, required this.cusumC, required this.triggeredTier, this.schemaV = 1});
  factory _PatternResult.fromJson(Map<String, dynamic> json) => _$PatternResultFromJson(json);

@override final  String dateId;
@override final  double? mannKendallZ;
@override final  int slidingNegCount;
@override final  int consecutiveHighIntensity;
@override final  double? zScoreToday;
@override final  double cusumC;
@override final  Tier? triggeredTier;
@override@JsonKey() final  int schemaV;

/// Create a copy of PatternResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatternResultCopyWith<_PatternResult> get copyWith => __$PatternResultCopyWithImpl<_PatternResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatternResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatternResult&&(identical(other.dateId, dateId) || other.dateId == dateId)&&(identical(other.mannKendallZ, mannKendallZ) || other.mannKendallZ == mannKendallZ)&&(identical(other.slidingNegCount, slidingNegCount) || other.slidingNegCount == slidingNegCount)&&(identical(other.consecutiveHighIntensity, consecutiveHighIntensity) || other.consecutiveHighIntensity == consecutiveHighIntensity)&&(identical(other.zScoreToday, zScoreToday) || other.zScoreToday == zScoreToday)&&(identical(other.cusumC, cusumC) || other.cusumC == cusumC)&&(identical(other.triggeredTier, triggeredTier) || other.triggeredTier == triggeredTier)&&(identical(other.schemaV, schemaV) || other.schemaV == schemaV));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dateId,mannKendallZ,slidingNegCount,consecutiveHighIntensity,zScoreToday,cusumC,triggeredTier,schemaV);

@override
String toString() {
  return 'PatternResult(dateId: $dateId, mannKendallZ: $mannKendallZ, slidingNegCount: $slidingNegCount, consecutiveHighIntensity: $consecutiveHighIntensity, zScoreToday: $zScoreToday, cusumC: $cusumC, triggeredTier: $triggeredTier, schemaV: $schemaV)';
}


}

/// @nodoc
abstract mixin class _$PatternResultCopyWith<$Res> implements $PatternResultCopyWith<$Res> {
  factory _$PatternResultCopyWith(_PatternResult value, $Res Function(_PatternResult) _then) = __$PatternResultCopyWithImpl;
@override @useResult
$Res call({
 String dateId, double? mannKendallZ, int slidingNegCount, int consecutiveHighIntensity, double? zScoreToday, double cusumC, Tier? triggeredTier, int schemaV
});




}
/// @nodoc
class __$PatternResultCopyWithImpl<$Res>
    implements _$PatternResultCopyWith<$Res> {
  __$PatternResultCopyWithImpl(this._self, this._then);

  final _PatternResult _self;
  final $Res Function(_PatternResult) _then;

/// Create a copy of PatternResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dateId = null,Object? mannKendallZ = freezed,Object? slidingNegCount = null,Object? consecutiveHighIntensity = null,Object? zScoreToday = freezed,Object? cusumC = null,Object? triggeredTier = freezed,Object? schemaV = null,}) {
  return _then(_PatternResult(
dateId: null == dateId ? _self.dateId : dateId // ignore: cast_nullable_to_non_nullable
as String,mannKendallZ: freezed == mannKendallZ ? _self.mannKendallZ : mannKendallZ // ignore: cast_nullable_to_non_nullable
as double?,slidingNegCount: null == slidingNegCount ? _self.slidingNegCount : slidingNegCount // ignore: cast_nullable_to_non_nullable
as int,consecutiveHighIntensity: null == consecutiveHighIntensity ? _self.consecutiveHighIntensity : consecutiveHighIntensity // ignore: cast_nullable_to_non_nullable
as int,zScoreToday: freezed == zScoreToday ? _self.zScoreToday : zScoreToday // ignore: cast_nullable_to_non_nullable
as double?,cusumC: null == cusumC ? _self.cusumC : cusumC // ignore: cast_nullable_to_non_nullable
as double,triggeredTier: freezed == triggeredTier ? _self.triggeredTier : triggeredTier // ignore: cast_nullable_to_non_nullable
as Tier?,schemaV: null == schemaV ? _self.schemaV : schemaV // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
