// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AiSuggestion {
  MoodType get mood => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  String get rationale => throw _privateConstructorUsedError;
  AiSuggestionAlternative? get alternative =>
      throw _privateConstructorUsedError;
  AiSafetyFlag? get safetyFlag => throw _privateConstructorUsedError;
  Duration get latency => throw _privateConstructorUsedError;

  /// Create a copy of AiSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiSuggestionCopyWith<AiSuggestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiSuggestionCopyWith<$Res> {
  factory $AiSuggestionCopyWith(
    AiSuggestion value,
    $Res Function(AiSuggestion) then,
  ) = _$AiSuggestionCopyWithImpl<$Res, AiSuggestion>;
  @useResult
  $Res call({
    MoodType mood,
    double confidence,
    String rationale,
    AiSuggestionAlternative? alternative,
    AiSafetyFlag? safetyFlag,
    Duration latency,
  });

  $AiSuggestionAlternativeCopyWith<$Res>? get alternative;
}

/// @nodoc
class _$AiSuggestionCopyWithImpl<$Res, $Val extends AiSuggestion>
    implements $AiSuggestionCopyWith<$Res> {
  _$AiSuggestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = null,
    Object? confidence = null,
    Object? rationale = null,
    Object? alternative = freezed,
    Object? safetyFlag = freezed,
    Object? latency = null,
  }) {
    return _then(
      _value.copyWith(
            mood: null == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as MoodType,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            rationale: null == rationale
                ? _value.rationale
                : rationale // ignore: cast_nullable_to_non_nullable
                      as String,
            alternative: freezed == alternative
                ? _value.alternative
                : alternative // ignore: cast_nullable_to_non_nullable
                      as AiSuggestionAlternative?,
            safetyFlag: freezed == safetyFlag
                ? _value.safetyFlag
                : safetyFlag // ignore: cast_nullable_to_non_nullable
                      as AiSafetyFlag?,
            latency: null == latency
                ? _value.latency
                : latency // ignore: cast_nullable_to_non_nullable
                      as Duration,
          )
          as $Val,
    );
  }

  /// Create a copy of AiSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AiSuggestionAlternativeCopyWith<$Res>? get alternative {
    if (_value.alternative == null) {
      return null;
    }

    return $AiSuggestionAlternativeCopyWith<$Res>(_value.alternative!, (value) {
      return _then(_value.copyWith(alternative: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AiSuggestionImplCopyWith<$Res>
    implements $AiSuggestionCopyWith<$Res> {
  factory _$$AiSuggestionImplCopyWith(
    _$AiSuggestionImpl value,
    $Res Function(_$AiSuggestionImpl) then,
  ) = __$$AiSuggestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    MoodType mood,
    double confidence,
    String rationale,
    AiSuggestionAlternative? alternative,
    AiSafetyFlag? safetyFlag,
    Duration latency,
  });

  @override
  $AiSuggestionAlternativeCopyWith<$Res>? get alternative;
}

/// @nodoc
class __$$AiSuggestionImplCopyWithImpl<$Res>
    extends _$AiSuggestionCopyWithImpl<$Res, _$AiSuggestionImpl>
    implements _$$AiSuggestionImplCopyWith<$Res> {
  __$$AiSuggestionImplCopyWithImpl(
    _$AiSuggestionImpl _value,
    $Res Function(_$AiSuggestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = null,
    Object? confidence = null,
    Object? rationale = null,
    Object? alternative = freezed,
    Object? safetyFlag = freezed,
    Object? latency = null,
  }) {
    return _then(
      _$AiSuggestionImpl(
        mood: null == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as MoodType,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        rationale: null == rationale
            ? _value.rationale
            : rationale // ignore: cast_nullable_to_non_nullable
                  as String,
        alternative: freezed == alternative
            ? _value.alternative
            : alternative // ignore: cast_nullable_to_non_nullable
                  as AiSuggestionAlternative?,
        safetyFlag: freezed == safetyFlag
            ? _value.safetyFlag
            : safetyFlag // ignore: cast_nullable_to_non_nullable
                  as AiSafetyFlag?,
        latency: null == latency
            ? _value.latency
            : latency // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc

class _$AiSuggestionImpl implements _AiSuggestion {
  const _$AiSuggestionImpl({
    required this.mood,
    required this.confidence,
    required this.rationale,
    this.alternative,
    this.safetyFlag,
    required this.latency,
  }) : assert(
         confidence >= 0 && confidence <= 1,
         'confidence must be in [0, 1]',
       );

  @override
  final MoodType mood;
  @override
  final double confidence;
  @override
  final String rationale;
  @override
  final AiSuggestionAlternative? alternative;
  @override
  final AiSafetyFlag? safetyFlag;
  @override
  final Duration latency;

  @override
  String toString() {
    return 'AiSuggestion(mood: $mood, confidence: $confidence, rationale: $rationale, alternative: $alternative, safetyFlag: $safetyFlag, latency: $latency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiSuggestionImpl &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.rationale, rationale) ||
                other.rationale == rationale) &&
            (identical(other.alternative, alternative) ||
                other.alternative == alternative) &&
            (identical(other.safetyFlag, safetyFlag) ||
                other.safetyFlag == safetyFlag) &&
            (identical(other.latency, latency) || other.latency == latency));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    mood,
    confidence,
    rationale,
    alternative,
    safetyFlag,
    latency,
  );

  /// Create a copy of AiSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiSuggestionImplCopyWith<_$AiSuggestionImpl> get copyWith =>
      __$$AiSuggestionImplCopyWithImpl<_$AiSuggestionImpl>(this, _$identity);
}

abstract class _AiSuggestion implements AiSuggestion {
  const factory _AiSuggestion({
    required final MoodType mood,
    required final double confidence,
    required final String rationale,
    final AiSuggestionAlternative? alternative,
    final AiSafetyFlag? safetyFlag,
    required final Duration latency,
  }) = _$AiSuggestionImpl;

  @override
  MoodType get mood;
  @override
  double get confidence;
  @override
  String get rationale;
  @override
  AiSuggestionAlternative? get alternative;
  @override
  AiSafetyFlag? get safetyFlag;
  @override
  Duration get latency;

  /// Create a copy of AiSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiSuggestionImplCopyWith<_$AiSuggestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AiSuggestionAlternative {
  MoodType get mood => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;

  /// Create a copy of AiSuggestionAlternative
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiSuggestionAlternativeCopyWith<AiSuggestionAlternative> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiSuggestionAlternativeCopyWith<$Res> {
  factory $AiSuggestionAlternativeCopyWith(
    AiSuggestionAlternative value,
    $Res Function(AiSuggestionAlternative) then,
  ) = _$AiSuggestionAlternativeCopyWithImpl<$Res, AiSuggestionAlternative>;
  @useResult
  $Res call({MoodType mood, double confidence});
}

/// @nodoc
class _$AiSuggestionAlternativeCopyWithImpl<
  $Res,
  $Val extends AiSuggestionAlternative
>
    implements $AiSuggestionAlternativeCopyWith<$Res> {
  _$AiSuggestionAlternativeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiSuggestionAlternative
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mood = null, Object? confidence = null}) {
    return _then(
      _value.copyWith(
            mood: null == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as MoodType,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiSuggestionAlternativeImplCopyWith<$Res>
    implements $AiSuggestionAlternativeCopyWith<$Res> {
  factory _$$AiSuggestionAlternativeImplCopyWith(
    _$AiSuggestionAlternativeImpl value,
    $Res Function(_$AiSuggestionAlternativeImpl) then,
  ) = __$$AiSuggestionAlternativeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MoodType mood, double confidence});
}

/// @nodoc
class __$$AiSuggestionAlternativeImplCopyWithImpl<$Res>
    extends
        _$AiSuggestionAlternativeCopyWithImpl<
          $Res,
          _$AiSuggestionAlternativeImpl
        >
    implements _$$AiSuggestionAlternativeImplCopyWith<$Res> {
  __$$AiSuggestionAlternativeImplCopyWithImpl(
    _$AiSuggestionAlternativeImpl _value,
    $Res Function(_$AiSuggestionAlternativeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiSuggestionAlternative
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mood = null, Object? confidence = null}) {
    return _then(
      _$AiSuggestionAlternativeImpl(
        mood: null == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as MoodType,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$AiSuggestionAlternativeImpl implements _AiSuggestionAlternative {
  const _$AiSuggestionAlternativeImpl({
    required this.mood,
    required this.confidence,
  }) : assert(
         confidence >= 0 && confidence <= 1,
         'confidence must be in [0, 1]',
       );

  @override
  final MoodType mood;
  @override
  final double confidence;

  @override
  String toString() {
    return 'AiSuggestionAlternative(mood: $mood, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiSuggestionAlternativeImpl &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mood, confidence);

  /// Create a copy of AiSuggestionAlternative
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiSuggestionAlternativeImplCopyWith<_$AiSuggestionAlternativeImpl>
  get copyWith =>
      __$$AiSuggestionAlternativeImplCopyWithImpl<
        _$AiSuggestionAlternativeImpl
      >(this, _$identity);
}

abstract class _AiSuggestionAlternative implements AiSuggestionAlternative {
  const factory _AiSuggestionAlternative({
    required final MoodType mood,
    required final double confidence,
  }) = _$AiSuggestionAlternativeImpl;

  @override
  MoodType get mood;
  @override
  double get confidence;

  /// Create a copy of AiSuggestionAlternative
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiSuggestionAlternativeImplCopyWith<_$AiSuggestionAlternativeImpl>
  get copyWith => throw _privateConstructorUsedError;
}
