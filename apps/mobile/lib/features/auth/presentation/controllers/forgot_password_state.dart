import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_state.freezed.dart';

/// Reactive state for the forgot-password flow.
///
/// `isSent` flips to `true` after the use case returns success — the
/// screen swaps the form out for a "Check your inbox" confirmation
/// rather than holding the form open. Errors render inline on the form.
@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default('') String email,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSent,
    String? errorMessage,
  }) = _ForgotPasswordState;
}
