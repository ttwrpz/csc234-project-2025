import 'package:core/core.dart';

import '../auth_failure.dart';
import '../auth_repository.dart';
import '../validators/email_validator.dart';

/// Requests a password-reset email for [email].
///
/// Validates the address locally so we never make a network call for an
/// obviously malformed input; Firebase's server-side validation is the
/// final word on whether the address is deliverable.
class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void, AuthFailure>> call(String email) async {
    final trimmed = email.trim();
    if (!emailIsValid(trimmed)) {
      return const Err(AuthFailure.invalidEmail());
    }
    return _repository.sendPasswordResetEmail(trimmed);
  }
}
