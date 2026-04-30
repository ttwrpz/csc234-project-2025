// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MoodDraft {
  MoodType? get mood => throw _privateConstructorUsedError;
  int get intensity => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  List<String> get mediaRefs => throw _privateConstructorUsedError;
  List<MoodMedia> get pickedMedia => throw _privateConstructorUsedError;

  /// Create a copy of MoodDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoodDraftCopyWith<MoodDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoodDraftCopyWith<$Res> {
  factory $MoodDraftCopyWith(MoodDraft value, $Res Function(MoodDraft) then) =
      _$MoodDraftCopyWithImpl<$Res, MoodDraft>;
  @useResult
  $Res call({
    MoodType? mood,
    int intensity,
    String text,
    List<String> mediaRefs,
    List<MoodMedia> pickedMedia,
  });
}

/// @nodoc
class _$MoodDraftCopyWithImpl<$Res, $Val extends MoodDraft>
    implements $MoodDraftCopyWith<$Res> {
  _$MoodDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoodDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = freezed,
    Object? intensity = null,
    Object? text = null,
    Object? mediaRefs = null,
    Object? pickedMedia = null,
  }) {
    return _then(
      _value.copyWith(
            mood: freezed == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as MoodType?,
            intensity: null == intensity
                ? _value.intensity
                : intensity // ignore: cast_nullable_to_non_nullable
                      as int,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            mediaRefs: null == mediaRefs
                ? _value.mediaRefs
                : mediaRefs // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            pickedMedia: null == pickedMedia
                ? _value.pickedMedia
                : pickedMedia // ignore: cast_nullable_to_non_nullable
                      as List<MoodMedia>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MoodDraftImplCopyWith<$Res>
    implements $MoodDraftCopyWith<$Res> {
  factory _$$MoodDraftImplCopyWith(
    _$MoodDraftImpl value,
    $Res Function(_$MoodDraftImpl) then,
  ) = __$$MoodDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    MoodType? mood,
    int intensity,
    String text,
    List<String> mediaRefs,
    List<MoodMedia> pickedMedia,
  });
}

/// @nodoc
class __$$MoodDraftImplCopyWithImpl<$Res>
    extends _$MoodDraftCopyWithImpl<$Res, _$MoodDraftImpl>
    implements _$$MoodDraftImplCopyWith<$Res> {
  __$$MoodDraftImplCopyWithImpl(
    _$MoodDraftImpl _value,
    $Res Function(_$MoodDraftImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoodDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = freezed,
    Object? intensity = null,
    Object? text = null,
    Object? mediaRefs = null,
    Object? pickedMedia = null,
  }) {
    return _then(
      _$MoodDraftImpl(
        mood: freezed == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as MoodType?,
        intensity: null == intensity
            ? _value.intensity
            : intensity // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        mediaRefs: null == mediaRefs
            ? _value._mediaRefs
            : mediaRefs // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        pickedMedia: null == pickedMedia
            ? _value._pickedMedia
            : pickedMedia // ignore: cast_nullable_to_non_nullable
                  as List<MoodMedia>,
      ),
    );
  }
}

/// @nodoc

class _$MoodDraftImpl extends _MoodDraft {
  const _$MoodDraftImpl({
    this.mood,
    this.intensity = 3,
    this.text = '',
    final List<String> mediaRefs = const <String>[],
    final List<MoodMedia> pickedMedia = const <MoodMedia>[],
  }) : _mediaRefs = mediaRefs,
       _pickedMedia = pickedMedia,
       super._();

  @override
  final MoodType? mood;
  @override
  @JsonKey()
  final int intensity;
  @override
  @JsonKey()
  final String text;
  final List<String> _mediaRefs;
  @override
  @JsonKey()
  List<String> get mediaRefs {
    if (_mediaRefs is EqualUnmodifiableListView) return _mediaRefs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mediaRefs);
  }

  final List<MoodMedia> _pickedMedia;
  @override
  @JsonKey()
  List<MoodMedia> get pickedMedia {
    if (_pickedMedia is EqualUnmodifiableListView) return _pickedMedia;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pickedMedia);
  }

  @override
  String toString() {
    return 'MoodDraft(mood: $mood, intensity: $intensity, text: $text, mediaRefs: $mediaRefs, pickedMedia: $pickedMedia)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoodDraftImpl &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(
              other._mediaRefs,
              _mediaRefs,
            ) &&
            const DeepCollectionEquality().equals(
              other._pickedMedia,
              _pickedMedia,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    mood,
    intensity,
    text,
    const DeepCollectionEquality().hash(_mediaRefs),
    const DeepCollectionEquality().hash(_pickedMedia),
  );

  /// Create a copy of MoodDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoodDraftImplCopyWith<_$MoodDraftImpl> get copyWith =>
      __$$MoodDraftImplCopyWithImpl<_$MoodDraftImpl>(this, _$identity);
}

abstract class _MoodDraft extends MoodDraft {
  const factory _MoodDraft({
    final MoodType? mood,
    final int intensity,
    final String text,
    final List<String> mediaRefs,
    final List<MoodMedia> pickedMedia,
  }) = _$MoodDraftImpl;
  const _MoodDraft._() : super._();

  @override
  MoodType? get mood;
  @override
  int get intensity;
  @override
  String get text;
  @override
  List<String> get mediaRefs;
  @override
  List<MoodMedia> get pickedMedia;

  /// Create a copy of MoodDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoodDraftImplCopyWith<_$MoodDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
