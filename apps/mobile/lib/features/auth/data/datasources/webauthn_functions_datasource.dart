import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper over the four WebAuthn Cloud Function callables.
///
/// Each method passes the request payload verbatim and returns the raw
/// response map; the repository owns the success/failure pattern-match
/// and any base64url decoding.
///
/// All four CFs use the `result-typed { ok, code }` discriminated
/// union - `unauthenticated` short-circuits to a thrown
/// `FirebaseFunctionsException`; every business-level reject arrives
/// as `{ ok: false, code: '<reason>' }`.
class WebauthnFunctionsDatasource {
  const WebauthnFunctionsDatasource(this._functions);

  final FirebaseFunctions _functions;

  Future<Map<String, Object?>> registerStart() async {
    final result = await _functions.httpsCallable('webauthnRegisterStart').call(
      {'v': 1},
    );
    return Map<String, Object?>.from(result.data as Map);
  }

  Future<Map<String, Object?>> registerFinish({
    required String challengeId,
    required Map<String, Object?> response,
  }) async {
    final result = await _functions
        .httpsCallable('webauthnRegisterFinish')
        .call({'v': 1, 'challengeId': challengeId, 'response': response});
    return Map<String, Object?>.from(result.data as Map);
  }

  Future<Map<String, Object?>> assertionStart() async {
    final result = await _functions
        .httpsCallable('webauthnAssertionStart')
        .call({'v': 1});
    return Map<String, Object?>.from(result.data as Map);
  }

  Future<Map<String, Object?>> assertionFinish({
    required String challengeId,
    required Map<String, Object?> response,
  }) async {
    final result = await _functions
        .httpsCallable('webauthnAssertionFinish')
        .call({'v': 1, 'challengeId': challengeId, 'response': response});
    return Map<String, Object?>.from(result.data as Map);
  }

  /// UNAUTHENTICATED cold-boot sign-in, leg 1. Returns usernameless
  /// assertion options + a challengeId; the client runs a discoverable-
  /// credential `navigator.credentials.get()`.
  Future<Map<String, Object?>> loginStart() async {
    final result = await _functions.httpsCallable('webauthnLoginStart').call({
      'v': 1,
    });
    return Map<String, Object?>.from(result.data as Map);
  }

  /// UNAUTHENTICATED cold-boot sign-in, leg 2. On `ok`, the response
  /// carries a Firebase custom `token` for `signInWithCustomToken`.
  Future<Map<String, Object?>> loginFinish({
    required String challengeId,
    required Map<String, Object?> response,
  }) async {
    final result = await _functions.httpsCallable('webauthnLoginFinish').call({
      'v': 1,
      'challengeId': challengeId,
      'response': response,
    });
    return Map<String, Object?>.from(result.data as Map);
  }

  /// Retire the user's registered credential(s). Authenticated callable;
  /// returns `{ ok: true, removed: <count> }`. Idempotent - removing when
  /// none exist returns `removed: 0`.
  Future<Map<String, Object?>> removeCredential() async {
    final result = await _functions
        .httpsCallable('webauthnRemoveCredential')
        .call({'v': 1});
    return Map<String, Object?>.from(result.data as Map);
  }
}
