// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webauthn_credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebauthnCredential {

/// Base64URL-encoded credential id (also the Firestore doc id).
/// Used as `allowCredentials.id` on subsequent assertion ceremonies.
 String get credentialId;/// Server-time timestamp when registration finished. Surfaced as
/// "Registered May 15" in the Privacy UI status tile.
 DateTime get createdAt;/// Server-time timestamp of the most recent successful assertion.
/// Null until the first verify. Surfaced as "Last used May 17" in
/// the Privacy UI status tile.
 DateTime? get lastUsedAt;/// Count of consecutive failed assertion attempts since the last
/// success. Reset to 0 on success.
 int get failedAttempts;/// If non-null, assertion is rate-limited until this UTC time.
 DateTime? get lockedUntil;
/// Create a copy of WebauthnCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebauthnCredentialCopyWith<WebauthnCredential> get copyWith => _$WebauthnCredentialCopyWithImpl<WebauthnCredential>(this as WebauthnCredential, _$identity);

  /// Serializes this WebauthnCredential to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebauthnCredential&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.failedAttempts, failedAttempts) || other.failedAttempts == failedAttempts)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,credentialId,createdAt,lastUsedAt,failedAttempts,lockedUntil);

@override
String toString() {
  return 'WebauthnCredential(credentialId: $credentialId, createdAt: $createdAt, lastUsedAt: $lastUsedAt, failedAttempts: $failedAttempts, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class $WebauthnCredentialCopyWith<$Res>  {
  factory $WebauthnCredentialCopyWith(WebauthnCredential value, $Res Function(WebauthnCredential) _then) = _$WebauthnCredentialCopyWithImpl;
@useResult
$Res call({
 String credentialId, DateTime createdAt, DateTime? lastUsedAt, int failedAttempts, DateTime? lockedUntil
});




}
/// @nodoc
class _$WebauthnCredentialCopyWithImpl<$Res>
    implements $WebauthnCredentialCopyWith<$Res> {
  _$WebauthnCredentialCopyWithImpl(this._self, this._then);

  final WebauthnCredential _self;
  final $Res Function(WebauthnCredential) _then;

/// Create a copy of WebauthnCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? credentialId = null,Object? createdAt = null,Object? lastUsedAt = freezed,Object? failedAttempts = null,Object? lockedUntil = freezed,}) {
  return _then(_self.copyWith(
credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failedAttempts: null == failedAttempts ? _self.failedAttempts : failedAttempts // ignore: cast_nullable_to_non_nullable
as int,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WebauthnCredential].
extension WebauthnCredentialPatterns on WebauthnCredential {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebauthnCredential value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebauthnCredential() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebauthnCredential value)  $default,){
final _that = this;
switch (_that) {
case _WebauthnCredential():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebauthnCredential value)?  $default,){
final _that = this;
switch (_that) {
case _WebauthnCredential() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String credentialId,  DateTime createdAt,  DateTime? lastUsedAt,  int failedAttempts,  DateTime? lockedUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebauthnCredential() when $default != null:
return $default(_that.credentialId,_that.createdAt,_that.lastUsedAt,_that.failedAttempts,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String credentialId,  DateTime createdAt,  DateTime? lastUsedAt,  int failedAttempts,  DateTime? lockedUntil)  $default,) {final _that = this;
switch (_that) {
case _WebauthnCredential():
return $default(_that.credentialId,_that.createdAt,_that.lastUsedAt,_that.failedAttempts,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String credentialId,  DateTime createdAt,  DateTime? lastUsedAt,  int failedAttempts,  DateTime? lockedUntil)?  $default,) {final _that = this;
switch (_that) {
case _WebauthnCredential() when $default != null:
return $default(_that.credentialId,_that.createdAt,_that.lastUsedAt,_that.failedAttempts,_that.lockedUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebauthnCredential implements WebauthnCredential {
  const _WebauthnCredential({required this.credentialId, required this.createdAt, this.lastUsedAt, this.failedAttempts = 0, this.lockedUntil});
  factory _WebauthnCredential.fromJson(Map<String, dynamic> json) => _$WebauthnCredentialFromJson(json);

/// Base64URL-encoded credential id (also the Firestore doc id).
/// Used as `allowCredentials.id` on subsequent assertion ceremonies.
@override final  String credentialId;
/// Server-time timestamp when registration finished. Surfaced as
/// "Registered May 15" in the Privacy UI status tile.
@override final  DateTime createdAt;
/// Server-time timestamp of the most recent successful assertion.
/// Null until the first verify. Surfaced as "Last used May 17" in
/// the Privacy UI status tile.
@override final  DateTime? lastUsedAt;
/// Count of consecutive failed assertion attempts since the last
/// success. Reset to 0 on success.
@override@JsonKey() final  int failedAttempts;
/// If non-null, assertion is rate-limited until this UTC time.
@override final  DateTime? lockedUntil;

/// Create a copy of WebauthnCredential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebauthnCredentialCopyWith<_WebauthnCredential> get copyWith => __$WebauthnCredentialCopyWithImpl<_WebauthnCredential>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebauthnCredentialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebauthnCredential&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.failedAttempts, failedAttempts) || other.failedAttempts == failedAttempts)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,credentialId,createdAt,lastUsedAt,failedAttempts,lockedUntil);

@override
String toString() {
  return 'WebauthnCredential(credentialId: $credentialId, createdAt: $createdAt, lastUsedAt: $lastUsedAt, failedAttempts: $failedAttempts, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class _$WebauthnCredentialCopyWith<$Res> implements $WebauthnCredentialCopyWith<$Res> {
  factory _$WebauthnCredentialCopyWith(_WebauthnCredential value, $Res Function(_WebauthnCredential) _then) = __$WebauthnCredentialCopyWithImpl;
@override @useResult
$Res call({
 String credentialId, DateTime createdAt, DateTime? lastUsedAt, int failedAttempts, DateTime? lockedUntil
});




}
/// @nodoc
class __$WebauthnCredentialCopyWithImpl<$Res>
    implements _$WebauthnCredentialCopyWith<$Res> {
  __$WebauthnCredentialCopyWithImpl(this._self, this._then);

  final _WebauthnCredential _self;
  final $Res Function(_WebauthnCredential) _then;

/// Create a copy of WebauthnCredential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? credentialId = null,Object? createdAt = null,Object? lastUsedAt = freezed,Object? failedAttempts = null,Object? lockedUntil = freezed,}) {
  return _then(_WebauthnCredential(
credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failedAttempts: null == failedAttempts ? _self.failedAttempts : failedAttempts // ignore: cast_nullable_to_non_nullable
as int,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
