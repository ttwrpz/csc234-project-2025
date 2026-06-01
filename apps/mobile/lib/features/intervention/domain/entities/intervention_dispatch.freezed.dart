// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intervention_dispatch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InterventionDispatch {

 Tier get tier;/// Quote text + `'\n\n'` + `DisclaimerCopy.notificationFooter`.
/// Always contains the footer as a suffix.
 String get body;/// Semantic CTA keys for the renderer. Order matches reading order.
/// Tier 1: `['open_breathing', 'opt_out']`.
/// Tier 2: `['open_journal', 'opt_out']`.
/// Tier 3: `['open_crisis', 'opt_out']` - crisis screen carries the
/// Hotline 1323 link.
 List<String> get ctas;/// UUID-ish id for the audit record at
/// `users/{uid}/interventions/{dispatchId}`. Deterministic on
/// `(tier, dispatchedAt.millisecondsSinceEpoch)` so a retry never
/// emits a second row.
 String get dispatchId;/// Stable id of the [Quote] that produced `body`. Persisted in the
/// audit record; never surfaced to the user.
 String get quoteId; DateTime get dispatchedAt;
/// Create a copy of InterventionDispatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterventionDispatchCopyWith<InterventionDispatch> get copyWith => _$InterventionDispatchCopyWithImpl<InterventionDispatch>(this as InterventionDispatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterventionDispatch&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.ctas, ctas)&&(identical(other.dispatchId, dispatchId) || other.dispatchId == dispatchId)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt));
}


@override
int get hashCode => Object.hash(runtimeType,tier,body,const DeepCollectionEquality().hash(ctas),dispatchId,quoteId,dispatchedAt);

@override
String toString() {
  return 'InterventionDispatch(tier: $tier, body: $body, ctas: $ctas, dispatchId: $dispatchId, quoteId: $quoteId, dispatchedAt: $dispatchedAt)';
}


}

