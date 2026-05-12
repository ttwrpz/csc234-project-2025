// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight_window.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InsightWindow {

 DateTime get startDate; DateTime get endDate; int get dayCount; InsightWindowPreset get preset;
/// Create a copy of InsightWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightWindowCopyWith<InsightWindow> get copyWith => _$InsightWindowCopyWithImpl<InsightWindow>(this as InsightWindow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightWindow&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.dayCount, dayCount) || other.dayCount == dayCount)&&(identical(other.preset, preset) || other.preset == preset));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate,dayCount,preset);

@override
String toString() {
  return 'InsightWindow(startDate: $startDate, endDate: $endDate, dayCount: $dayCount, preset: $preset)';
}


}

/// @nodoc
abstract mixin class $InsightWindowCopyWith<$Res>  {
  factory $InsightWindowCopyWith(InsightWindow value, $Res Function(InsightWindow) _then) = _$InsightWindowCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, DateTime endDate, int dayCount, InsightWindowPreset preset
});




}
/// @nodoc
class _$InsightWindowCopyWithImpl<$Res>
    implements $InsightWindowCopyWith<$Res> {
  _$InsightWindowCopyWithImpl(this._self, this._then);

  final InsightWindow _self;
  final $Res Function(InsightWindow) _then;

/// Create a copy of InsightWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = null,Object? dayCount = null,Object? preset = null,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,dayCount: null == dayCount ? _self.dayCount : dayCount // ignore: cast_nullable_to_non_nullable
as int,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as InsightWindowPreset,
  ));
}

}


/// Adds pattern-matching-related methods to [InsightWindow].
extension InsightWindowPatterns on InsightWindow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightWindow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightWindow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightWindow value)  $default,){
final _that = this;
switch (_that) {
case _InsightWindow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightWindow value)?  $default,){
final _that = this;
switch (_that) {
case _InsightWindow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  int dayCount,  InsightWindowPreset preset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightWindow() when $default != null:
return $default(_that.startDate,_that.endDate,_that.dayCount,_that.preset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  int dayCount,  InsightWindowPreset preset)  $default,) {final _that = this;
switch (_that) {
case _InsightWindow():
return $default(_that.startDate,_that.endDate,_that.dayCount,_that.preset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startDate,  DateTime endDate,  int dayCount,  InsightWindowPreset preset)?  $default,) {final _that = this;
switch (_that) {
case _InsightWindow() when $default != null:
return $default(_that.startDate,_that.endDate,_that.dayCount,_that.preset);case _:
  return null;

}
}

}

/// @nodoc


class _InsightWindow implements InsightWindow {
  const _InsightWindow({required this.startDate, required this.endDate, required this.dayCount, required this.preset});
  

@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  int dayCount;
@override final  InsightWindowPreset preset;

/// Create a copy of InsightWindow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightWindowCopyWith<_InsightWindow> get copyWith => __$InsightWindowCopyWithImpl<_InsightWindow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightWindow&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.dayCount, dayCount) || other.dayCount == dayCount)&&(identical(other.preset, preset) || other.preset == preset));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate,dayCount,preset);

@override
String toString() {
  return 'InsightWindow(startDate: $startDate, endDate: $endDate, dayCount: $dayCount, preset: $preset)';
}


}

/// @nodoc
abstract mixin class _$InsightWindowCopyWith<$Res> implements $InsightWindowCopyWith<$Res> {
  factory _$InsightWindowCopyWith(_InsightWindow value, $Res Function(_InsightWindow) _then) = __$InsightWindowCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDate, DateTime endDate, int dayCount, InsightWindowPreset preset
});




}
/// @nodoc
class __$InsightWindowCopyWithImpl<$Res>
    implements _$InsightWindowCopyWith<$Res> {
  __$InsightWindowCopyWithImpl(this._self, this._then);

  final _InsightWindow _self;
  final $Res Function(_InsightWindow) _then;

/// Create a copy of InsightWindow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,Object? dayCount = null,Object? preset = null,}) {
  return _then(_InsightWindow(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,dayCount: null == dayCount ? _self.dayCount : dayCount // ignore: cast_nullable_to_non_nullable
as int,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as InsightWindowPreset,
  ));
}


}

// dart format on
