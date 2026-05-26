// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_flags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeatureFlags {

 bool get aiPatternAnalysisEnabled; bool get geminiDetectionEnabled;/// Gates the cheer-up dispatcher path (`cheer_up_controller` +
/// `sendCheerUpPush` Cloud Function). Default `false`: the
/// client-side Pattern Engine writes `users/{uid}/patterns/{date}`
/// regardless, but no notification fires. Flip to `true` once the
/// dispatcher reads `patterns/{date}.triggeredTier`, the Quote
/// Library safety filter is attached, and the bipolar/medical
/// disclaimer footer is in place.
 bool get interventionDispatchEnabled;
/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureFlagsCopyWith<FeatureFlags> get copyWith => _$FeatureFlagsCopyWithImpl<FeatureFlags>(this as FeatureFlags, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureFlags&&(identical(other.aiPatternAnalysisEnabled, aiPatternAnalysisEnabled) || other.aiPatternAnalysisEnabled == aiPatternAnalysisEnabled)&&(identical(other.geminiDetectionEnabled, geminiDetectionEnabled) || other.geminiDetectionEnabled == geminiDetectionEnabled)&&(identical(other.interventionDispatchEnabled, interventionDispatchEnabled) || other.interventionDispatchEnabled == interventionDispatchEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,aiPatternAnalysisEnabled,geminiDetectionEnabled,interventionDispatchEnabled);

@override
String toString() {
  return 'FeatureFlags(aiPatternAnalysisEnabled: $aiPatternAnalysisEnabled, geminiDetectionEnabled: $geminiDetectionEnabled, interventionDispatchEnabled: $interventionDispatchEnabled)';
}


}

/// @nodoc
abstract mixin class $FeatureFlagsCopyWith<$Res>  {
  factory $FeatureFlagsCopyWith(FeatureFlags value, $Res Function(FeatureFlags) _then) = _$FeatureFlagsCopyWithImpl;
@useResult
$Res call({
 bool aiPatternAnalysisEnabled, bool geminiDetectionEnabled, bool interventionDispatchEnabled
});




}
/// @nodoc
class _$FeatureFlagsCopyWithImpl<$Res>
    implements $FeatureFlagsCopyWith<$Res> {
  _$FeatureFlagsCopyWithImpl(this._self, this._then);

  final FeatureFlags _self;
  final $Res Function(FeatureFlags) _then;

/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aiPatternAnalysisEnabled = null,Object? geminiDetectionEnabled = null,Object? interventionDispatchEnabled = null,}) {
  return _then(_self.copyWith(
aiPatternAnalysisEnabled: null == aiPatternAnalysisEnabled ? _self.aiPatternAnalysisEnabled : aiPatternAnalysisEnabled // ignore: cast_nullable_to_non_nullable
as bool,geminiDetectionEnabled: null == geminiDetectionEnabled ? _self.geminiDetectionEnabled : geminiDetectionEnabled // ignore: cast_nullable_to_non_nullable
as bool,interventionDispatchEnabled: null == interventionDispatchEnabled ? _self.interventionDispatchEnabled : interventionDispatchEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureFlags].
extension FeatureFlagsPatterns on FeatureFlags {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureFlags value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureFlags value)  $default,){
final _that = this;
switch (_that) {
case _FeatureFlags():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureFlags value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool aiPatternAnalysisEnabled,  bool geminiDetectionEnabled,  bool interventionDispatchEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
return $default(_that.aiPatternAnalysisEnabled,_that.geminiDetectionEnabled,_that.interventionDispatchEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool aiPatternAnalysisEnabled,  bool geminiDetectionEnabled,  bool interventionDispatchEnabled)  $default,) {final _that = this;
switch (_that) {
case _FeatureFlags():
return $default(_that.aiPatternAnalysisEnabled,_that.geminiDetectionEnabled,_that.interventionDispatchEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool aiPatternAnalysisEnabled,  bool geminiDetectionEnabled,  bool interventionDispatchEnabled)?  $default,) {final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
return $default(_that.aiPatternAnalysisEnabled,_that.geminiDetectionEnabled,_that.interventionDispatchEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _FeatureFlags extends FeatureFlags {
  const _FeatureFlags({required this.aiPatternAnalysisEnabled, required this.geminiDetectionEnabled, required this.interventionDispatchEnabled}): super._();
  

@override final  bool aiPatternAnalysisEnabled;
@override final  bool geminiDetectionEnabled;
/// Gates the cheer-up dispatcher path (`cheer_up_controller` +
/// `sendCheerUpPush` Cloud Function). Default `false`: the
/// client-side Pattern Engine writes `users/{uid}/patterns/{date}`
/// regardless, but no notification fires. Flip to `true` once the
/// dispatcher reads `patterns/{date}.triggeredTier`, the Quote
/// Library safety filter is attached, and the bipolar/medical
/// disclaimer footer is in place.
@override final  bool interventionDispatchEnabled;

/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureFlagsCopyWith<_FeatureFlags> get copyWith => __$FeatureFlagsCopyWithImpl<_FeatureFlags>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureFlags&&(identical(other.aiPatternAnalysisEnabled, aiPatternAnalysisEnabled) || other.aiPatternAnalysisEnabled == aiPatternAnalysisEnabled)&&(identical(other.geminiDetectionEnabled, geminiDetectionEnabled) || other.geminiDetectionEnabled == geminiDetectionEnabled)&&(identical(other.interventionDispatchEnabled, interventionDispatchEnabled) || other.interventionDispatchEnabled == interventionDispatchEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,aiPatternAnalysisEnabled,geminiDetectionEnabled,interventionDispatchEnabled);

@override
String toString() {
  return 'FeatureFlags(aiPatternAnalysisEnabled: $aiPatternAnalysisEnabled, geminiDetectionEnabled: $geminiDetectionEnabled, interventionDispatchEnabled: $interventionDispatchEnabled)';
}


}

/// @nodoc
abstract mixin class _$FeatureFlagsCopyWith<$Res> implements $FeatureFlagsCopyWith<$Res> {
  factory _$FeatureFlagsCopyWith(_FeatureFlags value, $Res Function(_FeatureFlags) _then) = __$FeatureFlagsCopyWithImpl;
@override @useResult
$Res call({
 bool aiPatternAnalysisEnabled, bool geminiDetectionEnabled, bool interventionDispatchEnabled
});




}
/// @nodoc
class __$FeatureFlagsCopyWithImpl<$Res>
    implements _$FeatureFlagsCopyWith<$Res> {
  __$FeatureFlagsCopyWithImpl(this._self, this._then);

  final _FeatureFlags _self;
  final $Res Function(_FeatureFlags) _then;

/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aiPatternAnalysisEnabled = null,Object? geminiDetectionEnabled = null,Object? interventionDispatchEnabled = null,}) {
  return _then(_FeatureFlags(
aiPatternAnalysisEnabled: null == aiPatternAnalysisEnabled ? _self.aiPatternAnalysisEnabled : aiPatternAnalysisEnabled // ignore: cast_nullable_to_non_nullable
as bool,geminiDetectionEnabled: null == geminiDetectionEnabled ? _self.geminiDetectionEnabled : geminiDetectionEnabled // ignore: cast_nullable_to_non_nullable
as bool,interventionDispatchEnabled: null == interventionDispatchEnabled ? _self.interventionDispatchEnabled : interventionDispatchEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
