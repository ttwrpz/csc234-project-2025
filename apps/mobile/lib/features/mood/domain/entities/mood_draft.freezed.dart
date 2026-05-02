// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MoodDraft {

 MoodType? get mood; int get intensity; String get text; List<String> get mediaRefs; List<MoodMedia> get pickedMedia;
/// Create a copy of MoodDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodDraftCopyWith<MoodDraft> get copyWith => _$MoodDraftCopyWithImpl<MoodDraft>(this as MoodDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodDraft&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.mediaRefs, mediaRefs)&&const DeepCollectionEquality().equals(other.pickedMedia, pickedMedia));
}


@override
int get hashCode => Object.hash(runtimeType,mood,intensity,text,const DeepCollectionEquality().hash(mediaRefs),const DeepCollectionEquality().hash(pickedMedia));

@override
String toString() {
  return 'MoodDraft(mood: $mood, intensity: $intensity, text: $text, mediaRefs: $mediaRefs, pickedMedia: $pickedMedia)';
}


}

/// @nodoc
abstract mixin class $MoodDraftCopyWith<$Res>  {
  factory $MoodDraftCopyWith(MoodDraft value, $Res Function(MoodDraft) _then) = _$MoodDraftCopyWithImpl;
@useResult
$Res call({
 MoodType? mood, int intensity, String text, List<String> mediaRefs, List<MoodMedia> pickedMedia
});




}
/// @nodoc
class _$MoodDraftCopyWithImpl<$Res>
    implements $MoodDraftCopyWith<$Res> {
  _$MoodDraftCopyWithImpl(this._self, this._then);

  final MoodDraft _self;
  final $Res Function(MoodDraft) _then;

/// Create a copy of MoodDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mood = freezed,Object? intensity = null,Object? text = null,Object? mediaRefs = null,Object? pickedMedia = null,}) {
  return _then(_self.copyWith(
mood: freezed == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType?,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mediaRefs: null == mediaRefs ? _self.mediaRefs : mediaRefs // ignore: cast_nullable_to_non_nullable
as List<String>,pickedMedia: null == pickedMedia ? _self.pickedMedia : pickedMedia // ignore: cast_nullable_to_non_nullable
as List<MoodMedia>,
  ));
}

}


/// Adds pattern-matching-related methods to [MoodDraft].
extension MoodDraftPatterns on MoodDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoodDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoodDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoodDraft value)  $default,){
final _that = this;
switch (_that) {
case _MoodDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoodDraft value)?  $default,){
final _that = this;
switch (_that) {
case _MoodDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MoodType? mood,  int intensity,  String text,  List<String> mediaRefs,  List<MoodMedia> pickedMedia)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoodDraft() when $default != null:
return $default(_that.mood,_that.intensity,_that.text,_that.mediaRefs,_that.pickedMedia);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MoodType? mood,  int intensity,  String text,  List<String> mediaRefs,  List<MoodMedia> pickedMedia)  $default,) {final _that = this;
switch (_that) {
case _MoodDraft():
return $default(_that.mood,_that.intensity,_that.text,_that.mediaRefs,_that.pickedMedia);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MoodType? mood,  int intensity,  String text,  List<String> mediaRefs,  List<MoodMedia> pickedMedia)?  $default,) {final _that = this;
switch (_that) {
case _MoodDraft() when $default != null:
return $default(_that.mood,_that.intensity,_that.text,_that.mediaRefs,_that.pickedMedia);case _:
  return null;

}
}

}

/// @nodoc


class _MoodDraft extends MoodDraft {
  const _MoodDraft({this.mood, this.intensity = 3, this.text = '', final  List<String> mediaRefs = const <String>[], final  List<MoodMedia> pickedMedia = const <MoodMedia>[]}): _mediaRefs = mediaRefs,_pickedMedia = pickedMedia,super._();
  

@override final  MoodType? mood;
@override@JsonKey() final  int intensity;
@override@JsonKey() final  String text;
 final  List<String> _mediaRefs;
@override@JsonKey() List<String> get mediaRefs {
  if (_mediaRefs is EqualUnmodifiableListView) return _mediaRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaRefs);
}

 final  List<MoodMedia> _pickedMedia;
@override@JsonKey() List<MoodMedia> get pickedMedia {
  if (_pickedMedia is EqualUnmodifiableListView) return _pickedMedia;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pickedMedia);
}


/// Create a copy of MoodDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoodDraftCopyWith<_MoodDraft> get copyWith => __$MoodDraftCopyWithImpl<_MoodDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoodDraft&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._mediaRefs, _mediaRefs)&&const DeepCollectionEquality().equals(other._pickedMedia, _pickedMedia));
}


@override
int get hashCode => Object.hash(runtimeType,mood,intensity,text,const DeepCollectionEquality().hash(_mediaRefs),const DeepCollectionEquality().hash(_pickedMedia));

@override
String toString() {
  return 'MoodDraft(mood: $mood, intensity: $intensity, text: $text, mediaRefs: $mediaRefs, pickedMedia: $pickedMedia)';
}


}

/// @nodoc
abstract mixin class _$MoodDraftCopyWith<$Res> implements $MoodDraftCopyWith<$Res> {
  factory _$MoodDraftCopyWith(_MoodDraft value, $Res Function(_MoodDraft) _then) = __$MoodDraftCopyWithImpl;
@override @useResult
$Res call({
 MoodType? mood, int intensity, String text, List<String> mediaRefs, List<MoodMedia> pickedMedia
});




}
/// @nodoc
class __$MoodDraftCopyWithImpl<$Res>
    implements _$MoodDraftCopyWith<$Res> {
  __$MoodDraftCopyWithImpl(this._self, this._then);

  final _MoodDraft _self;
  final $Res Function(_MoodDraft) _then;

/// Create a copy of MoodDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mood = freezed,Object? intensity = null,Object? text = null,Object? mediaRefs = null,Object? pickedMedia = null,}) {
  return _then(_MoodDraft(
mood: freezed == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType?,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mediaRefs: null == mediaRefs ? _self._mediaRefs : mediaRefs // ignore: cast_nullable_to_non_nullable
as List<String>,pickedMedia: null == pickedMedia ? _self._pickedMedia : pickedMedia // ignore: cast_nullable_to_non_nullable
as List<MoodMedia>,
  ));
}


}

// dart format on
