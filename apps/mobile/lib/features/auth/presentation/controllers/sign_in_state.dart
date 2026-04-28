import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_state.freezed.dart';

/// Reactive state for [SignInScreen]. The `password` field is held in memory
/// only for the duration of the form submission and is never logged.
@freezed
class SignInState with _$SignInState {
  const factory SignInState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _SignInState;
}
