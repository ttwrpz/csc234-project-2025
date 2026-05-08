import 'package:core/core.dart';

import '../auth_credentials.dart';
import '../auth_failure.dart';
import '../auth_repository.dart';

/// Composes the three-step account deletion: reauth → call deleteAccount
/// CF (server cascade per ADR-0009) → signOut. The repository owns the
/// actual Firebase Auth + Cloud Functions calls; this use case is the
/// orchestration entry point that the Settings controller invokes.
///
/// Reauth fence: Firebase Auth requires a recent sign-in (~5min) before
/// `currentUser.delete()` will succeed. The use case calls
/// [AuthRepository.reauthenticate] first; if that fails the CF is never
/// invoked and the local user remains signed in.
///
/// Failure semantics:
///   - `AuthFailure.wrongPassword()` etc. on reauth → use case returns
///     the failure unchanged; nothing on the server is touched.
///   - `AuthFailure.network()` on the CF call → returns the failure
///     unchanged; user is still signed in and can retry. The CF is
///     idempotent so a retry on a partial-cascade run cleans the tail.
///   - `signOut()` failure post-delete → returns that failure even
///     though the data is gone server-side. The local session is the
///     only thing the recent-login window guards against, and the
///     downstream router redirect on auth state still runs.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void, AuthFailure>> call({
    required AuthCredentials reauth,
  }) async {
    final reauthResult = await _repository.reauthenticate(reauth);
    if (reauthResult is Err<void, AuthFailure>) {
      return reauthResult;
    }

    final deleteResult = await _repository.deleteAccount();
    if (deleteResult is Err<void, AuthFailure>) {
      return deleteResult;
    }

    return _repository.signOut();
  }
}
