import 'package:core/core.dart';

import '../auth_failure.dart';
import '../auth_repository.dart';

/// Ends the current session. The router's `refreshListenable` will redirect
/// to `/sign-in` automatically when the auth-state stream emits `null`.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void, AuthFailure>> call() {
    return _repository.signOut();
  }
}
