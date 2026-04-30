// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AuthCredentials {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String email, String password) emailPassword,
    required TResult Function() google,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String email, String password)? emailPassword,
    TResult? Function()? google,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String email, String password)? emailPassword,
    TResult Function()? google,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmailPasswordCredentials value) emailPassword,
    required TResult Function(GoogleCredentials value) google,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmailPasswordCredentials value)? emailPassword,
    TResult? Function(GoogleCredentials value)? google,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmailPasswordCredentials value)? emailPassword,
    TResult Function(GoogleCredentials value)? google,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthCredentialsCopyWith<$Res> {
  factory $AuthCredentialsCopyWith(
    AuthCredentials value,
    $Res Function(AuthCredentials) then,
  ) = _$AuthCredentialsCopyWithImpl<$Res, AuthCredentials>;
}

/// @nodoc
class _$AuthCredentialsCopyWithImpl<$Res, $Val extends AuthCredentials>
    implements $AuthCredentialsCopyWith<$Res> {
  _$AuthCredentialsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthCredentials
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$EmailPasswordCredentialsImplCopyWith<$Res> {
  factory _$$EmailPasswordCredentialsImplCopyWith(
    _$EmailPasswordCredentialsImpl value,
    $Res Function(_$EmailPasswordCredentialsImpl) then,
  ) = __$$EmailPasswordCredentialsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email, String password});
}

/// @nodoc
class __$$EmailPasswordCredentialsImplCopyWithImpl<$Res>
    extends _$AuthCredentialsCopyWithImpl<$Res, _$EmailPasswordCredentialsImpl>
    implements _$$EmailPasswordCredentialsImplCopyWith<$Res> {
  __$$EmailPasswordCredentialsImplCopyWithImpl(
    _$EmailPasswordCredentialsImpl _value,
    $Res Function(_$EmailPasswordCredentialsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthCredentials
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? password = null}) {
    return _then(
      _$EmailPasswordCredentialsImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$EmailPasswordCredentialsImpl extends EmailPasswordCredentials {
  const _$EmailPasswordCredentialsImpl({
    required this.email,
    required this.password,
  }) : super._();

  @override
  final String email;
  @override
  final String password;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmailPasswordCredentialsImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @override
  int get hashCode => Object.hash(runtimeType, email, password);

  /// Create a copy of AuthCredentials
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmailPasswordCredentialsImplCopyWith<_$EmailPasswordCredentialsImpl>
  get copyWith =>
      __$$EmailPasswordCredentialsImplCopyWithImpl<
        _$EmailPasswordCredentialsImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String email, String password) emailPassword,
    required TResult Function() google,
  }) {
    return emailPassword(email, password);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String email, String password)? emailPassword,
    TResult? Function()? google,
  }) {
    return emailPassword?.call(email, password);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String email, String password)? emailPassword,
    TResult Function()? google,
    required TResult orElse(),
  }) {
    if (emailPassword != null) {
      return emailPassword(email, password);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmailPasswordCredentials value) emailPassword,
    required TResult Function(GoogleCredentials value) google,
  }) {
    return emailPassword(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmailPasswordCredentials value)? emailPassword,
    TResult? Function(GoogleCredentials value)? google,
  }) {
    return emailPassword?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmailPasswordCredentials value)? emailPassword,
    TResult Function(GoogleCredentials value)? google,
    required TResult orElse(),
  }) {
    if (emailPassword != null) {
      return emailPassword(this);
    }
    return orElse();
  }
}

abstract class EmailPasswordCredentials extends AuthCredentials {
  const factory EmailPasswordCredentials({
    required final String email,
    required final String password,
  }) = _$EmailPasswordCredentialsImpl;
  const EmailPasswordCredentials._() : super._();

  String get email;
  String get password;

  /// Create a copy of AuthCredentials
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmailPasswordCredentialsImplCopyWith<_$EmailPasswordCredentialsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoogleCredentialsImplCopyWith<$Res> {
  factory _$$GoogleCredentialsImplCopyWith(
    _$GoogleCredentialsImpl value,
    $Res Function(_$GoogleCredentialsImpl) then,
  ) = __$$GoogleCredentialsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GoogleCredentialsImplCopyWithImpl<$Res>
    extends _$AuthCredentialsCopyWithImpl<$Res, _$GoogleCredentialsImpl>
    implements _$$GoogleCredentialsImplCopyWith<$Res> {
  __$$GoogleCredentialsImplCopyWithImpl(
    _$GoogleCredentialsImpl _value,
    $Res Function(_$GoogleCredentialsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthCredentials
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$GoogleCredentialsImpl extends GoogleCredentials {
  const _$GoogleCredentialsImpl() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$GoogleCredentialsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String email, String password) emailPassword,
    required TResult Function() google,
  }) {
    return google();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String email, String password)? emailPassword,
    TResult? Function()? google,
  }) {
    return google?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String email, String password)? emailPassword,
    TResult Function()? google,
    required TResult orElse(),
  }) {
    if (google != null) {
      return google();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EmailPasswordCredentials value) emailPassword,
    required TResult Function(GoogleCredentials value) google,
  }) {
    return google(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EmailPasswordCredentials value)? emailPassword,
    TResult? Function(GoogleCredentials value)? google,
  }) {
    return google?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EmailPasswordCredentials value)? emailPassword,
    TResult Function(GoogleCredentials value)? google,
    required TResult orElse(),
  }) {
    if (google != null) {
      return google(this);
    }
    return orElse();
  }
}

abstract class GoogleCredentials extends AuthCredentials {
  const factory GoogleCredentials() = _$GoogleCredentialsImpl;
  const GoogleCredentials._() : super._();
}