/// @nodoc
abstract mixin class $InterventionDispatchCopyWith<$Res>  {
  factory $InterventionDispatchCopyWith(InterventionDispatch value, $Res Function(InterventionDispatch) _then) = _$InterventionDispatchCopyWithImpl;
@useResult
$Res call({
 Tier tier, String body, List<String> ctas, String dispatchId, String quoteId, DateTime dispatchedAt
});




}
/// @nodoc
class _$InterventionDispatchCopyWithImpl<$Res>
    implements $InterventionDispatchCopyWith<$Res> {
  _$InterventionDispatchCopyWithImpl(this._self, this._then);

  final InterventionDispatch _self;
  final $Res Function(InterventionDispatch) _then;

/// Create a copy of InterventionDispatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,Object? body = null,Object? ctas = null,Object? dispatchId = null,Object? quoteId = null,Object? dispatchedAt = null,}) {
  return _then(_self.copyWith(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as Tier,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,ctas: null == ctas ? _self.ctas : ctas // ignore: cast_nullable_to_non_nullable
as List<String>,dispatchId: null == dispatchId ? _self.dispatchId : dispatchId // ignore: cast_nullable_to_non_nullable
as String,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,dispatchedAt: null == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InterventionDispatch].
extension InterventionDispatchPatterns on InterventionDispatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InterventionDispatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InterventionDispatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InterventionDispatch value)  $default,){
final _that = this;
switch (_that) {
case _InterventionDispatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InterventionDispatch value)?  $default,){
final _that = this;
switch (_that) {
case _InterventionDispatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Tier tier,  String body,  List<String> ctas,  String dispatchId,  String quoteId,  DateTime dispatchedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InterventionDispatch() when $default != null:
return $default(_that.tier,_that.body,_that.ctas,_that.dispatchId,_that.quoteId,_that.dispatchedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Tier tier,  String body,  List<String> ctas,  String dispatchId,  String quoteId,  DateTime dispatchedAt)  $default,) {final _that = this;
switch (_that) {
case _InterventionDispatch():
return $default(_that.tier,_that.body,_that.ctas,_that.dispatchId,_that.quoteId,_that.dispatchedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Tier tier,  String body,  List<String> ctas,  String dispatchId,  String quoteId,  DateTime dispatchedAt)?  $default,) {final _that = this;
switch (_that) {
case _InterventionDispatch() when $default != null:
return $default(_that.tier,_that.body,_that.ctas,_that.dispatchId,_that.quoteId,_that.dispatchedAt);case _:
  return null;

}
}

}

/// @nodoc


class _InterventionDispatch implements InterventionDispatch {
  const _InterventionDispatch({required this.tier, required this.body, required final  List<String> ctas, required this.dispatchId, required this.quoteId, required this.dispatchedAt}): _ctas = ctas;
  

@override final  Tier tier;
/// Quote text + `'\n\n'` + `DisclaimerCopy.notificationFooter`.
/// Always contains the footer as a suffix.
@override final  String body;
/// Semantic CTA keys for the renderer. Order matches reading order.
/// Tier 1: `['open_breathing', 'opt_out']`.
/// Tier 2: `['open_journal', 'opt_out']`.
/// Tier 3: `['open_crisis', 'opt_out']` - crisis screen carries the
/// Hotline 1323 link.
 final  List<String> _ctas;
/// Semantic CTA keys for the renderer. Order matches reading order.
/// Tier 1: `['open_breathing', 'opt_out']`.
/// Tier 2: `['open_journal', 'opt_out']`.
/// Tier 3: `['open_crisis', 'opt_out']` - crisis screen carries the
/// Hotline 1323 link.
@override List<String> get ctas {
  if (_ctas is EqualUnmodifiableListView) return _ctas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ctas);
}

/// UUID-ish id for the audit record at
/// `users/{uid}/interventions/{dispatchId}`. Deterministic on
/// `(tier, dispatchedAt.millisecondsSinceEpoch)` so a retry never
/// emits a second row.
@override final  String dispatchId;
/// Stable id of the [Quote] that produced `body`. Persisted in the
/// audit record; never surfaced to the user.
@override final  String quoteId;
@override final  DateTime dispatchedAt;

/// Create a copy of InterventionDispatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterventionDispatchCopyWith<_InterventionDispatch> get copyWith => __$InterventionDispatchCopyWithImpl<_InterventionDispatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InterventionDispatch&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._ctas, _ctas)&&(identical(other.dispatchId, dispatchId) || other.dispatchId == dispatchId)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt));
}


@override
int get hashCode => Object.hash(runtimeType,tier,body,const DeepCollectionEquality().hash(_ctas),dispatchId,quoteId,dispatchedAt);

@override
String toString() {
  return 'InterventionDispatch(tier: $tier, body: $body, ctas: $ctas, dispatchId: $dispatchId, quoteId: $quoteId, dispatchedAt: $dispatchedAt)';
}


}

/// @nodoc
abstract mixin class _$InterventionDispatchCopyWith<$Res> implements $InterventionDispatchCopyWith<$Res> {
  factory _$InterventionDispatchCopyWith(_InterventionDispatch value, $Res Function(_InterventionDispatch) _then) = __$InterventionDispatchCopyWithImpl;
@override @useResult
$Res call({
 Tier tier, String body, List<String> ctas, String dispatchId, String quoteId, DateTime dispatchedAt
});




}
/// @nodoc
class __$InterventionDispatchCopyWithImpl<$Res>
    implements _$InterventionDispatchCopyWith<$Res> {
  __$InterventionDispatchCopyWithImpl(this._self, this._then);

  final _InterventionDispatch _self;
  final $Res Function(_InterventionDispatch) _then;

/// Create a copy of InterventionDispatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier = null,Object? body = null,Object? ctas = null,Object? dispatchId = null,Object? quoteId = null,Object? dispatchedAt = null,}) {
  return _then(_InterventionDispatch(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as Tier,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,ctas: null == ctas ? _self._ctas : ctas // ignore: cast_nullable_to_non_nullable
as List<String>,dispatchId: null == dispatchId ? _self.dispatchId : dispatchId // ignore: cast_nullable_to_non_nullable
as String,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,dispatchedAt: null == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
