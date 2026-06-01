// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MoodMedia {

/// Device-side file URI returned by the picker. Treat as ephemeral -
/// callers must upload before the user backgrounds the app for long.
 String get localPath; MoodMediaKind get kind; int get sizeBytes;/// MIME type detected from the picker (`XFile.mimeType`) or, when null,
/// inferred from the filename via `package:mime`.
 String get mimeType;
/// Create a copy of MoodMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodMediaCopyWith<MoodMedia> get copyWith => _$MoodMediaCopyWithImpl<MoodMedia>(this as MoodMedia, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodMedia&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,localPath,kind,sizeBytes,mimeType);

@override
String toString() {
  return 'MoodMedia(localPath: $localPath, kind: $kind, sizeBytes: $sizeBytes, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $MoodMediaCopyWith<$Res>  {
  factory $MoodMediaCopyWith(MoodMedia value, $Res Function(MoodMedia) _then) = _$MoodMediaCopyWithImpl;
@useResult
$Res call({
 String localPath, MoodMediaKind kind, int sizeBytes, String mimeType
});




}
/// @nodoc
class _$MoodMediaCopyWithImpl<$Res>
    implements $MoodMediaCopyWith<$Res> {
  _$MoodMediaCopyWithImpl(this._self, this._then);

  final MoodMedia _self;
  final $Res Function(MoodMedia) _then;

/// Create a copy of MoodMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localPath = null,Object? kind = null,Object? sizeBytes = null,Object? mimeType = null,}) {
  return _then(_self.copyWith(
localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MoodMediaKind,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MoodMedia].
extension MoodMediaPatterns on MoodMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoodMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoodMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoodMedia value)  $default,){
final _that = this;
switch (_that) {
case _MoodMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoodMedia value)?  $default,){
final _that = this;
switch (_that) {
case _MoodMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String localPath,  MoodMediaKind kind,  int sizeBytes,  String mimeType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoodMedia() when $default != null:
return $default(_that.localPath,_that.kind,_that.sizeBytes,_that.mimeType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String localPath,  MoodMediaKind kind,  int sizeBytes,  String mimeType)  $default,) {final _that = this;
switch (_that) {
case _MoodMedia():
return $default(_that.localPath,_that.kind,_that.sizeBytes,_that.mimeType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String localPath,  MoodMediaKind kind,  int sizeBytes,  String mimeType)?  $default,) {final _that = this;
switch (_that) {
case _MoodMedia() when $default != null:
return $default(_that.localPath,_that.kind,_that.sizeBytes,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc


class _MoodMedia implements MoodMedia {
  const _MoodMedia({required this.localPath, required this.kind, required this.sizeBytes, required this.mimeType});
  

/// Device-side file URI returned by the picker. Treat as ephemeral -
/// callers must upload before the user backgrounds the app for long.
@override final  String localPath;
@override final  MoodMediaKind kind;
@override final  int sizeBytes;
/// MIME type detected from the picker (`XFile.mimeType`) or, when null,
/// inferred from the filename via `package:mime`.
@override final  String mimeType;

/// Create a copy of MoodMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoodMediaCopyWith<_MoodMedia> get copyWith => __$MoodMediaCopyWithImpl<_MoodMedia>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoodMedia&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,localPath,kind,sizeBytes,mimeType);

@override
String toString() {
  return 'MoodMedia(localPath: $localPath, kind: $kind, sizeBytes: $sizeBytes, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class _$MoodMediaCopyWith<$Res> implements $MoodMediaCopyWith<$Res> {
  factory _$MoodMediaCopyWith(_MoodMedia value, $Res Function(_MoodMedia) _then) = __$MoodMediaCopyWithImpl;
@override @useResult
$Res call({
 String localPath, MoodMediaKind kind, int sizeBytes, String mimeType
});




}
/// @nodoc
class __$MoodMediaCopyWithImpl<$Res>
    implements _$MoodMediaCopyWith<$Res> {
  __$MoodMediaCopyWithImpl(this._self, this._then);

  final _MoodMedia _self;
  final $Res Function(_MoodMedia) _then;

/// Create a copy of MoodMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localPath = null,Object? kind = null,Object? sizeBytes = null,Object? mimeType = null,}) {
  return _then(_MoodMedia(
localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MoodMediaKind,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
