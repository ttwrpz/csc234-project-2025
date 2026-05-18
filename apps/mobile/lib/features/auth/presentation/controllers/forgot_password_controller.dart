import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import 'forgot_password_state.dart';

part 'forgot_password_controller.g.dart';

/// Controller for the forgot-password screen. Holds the email input
/// state, dispatches the use case, and surfaces a single inline error
/// message on failure. Success flips `isSent` so the view swaps the
/// form for a confirmation panel.
@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  void setEmail(String email) =>
      state = state.copyWith(email: email, errorMessage: null);

  Future<void> submit() async {
    if (state.isSubmitting || state.isSent) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final usecase = ref.read(sendPasswordResetEmailUseCaseProvider);
    final result = await usecase(state.email);
    state = result.fold(
      ok: (_) => state.copyWith(isSubmitting: false, isSent: true),
      err: (failure) =>
          state.copyWith(isSubmitting: false, errorMessage: failure.message),
    );
  }
}
