// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intervention_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$InterventionState {
  bool get triggered => throw _privateConstructorUsedError;
  bool get escalated => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;

  /// Create a copy of InterventionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InterventionStateCopyWith<InterventionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InterventionStateCopyWith<$Res> {
  factory $InterventionStateCopyWith(
    InterventionState value,
    $Res Function(InterventionState) then,
  ) = _$InterventionStateCopyWithImpl<$Res, InterventionState>;
  @useResult
  $Res call({bool triggered, bool escalated, String reason});
}

/// @nodoc
class _$InterventionStateCopyWithImpl<$Res, $Val extends InterventionState>
    implements $InterventionStateCopyWith<$Res> {
  _$InterventionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InterventionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? triggered = null,
    Object? escalated = null,
    Object? reason = null,
  }) {
    return _then(
      _value.copyWith(
            triggered: null == triggered
                ? _value.triggered
                : triggered // ignore: cast_nullable_to_non_nullable
                      as bool,
            escalated: null == escalated
                ? _value.escalated
                : escalated // ignore: cast_nullable_to_non_nullable
                      as bool,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InterventionStateImplCopyWith<$Res>
    implements $InterventionStateCopyWith<$Res> {
  factory _$$InterventionStateImplCopyWith(
    _$InterventionStateImpl value,
    $Res Function(_$InterventionStateImpl) then,
  ) = __$$InterventionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool triggered, bool escalated, String reason});
}

/// @nodoc
class __$$InterventionStateImplCopyWithImpl<$Res>
    extends _$InterventionStateCopyWithImpl<$Res, _$InterventionStateImpl>
    implements _$$InterventionStateImplCopyWith<$Res> {
  __$$InterventionStateImplCopyWithImpl(
    _$InterventionStateImpl _value,
    $Res Function(_$InterventionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InterventionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? triggered = null,
    Object? escalated = null,
    Object? reason = null,
  }) {
    return _then(
      _$InterventionStateImpl(
        triggered: null == triggered
            ? _value.triggered
            : triggered // ignore: cast_nullable_to_non_nullable
                  as bool,
        escalated: null == escalated
            ? _value.escalated
            : escalated // ignore: cast_nullable_to_non_nullable
                  as bool,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$InterventionStateImpl implements _InterventionState {
  const _$InterventionStateImpl({
    required this.triggered,
    required this.escalated,
    required this.reason,
  });

  @override
  final bool triggered;
  @override
  final bool escalated;
  @override
  final String reason;

  @override
  String toString() {
    return 'InterventionState(triggered: $triggered, escalated: $escalated, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InterventionStateImpl &&
            (identical(other.triggered, triggered) ||
                other.triggered == triggered) &&
            (identical(other.escalated, escalated) ||
                other.escalated == escalated) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, triggered, escalated, reason);

  /// Create a copy of InterventionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InterventionStateImplCopyWith<_$InterventionStateImpl> get copyWith =>
      __$$InterventionStateImplCopyWithImpl<_$InterventionStateImpl>(
        this,
        _$identity,
      );
}

abstract class _InterventionState implements InterventionState {
  const factory _InterventionState({
    required final bool triggered,
    required final bool escalated,
    required final String reason,
  }) = _$InterventionStateImpl;

  @override
  bool get triggered;
  @override
  bool get escalated;
  @override
  String get reason;

  /// Create a copy of InterventionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InterventionStateImplCopyWith<_$InterventionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
