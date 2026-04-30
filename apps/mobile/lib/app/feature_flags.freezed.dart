// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_flags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FeatureFlags {
  bool get aiPatternAnalysisEnabled => throw _privateConstructorUsedError;
  bool get geminiDetectionEnabled => throw _privateConstructorUsedError;

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeatureFlagsCopyWith<FeatureFlags> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeatureFlagsCopyWith<$Res> {
  factory $FeatureFlagsCopyWith(
    FeatureFlags value,
    $Res Function(FeatureFlags) then,
  ) = _$FeatureFlagsCopyWithImpl<$Res, FeatureFlags>;
  @useResult
  $Res call({bool aiPatternAnalysisEnabled, bool geminiDetectionEnabled});
}

/// @nodoc
class _$FeatureFlagsCopyWithImpl<$Res, $Val extends FeatureFlags>
    implements $FeatureFlagsCopyWith<$Res> {
  _$FeatureFlagsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? aiPatternAnalysisEnabled = null,
    Object? geminiDetectionEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            aiPatternAnalysisEnabled: null == aiPatternAnalysisEnabled
                ? _value.aiPatternAnalysisEnabled
                : aiPatternAnalysisEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            geminiDetectionEnabled: null == geminiDetectionEnabled
                ? _value.geminiDetectionEnabled
                : geminiDetectionEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FeatureFlagsImplCopyWith<$Res>
    implements $FeatureFlagsCopyWith<$Res> {
  factory _$$FeatureFlagsImplCopyWith(
    _$FeatureFlagsImpl value,
    $Res Function(_$FeatureFlagsImpl) then,
  ) = __$$FeatureFlagsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool aiPatternAnalysisEnabled, bool geminiDetectionEnabled});
}

/// @nodoc
class __$$FeatureFlagsImplCopyWithImpl<$Res>
    extends _$FeatureFlagsCopyWithImpl<$Res, _$FeatureFlagsImpl>
    implements _$$FeatureFlagsImplCopyWith<$Res> {
  __$$FeatureFlagsImplCopyWithImpl(
    _$FeatureFlagsImpl _value,
    $Res Function(_$FeatureFlagsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? aiPatternAnalysisEnabled = null,
    Object? geminiDetectionEnabled = null,
  }) {
    return _then(
      _$FeatureFlagsImpl(
        aiPatternAnalysisEnabled: null == aiPatternAnalysisEnabled
            ? _value.aiPatternAnalysisEnabled
            : aiPatternAnalysisEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        geminiDetectionEnabled: null == geminiDetectionEnabled
            ? _value.geminiDetectionEnabled
            : geminiDetectionEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$FeatureFlagsImpl extends _FeatureFlags {
  const _$FeatureFlagsImpl({
    required this.aiPatternAnalysisEnabled,
    required this.geminiDetectionEnabled,
  }) : super._();

  @override
  final bool aiPatternAnalysisEnabled;
  @override
  final bool geminiDetectionEnabled;

  @override
  String toString() {
    return 'FeatureFlags(aiPatternAnalysisEnabled: $aiPatternAnalysisEnabled, geminiDetectionEnabled: $geminiDetectionEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeatureFlagsImpl &&
            (identical(
                  other.aiPatternAnalysisEnabled,
                  aiPatternAnalysisEnabled,
                ) ||
                other.aiPatternAnalysisEnabled == aiPatternAnalysisEnabled) &&
            (identical(other.geminiDetectionEnabled, geminiDetectionEnabled) ||
                other.geminiDetectionEnabled == geminiDetectionEnabled));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    aiPatternAnalysisEnabled,
    geminiDetectionEnabled,
  );

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeatureFlagsImplCopyWith<_$FeatureFlagsImpl> get copyWith =>
      __$$FeatureFlagsImplCopyWithImpl<_$FeatureFlagsImpl>(this, _$identity);
}

abstract class _FeatureFlags extends FeatureFlags {
  const factory _FeatureFlags({
    required final bool aiPatternAnalysisEnabled,
    required final bool geminiDetectionEnabled,
  }) = _$FeatureFlagsImpl;
  const _FeatureFlags._() : super._();

  @override
  bool get aiPatternAnalysisEnabled;
  @override
  bool get geminiDetectionEnabled;

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeatureFlagsImplCopyWith<_$FeatureFlagsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
