// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_suggestion_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AiSuggestionDto _$AiSuggestionDtoFromJson(Map<String, dynamic> json) {
  return _AiSuggestionDto.fromJson(json);
}

/// @nodoc
mixin _$AiSuggestionDto {
  bool get ok => throw _privateConstructorUsedError;
  int get v => throw _privateConstructorUsedError;
  String get requestId => throw _privateConstructorUsedError;
  String get mood => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  AiSuggestionAlternativeDto? get alternative =>
      throw _privateConstructorUsedError;
  String get rationale => throw _privateConstructorUsedError;
  String? get flag => throw _privateConstructorUsedError;
  int get latencyMs => throw _privateConstructorUsedError;
  String get modelVersion => throw _privateConstructorUsedError;

  /// Serializes this AiSuggestionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiSuggestionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiSuggestionDtoCopyWith<AiSuggestionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiSuggestionDtoCopyWith<$Res> {
  factory $AiSuggestionDtoCopyWith(
    AiSuggestionDto value,
    $Res Function(AiSuggestionDto) then,
  ) = _$AiSuggestionDtoCopyWithImpl<$Res, AiSuggestionDto>;
  @useResult
  $Res call({
    bool ok,
    int v,
    String requestId,
    String mood,
    double confidence,
    AiSuggestionAlternativeDto? alternative,
    String rationale,
    String? flag,
    int latencyMs,
    String modelVersion,
  });

  $AiSuggestionAlternativeDtoCopyWith<$Res>? get alternative;
}

