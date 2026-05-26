// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pin_hash.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PinHash {

/// PBKDF2 variant identifier. Fixed at `'pbkdf2-sha256'`. Stored
/// explicitly so a future rotation (e.g. Argon2id) can be
/// distinguished at read time without a schema migration.
 String get algorithm;/// PBKDF2 iteration count. ≥ 100 000.
 int get iterations;/// Base64-encoded 16-byte random salt. Per-user; generated once at
/// setup and never rotated unless the PIN itself is replaced.
 String get saltBase64;/// Base64-encoded 32-byte PBKDF2 derived key.
 String get hashBase64;/// Server-time timestamp when this PIN was set up. Used only for
/// audit (e.g. "PIN set N days ago"); never for security decisions.
 DateTime get createdAt;/// Count of consecutive failed verification attempts since the last
/// success. Reset to 0 on success.
 int get failedAttempts;/// If non-null, verification is rate-limited until this UTC time.
/// Reads of the hash doc may also be blocked by the Firestore rule
/// `lockedUntil > request.time`.
 DateTime? get lockedUntil;
/// Create a copy of PinHash
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinHashCopyWith<PinHash> get copyWith => _$PinHashCopyWithImpl<PinHash>(this as PinHash, _$identity);

  /// Serializes this PinHash to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinHash&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.iterations, iterations) || other.iterations == iterations)&&(identical(other.saltBase64, saltBase64) || other.saltBase64 == saltBase64)&&(identical(other.hashBase64, hashBase64) || other.hashBase64 == hashBase64)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.failedAttempts, failedAttempts) || other.failedAttempts == failedAttempts)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,algorithm,iterations,saltBase64,hashBase64,createdAt,failedAttempts,lockedUntil);

