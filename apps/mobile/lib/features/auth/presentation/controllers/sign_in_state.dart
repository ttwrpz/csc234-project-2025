import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_state.freezed.dart';

/// Which sign-in method (if any) is currently in flight. Drives the
/// per-button spinner state so only the actively-submitting button
/// shows a loading indicator while the other is disabled.
///
/// A single shared `isSubmitting: bool` would light BOTH the
/// email/password spinner AND the Google button's spinner when only
/// one flow is in flight; splitting the two states means each button
/// only renders its own spinner.
enum SignInSubmitMethod { none, password, google }

/// Reactive state for [SignInScreen]. The `password` field is held in memory
/// only for the duration of the form submission and is never logged.
@freezed
abstract class SignInState with _$SignInState {
  const factory SignInState({
    @Default('') String email,
    @Default('') String password,
    @Default(SignInSubmitMethod.none) SignInSubmitMethod submittingWith,
    String? errorMessage,
  }) = _SignInState;

  const SignInState._();

  /// True when EITHER sign-in path is currently in flight. Used to
  /// disable the inactive button without lighting up its spinner.
  bool get isSubmitting => submittingWith != SignInSubmitMethod.none;
}
