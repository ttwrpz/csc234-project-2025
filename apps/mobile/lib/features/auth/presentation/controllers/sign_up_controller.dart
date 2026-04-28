import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import 'sign_up_state.dart';

part 'sign_up_controller.g.dart';

@riverpod
class SignUpController extends _$SignUpController {
  @override
  SignUpState build() => const SignUpState();

  void setEmail(String email) =>
      state = state.copyWith(email: email, errorMessage: null);

  void setPassword(String password) =>
      state = state.copyWith(password: password, errorMessage: null);

  void setConfirmPassword(String confirmPassword) => state = state.copyWith(
    confirmPassword: confirmPassword,
    errorMessage: null,
  );

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (state.password != state.confirmPassword) {
      state = state.copyWith(errorMessage: 'Passwords do not match.');
      return;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final usecase = ref.read(registerWithEmailUseCaseProvider);
    final result = await usecase(email: state.email, password: state.password);
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: result.fold(
        ok: (_) => null,
        err: (failure) => failure.message,
      ),
    );
  }

  Future<void> submitGoogle() async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final usecase = ref.read(signInWithGoogleUseCaseProvider);
    final result = await usecase();
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: result.fold(
        ok: (_) => null,
        err: (failure) => failure.message,
      ),
    );
  }
}
