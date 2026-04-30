// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MoodMedia {
  /// Device-side file URI returned by the picker. Treat as ephemeral —
  /// callers must upload before the user backgrounds the app for long.
  String get localPath => throw _privateConstructorUsedError;
  MoodMediaKind get kind => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;

  /// MIME type detected from the picker (`XFile.mimeType`) or, when null,
  /// inferred from the filename via `package:mime`.
  String get mimeType => throw _privateConstructorUsedError;

  /// Create a copy of MoodMedia
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoodMediaCopyWith<MoodMedia> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoodMediaCopyWith<$Res> {
  factory $MoodMediaCopyWith(MoodMedia value, $Res Function(MoodMedia) then) =
      _$MoodMediaCopyWithImpl<$Res, MoodMedia>;
  @useResult
  $Res call({
    String localPath,
    MoodMediaKind kind,
    int sizeBytes,
    String mimeType,
  });
}

/// @nodoc
class _$MoodMediaCopyWithImpl<$Res, $Val extends MoodMedia>
    implements $MoodMediaCopyWith<$Res> {
  _$MoodMediaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoodMedia
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localPath = null,
    Object? kind = null,
    Object? sizeBytes = null,
    Object? mimeType = null,
  }) {
    return _then(
      _value.copyWith(
            localPath: null == localPath
                ? _value.localPath
                : localPath // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as MoodMediaKind,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            mimeType: null == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MoodMediaImplCopyWith<$Res>
    implements $MoodMediaCopyWith<$Res> {
  factory _$$MoodMediaImplCopyWith(
    _$MoodMediaImpl value,
    $Res Function(_$MoodMediaImpl) then,
  ) = __$$MoodMediaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String localPath,
    MoodMediaKind kind,
    int sizeBytes,
    String mimeType,
  });
}

/// @nodoc
class __$$MoodMediaImplCopyWithImpl<$Res>
    extends _$MoodMediaCopyWithImpl<$Res, _$MoodMediaImpl>
    implements _$$MoodMediaImplCopyWith<$Res> {
  __$$MoodMediaImplCopyWithImpl(
    _$MoodMediaImpl _value,
    $Res Function(_$MoodMediaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoodMedia
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localPath = null,
    Object? kind = null,
    Object? sizeBytes = null,
    Object? mimeType = null,
  }) {
    return _then(
      _$MoodMediaImpl(
        localPath: null == localPath
            ? _value.localPath
            : localPath // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as MoodMediaKind,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        mimeType: null == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$MoodMediaImpl implements _MoodMedia {
  const _$MoodMediaImpl({
    required this.localPath,
    required this.kind,
    required this.sizeBytes,
    required this.mimeType,
  });

  /// Device-side file URI returned by the picker. Treat as ephemeral —
  /// callers must upload before the user backgrounds the app for long.
  @override
  final String localPath;
  @override
  final MoodMediaKind kind;
  @override
  final int sizeBytes;

  /// MIME type detected from the picker (`XFile.mimeType`) or, when null,
  /// inferred from the filename via `package:mime`.
  @override
  final String mimeType;

  @override
  String toString() {
    return 'MoodMedia(localPath: $localPath, kind: $kind, sizeBytes: $sizeBytes, mimeType: $mimeType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoodMediaImpl &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, localPath, kind, sizeBytes, mimeType);

  /// Create a copy of MoodMedia
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoodMediaImplCopyWith<_$MoodMediaImpl> get copyWith =>
      __$$MoodMediaImplCopyWithImpl<_$MoodMediaImpl>(this, _$identity);
}

abstract class _MoodMedia implements MoodMedia {
  const factory _MoodMedia({
    required final String localPath,
    required final MoodMediaKind kind,
    required final int sizeBytes,
    required final String mimeType,
  }) = _$MoodMediaImpl;

  /// Device-side file URI returned by the picker. Treat as ephemeral —
  /// callers must upload before the user backgrounds the app for long.
  @override
  String get localPath;
  @override
  MoodMediaKind get kind;
  @override
  int get sizeBytes;

  /// MIME type detected from the picker (`XFile.mimeType`) or, when null,
  /// inferred from the filename via `package:mime`.
  @override
  String get mimeType;

  /// Create a copy of MoodMedia
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoodMediaImplCopyWith<_$MoodMediaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
