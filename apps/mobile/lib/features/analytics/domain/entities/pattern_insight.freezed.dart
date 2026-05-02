// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pattern_insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PatternInsight _$PatternInsightFromJson(Map<String, dynamic> json) {
  return _PatternInsight.fromJson(json);
}

/// @nodoc
mixin _$PatternInsight {
  String get id => throw _privateConstructorUsedError;
  PatternInsightKind get kind => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  int get sampleSize => throw _privateConstructorUsedError;
  DateTime get generatedAt => throw _privateConstructorUsedError;

  /// Serializes this PatternInsight to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PatternInsight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PatternInsightCopyWith<PatternInsight> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PatternInsightCopyWith<$Res> {
  factory $PatternInsightCopyWith(
    PatternInsight value,
    $Res Function(PatternInsight) then,
  ) = _$PatternInsightCopyWithImpl<$Res, PatternInsight>;
  @useResult
  $Res call({
    String id,
    PatternInsightKind kind,
    String text,
    double confidence,
    int sampleSize,
    DateTime generatedAt,
  });
}

/// @nodoc
class _$PatternInsightCopyWithImpl<$Res, $Val extends PatternInsight>
    implements $PatternInsightCopyWith<$Res> {
  _$PatternInsightCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PatternInsight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? text = null,
    Object? confidence = null,
    Object? sampleSize = null,
    Object? generatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as PatternInsightKind,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            sampleSize: null == sampleSize
                ? _value.sampleSize
                : sampleSize // ignore: cast_nullable_to_non_nullable
                      as int,
            generatedAt: null == generatedAt
                ? _value.generatedAt
                : generatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PatternInsightImplCopyWith<$Res>
    implements $PatternInsightCopyWith<$Res> {
  factory _$$PatternInsightImplCopyWith(
    _$PatternInsightImpl value,
    $Res Function(_$PatternInsightImpl) then,
  ) = __$$PatternInsightImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    PatternInsightKind kind,
    String text,
    double confidence,
    int sampleSize,
    DateTime generatedAt,
  });
}

/// @nodoc
class __$$PatternInsightImplCopyWithImpl<$Res>
    extends _$PatternInsightCopyWithImpl<$Res, _$PatternInsightImpl>
    implements _$$PatternInsightImplCopyWith<$Res> {
  __$$PatternInsightImplCopyWithImpl(
    _$PatternInsightImpl _value,
    $Res Function(_$PatternInsightImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PatternInsight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? text = null,
    Object? confidence = null,
    Object? sampleSize = null,
    Object? generatedAt = null,
  }) {
    return _then(
      _$PatternInsightImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as PatternInsightKind,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        sampleSize: null == sampleSize
            ? _value.sampleSize
            : sampleSize // ignore: cast_nullable_to_non_nullable
                  as int,
        generatedAt: null == generatedAt
            ? _value.generatedAt
            : generatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PatternInsightImpl implements _PatternInsight {
  const _$PatternInsightImpl({
    required this.id,
    required this.kind,
    required this.text,
    required this.confidence,
    required this.sampleSize,
    required this.generatedAt,
  });

  factory _$PatternInsightImpl.fromJson(Map<String, dynamic> json) =>
      _$$PatternInsightImplFromJson(json);

  @override
  final String id;
  @override
  final PatternInsightKind kind;
  @override
  final String text;
  @override
  final double confidence;
  @override
  final int sampleSize;
  @override
  final DateTime generatedAt;

  @override
  String toString() {
    return 'PatternInsight(id: $id, kind: $kind, text: $text, confidence: $confidence, sampleSize: $sampleSize, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PatternInsightImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.sampleSize, sampleSize) ||
                other.sampleSize == sampleSize) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    text,
    confidence,
    sampleSize,
    generatedAt,
  );

  /// Create a copy of PatternInsight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PatternInsightImplCopyWith<_$PatternInsightImpl> get copyWith =>
      __$$PatternInsightImplCopyWithImpl<_$PatternInsightImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PatternInsightImplToJson(this);
  }
}

abstract class _PatternInsight implements PatternInsight {
  const factory _PatternInsight({
    required final String id,
    required final PatternInsightKind kind,
    required final String text,
    required final double confidence,
    required final int sampleSize,
    required final DateTime generatedAt,
  }) = _$PatternInsightImpl;

  factory _PatternInsight.fromJson(Map<String, dynamic> json) =
      _$PatternInsightImpl.fromJson;

  @override
  String get id;
  @override
  PatternInsightKind get kind;
  @override
  String get text;
  @override
  double get confidence;
  @override
  int get sampleSize;
  @override
  DateTime get generatedAt;

  /// Create a copy of PatternInsight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PatternInsightImplCopyWith<_$PatternInsightImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
