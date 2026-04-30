import 'package:core/core.dart';

import '../auth_failure.dart';
import '../auth_repository.dart';
import '../entities/app_user.dart';
import '../validators/email_validator.dart';
import '../validators/password_validator.dart';

/// Signs an existing user in with email and password.
///
/// Validates inputs locally (HB-001 invariant 5) so invalid submissions never
/// hit the network. Provider lives in `data/providers.dart`.
class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser, AuthFailure>> call({
    required String email,
    required String password,
  }) async {
    if (!emailIsValid(email)) {
      return const Err(AuthFailure.invalidEmail());
    }
    if (!passwordIsValid(password)) {
      return const Err(AuthFailure.weakPassword());
    }
    return _repository.signInWithEmail(email: email.trim(), password: password);
  }
}
