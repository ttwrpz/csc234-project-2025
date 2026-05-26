// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intervention_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InterventionRecord {

 String get dispatchId; Tier get tier; DateTime get dispatchedAt; String get quoteId;/// 48h gate the dispatcher enforces. Persisted so the Cloud Function
/// (or admin tooling) can audit the cooldown without re-deriving from
/// the anchor doc.
 DateTime get cooldownUntil;/// True when the user tapped "I'm okay". One-way false → true; the
/// rules enforce this at the wire level.
 bool get optedOut; int get schemaV;
/// Create a copy of InterventionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterventionRecordCopyWith<InterventionRecord> get copyWith => _$InterventionRecordCopyWithImpl<InterventionRecord>(this as InterventionRecord, _$identity);

  /// Serializes this InterventionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterventionRecord&&(identical(other.dispatchId, dispatchId) || other.dispatchId == dispatchId)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.cooldownUntil, cooldownUntil) || other.cooldownUntil == cooldownUntil)&&(identical(other.optedOut, optedOut) || other.optedOut == optedOut)&&(identical(other.schemaV, schemaV) || other.schemaV == schemaV));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dispatchId,tier,dispatchedAt,quoteId,cooldownUntil,optedOut,schemaV);

@override
String toString() {
  return 'InterventionRecord(dispatchId: $dispatchId, tier: $tier, dispatchedAt: $dispatchedAt, quoteId: $quoteId, cooldownUntil: $cooldownUntil, optedOut: $optedOut, schemaV: $schemaV)';
}


}

/// @nodoc
abstract mixin class $InterventionRecordCopyWith<$Res>  {
  factory $InterventionRecordCopyWith(InterventionRecord value, $Res Function(InterventionRecord) _then) = _$InterventionRecordCopyWithImpl;
@useResult
$Res call({
 String dispatchId, Tier tier, DateTime dispatchedAt, String quoteId, DateTime cooldownUntil, bool optedOut, int schemaV
});




}
/// @nodoc
class _$InterventionRecordCopyWithImpl<$Res>
    implements $InterventionRecordCopyWith<$Res> {
  _$InterventionRecordCopyWithImpl(this._self, this._then);

  final InterventionRecord _self;
  final $Res Function(InterventionRecord) _then;

/// Create a copy of InterventionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dispatchId = null,Object? tier = null,Object? dispatchedAt = null,Object? quoteId = null,Object? cooldownUntil = null,Object? optedOut = null,Object? schemaV = null,}) {
  return _then(_self.copyWith(
dispatchId: null == dispatchId ? _self.dispatchId : dispatchId // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as Tier,dispatchedAt: null == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,cooldownUntil: null == cooldownUntil ? _self.cooldownUntil : cooldownUntil // ignore: cast_nullable_to_non_nullable
as DateTime,optedOut: null == optedOut ? _self.optedOut : optedOut // ignore: cast_nullable_to_non_nullable
as bool,schemaV: null == schemaV ? _self.schemaV : schemaV // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InterventionRecord].
extension InterventionRecordPatterns on InterventionRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InterventionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InterventionRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InterventionRecord value)  $default,){
final _that = this;
switch (_that) {
case _InterventionRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InterventionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _InterventionRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dispatchId,  Tier tier,  DateTime dispatchedAt,  String quoteId,  DateTime cooldownUntil,  bool optedOut,  int schemaV)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InterventionRecord() when $default != null:
return $default(_that.dispatchId,_that.tier,_that.dispatchedAt,_that.quoteId,_that.cooldownUntil,_that.optedOut,_that.schemaV);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dispatchId,  Tier tier,  DateTime dispatchedAt,  String quoteId,  DateTime cooldownUntil,  bool optedOut,  int schemaV)  $default,) {final _that = this;
switch (_that) {
case _InterventionRecord():
return $default(_that.dispatchId,_that.tier,_that.dispatchedAt,_that.quoteId,_that.cooldownUntil,_that.optedOut,_that.schemaV);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dispatchId,  Tier tier,  DateTime dispatchedAt,  String quoteId,  DateTime cooldownUntil,  bool optedOut,  int schemaV)?  $default,) {final _that = this;
switch (_that) {
case _InterventionRecord() when $default != null:
return $default(_that.dispatchId,_that.tier,_that.dispatchedAt,_that.quoteId,_that.cooldownUntil,_that.optedOut,_that.schemaV);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InterventionRecord implements InterventionRecord {
  const _InterventionRecord({required this.dispatchId, required this.tier, required this.dispatchedAt, required this.quoteId, required this.cooldownUntil, this.optedOut = false, this.schemaV = 1});
  factory _InterventionRecord.fromJson(Map<String, dynamic> json) => _$InterventionRecordFromJson(json);

@override final  String dispatchId;
@override final  Tier tier;
@override final  DateTime dispatchedAt;
@override final  String quoteId;
/// 48h gate the dispatcher enforces. Persisted so the Cloud Function
/// (or admin tooling) can audit the cooldown without re-deriving from
/// the anchor doc.
@override final  DateTime cooldownUntil;
/// True when the user tapped "I'm okay". One-way false → true; the
/// rules enforce this at the wire level.
@override@JsonKey() final  bool optedOut;
@override@JsonKey() final  int schemaV;

/// Create a copy of InterventionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterventionRecordCopyWith<_InterventionRecord> get copyWith => __$InterventionRecordCopyWithImpl<_InterventionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InterventionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InterventionRecord&&(identical(other.dispatchId, dispatchId) || other.dispatchId == dispatchId)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.cooldownUntil, cooldownUntil) || other.cooldownUntil == cooldownUntil)&&(identical(other.optedOut, optedOut) || other.optedOut == optedOut)&&(identical(other.schemaV, schemaV) || other.schemaV == schemaV));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dispatchId,tier,dispatchedAt,quoteId,cooldownUntil,optedOut,schemaV);

@override
String toString() {
  return 'InterventionRecord(dispatchId: $dispatchId, tier: $tier, dispatchedAt: $dispatchedAt, quoteId: $quoteId, cooldownUntil: $cooldownUntil, optedOut: $optedOut, schemaV: $schemaV)';
}


}

/// @nodoc
abstract mixin class _$InterventionRecordCopyWith<$Res> implements $InterventionRecordCopyWith<$Res> {
  factory _$InterventionRecordCopyWith(_InterventionRecord value, $Res Function(_InterventionRecord) _then) = __$InterventionRecordCopyWithImpl;
@override @useResult
$Res call({
 String dispatchId, Tier tier, DateTime dispatchedAt, String quoteId, DateTime cooldownUntil, bool optedOut, int schemaV
});




}
/// @nodoc
class __$InterventionRecordCopyWithImpl<$Res>
    implements _$InterventionRecordCopyWith<$Res> {
  __$InterventionRecordCopyWithImpl(this._self, this._then);

  final _InterventionRecord _self;
  final $Res Function(_InterventionRecord) _then;

/// Create a copy of InterventionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dispatchId = null,Object? tier = null,Object? dispatchedAt = null,Object? quoteId = null,Object? cooldownUntil = null,Object? optedOut = null,Object? schemaV = null,}) {
  return _then(_InterventionRecord(
dispatchId: null == dispatchId ? _self.dispatchId : dispatchId // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as Tier,dispatchedAt: null == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,cooldownUntil: null == cooldownUntil ? _self.cooldownUntil : cooldownUntil // ignore: cast_nullable_to_non_nullable
as DateTime,optedOut: null == optedOut ? _self.optedOut : optedOut // ignore: cast_nullable_to_non_nullable
as bool,schemaV: null == schemaV ? _self.schemaV : schemaV // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
