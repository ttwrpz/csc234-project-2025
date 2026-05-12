import 'package:core/core.dart';

import '../auth_credentials.dart';
import '../auth_failure.dart';
import '../auth_repository.dart';

/// Composes the four-step account deletion: reauth → server cascade
/// (CF) → local Firebase Auth user delete → signOut. The repository
/// owns the actual Firebase Auth + Cloud Functions calls; this use
/// case is the orchestration entry point that the Settings controller
/// invokes.
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
///   - `AuthFailure.requiresRecentLogin()` from
///     [AuthRepository.deleteCurrentUser] → use case logs and proceeds
///     to signOut anyway. The server data is already gone; the local
///     session is the only thing the recent-login window guards
///     against. The local Auth record being orphaned is acceptable per
///     ADR-0009 §"Good" point 5. The signOut still triggers the
///     router's auth-state redirect.
///   - Other failures from [AuthRepository.deleteCurrentUser] → same
///     treatment as `requiresRecentLogin`. The server cascade has
///     already run; the use case proceeds to signOut as a best-effort
///     cleanup rather than stranding the user in a half-deleted state.
///   - `signOut()` failure post-delete → returns that failure even
///     though the data is gone server-side. The downstream router
///     redirect on auth state still runs.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(
    this._repository, {
    Logger logger = const Logger('auth.deleteAccount'),
  }) : _logger = logger;

  final AuthRepository _repository;
  final Logger _logger;

  /// Sentinel for the recent-login branch. The variant is constructed
  /// via the `const factory`, so `identical(...)` works as a stable
  /// type check without exposing the private `_RequiresRecentLogin`
  /// class on the sealed surface.
  static const AuthFailure _requiresRecentLogin =
      AuthFailure.requiresRecentLogin();

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

    // Server cascade succeeded. Try to delete the local Firebase Auth
    // user too. Per ADR-0009 §"Good" point 5, ANY failure here is
    // recoverable — the server data is already gone, so an orphaned
    // local Auth record is acceptable. Log the transition so the
    // ops audit trail can spot drift between server cascade success
    // and Auth-record cleanup.
    final deleteAuthResult = await _repository.deleteCurrentUser();
    if (deleteAuthResult is Err<void, AuthFailure>) {
      final failure = deleteAuthResult.failure;
      if (identical(failure, _requiresRecentLogin)) {
        _logger.info(
          'deleteCurrentUser hit recent-login window post-cascade — '
          'proceeding to signOut anyway',
        );
      } else {
        _logger.warn(
          'deleteCurrentUser failed post-cascade '
          '(${failure.runtimeType}) — proceeding to signOut anyway',
        );
      }
    }

    return _repository.signOut();
  }
}
