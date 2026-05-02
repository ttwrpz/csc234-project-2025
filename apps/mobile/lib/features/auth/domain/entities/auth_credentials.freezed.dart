// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthCredentials {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthCredentials);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $AuthCredentialsCopyWith<$Res>  {
$AuthCredentialsCopyWith(AuthCredentials _, $Res Function(AuthCredentials) __);
}


/// Adds pattern-matching-related methods to [AuthCredentials].
extension AuthCredentialsPatterns on AuthCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EmailPasswordCredentials value)?  emailPassword,TResult Function( GoogleCredentials value)?  google,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EmailPasswordCredentials() when emailPassword != null:
return emailPassword(_that);case GoogleCredentials() when google != null:
return google(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EmailPasswordCredentials value)  emailPassword,required TResult Function( GoogleCredentials value)  google,}){
final _that = this;
switch (_that) {
case EmailPasswordCredentials():
return emailPassword(_that);case GoogleCredentials():
return google(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EmailPasswordCredentials value)?  emailPassword,TResult? Function( GoogleCredentials value)?  google,}){
final _that = this;
switch (_that) {
case EmailPasswordCredentials() when emailPassword != null:
return emailPassword(_that);case GoogleCredentials() when google != null:
return google(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String email,  String password)?  emailPassword,TResult Function()?  google,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EmailPasswordCredentials() when emailPassword != null:
return emailPassword(_that.email,_that.password);case GoogleCredentials() when google != null:
return google();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String email,  String password)  emailPassword,required TResult Function()  google,}) {final _that = this;
switch (_that) {
case EmailPasswordCredentials():
return emailPassword(_that.email,_that.password);case GoogleCredentials():
return google();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String email,  String password)?  emailPassword,TResult? Function()?  google,}) {final _that = this;
switch (_that) {
case EmailPasswordCredentials() when emailPassword != null:
return emailPassword(_that.email,_that.password);case GoogleCredentials() when google != null:
return google();case _:
  return null;

}
}

}

/// @nodoc


class EmailPasswordCredentials extends AuthCredentials {
  const EmailPasswordCredentials({required this.email, required this.password}): super._();
  

 final  String email;
 final  String password;

/// Create a copy of AuthCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailPasswordCredentialsCopyWith<EmailPasswordCredentials> get copyWith => _$EmailPasswordCredentialsCopyWithImpl<EmailPasswordCredentials>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailPasswordCredentials&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,email,password);



}

/// @nodoc
abstract mixin class $EmailPasswordCredentialsCopyWith<$Res> implements $AuthCredentialsCopyWith<$Res> {
  factory $EmailPasswordCredentialsCopyWith(EmailPasswordCredentials value, $Res Function(EmailPasswordCredentials) _then) = _$EmailPasswordCredentialsCopyWithImpl;
@useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class _$EmailPasswordCredentialsCopyWithImpl<$Res>
    implements $EmailPasswordCredentialsCopyWith<$Res> {
  _$EmailPasswordCredentialsCopyWithImpl(this._self, this._then);

  final EmailPasswordCredentials _self;
  final $Res Function(EmailPasswordCredentials) _then;

/// Create a copy of AuthCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(EmailPasswordCredentials(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GoogleCredentials extends AuthCredentials {
  const GoogleCredentials(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoogleCredentials);
}


@override
int get hashCode => runtimeType.hashCode;



}




// dart format on
