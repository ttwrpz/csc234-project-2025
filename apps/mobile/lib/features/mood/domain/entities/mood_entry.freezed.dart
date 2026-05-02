// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MoodEntry {

 String get id; String get userId; MoodType get mood; int get intensity; String get text; DateTime get createdAt; DateTime? get updatedAt; List<String> get mediaRefs;
/// Create a copy of MoodEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodEntryCopyWith<MoodEntry> get copyWith => _$MoodEntryCopyWithImpl<MoodEntry>(this as MoodEntry, _$identity);

  /// Serializes this MoodEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.mediaRefs, mediaRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,mood,intensity,text,createdAt,updatedAt,const DeepCollectionEquality().hash(mediaRefs));

@override
String toString() {
  return 'MoodEntry(id: $id, userId: $userId, mood: $mood, intensity: $intensity, text: $text, createdAt: $createdAt, updatedAt: $updatedAt, mediaRefs: $mediaRefs)';
}


}

/// @nodoc
abstract mixin class $MoodEntryCopyWith<$Res>  {
  factory $MoodEntryCopyWith(MoodEntry value, $Res Function(MoodEntry) _then) = _$MoodEntryCopyWithImpl;
@useResult
$Res call({
 String id, String userId, MoodType mood, int intensity, String text, DateTime createdAt, DateTime? updatedAt, List<String> mediaRefs
});




}
/// @nodoc
class _$MoodEntryCopyWithImpl<$Res>
    implements $MoodEntryCopyWith<$Res> {
  _$MoodEntryCopyWithImpl(this._self, this._then);

  final MoodEntry _self;
  final $Res Function(MoodEntry) _then;

/// Create a copy of MoodEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? mood = null,Object? intensity = null,Object? text = null,Object? createdAt = null,Object? updatedAt = freezed,Object? mediaRefs = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaRefs: null == mediaRefs ? _self.mediaRefs : mediaRefs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MoodEntry].
extension MoodEntryPatterns on MoodEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoodEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoodEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoodEntry value)  $default,){
final _that = this;
switch (_that) {
case _MoodEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoodEntry value)?  $default,){
final _that = this;
switch (_that) {
case _MoodEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  MoodType mood,  int intensity,  String text,  DateTime createdAt,  DateTime? updatedAt,  List<String> mediaRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoodEntry() when $default != null:
return $default(_that.id,_that.userId,_that.mood,_that.intensity,_that.text,_that.createdAt,_that.updatedAt,_that.mediaRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  MoodType mood,  int intensity,  String text,  DateTime createdAt,  DateTime? updatedAt,  List<String> mediaRefs)  $default,) {final _that = this;
switch (_that) {
case _MoodEntry():
return $default(_that.id,_that.userId,_that.mood,_that.intensity,_that.text,_that.createdAt,_that.updatedAt,_that.mediaRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  MoodType mood,  int intensity,  String text,  DateTime createdAt,  DateTime? updatedAt,  List<String> mediaRefs)?  $default,) {final _that = this;
switch (_that) {
case _MoodEntry() when $default != null:
return $default(_that.id,_that.userId,_that.mood,_that.intensity,_that.text,_that.createdAt,_that.updatedAt,_that.mediaRefs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoodEntry extends MoodEntry {
  const _MoodEntry({required this.id, required this.userId, required this.mood, required this.intensity, required this.text, required this.createdAt, this.updatedAt, final  List<String> mediaRefs = const <String>[]}): _mediaRefs = mediaRefs,super._();
  factory _MoodEntry.fromJson(Map<String, dynamic> json) => _$MoodEntryFromJson(json);

@override final  String id;
@override final  String userId;
@override final  MoodType mood;
@override final  int intensity;
@override final  String text;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;
 final  List<String> _mediaRefs;
@override@JsonKey() List<String> get mediaRefs {
  if (_mediaRefs is EqualUnmodifiableListView) return _mediaRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaRefs);
}


/// Create a copy of MoodEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoodEntryCopyWith<_MoodEntry> get copyWith => __$MoodEntryCopyWithImpl<_MoodEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoodEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoodEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._mediaRefs, _mediaRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,mood,intensity,text,createdAt,updatedAt,const DeepCollectionEquality().hash(_mediaRefs));

@override
String toString() {
  return 'MoodEntry(id: $id, userId: $userId, mood: $mood, intensity: $intensity, text: $text, createdAt: $createdAt, updatedAt: $updatedAt, mediaRefs: $mediaRefs)';
}


}

/// @nodoc
abstract mixin class _$MoodEntryCopyWith<$Res> implements $MoodEntryCopyWith<$Res> {
  factory _$MoodEntryCopyWith(_MoodEntry value, $Res Function(_MoodEntry) _then) = __$MoodEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, MoodType mood, int intensity, String text, DateTime createdAt, DateTime? updatedAt, List<String> mediaRefs
});




}
/// @nodoc
class __$MoodEntryCopyWithImpl<$Res>
    implements _$MoodEntryCopyWith<$Res> {
  __$MoodEntryCopyWithImpl(this._self, this._then);

  final _MoodEntry _self;
  final $Res Function(_MoodEntry) _then;

/// Create a copy of MoodEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? mood = null,Object? intensity = null,Object? text = null,Object? createdAt = null,Object? updatedAt = freezed,Object? mediaRefs = null,}) {
  return _then(_MoodEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaRefs: null == mediaRefs ? _self._mediaRefs : mediaRefs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
