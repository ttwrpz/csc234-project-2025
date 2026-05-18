import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper over `FirebaseFunctions.httpsCallable('wipeUserData')`.
///
/// The `wipeUserData` admin-SDK callable owns the server-side cascade
/// (every subcollection under `users/{uid}/` plus the user profile
/// field reset). The function deliberately does NOT delete the
/// Firebase Auth user — that's done client-side after this call
/// returns, inside the same recent-login window.
///
/// Owns transport (region pinning via the injected functions handle,
/// CF exception → typed enum) only. Domain mapping happens upstream in
/// [AuthRepositoryImpl.deleteAccount].
///
/// PII fence: the call body is empty — `wipeUserData` resolves the
/// caller's uid from `request.auth.uid` on the server. No payload
/// fields are ever populated by the client.
class DeleteAccountFunctionsDatasource {
  const DeleteAccountFunctionsDatasource(this._functions);

  final FirebaseFunctions _functions;

  /// Invokes `wipeUserData`. Returns when the cascade completes (the
  /// CF awaits all subcollection drains before responding). Throws a
  /// typed [DeleteAccountDatasourceException] for protocol-level
  /// failures.
  Future<void> call() async {
    final callable = _functions.httpsCallable('wipeUserData');
    try {
      await callable.call<Object?>();
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw const DeleteAccountDatasourceException.unauthenticated();
        case 'unavailable':
        case 'deadline-exceeded':
          throw const DeleteAccountDatasourceException.network();
        default:
          throw DeleteAccountDatasourceException.unknown(e);
      }
    } catch (e) {
      throw DeleteAccountDatasourceException.unknown(e);
    }
  }
}

/// Typed exceptions the repository unwraps into [AuthFailure] variants.
/// Scoped to the data layer — the domain never sees these. The
/// variant classes are public so the repository in a sibling file
/// can pattern-match on the sealed hierarchy via `switch`.
sealed class DeleteAccountDatasourceException implements Exception {
  const DeleteAccountDatasourceException();

  const factory DeleteAccountDatasourceException.unauthenticated() =
      DeleteAccountUnauthenticatedException;
  const factory DeleteAccountDatasourceException.network() =
      DeleteAccountNetworkException;
  const factory DeleteAccountDatasourceException.unknown(Object? cause) =
      DeleteAccountUnknownException;
}

class DeleteAccountUnauthenticatedException
    extends DeleteAccountDatasourceException {
  const DeleteAccountUnauthenticatedException();
}

class DeleteAccountNetworkException extends DeleteAccountDatasourceException {
  const DeleteAccountNetworkException();
}

class DeleteAccountUnknownException extends DeleteAccountDatasourceException {
  const DeleteAccountUnknownException(this.cause);
  final Object? cause;
}
