// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notifications_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationsSettings {

 bool get cheerUpEnabled; bool get tier1Enabled; bool get tier2Enabled; bool get tier3Enabled; List<FcmTokenRecord> get tokens; DateTime? get updatedAt;
/// Create a copy of NotificationsSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationsSettingsCopyWith<NotificationsSettings> get copyWith => _$NotificationsSettingsCopyWithImpl<NotificationsSettings>(this as NotificationsSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationsSettings&&(identical(other.cheerUpEnabled, cheerUpEnabled) || other.cheerUpEnabled == cheerUpEnabled)&&(identical(other.tier1Enabled, tier1Enabled) || other.tier1Enabled == tier1Enabled)&&(identical(other.tier2Enabled, tier2Enabled) || other.tier2Enabled == tier2Enabled)&&(identical(other.tier3Enabled, tier3Enabled) || other.tier3Enabled == tier3Enabled)&&const DeepCollectionEquality().equals(other.tokens, tokens)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,cheerUpEnabled,tier1Enabled,tier2Enabled,tier3Enabled,const DeepCollectionEquality().hash(tokens),updatedAt);

@override
String toString() {
  return 'NotificationsSettings(cheerUpEnabled: $cheerUpEnabled, tier1Enabled: $tier1Enabled, tier2Enabled: $tier2Enabled, tier3Enabled: $tier3Enabled, tokens: $tokens, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $NotificationsSettingsCopyWith<$Res>  {
  factory $NotificationsSettingsCopyWith(NotificationsSettings value, $Res Function(NotificationsSettings) _then) = _$NotificationsSettingsCopyWithImpl;
@useResult
$Res call({
 bool cheerUpEnabled, bool tier1Enabled, bool tier2Enabled, bool tier3Enabled, List<FcmTokenRecord> tokens, DateTime? updatedAt
});




}
/// @nodoc
class _$NotificationsSettingsCopyWithImpl<$Res>
    implements $NotificationsSettingsCopyWith<$Res> {
  _$NotificationsSettingsCopyWithImpl(this._self, this._then);

  final NotificationsSettings _self;
  final $Res Function(NotificationsSettings) _then;

/// Create a copy of NotificationsSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cheerUpEnabled = null,Object? tier1Enabled = null,Object? tier2Enabled = null,Object? tier3Enabled = null,Object? tokens = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
cheerUpEnabled: null == cheerUpEnabled ? _self.cheerUpEnabled : cheerUpEnabled // ignore: cast_nullable_to_non_nullable
as bool,tier1Enabled: null == tier1Enabled ? _self.tier1Enabled : tier1Enabled // ignore: cast_nullable_to_non_nullable
as bool,tier2Enabled: null == tier2Enabled ? _self.tier2Enabled : tier2Enabled // ignore: cast_nullable_to_non_nullable
as bool,tier3Enabled: null == tier3Enabled ? _self.tier3Enabled : tier3Enabled // ignore: cast_nullable_to_non_nullable
as bool,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as List<FcmTokenRecord>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationsSettings].
extension NotificationsSettingsPatterns on NotificationsSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationsSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationsSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationsSettings value)  $default,){
final _that = this;
switch (_that) {
case _NotificationsSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationsSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationsSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool cheerUpEnabled,  bool tier1Enabled,  bool tier2Enabled,  bool tier3Enabled,  List<FcmTokenRecord> tokens,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationsSettings() when $default != null:
return $default(_that.cheerUpEnabled,_that.tier1Enabled,_that.tier2Enabled,_that.tier3Enabled,_that.tokens,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool cheerUpEnabled,  bool tier1Enabled,  bool tier2Enabled,  bool tier3Enabled,  List<FcmTokenRecord> tokens,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _NotificationsSettings():
return $default(_that.cheerUpEnabled,_that.tier1Enabled,_that.tier2Enabled,_that.tier3Enabled,_that.tokens,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool cheerUpEnabled,  bool tier1Enabled,  bool tier2Enabled,  bool tier3Enabled,  List<FcmTokenRecord> tokens,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationsSettings() when $default != null:
return $default(_that.cheerUpEnabled,_that.tier1Enabled,_that.tier2Enabled,_that.tier3Enabled,_that.tokens,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationsSettings extends NotificationsSettings {
  const _NotificationsSettings({this.cheerUpEnabled = true, this.tier1Enabled = true, this.tier2Enabled = true, this.tier3Enabled = true, final  List<FcmTokenRecord> tokens = const <FcmTokenRecord>[], this.updatedAt}): _tokens = tokens,super._();
  

@override@JsonKey() final  bool cheerUpEnabled;
@override@JsonKey() final  bool tier1Enabled;
@override@JsonKey() final  bool tier2Enabled;
@override@JsonKey() final  bool tier3Enabled;
 final  List<FcmTokenRecord> _tokens;
@override@JsonKey() List<FcmTokenRecord> get tokens {
  if (_tokens is EqualUnmodifiableListView) return _tokens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tokens);
}

@override final  DateTime? updatedAt;

/// Create a copy of NotificationsSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationsSettingsCopyWith<_NotificationsSettings> get copyWith => __$NotificationsSettingsCopyWithImpl<_NotificationsSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationsSettings&&(identical(other.cheerUpEnabled, cheerUpEnabled) || other.cheerUpEnabled == cheerUpEnabled)&&(identical(other.tier1Enabled, tier1Enabled) || other.tier1Enabled == tier1Enabled)&&(identical(other.tier2Enabled, tier2Enabled) || other.tier2Enabled == tier2Enabled)&&(identical(other.tier3Enabled, tier3Enabled) || other.tier3Enabled == tier3Enabled)&&const DeepCollectionEquality().equals(other._tokens, _tokens)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,cheerUpEnabled,tier1Enabled,tier2Enabled,tier3Enabled,const DeepCollectionEquality().hash(_tokens),updatedAt);

@override
String toString() {
  return 'NotificationsSettings(cheerUpEnabled: $cheerUpEnabled, tier1Enabled: $tier1Enabled, tier2Enabled: $tier2Enabled, tier3Enabled: $tier3Enabled, tokens: $tokens, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationsSettingsCopyWith<$Res> implements $NotificationsSettingsCopyWith<$Res> {
  factory _$NotificationsSettingsCopyWith(_NotificationsSettings value, $Res Function(_NotificationsSettings) _then) = __$NotificationsSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool cheerUpEnabled, bool tier1Enabled, bool tier2Enabled, bool tier3Enabled, List<FcmTokenRecord> tokens, DateTime? updatedAt
});




}
/// @nodoc
class __$NotificationsSettingsCopyWithImpl<$Res>
    implements _$NotificationsSettingsCopyWith<$Res> {
  __$NotificationsSettingsCopyWithImpl(this._self, this._then);

  final _NotificationsSettings _self;
  final $Res Function(_NotificationsSettings) _then;

/// Create a copy of NotificationsSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cheerUpEnabled = null,Object? tier1Enabled = null,Object? tier2Enabled = null,Object? tier3Enabled = null,Object? tokens = null,Object? updatedAt = freezed,}) {
  return _then(_NotificationsSettings(
cheerUpEnabled: null == cheerUpEnabled ? _self.cheerUpEnabled : cheerUpEnabled // ignore: cast_nullable_to_non_nullable
as bool,tier1Enabled: null == tier1Enabled ? _self.tier1Enabled : tier1Enabled // ignore: cast_nullable_to_non_nullable
as bool,tier2Enabled: null == tier2Enabled ? _self.tier2Enabled : tier2Enabled // ignore: cast_nullable_to_non_nullable
as bool,tier3Enabled: null == tier3Enabled ? _self.tier3Enabled : tier3Enabled // ignore: cast_nullable_to_non_nullable
as bool,tokens: null == tokens ? _self._tokens : tokens // ignore: cast_nullable_to_non_nullable
as List<FcmTokenRecord>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
