// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'biometric_capability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BiometricCapability {
  /// Hardware supports biometric (fingerprint, face, etc.).
  bool get isAvailable => throw _privateConstructorUsedError;

  /// At least one biometric is enrolled on the device.
  bool get hasEnrolledBiometrics => throw _privateConstructorUsedError;

  /// User has accepted the in-app opt-in toggle.
  bool get userOptedIn => throw _privateConstructorUsedError;

  /// Create a copy of BiometricCapability
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BiometricCapabilityCopyWith<BiometricCapability> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BiometricCapabilityCopyWith<$Res> {
  factory $BiometricCapabilityCopyWith(
    BiometricCapability value,
    $Res Function(BiometricCapability) then,
  ) = _$BiometricCapabilityCopyWithImpl<$Res, BiometricCapability>;
  @useResult
  $Res call({bool isAvailable, bool hasEnrolledBiometrics, bool userOptedIn});
}

/// @nodoc
class _$BiometricCapabilityCopyWithImpl<$Res, $Val extends BiometricCapability>
    implements $BiometricCapabilityCopyWith<$Res> {
  _$BiometricCapabilityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BiometricCapability
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAvailable = null,
    Object? hasEnrolledBiometrics = null,
    Object? userOptedIn = null,
  }) {
    return _then(
      _value.copyWith(
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasEnrolledBiometrics: null == hasEnrolledBiometrics
                ? _value.hasEnrolledBiometrics
                : hasEnrolledBiometrics // ignore: cast_nullable_to_non_nullable
                      as bool,
            userOptedIn: null == userOptedIn
                ? _value.userOptedIn
                : userOptedIn // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BiometricCapabilityImplCopyWith<$Res>
    implements $BiometricCapabilityCopyWith<$Res> {
  factory _$$BiometricCapabilityImplCopyWith(
    _$BiometricCapabilityImpl value,
    $Res Function(_$BiometricCapabilityImpl) then,
  ) = __$$BiometricCapabilityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isAvailable, bool hasEnrolledBiometrics, bool userOptedIn});
}

/// @nodoc
class __$$BiometricCapabilityImplCopyWithImpl<$Res>
    extends _$BiometricCapabilityCopyWithImpl<$Res, _$BiometricCapabilityImpl>
    implements _$$BiometricCapabilityImplCopyWith<$Res> {
  __$$BiometricCapabilityImplCopyWithImpl(
    _$BiometricCapabilityImpl _value,
    $Res Function(_$BiometricCapabilityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BiometricCapability
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAvailable = null,
    Object? hasEnrolledBiometrics = null,
    Object? userOptedIn = null,
  }) {
    return _then(
      _$BiometricCapabilityImpl(
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasEnrolledBiometrics: null == hasEnrolledBiometrics
            ? _value.hasEnrolledBiometrics
            : hasEnrolledBiometrics // ignore: cast_nullable_to_non_nullable
                  as bool,
        userOptedIn: null == userOptedIn
            ? _value.userOptedIn
            : userOptedIn // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$BiometricCapabilityImpl extends _BiometricCapability {
  const _$BiometricCapabilityImpl({
    required this.isAvailable,
    required this.hasEnrolledBiometrics,
    required this.userOptedIn,
  }) : super._();

  /// Hardware supports biometric (fingerprint, face, etc.).
  @override
  final bool isAvailable;

  /// At least one biometric is enrolled on the device.
  @override
  final bool hasEnrolledBiometrics;

  /// User has accepted the in-app opt-in toggle.
  @override
  final bool userOptedIn;

  @override
  String toString() {
    return 'BiometricCapability(isAvailable: $isAvailable, hasEnrolledBiometrics: $hasEnrolledBiometrics, userOptedIn: $userOptedIn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BiometricCapabilityImpl &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.hasEnrolledBiometrics, hasEnrolledBiometrics) ||
                other.hasEnrolledBiometrics == hasEnrolledBiometrics) &&
            (identical(other.userOptedIn, userOptedIn) ||
                other.userOptedIn == userOptedIn));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isAvailable, hasEnrolledBiometrics, userOptedIn);

  /// Create a copy of BiometricCapability
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BiometricCapabilityImplCopyWith<_$BiometricCapabilityImpl> get copyWith =>
      __$$BiometricCapabilityImplCopyWithImpl<_$BiometricCapabilityImpl>(
        this,
        _$identity,
      );
}

abstract class _BiometricCapability extends BiometricCapability {
  const factory _BiometricCapability({
    required final bool isAvailable,
    required final bool hasEnrolledBiometrics,
    required final bool userOptedIn,
  }) = _$BiometricCapabilityImpl;
  const _BiometricCapability._() : super._();

  /// Hardware supports biometric (fingerprint, face, etc.).
  @override
  bool get isAvailable;

  /// At least one biometric is enrolled on the device.
  @override
  bool get hasEnrolledBiometrics;

  /// User has accepted the in-app opt-in toggle.
  @override
  bool get userOptedIn;

  /// Create a copy of BiometricCapability
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BiometricCapabilityImplCopyWith<_$BiometricCapabilityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
