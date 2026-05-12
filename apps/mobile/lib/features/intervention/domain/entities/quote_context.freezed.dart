// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuoteContext {

/// ISO-8601 weekId (`YYYY-Www`) — for log correlation only.
 String get weekId;/// Today's average score `S` in [-1, +1]. Negative = rough day.
 double get dailyAvgS;/// The most-logged mood today, or null if the user has not logged today.
/// Used by the Cloud Function to pick a template; never echoed back to
/// the user verbatim.
 MoodType? get dominantEmotion;
/// Create a copy of QuoteContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteContextCopyWith<QuoteContext> get copyWith => _$QuoteContextCopyWithImpl<QuoteContext>(this as QuoteContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteContext&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.dailyAvgS, dailyAvgS) || other.dailyAvgS == dailyAvgS)&&(identical(other.dominantEmotion, dominantEmotion) || other.dominantEmotion == dominantEmotion));
}


@override
int get hashCode => Object.hash(runtimeType,weekId,dailyAvgS,dominantEmotion);

@override
String toString() {
  return 'QuoteContext(weekId: $weekId, dailyAvgS: $dailyAvgS, dominantEmotion: $dominantEmotion)';
}


}

/// @nodoc
abstract mixin class $QuoteContextCopyWith<$Res>  {
  factory $QuoteContextCopyWith(QuoteContext value, $Res Function(QuoteContext) _then) = _$QuoteContextCopyWithImpl;
@useResult
$Res call({
 String weekId, double dailyAvgS, MoodType? dominantEmotion
});




}
/// @nodoc
class _$QuoteContextCopyWithImpl<$Res>
    implements $QuoteContextCopyWith<$Res> {
  _$QuoteContextCopyWithImpl(this._self, this._then);

  final QuoteContext _self;
  final $Res Function(QuoteContext) _then;

/// Create a copy of QuoteContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekId = null,Object? dailyAvgS = null,Object? dominantEmotion = freezed,}) {
  return _then(_self.copyWith(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,dailyAvgS: null == dailyAvgS ? _self.dailyAvgS : dailyAvgS // ignore: cast_nullable_to_non_nullable
as double,dominantEmotion: freezed == dominantEmotion ? _self.dominantEmotion : dominantEmotion // ignore: cast_nullable_to_non_nullable
as MoodType?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuoteContext].
extension QuoteContextPatterns on QuoteContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuoteContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuoteContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuoteContext value)  $default,){
final _that = this;
switch (_that) {
case _QuoteContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuoteContext value)?  $default,){
final _that = this;
switch (_that) {
case _QuoteContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekId,  double dailyAvgS,  MoodType? dominantEmotion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuoteContext() when $default != null:
return $default(_that.weekId,_that.dailyAvgS,_that.dominantEmotion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekId,  double dailyAvgS,  MoodType? dominantEmotion)  $default,) {final _that = this;
switch (_that) {
case _QuoteContext():
return $default(_that.weekId,_that.dailyAvgS,_that.dominantEmotion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekId,  double dailyAvgS,  MoodType? dominantEmotion)?  $default,) {final _that = this;
switch (_that) {
case _QuoteContext() when $default != null:
return $default(_that.weekId,_that.dailyAvgS,_that.dominantEmotion);case _:
  return null;

}
}

}

/// @nodoc


class _QuoteContext implements QuoteContext {
  const _QuoteContext({required this.weekId, required this.dailyAvgS, this.dominantEmotion});
  

/// ISO-8601 weekId (`YYYY-Www`) — for log correlation only.
@override final  String weekId;
/// Today's average score `S` in [-1, +1]. Negative = rough day.
@override final  double dailyAvgS;
/// The most-logged mood today, or null if the user has not logged today.
/// Used by the Cloud Function to pick a template; never echoed back to
/// the user verbatim.
@override final  MoodType? dominantEmotion;

/// Create a copy of QuoteContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteContextCopyWith<_QuoteContext> get copyWith => __$QuoteContextCopyWithImpl<_QuoteContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuoteContext&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.dailyAvgS, dailyAvgS) || other.dailyAvgS == dailyAvgS)&&(identical(other.dominantEmotion, dominantEmotion) || other.dominantEmotion == dominantEmotion));
}


@override
int get hashCode => Object.hash(runtimeType,weekId,dailyAvgS,dominantEmotion);

@override
String toString() {
  return 'QuoteContext(weekId: $weekId, dailyAvgS: $dailyAvgS, dominantEmotion: $dominantEmotion)';
}


}

/// @nodoc
abstract mixin class _$QuoteContextCopyWith<$Res> implements $QuoteContextCopyWith<$Res> {
  factory _$QuoteContextCopyWith(_QuoteContext value, $Res Function(_QuoteContext) _then) = __$QuoteContextCopyWithImpl;
@override @useResult
$Res call({
 String weekId, double dailyAvgS, MoodType? dominantEmotion
});




}
/// @nodoc
class __$QuoteContextCopyWithImpl<$Res>
    implements _$QuoteContextCopyWith<$Res> {
  __$QuoteContextCopyWithImpl(this._self, this._then);

  final _QuoteContext _self;
  final $Res Function(_QuoteContext) _then;

/// Create a copy of QuoteContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekId = null,Object? dailyAvgS = null,Object? dominantEmotion = freezed,}) {
  return _then(_QuoteContext(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,dailyAvgS: null == dailyAvgS ? _self.dailyAvgS : dailyAvgS // ignore: cast_nullable_to_non_nullable
as double,dominantEmotion: freezed == dominantEmotion ? _self.dominantEmotion : dominantEmotion // ignore: cast_nullable_to_non_nullable
as MoodType?,
  ));
}


}

// dart format on
