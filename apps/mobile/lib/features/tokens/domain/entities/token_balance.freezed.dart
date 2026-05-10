// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TokenBalance {

 int get balance; int get earnedToday; DateTime? get lastEarnedDate;
/// Create a copy of TokenBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenBalanceCopyWith<TokenBalance> get copyWith => _$TokenBalanceCopyWithImpl<TokenBalance>(this as TokenBalance, _$identity);

  /// Serializes this TokenBalance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenBalance&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.earnedToday, earnedToday) || other.earnedToday == earnedToday)&&(identical(other.lastEarnedDate, lastEarnedDate) || other.lastEarnedDate == lastEarnedDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,earnedToday,lastEarnedDate);

@override
String toString() {
  return 'TokenBalance(balance: $balance, earnedToday: $earnedToday, lastEarnedDate: $lastEarnedDate)';
}


}

/// @nodoc
abstract mixin class $TokenBalanceCopyWith<$Res>  {
  factory $TokenBalanceCopyWith(TokenBalance value, $Res Function(TokenBalance) _then) = _$TokenBalanceCopyWithImpl;
@useResult
$Res call({
 int balance, int earnedToday, DateTime? lastEarnedDate
});




}
/// @nodoc
class _$TokenBalanceCopyWithImpl<$Res>
    implements $TokenBalanceCopyWith<$Res> {
  _$TokenBalanceCopyWithImpl(this._self, this._then);

  final TokenBalance _self;
  final $Res Function(TokenBalance) _then;

/// Create a copy of TokenBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = null,Object? earnedToday = null,Object? lastEarnedDate = freezed,}) {
  return _then(_self.copyWith(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,earnedToday: null == earnedToday ? _self.earnedToday : earnedToday // ignore: cast_nullable_to_non_nullable
as int,lastEarnedDate: freezed == lastEarnedDate ? _self.lastEarnedDate : lastEarnedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenBalance].
extension TokenBalancePatterns on TokenBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenBalance value)  $default,){
final _that = this;
switch (_that) {
case _TokenBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenBalance value)?  $default,){
final _that = this;
switch (_that) {
case _TokenBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int balance,  int earnedToday,  DateTime? lastEarnedDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenBalance() when $default != null:
return $default(_that.balance,_that.earnedToday,_that.lastEarnedDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int balance,  int earnedToday,  DateTime? lastEarnedDate)  $default,) {final _that = this;
switch (_that) {
case _TokenBalance():
return $default(_that.balance,_that.earnedToday,_that.lastEarnedDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int balance,  int earnedToday,  DateTime? lastEarnedDate)?  $default,) {final _that = this;
switch (_that) {
case _TokenBalance() when $default != null:
return $default(_that.balance,_that.earnedToday,_that.lastEarnedDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenBalance implements TokenBalance {
  const _TokenBalance({required this.balance, required this.earnedToday, required this.lastEarnedDate});
  factory _TokenBalance.fromJson(Map<String, dynamic> json) => _$TokenBalanceFromJson(json);

@override final  int balance;
@override final  int earnedToday;
@override final  DateTime? lastEarnedDate;

/// Create a copy of TokenBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenBalanceCopyWith<_TokenBalance> get copyWith => __$TokenBalanceCopyWithImpl<_TokenBalance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenBalanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenBalance&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.earnedToday, earnedToday) || other.earnedToday == earnedToday)&&(identical(other.lastEarnedDate, lastEarnedDate) || other.lastEarnedDate == lastEarnedDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,earnedToday,lastEarnedDate);

@override
String toString() {
  return 'TokenBalance(balance: $balance, earnedToday: $earnedToday, lastEarnedDate: $lastEarnedDate)';
}


}

/// @nodoc
abstract mixin class _$TokenBalanceCopyWith<$Res> implements $TokenBalanceCopyWith<$Res> {
  factory _$TokenBalanceCopyWith(_TokenBalance value, $Res Function(_TokenBalance) _then) = __$TokenBalanceCopyWithImpl;
@override @useResult
$Res call({
 int balance, int earnedToday, DateTime? lastEarnedDate
});




}
/// @nodoc
class __$TokenBalanceCopyWithImpl<$Res>
    implements _$TokenBalanceCopyWith<$Res> {
  __$TokenBalanceCopyWithImpl(this._self, this._then);

  final _TokenBalance _self;
  final $Res Function(_TokenBalance) _then;

/// Create a copy of TokenBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = null,Object? earnedToday = null,Object? lastEarnedDate = freezed,}) {
  return _then(_TokenBalance(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,earnedToday: null == earnedToday ? _self.earnedToday : earnedToday // ignore: cast_nullable_to_non_nullable
as int,lastEarnedDate: freezed == lastEarnedDate ? _self.lastEarnedDate : lastEarnedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
