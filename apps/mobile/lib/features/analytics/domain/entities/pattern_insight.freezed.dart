// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pattern_insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PatternInsight {

 String get id; PatternInsightKind get kind; String get text; double get confidence; int get sampleSize; DateTime get generatedAt;
/// Create a copy of PatternInsight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatternInsightCopyWith<PatternInsight> get copyWith => _$PatternInsightCopyWithImpl<PatternInsight>(this as PatternInsight, _$identity);

  /// Serializes this PatternInsight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatternInsight&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.text, text) || other.text == text)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,text,confidence,sampleSize,generatedAt);

@override
String toString() {
  return 'PatternInsight(id: $id, kind: $kind, text: $text, confidence: $confidence, sampleSize: $sampleSize, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class $PatternInsightCopyWith<$Res>  {
  factory $PatternInsightCopyWith(PatternInsight value, $Res Function(PatternInsight) _then) = _$PatternInsightCopyWithImpl;
@useResult
$Res call({
 String id, PatternInsightKind kind, String text, double confidence, int sampleSize, DateTime generatedAt
});




}
/// @nodoc
class _$PatternInsightCopyWithImpl<$Res>
    implements $PatternInsightCopyWith<$Res> {
  _$PatternInsightCopyWithImpl(this._self, this._then);

  final PatternInsight _self;
  final $Res Function(PatternInsight) _then;

/// Create a copy of PatternInsight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? text = null,Object? confidence = null,Object? sampleSize = null,Object? generatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PatternInsightKind,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PatternInsight].
extension PatternInsightPatterns on PatternInsight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatternInsight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatternInsight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatternInsight value)  $default,){
final _that = this;
switch (_that) {
case _PatternInsight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatternInsight value)?  $default,){
final _that = this;
switch (_that) {
case _PatternInsight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PatternInsightKind kind,  String text,  double confidence,  int sampleSize,  DateTime generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatternInsight() when $default != null:
return $default(_that.id,_that.kind,_that.text,_that.confidence,_that.sampleSize,_that.generatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PatternInsightKind kind,  String text,  double confidence,  int sampleSize,  DateTime generatedAt)  $default,) {final _that = this;
switch (_that) {
case _PatternInsight():
return $default(_that.id,_that.kind,_that.text,_that.confidence,_that.sampleSize,_that.generatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PatternInsightKind kind,  String text,  double confidence,  int sampleSize,  DateTime generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PatternInsight() when $default != null:
return $default(_that.id,_that.kind,_that.text,_that.confidence,_that.sampleSize,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatternInsight implements PatternInsight {
  const _PatternInsight({required this.id, required this.kind, required this.text, required this.confidence, required this.sampleSize, required this.generatedAt});
  factory _PatternInsight.fromJson(Map<String, dynamic> json) => _$PatternInsightFromJson(json);

@override final  String id;
@override final  PatternInsightKind kind;
@override final  String text;
@override final  double confidence;
@override final  int sampleSize;
@override final  DateTime generatedAt;

/// Create a copy of PatternInsight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatternInsightCopyWith<_PatternInsight> get copyWith => __$PatternInsightCopyWithImpl<_PatternInsight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatternInsightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatternInsight&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.text, text) || other.text == text)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,text,confidence,sampleSize,generatedAt);

@override
String toString() {
  return 'PatternInsight(id: $id, kind: $kind, text: $text, confidence: $confidence, sampleSize: $sampleSize, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$PatternInsightCopyWith<$Res> implements $PatternInsightCopyWith<$Res> {
  factory _$PatternInsightCopyWith(_PatternInsight value, $Res Function(_PatternInsight) _then) = __$PatternInsightCopyWithImpl;
@override @useResult
$Res call({
 String id, PatternInsightKind kind, String text, double confidence, int sampleSize, DateTime generatedAt
});




}
/// @nodoc
class __$PatternInsightCopyWithImpl<$Res>
    implements _$PatternInsightCopyWith<$Res> {
  __$PatternInsightCopyWithImpl(this._self, this._then);

  final _PatternInsight _self;
  final $Res Function(_PatternInsight) _then;

/// Create a copy of PatternInsight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? text = null,Object? confidence = null,Object? sampleSize = null,Object? generatedAt = null,}) {
  return _then(_PatternInsight(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PatternInsightKind,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
