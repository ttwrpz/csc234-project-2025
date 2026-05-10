// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiSuggestion {

 MoodType get mood; double get confidence; String get rationale; AiSuggestionAlternative? get alternative; AiSafetyFlag? get safetyFlag; Duration get latency;/// Inferred 1..5 intensity from the model. The Log Mood UI uses
/// this to pre-fill the intensity slider when the user accepts
/// the AI suggestion. Defaults to 3 (neutral) on the wire when
/// the model omits it; clamped to [1, 5] by both the server and
/// the Dart DTO mapper.
 int get intensity;
/// Create a copy of AiSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiSuggestionCopyWith<AiSuggestion> get copyWith => _$AiSuggestionCopyWithImpl<AiSuggestion>(this as AiSuggestion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiSuggestion&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.alternative, alternative) || other.alternative == alternative)&&(identical(other.safetyFlag, safetyFlag) || other.safetyFlag == safetyFlag)&&(identical(other.latency, latency) || other.latency == latency)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}


@override
int get hashCode => Object.hash(runtimeType,mood,confidence,rationale,alternative,safetyFlag,latency,intensity);

@override
String toString() {
  return 'AiSuggestion(mood: $mood, confidence: $confidence, rationale: $rationale, alternative: $alternative, safetyFlag: $safetyFlag, latency: $latency, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $AiSuggestionCopyWith<$Res>  {
  factory $AiSuggestionCopyWith(AiSuggestion value, $Res Function(AiSuggestion) _then) = _$AiSuggestionCopyWithImpl;
@useResult
$Res call({
 MoodType mood, double confidence, String rationale, AiSuggestionAlternative? alternative, AiSafetyFlag? safetyFlag, Duration latency, int intensity
});


$AiSuggestionAlternativeCopyWith<$Res>? get alternative;

}
/// @nodoc
class _$AiSuggestionCopyWithImpl<$Res>
    implements $AiSuggestionCopyWith<$Res> {
  _$AiSuggestionCopyWithImpl(this._self, this._then);

  final AiSuggestion _self;
  final $Res Function(AiSuggestion) _then;

/// Create a copy of AiSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mood = null,Object? confidence = null,Object? rationale = null,Object? alternative = freezed,Object? safetyFlag = freezed,Object? latency = null,Object? intensity = null,}) {
  return _then(_self.copyWith(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,alternative: freezed == alternative ? _self.alternative : alternative // ignore: cast_nullable_to_non_nullable
as AiSuggestionAlternative?,safetyFlag: freezed == safetyFlag ? _self.safetyFlag : safetyFlag // ignore: cast_nullable_to_non_nullable
as AiSafetyFlag?,latency: null == latency ? _self.latency : latency // ignore: cast_nullable_to_non_nullable
as Duration,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AiSuggestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiSuggestionAlternativeCopyWith<$Res>? get alternative {
    if (_self.alternative == null) {
    return null;
  }

  return $AiSuggestionAlternativeCopyWith<$Res>(_self.alternative!, (value) {
    return _then(_self.copyWith(alternative: value));
  });
}
}


/// Adds pattern-matching-related methods to [AiSuggestion].
extension AiSuggestionPatterns on AiSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _AiSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _AiSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MoodType mood,  double confidence,  String rationale,  AiSuggestionAlternative? alternative,  AiSafetyFlag? safetyFlag,  Duration latency,  int intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiSuggestion() when $default != null:
return $default(_that.mood,_that.confidence,_that.rationale,_that.alternative,_that.safetyFlag,_that.latency,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MoodType mood,  double confidence,  String rationale,  AiSuggestionAlternative? alternative,  AiSafetyFlag? safetyFlag,  Duration latency,  int intensity)  $default,) {final _that = this;
switch (_that) {
case _AiSuggestion():
return $default(_that.mood,_that.confidence,_that.rationale,_that.alternative,_that.safetyFlag,_that.latency,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MoodType mood,  double confidence,  String rationale,  AiSuggestionAlternative? alternative,  AiSafetyFlag? safetyFlag,  Duration latency,  int intensity)?  $default,) {final _that = this;
switch (_that) {
case _AiSuggestion() when $default != null:
return $default(_that.mood,_that.confidence,_that.rationale,_that.alternative,_that.safetyFlag,_that.latency,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc


class _AiSuggestion implements AiSuggestion {
  const _AiSuggestion({required this.mood, required this.confidence, required this.rationale, this.alternative, this.safetyFlag, required this.latency, this.intensity = 3}): assert(confidence >= 0 && confidence <= 1, 'confidence must be in [0, 1]'),assert(intensity >= 1 && intensity <= 5, 'intensity must be in [1, 5]');
  

@override final  MoodType mood;
@override final  double confidence;
@override final  String rationale;
@override final  AiSuggestionAlternative? alternative;
@override final  AiSafetyFlag? safetyFlag;
@override final  Duration latency;
/// Inferred 1..5 intensity from the model. The Log Mood UI uses
/// this to pre-fill the intensity slider when the user accepts
/// the AI suggestion. Defaults to 3 (neutral) on the wire when
/// the model omits it; clamped to [1, 5] by both the server and
/// the Dart DTO mapper.
@override@JsonKey() final  int intensity;

/// Create a copy of AiSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiSuggestionCopyWith<_AiSuggestion> get copyWith => __$AiSuggestionCopyWithImpl<_AiSuggestion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiSuggestion&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.rationale, rationale) || other.rationale == rationale)&&(identical(other.alternative, alternative) || other.alternative == alternative)&&(identical(other.safetyFlag, safetyFlag) || other.safetyFlag == safetyFlag)&&(identical(other.latency, latency) || other.latency == latency)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}


@override
int get hashCode => Object.hash(runtimeType,mood,confidence,rationale,alternative,safetyFlag,latency,intensity);

@override
String toString() {
  return 'AiSuggestion(mood: $mood, confidence: $confidence, rationale: $rationale, alternative: $alternative, safetyFlag: $safetyFlag, latency: $latency, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$AiSuggestionCopyWith<$Res> implements $AiSuggestionCopyWith<$Res> {
  factory _$AiSuggestionCopyWith(_AiSuggestion value, $Res Function(_AiSuggestion) _then) = __$AiSuggestionCopyWithImpl;
@override @useResult
$Res call({
 MoodType mood, double confidence, String rationale, AiSuggestionAlternative? alternative, AiSafetyFlag? safetyFlag, Duration latency, int intensity
});


@override $AiSuggestionAlternativeCopyWith<$Res>? get alternative;

}
/// @nodoc
class __$AiSuggestionCopyWithImpl<$Res>
    implements _$AiSuggestionCopyWith<$Res> {
  __$AiSuggestionCopyWithImpl(this._self, this._then);

  final _AiSuggestion _self;
  final $Res Function(_AiSuggestion) _then;

/// Create a copy of AiSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mood = null,Object? confidence = null,Object? rationale = null,Object? alternative = freezed,Object? safetyFlag = freezed,Object? latency = null,Object? intensity = null,}) {
  return _then(_AiSuggestion(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,alternative: freezed == alternative ? _self.alternative : alternative // ignore: cast_nullable_to_non_nullable
as AiSuggestionAlternative?,safetyFlag: freezed == safetyFlag ? _self.safetyFlag : safetyFlag // ignore: cast_nullable_to_non_nullable
as AiSafetyFlag?,latency: null == latency ? _self.latency : latency // ignore: cast_nullable_to_non_nullable
as Duration,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AiSuggestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiSuggestionAlternativeCopyWith<$Res>? get alternative {
    if (_self.alternative == null) {
    return null;
  }

  return $AiSuggestionAlternativeCopyWith<$Res>(_self.alternative!, (value) {
    return _then(_self.copyWith(alternative: value));
  });
}
}

/// @nodoc
mixin _$AiSuggestionAlternative {

 MoodType get mood; double get confidence;
/// Create a copy of AiSuggestionAlternative
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiSuggestionAlternativeCopyWith<AiSuggestionAlternative> get copyWith => _$AiSuggestionAlternativeCopyWithImpl<AiSuggestionAlternative>(this as AiSuggestionAlternative, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiSuggestionAlternative&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,mood,confidence);

@override
String toString() {
  return 'AiSuggestionAlternative(mood: $mood, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $AiSuggestionAlternativeCopyWith<$Res>  {
  factory $AiSuggestionAlternativeCopyWith(AiSuggestionAlternative value, $Res Function(AiSuggestionAlternative) _then) = _$AiSuggestionAlternativeCopyWithImpl;
@useResult
$Res call({
 MoodType mood, double confidence
});




}
/// @nodoc
class _$AiSuggestionAlternativeCopyWithImpl<$Res>
    implements $AiSuggestionAlternativeCopyWith<$Res> {
  _$AiSuggestionAlternativeCopyWithImpl(this._self, this._then);

  final AiSuggestionAlternative _self;
  final $Res Function(AiSuggestionAlternative) _then;

/// Create a copy of AiSuggestionAlternative
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mood = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AiSuggestionAlternative].
extension AiSuggestionAlternativePatterns on AiSuggestionAlternative {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiSuggestionAlternative value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiSuggestionAlternative() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiSuggestionAlternative value)  $default,){
final _that = this;
switch (_that) {
case _AiSuggestionAlternative():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiSuggestionAlternative value)?  $default,){
final _that = this;
switch (_that) {
case _AiSuggestionAlternative() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MoodType mood,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiSuggestionAlternative() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MoodType mood,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _AiSuggestionAlternative():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MoodType mood,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _AiSuggestionAlternative() when $default != null:
return $default(_that.mood,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _AiSuggestionAlternative implements AiSuggestionAlternative {
  const _AiSuggestionAlternative({required this.mood, required this.confidence}): assert(confidence >= 0 && confidence <= 1, 'confidence must be in [0, 1]');
  

@override final  MoodType mood;
@override final  double confidence;

/// Create a copy of AiSuggestionAlternative
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiSuggestionAlternativeCopyWith<_AiSuggestionAlternative> get copyWith => __$AiSuggestionAlternativeCopyWithImpl<_AiSuggestionAlternative>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiSuggestionAlternative&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,mood,confidence);

@override
String toString() {
  return 'AiSuggestionAlternative(mood: $mood, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$AiSuggestionAlternativeCopyWith<$Res> implements $AiSuggestionAlternativeCopyWith<$Res> {
  factory _$AiSuggestionAlternativeCopyWith(_AiSuggestionAlternative value, $Res Function(_AiSuggestionAlternative) _then) = __$AiSuggestionAlternativeCopyWithImpl;
@override @useResult
$Res call({
 MoodType mood, double confidence
});




}
/// @nodoc
class __$AiSuggestionAlternativeCopyWithImpl<$Res>
    implements _$AiSuggestionAlternativeCopyWith<$Res> {
  __$AiSuggestionAlternativeCopyWithImpl(this._self, this._then);

  final _AiSuggestionAlternative _self;
  final $Res Function(_AiSuggestionAlternative) _then;

/// Create a copy of AiSuggestionAlternative
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mood = null,Object? confidence = null,}) {
  return _then(_AiSuggestionAlternative(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as MoodType,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
