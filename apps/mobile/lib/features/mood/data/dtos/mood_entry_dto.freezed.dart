// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MoodEntryDto {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get mood => throw _privateConstructorUsedError; // MoodType.name
  int get intensity => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  Timestamp get createdAt => throw _privateConstructorUsedError;
  Timestamp? get updatedAt => throw _privateConstructorUsedError;
  List<String> get mediaRefs => throw _privateConstructorUsedError;

  /// Create a copy of MoodEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoodEntryDtoCopyWith<MoodEntryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoodEntryDtoCopyWith<$Res> {
  factory $MoodEntryDtoCopyWith(
    MoodEntryDto value,
    $Res Function(MoodEntryDto) then,
  ) = _$MoodEntryDtoCopyWithImpl<$Res, MoodEntryDto>;
  @useResult
  $Res call({
    String id,
    String userId,
    String mood,
    int intensity,
    String text,
    Timestamp createdAt,
    Timestamp? updatedAt,
    List<String> mediaRefs,
  });
}

/// @nodoc
class _$MoodEntryDtoCopyWithImpl<$Res, $Val extends MoodEntryDto>
    implements $MoodEntryDtoCopyWith<$Res> {
  _$MoodEntryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoodEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? mood = null,
    Object? intensity = null,
    Object? text = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? mediaRefs = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            mood: null == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as String,
            intensity: null == intensity
                ? _value.intensity
                : intensity // ignore: cast_nullable_to_non_nullable
                      as int,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp?,
            mediaRefs: null == mediaRefs
                ? _value.mediaRefs
                : mediaRefs // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MoodEntryDtoImplCopyWith<$Res>
    implements $MoodEntryDtoCopyWith<$Res> {
  factory _$$MoodEntryDtoImplCopyWith(
    _$MoodEntryDtoImpl value,
    $Res Function(_$MoodEntryDtoImpl) then,
  ) = __$$MoodEntryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String mood,
    int intensity,
    String text,
    Timestamp createdAt,
    Timestamp? updatedAt,
    List<String> mediaRefs,
  });
}

/// @nodoc
class __$$MoodEntryDtoImplCopyWithImpl<$Res>
    extends _$MoodEntryDtoCopyWithImpl<$Res, _$MoodEntryDtoImpl>
    implements _$$MoodEntryDtoImplCopyWith<$Res> {
  __$$MoodEntryDtoImplCopyWithImpl(
    _$MoodEntryDtoImpl _value,
    $Res Function(_$MoodEntryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoodEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? mood = null,
    Object? intensity = null,
    Object? text = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? mediaRefs = null,
  }) {
    return _then(
      _$MoodEntryDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        mood: null == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as String,
        intensity: null == intensity
            ? _value.intensity
            : intensity // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp?,
        mediaRefs: null == mediaRefs
            ? _value._mediaRefs
            : mediaRefs // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$MoodEntryDtoImpl extends _MoodEntryDto {
  const _$MoodEntryDtoImpl({
    required this.id,
    required this.userId,
    required this.mood,
    required this.intensity,
    required this.text,
    required this.createdAt,
    this.updatedAt,
    final List<String> mediaRefs = const <String>[],
  }) : _mediaRefs = mediaRefs,
       super._();

  @override
  final String id;
  @override
  final String userId;
  @override
  final String mood;
  // MoodType.name
  @override
  final int intensity;
  @override
  final String text;
  @override
  final Timestamp createdAt;
  @override
  final Timestamp? updatedAt;
  final List<String> _mediaRefs;
  @override
  @JsonKey()
  List<String> get mediaRefs {
    if (_mediaRefs is EqualUnmodifiableListView) return _mediaRefs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mediaRefs);
  }

  @override
  String toString() {
    return 'MoodEntryDto(id: $id, userId: $userId, mood: $mood, intensity: $intensity, text: $text, createdAt: $createdAt, updatedAt: $updatedAt, mediaRefs: $mediaRefs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoodEntryDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._mediaRefs,
              _mediaRefs,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    mood,
    intensity,
    text,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_mediaRefs),
  );

  /// Create a copy of MoodEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoodEntryDtoImplCopyWith<_$MoodEntryDtoImpl> get copyWith =>
      __$$MoodEntryDtoImplCopyWithImpl<_$MoodEntryDtoImpl>(this, _$identity);
}

abstract class _MoodEntryDto extends MoodEntryDto {
  const factory _MoodEntryDto({
    required final String id,
    required final String userId,
    required final String mood,
    required final int intensity,
    required final String text,
    required final Timestamp createdAt,
    final Timestamp? updatedAt,
    final List<String> mediaRefs,
  }) = _$MoodEntryDtoImpl;
  const _MoodEntryDto._() : super._();

  @override
  String get id;
  @override
  String get userId;
  @override
  String get mood; // MoodType.name
  @override
  int get intensity;
  @override
  String get text;
  @override
  Timestamp get createdAt;
  @override
  Timestamp? get updatedAt;
  @override
  List<String> get mediaRefs;

  /// Create a copy of MoodEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoodEntryDtoImplCopyWith<_$MoodEntryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