/// @nodoc
class _$AiSuggestionDtoCopyWithImpl<$Res, $Val extends AiSuggestionDto>
    implements $AiSuggestionDtoCopyWith<$Res> {
  _$AiSuggestionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiSuggestionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? v = null,
    Object? requestId = null,
    Object? mood = null,
    Object? confidence = null,
    Object? alternative = freezed,
    Object? rationale = null,
    Object? flag = freezed,
    Object? latencyMs = null,
    Object? modelVersion = null,
  }) {
    return _then(
      _value.copyWith(
            ok: null == ok
                ? _value.ok
                : ok // ignore: cast_nullable_to_non_nullable
                      as bool,
            v: null == v
                ? _value.v
                : v // ignore: cast_nullable_to_non_nullable
                      as int,
            requestId: null == requestId
                ? _value.requestId
                : requestId // ignore: cast_nullable_to_non_nullable
                      as String,
            mood: null == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            alternative: freezed == alternative
                ? _value.alternative
                : alternative // ignore: cast_nullable_to_non_nullable
                      as AiSuggestionAlternativeDto?,
            rationale: null == rationale
                ? _value.rationale
                : rationale // ignore: cast_nullable_to_non_nullable
                      as String,
            flag: freezed == flag
                ? _value.flag
                : flag // ignore: cast_nullable_to_non_nullable
                      as String?,
            latencyMs: null == latencyMs
                ? _value.latencyMs
                : latencyMs // ignore: cast_nullable_to_non_nullable
                      as int,
            modelVersion: null == modelVersion
                ? _value.modelVersion
                : modelVersion // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of AiSuggestionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AiSuggestionAlternativeDtoCopyWith<$Res>? get alternative {
    if (_value.alternative == null) {
      return null;
    }

    return $AiSuggestionAlternativeDtoCopyWith<$Res>(_value.alternative!, (
      value,
    ) {
      return _then(_value.copyWith(alternative: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AiSuggestionDtoImplCopyWith<$Res>
    implements $AiSuggestionDtoCopyWith<$Res> {
  factory _$$AiSuggestionDtoImplCopyWith(
    _$AiSuggestionDtoImpl value,
    $Res Function(_$AiSuggestionDtoImpl) then,
  ) = __$$AiSuggestionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool ok,
    int v,
    String requestId,
    String mood,
    double confidence,
    AiSuggestionAlternativeDto? alternative,
    String rationale,
    String? flag,
    int latencyMs,
    String modelVersion,
  });

  @override
  $AiSuggestionAlternativeDtoCopyWith<$Res>? get alternative;
}

/// @nodoc
class __$$AiSuggestionDtoImplCopyWithImpl<$Res>
    extends _$AiSuggestionDtoCopyWithImpl<$Res, _$AiSuggestionDtoImpl>
    implements _$$AiSuggestionDtoImplCopyWith<$Res> {
  __$$AiSuggestionDtoImplCopyWithImpl(
    _$AiSuggestionDtoImpl _value,
    $Res Function(_$AiSuggestionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiSuggestionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? v = null,
    Object? requestId = null,
    Object? mood = null,
    Object? confidence = null,
    Object? alternative = freezed,
    Object? rationale = null,
    Object? flag = freezed,
    Object? latencyMs = null,
    Object? modelVersion = null,
  }) {
    return _then(
      _$AiSuggestionDtoImpl(
        ok: null == ok
            ? _value.ok
            : ok // ignore: cast_nullable_to_non_nullable
                  as bool,
        v: null == v
            ? _value.v
            : v // ignore: cast_nullable_to_non_nullable
                  as int,
        requestId: null == requestId
            ? _value.requestId
            : requestId // ignore: cast_nullable_to_non_nullable
                  as String,
        mood: null == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        alternative: freezed == alternative
            ? _value.alternative
            : alternative // ignore: cast_nullable_to_non_nullable
                  as AiSuggestionAlternativeDto?,
        rationale: null == rationale
            ? _value.rationale
            : rationale // ignore: cast_nullable_to_non_nullable
                  as String,
        flag: freezed == flag
            ? _value.flag
            : flag // ignore: cast_nullable_to_non_nullable
                  as String?,
        latencyMs: null == latencyMs
            ? _value.latencyMs
            : latencyMs // ignore: cast_nullable_to_non_nullable
                  as int,
        modelVersion: null == modelVersion
            ? _value.modelVersion
            : modelVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiSuggestionDtoImpl extends _AiSuggestionDto {
  const _$AiSuggestionDtoImpl({
    required this.ok,
    required this.v,
    required this.requestId,
    required this.mood,
    required this.confidence,
    this.alternative,
    required this.rationale,
    this.flag,
    required this.latencyMs,
    required this.modelVersion,
  }) : super._();

  factory _$AiSuggestionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiSuggestionDtoImplFromJson(json);

  @override
  final bool ok;
  @override
  final int v;
  @override
  final String requestId;
  @override
  final String mood;
  @override
  final double confidence;
  @override
  final AiSuggestionAlternativeDto? alternative;
  @override
  final String rationale;
  @override
  final String? flag;
  @override
  final int latencyMs;
  @override
  final String modelVersion;

  @override
  String toString() {
    return 'AiSuggestionDto(ok: $ok, v: $v, requestId: $requestId, mood: $mood, confidence: $confidence, alternative: $alternative, rationale: $rationale, flag: $flag, latencyMs: $latencyMs, modelVersion: $modelVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiSuggestionDtoImpl &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.v, v) || other.v == v) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.alternative, alternative) ||
                other.alternative == alternative) &&
            (identical(other.rationale, rationale) ||
                other.rationale == rationale) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.latencyMs, latencyMs) ||
                other.latencyMs == latencyMs) &&
            (identical(other.modelVersion, modelVersion) ||
                other.modelVersion == modelVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    ok,
    v,
    requestId,
    mood,
    confidence,
    alternative,
    rationale,
    flag,
    latencyMs,
    modelVersion,
  );

  /// Create a copy of AiSuggestionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiSuggestionDtoImplCopyWith<_$AiSuggestionDtoImpl> get copyWith =>
      __$$AiSuggestionDtoImplCopyWithImpl<_$AiSuggestionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AiSuggestionDtoImplToJson(this);
  }
}

abstract class _AiSuggestionDto extends AiSuggestionDto {
  const factory _AiSuggestionDto({
    required final bool ok,
    required final int v,
    required final String requestId,
    required final String mood,
    required final double confidence,
    final AiSuggestionAlternativeDto? alternative,
    required final String rationale,
    final String? flag,
    required final int latencyMs,
    required final String modelVersion,
  }) = _$AiSuggestionDtoImpl;
  const _AiSuggestionDto._() : super._();

  factory _AiSuggestionDto.fromJson(Map<String, dynamic> json) =
      _$AiSuggestionDtoImpl.fromJson;

  @override
  bool get ok;
  @override
  int get v;
  @override
  String get requestId;
  @override
  String get mood;
  @override
  double get confidence;
  @override
  AiSuggestionAlternativeDto? get alternative;
  @override
  String get rationale;
  @override
  String? get flag;
  @override
  int get latencyMs;
  @override
  String get modelVersion;

  /// Create a copy of AiSuggestionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiSuggestionDtoImplCopyWith<_$AiSuggestionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AiSuggestionAlternativeDto _$AiSuggestionAlternativeDtoFromJson(
  Map<String, dynamic> json,
) {
  return _AiSuggestionAlternativeDto.fromJson(json);
}

/// @nodoc
mixin _$AiSuggestionAlternativeDto {
  String get mood => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this AiSuggestionAlternativeDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiSuggestionAlternativeDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiSuggestionAlternativeDtoCopyWith<AiSuggestionAlternativeDto>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiSuggestionAlternativeDtoCopyWith<$Res> {
  factory $AiSuggestionAlternativeDtoCopyWith(
    AiSuggestionAlternativeDto value,
    $Res Function(AiSuggestionAlternativeDto) then,
  ) =
      _$AiSuggestionAlternativeDtoCopyWithImpl<
        $Res,
        AiSuggestionAlternativeDto
      >;
  @useResult
  $Res call({String mood, double confidence});
}

/// @nodoc
class _$AiSuggestionAlternativeDtoCopyWithImpl<
  $Res,
  $Val extends AiSuggestionAlternativeDto
>
    implements $AiSuggestionAlternativeDtoCopyWith<$Res> {
  _$AiSuggestionAlternativeDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiSuggestionAlternativeDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mood = null, Object? confidence = null}) {
    return _then(
      _value.copyWith(
            mood: null == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$AiSuggestionAlternativeDtoImplCopyWith<$Res>
    implements $AiSuggestionAlternativeDtoCopyWith<$Res> {
  factory _$$AiSuggestionAlternativeDtoImplCopyWith(
    _$AiSuggestionAlternativeDtoImpl value,
    $Res Function(_$AiSuggestionAlternativeDtoImpl) then,
  ) = __$$AiSuggestionAlternativeDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String mood, double confidence});
}

/// @nodoc
class __$$AiSuggestionAlternativeDtoImplCopyWithImpl<$Res>
    extends
        _$AiSuggestionAlternativeDtoCopyWithImpl<
          $Res,
          _$AiSuggestionAlternativeDtoImpl
        >
    implements _$$AiSuggestionAlternativeDtoImplCopyWith<$Res> {
  __$$AiSuggestionAlternativeDtoImplCopyWithImpl(
    _$AiSuggestionAlternativeDtoImpl _value,
    $Res Function(_$AiSuggestionAlternativeDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiSuggestionAlternativeDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mood = null, Object? confidence = null}) {
    return _then(
      _$AiSuggestionAlternativeDtoImpl(
        mood: null == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiSuggestionAlternativeDtoImpl implements _AiSuggestionAlternativeDto {
  const _$AiSuggestionAlternativeDtoImpl({
    required this.mood,
    required this.confidence,
  });

  factory _$AiSuggestionAlternativeDtoImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$AiSuggestionAlternativeDtoImplFromJson(json);

  @override
  final String mood;
  @override
  final double confidence;

  @override
  String toString() {
    return 'AiSuggestionAlternativeDto(mood: $mood, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiSuggestionAlternativeDtoImpl &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, mood, confidence);

  /// Create a copy of AiSuggestionAlternativeDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiSuggestionAlternativeDtoImplCopyWith<_$AiSuggestionAlternativeDtoImpl>
  get copyWith =>
      __$$AiSuggestionAlternativeDtoImplCopyWithImpl<
        _$AiSuggestionAlternativeDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiSuggestionAlternativeDtoImplToJson(this);
  }
}

abstract class _AiSuggestionAlternativeDto
    implements AiSuggestionAlternativeDto {
  const factory _AiSuggestionAlternativeDto({
    required final String mood,
    required final double confidence,
  }) = _$AiSuggestionAlternativeDtoImpl;

  factory _AiSuggestionAlternativeDto.fromJson(Map<String, dynamic> json) =
      _$AiSuggestionAlternativeDtoImpl.fromJson;

  @override
  String get mood;
  @override
  double get confidence;

  /// Create a copy of AiSuggestionAlternativeDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiSuggestionAlternativeDtoImplCopyWith<_$AiSuggestionAlternativeDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
