import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import 'sign_in_state.dart';

part 'sign_in_controller.g.dart';

/// Controller for [SignInScreen]. Holds form state, drives the use cases,
/// and surfaces a friendly error message on failure.
///
/// Navigation on success is handled by the router's `refreshListenable` —
/// the controller does NOT call `context.go`. When auth state flips to
/// non-null, the router redirects from `/sign-in` to `/home` automatically.
@riverpod
class SignInController extends _$SignInController {
  @override
  SignInState build() => const SignInState();

  void setEmail(String email) =>
      state = state.copyWith(email: email, errorMessage: null);

  void setPassword(String password) =>
      state = state.copyWith(password: password, errorMessage: null);

  Future<void> submit() async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final usecase = ref.read(signInWithEmailUseCaseProvider);
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