@override
String toString() {
  return 'PinHash(algorithm: $algorithm, iterations: $iterations, saltBase64: $saltBase64, hashBase64: $hashBase64, createdAt: $createdAt, failedAttempts: $failedAttempts, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class $PinHashCopyWith<$Res>  {
  factory $PinHashCopyWith(PinHash value, $Res Function(PinHash) _then) = _$PinHashCopyWithImpl;
@useResult
$Res call({
 String algorithm, int iterations, String saltBase64, String hashBase64, DateTime createdAt, int failedAttempts, DateTime? lockedUntil
});




}
/// @nodoc
class _$PinHashCopyWithImpl<$Res>
    implements $PinHashCopyWith<$Res> {
  _$PinHashCopyWithImpl(this._self, this._then);

  final PinHash _self;
  final $Res Function(PinHash) _then;

/// Create a copy of PinHash
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? algorithm = null,Object? iterations = null,Object? saltBase64 = null,Object? hashBase64 = null,Object? createdAt = null,Object? failedAttempts = null,Object? lockedUntil = freezed,}) {
  return _then(_self.copyWith(
algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,iterations: null == iterations ? _self.iterations : iterations // ignore: cast_nullable_to_non_nullable
as int,saltBase64: null == saltBase64 ? _self.saltBase64 : saltBase64 // ignore: cast_nullable_to_non_nullable
as String,hashBase64: null == hashBase64 ? _self.hashBase64 : hashBase64 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,failedAttempts: null == failedAttempts ? _self.failedAttempts : failedAttempts // ignore: cast_nullable_to_non_nullable
as int,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PinHash].
extension PinHashPatterns on PinHash {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PinHash value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PinHash() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PinHash value)  $default,){
final _that = this;
switch (_that) {
case _PinHash():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PinHash value)?  $default,){
final _that = this;
switch (_that) {
case _PinHash() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String algorithm,  int iterations,  String saltBase64,  String hashBase64,  DateTime createdAt,  int failedAttempts,  DateTime? lockedUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PinHash() when $default != null:
return $default(_that.algorithm,_that.iterations,_that.saltBase64,_that.hashBase64,_that.createdAt,_that.failedAttempts,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String algorithm,  int iterations,  String saltBase64,  String hashBase64,  DateTime createdAt,  int failedAttempts,  DateTime? lockedUntil)  $default,) {final _that = this;
switch (_that) {
case _PinHash():
return $default(_that.algorithm,_that.iterations,_that.saltBase64,_that.hashBase64,_that.createdAt,_that.failedAttempts,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String algorithm,  int iterations,  String saltBase64,  String hashBase64,  DateTime createdAt,  int failedAttempts,  DateTime? lockedUntil)?  $default,) {final _that = this;
switch (_that) {
case _PinHash() when $default != null:
return $default(_that.algorithm,_that.iterations,_that.saltBase64,_that.hashBase64,_that.createdAt,_that.failedAttempts,_that.lockedUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PinHash implements PinHash {
  const _PinHash({required this.algorithm, required this.iterations, required this.saltBase64, required this.hashBase64, required this.createdAt, this.failedAttempts = 0, this.lockedUntil});
  factory _PinHash.fromJson(Map<String, dynamic> json) => _$PinHashFromJson(json);

/// PBKDF2 variant identifier. Fixed at `'pbkdf2-sha256'`. Stored
/// explicitly so a future rotation (e.g. Argon2id) can be
/// distinguished at read time without a schema migration.
@override final  String algorithm;
/// PBKDF2 iteration count. ≥ 100 000.
@override final  int iterations;
/// Base64-encoded 16-byte random salt. Per-user; generated once at
/// setup and never rotated unless the PIN itself is replaced.
@override final  String saltBase64;
/// Base64-encoded 32-byte PBKDF2 derived key.
@override final  String hashBase64;
/// Server-time timestamp when this PIN was set up. Used only for
/// audit (e.g. "PIN set N days ago"); never for security decisions.
@override final  DateTime createdAt;
/// Count of consecutive failed verification attempts since the last
/// success. Reset to 0 on success.
@override@JsonKey() final  int failedAttempts;
/// If non-null, verification is rate-limited until this UTC time.
/// Reads of the hash doc may also be blocked by the Firestore rule
/// `lockedUntil > request.time`.
@override final  DateTime? lockedUntil;

/// Create a copy of PinHash
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PinHashCopyWith<_PinHash> get copyWith => __$PinHashCopyWithImpl<_PinHash>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PinHashToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PinHash&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.iterations, iterations) || other.iterations == iterations)&&(identical(other.saltBase64, saltBase64) || other.saltBase64 == saltBase64)&&(identical(other.hashBase64, hashBase64) || other.hashBase64 == hashBase64)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.failedAttempts, failedAttempts) || other.failedAttempts == failedAttempts)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,algorithm,iterations,saltBase64,hashBase64,createdAt,failedAttempts,lockedUntil);

@override
String toString() {
  return 'PinHash(algorithm: $algorithm, iterations: $iterations, saltBase64: $saltBase64, hashBase64: $hashBase64, createdAt: $createdAt, failedAttempts: $failedAttempts, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class _$PinHashCopyWith<$Res> implements $PinHashCopyWith<$Res> {
  factory _$PinHashCopyWith(_PinHash value, $Res Function(_PinHash) _then) = __$PinHashCopyWithImpl;
@override @useResult
$Res call({
 String algorithm, int iterations, String saltBase64, String hashBase64, DateTime createdAt, int failedAttempts, DateTime? lockedUntil
});




}
/// @nodoc
class __$PinHashCopyWithImpl<$Res>
    implements _$PinHashCopyWith<$Res> {
  __$PinHashCopyWithImpl(this._self, this._then);

  final _PinHash _self;
  final $Res Function(_PinHash) _then;

/// Create a copy of PinHash
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? algorithm = null,Object? iterations = null,Object? saltBase64 = null,Object? hashBase64 = null,Object? createdAt = null,Object? failedAttempts = null,Object? lockedUntil = freezed,}) {
  return _then(_PinHash(
algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,iterations: null == iterations ? _self.iterations : iterations // ignore: cast_nullable_to_non_nullable
as int,saltBase64: null == saltBase64 ? _self.saltBase64 : saltBase64 // ignore: cast_nullable_to_non_nullable
as String,hashBase64: null == hashBase64 ? _self.hashBase64 : hashBase64 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,failedAttempts: null == failedAttempts ? _self.failedAttempts : failedAttempts // ignore: cast_nullable_to_non_nullable
as int,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
