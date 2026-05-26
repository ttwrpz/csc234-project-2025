// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_suggestion_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiSuggestionDto {

 bool get ok; int get v; String get requestId; String get mood; double get confidence; AiSuggestionAlternativeDto? get alternative; String get rationale; String? get flag; int get latencyMs; String get modelVersion;/// Inferred 1..5 intensity. Optional on the wire for backward
/// compatibility with older Cloud Function deploys that omit it;
/// defaults to 3 (neutral) when missing.
 int get intensity;
/// Create a copy of AiSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiSuggestionDtoCopyWith<AiSuggestionDto> get copyWith => _$AiSuggestionDtoCopyWithImpl<AiSuggestionDto>(this as AiSuggestionDto, _$identity);

  /// Serializes this AiSuggestionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiSuggestionDto&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.v, v) || other.v == v)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.alternative, alternative) || other.alternative == alternative)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.flag, flag) || other.flag == flag)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,v,requestId,mood,confidence,alternative,rationale,flag,latencyMs,modelVersion,intensity);

@override
String toString() {
  return 'AiSuggestionDto(ok: $ok, v: $v, requestId: $requestId, mood: $mood, confidence: $confidence, alternative: $alternative, rationale: $rationale, flag: $flag, latencyMs: $latencyMs, modelVersion: $modelVersion, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $AiSuggestionDtoCopyWith<$Res>  {
  factory $AiSuggestionDtoCopyWith(AiSuggestionDto value, $Res Function(AiSuggestionDto) _then) = _$AiSuggestionDtoCopyWithImpl;
@useResult
$Res call({
 bool ok, int v, String requestId, String mood, double confidence, AiSuggestionAlternativeDto? alternative, String rationale, String? flag, int latencyMs, String modelVersion, int intensity
});


$AiSuggestionAlternativeDtoCopyWith<$Res>? get alternative;

}
/// @nodoc
class _$AiSuggestionDtoCopyWithImpl<$Res>
    implements $AiSuggestionDtoCopyWith<$Res> {
  _$AiSuggestionDtoCopyWithImpl(this._self, this._then);

  final AiSuggestionDto _self;
  final $Res Function(AiSuggestionDto) _then;

/// Create a copy of AiSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? v = null,Object? requestId = null,Object? mood = null,Object? confidence = null,Object? alternative = freezed,Object? rationale = null,Object? flag = freezed,Object? latencyMs = null,Object? modelVersion = null,Object? intensity = null,}) {
  return _then(_self.copyWith(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,alternative: freezed == alternative ? _self.alternative : alternative // ignore: cast_nullable_to_non_nullable
as AiSuggestionAlternativeDto?,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String?,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AiSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiSuggestionAlternativeDtoCopyWith<$Res>? get alternative {
    if (_self.alternative == null) {
    return null;
  }

  return $AiSuggestionAlternativeDtoCopyWith<$Res>(_self.alternative!, (value) {
    return _then(_self.copyWith(alternative: value));
  });
}
}


/// Adds pattern-matching-related methods to [AiSuggestionDto].
extension AiSuggestionDtoPatterns on AiSuggestionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiSuggestionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiSuggestionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiSuggestionDto value)  $default,){
final _that = this;
switch (_that) {
case _AiSuggestionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiSuggestionDto value)?  $default,){
final _that = this;
switch (_that) {
case _AiSuggestionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  int v,  String requestId,  String mood,  double confidence,  AiSuggestionAlternativeDto? alternative,  String rationale,  String? flag,  int latencyMs,  String modelVersion,  int intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiSuggestionDto() when $default != null:
return $default(_that.ok,_that.v,_that.requestId,_that.mood,_that.confidence,_that.alternative,_that.rationale,_that.flag,_that.latencyMs,_that.modelVersion,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  int v,  String requestId,  String mood,  double confidence,  AiSuggestionAlternativeDto? alternative,  String rationale,  String? flag,  int latencyMs,  String modelVersion,  int intensity)  $default,) {final _that = this;
switch (_that) {
case _AiSuggestionDto():
return $default(_that.ok,_that.v,_that.requestId,_that.mood,_that.confidence,_that.alternative,_that.rationale,_that.flag,_that.latencyMs,_that.modelVersion,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  int v,  String requestId,  String mood,  double confidence,  AiSuggestionAlternativeDto? alternative,  String rationale,  String? flag,  int latencyMs,  String modelVersion,  int intensity)?  $default,) {final _that = this;
switch (_that) {
case _AiSuggestionDto() when $default != null:
return $default(_that.ok,_that.v,_that.requestId,_that.mood,_that.confidence,_that.alternative,_that.rationale,_that.flag,_that.latencyMs,_that.modelVersion,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiSuggestionDto extends AiSuggestionDto {
  const _AiSuggestionDto({required this.ok, required this.v, required this.requestId, required this.mood, required this.confidence, this.alternative, required this.rationale, this.flag, required this.latencyMs, required this.modelVersion, this.intensity = 3}): super._();
  factory _AiSuggestionDto.fromJson(Map<String, dynamic> json) => _$AiSuggestionDtoFromJson(json);

@override final  bool ok;
@override final  int v;
@override final  String requestId;
@override final  String mood;
@override final  double confidence;
@override final  AiSuggestionAlternativeDto? alternative;
@override final  String rationale;
@override final  String? flag;
@override final  int latencyMs;
@override final  String modelVersion;
/// Inferred 1..5 intensity. Optional on the wire for backward
/// compatibility with older Cloud Function deploys that omit it;
/// defaults to 3 (neutral) when missing.
@override@JsonKey() final  int intensity;

/// Create a copy of AiSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiSuggestionDtoCopyWith<_AiSuggestionDto> get copyWith => __$AiSuggestionDtoCopyWithImpl<_AiSuggestionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiSuggestionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiSuggestionDto&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.v, v) || other.v == v)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.alternative, alternative) || other.alternative == alternative)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.flag, flag) || other.flag == flag)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,v,requestId,mood,confidence,alternative,rationale,flag,latencyMs,modelVersion,intensity);

@override
String toString() {
  return 'AiSuggestionDto(ok: $ok, v: $v, requestId: $requestId, mood: $mood, confidence: $confidence, alternative: $alternative, rationale: $rationale, flag: $flag, latencyMs: $latencyMs, modelVersion: $modelVersion, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$AiSuggestionDtoCopyWith<$Res> implements $AiSuggestionDtoCopyWith<$Res> {
  factory _$AiSuggestionDtoCopyWith(_AiSuggestionDto value, $Res Function(_AiSuggestionDto) _then) = __$AiSuggestionDtoCopyWithImpl;
@override @useResult
$Res call({
 bool ok, int v, String requestId, String mood, double confidence, AiSuggestionAlternativeDto? alternative, String rationale, String? flag, int latencyMs, String modelVersion, int intensity
});


@override $AiSuggestionAlternativeDtoCopyWith<$Res>? get alternative;

}
/// @nodoc
class __$AiSuggestionDtoCopyWithImpl<$Res>
    implements _$AiSuggestionDtoCopyWith<$Res> {
  __$AiSuggestionDtoCopyWithImpl(this._self, this._then);

  final _AiSuggestionDto _self;
  final $Res Function(_AiSuggestionDto) _then;

/// Create a copy of AiSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? v = null,Object? requestId = null,Object? mood = null,Object? confidence = null,Object? alternative = freezed,Object? rationale = null,Object? flag = freezed,Object? latencyMs = null,Object? modelVersion = null,Object? intensity = null,}) {
  return _then(_AiSuggestionDto(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,alternative: freezed == alternative ? _self.alternative : alternative // ignore: cast_nullable_to_non_nullable
as AiSuggestionAlternativeDto?,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String?,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AiSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiSuggestionAlternativeDtoCopyWith<$Res>? get alternative {
    if (_self.alternative == null) {
    return null;
  }

  return $AiSuggestionAlternativeDtoCopyWith<$Res>(_self.alternative!, (value) {
    return _then(_self.copyWith(alternative: value));
  });
}
}


/// @nodoc
mixin _$AiSuggestionAlternativeDto {

 String get mood; double get confidence;
/// Create a copy of AiSuggestionAlternativeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiSuggestionAlternativeDtoCopyWith<AiSuggestionAlternativeDto> get copyWith => _$AiSuggestionAlternativeDtoCopyWithImpl<AiSuggestionAlternativeDto>(this as AiSuggestionAlternativeDto, _$identity);

  /// Serializes this AiSuggestionAlternativeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiSuggestionAlternativeDto&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mood,confidence);

@override
String toString() {
  return 'AiSuggestionAlternativeDto(mood: $mood, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $AiSuggestionAlternativeDtoCopyWith<$Res>  {
  factory $AiSuggestionAlternativeDtoCopyWith(AiSuggestionAlternativeDto value, $Res Function(AiSuggestionAlternativeDto) _then) = _$AiSuggestionAlternativeDtoCopyWithImpl;
@useResult
$Res call({
 String mood, double confidence
});




}
/// @nodoc
class _$AiSuggestionAlternativeDtoCopyWithImpl<$Res>
    implements $AiSuggestionAlternativeDtoCopyWith<$Res> {
  _$AiSuggestionAlternativeDtoCopyWithImpl(this._self, this._then);

  final AiSuggestionAlternativeDto _self;
  final $Res Function(AiSuggestionAlternativeDto) _then;

/// Create a copy of AiSuggestionAlternativeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mood = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AiSuggestionAlternativeDto].
extension AiSuggestionAlternativeDtoPatterns on AiSuggestionAlternativeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiSuggestionAlternativeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiSuggestionAlternativeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiSuggestionAlternativeDto value)  $default,){
final _that = this;
switch (_that) {
case _AiSuggestionAlternativeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiSuggestionAlternativeDto value)?  $default,){
final _that = this;
switch (_that) {
case _AiSuggestionAlternativeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mood,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiSuggestionAlternativeDto() when $default != null:
return $default(_that.mood,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mood,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _AiSuggestionAlternativeDto():
return $default(_that.mood,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mood,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _AiSuggestionAlternativeDto() when $default != null:
return $default(_that.mood,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiSuggestionAlternativeDto implements AiSuggestionAlternativeDto {
  const _AiSuggestionAlternativeDto({required this.mood, required this.confidence});
  factory _AiSuggestionAlternativeDto.fromJson(Map<String, dynamic> json) => _$AiSuggestionAlternativeDtoFromJson(json);

@override final  String mood;
@override final  double confidence;

/// Create a copy of AiSuggestionAlternativeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiSuggestionAlternativeDtoCopyWith<_AiSuggestionAlternativeDto> get copyWith => __$AiSuggestionAlternativeDtoCopyWithImpl<_AiSuggestionAlternativeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiSuggestionAlternativeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiSuggestionAlternativeDto&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mood,confidence);

@override
String toString() {
  return 'AiSuggestionAlternativeDto(mood: $mood, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$AiSuggestionAlternativeDtoCopyWith<$Res> implements $AiSuggestionAlternativeDtoCopyWith<$Res> {
  factory _$AiSuggestionAlternativeDtoCopyWith(_AiSuggestionAlternativeDto value, $Res Function(_AiSuggestionAlternativeDto) _then) = __$AiSuggestionAlternativeDtoCopyWithImpl;
@override @useResult
$Res call({
 String mood, double confidence
});




}
/// @nodoc
class __$AiSuggestionAlternativeDtoCopyWithImpl<$Res>
    implements _$AiSuggestionAlternativeDtoCopyWith<$Res> {
  __$AiSuggestionAlternativeDtoCopyWithImpl(this._self, this._then);

  final _AiSuggestionAlternativeDto _self;
  final $Res Function(_AiSuggestionAlternativeDto) _then;

/// Create a copy of AiSuggestionAlternativeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mood = null,Object? confidence = null,}) {
  return _then(_AiSuggestionAlternativeDto(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
