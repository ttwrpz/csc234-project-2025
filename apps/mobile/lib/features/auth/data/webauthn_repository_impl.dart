import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:core/core.dart';

import '../domain/entities/webauthn_credential.dart';
import '../domain/entities/webauthn_register_failure.dart';
import '../domain/entities/webauthn_remove_failure.dart';
import '../domain/entities/webauthn_verify_failure.dart';
import '../domain/repositories/webauthn_repository.dart';
import 'datasources/webauthn_browser_datasource.dart';
import 'datasources/webauthn_credential_firestore_datasource.dart';
import 'datasources/webauthn_functions_datasource.dart';

/// Repository implementation for the WebAuthn fallback factor.
///
/// Orchestrates the four-step ceremony for both register and verify:
///   1. Call the "start" Cloud Function to get a fresh challenge +
///      `PublicKeyCredentialCreation`/`RequestOptions`.
///   2. Hand the options to the browser via the JS-interop binding;
///      the browser prompts the user for the platform authenticator.
///   3. Call the "finish" Cloud Function with the browser's response;
///      the server verifies the attestation/assertion via
///      `@simplewebauthn/server` and persists/updates the credential.
///   4. Stream the updated credential back through Firestore for the
///      Privacy UI status tile to reflect the new state.
///
/// **Server-side verification:** unlike PIN (verified client-side via
/// PBKDF2), WebAuthn verification happens entirely in the Cloud
/// Function. The Dart client only orchestrates; it never decides
/// success / failure on its own.
class WebauthnRepositoryImpl implements WebauthnRepository {
  WebauthnRepositoryImpl({
    required WebauthnFunctionsDatasource functions,
    required WebauthnBrowserDatasource browser,
    required WebauthnCredentialFirestoreDatasource firestore,
    DateTime Function() clock = _systemClock,
    Logger logger = const Logger('auth.webauthn'),
  }) : _functions = functions,
       _browser = browser,
       _firestore = firestore,
       _clock = clock,
       _logger = logger;

  final WebauthnFunctionsDatasource _functions;
  final WebauthnBrowserDatasource _browser;
  final WebauthnCredentialFirestoreDatasource _firestore;
  final DateTime Function() _clock;
  final Logger _logger;

  static DateTime _systemClock() => DateTime.now().toUtc();

  @override
  Future<Result<WebauthnCredential, WebauthnRegisterFailure>> register({
    required String uid,
  }) async {
    // Step 1: server-issued challenge + creation options.
    final Map<String, Object?> startResp;
    try {
      startResp = await _functions.registerStart();
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('webauthnRegisterStart failed: ${e.code}');
      return const Err(WebauthnRegisterFailure.network());
    } catch (e) {
      _logger.error('webauthnRegisterStart unexpected', error: e);
      return Err(WebauthnRegisterFailure.unknown(e.runtimeType));
    }

    if (startResp['ok'] != true) {
      return _mapRegisterCode(startResp['code']);
    }
    final challengeId = startResp['challengeId'];
    final options = startResp['options'];
    if (challengeId is! String || options is! Map) {
      return const Err(WebauthnRegisterFailure.verificationFailed());
    }

    // Step 2: browser ceremony.
    final WebauthnRegistrationResponse browserResp;
    try {
      browserResp = await _browser.createCredential(
        Map<String, Object?>.from(options),
      );
    } on WebauthnUserCanceledException {
      return const Err(WebauthnRegisterFailure.userCanceled());
    } on WebauthnUnsupportedException {
      return const Err(WebauthnRegisterFailure.notProvisioned());
    } catch (e) {
      _logger.warn(
        'webauthn browser createCredential failed: ${e.runtimeType}',
      );
      return Err(WebauthnRegisterFailure.unknown(e.runtimeType));
    }

    // Step 3: server verification + persist.
    final Map<String, Object?> finishResp;
    try {
      finishResp = await _functions.registerFinish(
        challengeId: challengeId,
        response: browserResp.toJson(),
      );
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('webauthnRegisterFinish failed: ${e.code}');
      return const Err(WebauthnRegisterFailure.network());
    } catch (e) {
      _logger.error('webauthnRegisterFinish unexpected', error: e);
      return Err(WebauthnRegisterFailure.unknown(e.runtimeType));
    }

    if (finishResp['ok'] != true) {
      return _mapRegisterCode(finishResp['code']);
    }
    final credentialId = finishResp['credentialId'];
    if (credentialId is! String) {
      return const Err(WebauthnRegisterFailure.verificationFailed());
    }

    // The Firestore stream will catch up to the new doc within a few
    // hundred ms; for the immediate return we synthesize a minimal
    // credential snapshot so the caller can react without re-watching.
    return Ok(
      WebauthnCredential(credentialId: credentialId, createdAt: _clock()),
    );
  }

  @override
  Future<Result<void, WebauthnVerifyFailure>> verify({
    required String uid,
  }) async {
    final Map<String, Object?> startResp;
    try {
      startResp = await _functions.assertionStart();
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('webauthnAssertionStart failed: ${e.code}');
      return const Err(WebauthnVerifyFailure.network());
    } catch (e) {
      _logger.error('webauthnAssertionStart unexpected', error: e);
      return Err(WebauthnVerifyFailure.unknown(e.runtimeType));
    }
    if (startResp['ok'] != true) {
      return _mapVerifyCode(startResp['code'], startResp);
    }
    final challengeId = startResp['challengeId'];
    final options = startResp['options'];
    if (challengeId is! String || options is! Map) {
      return const Err(WebauthnVerifyFailure.unknown(null));
    }

    final WebauthnAssertionResponse browserResp;
    try {
      browserResp = await _browser.getAssertion(
        Map<String, Object?>.from(options),
      );
    } on WebauthnUserCanceledException {
      return const Err(WebauthnVerifyFailure.userCanceled());
    } on WebauthnUnsupportedException {
      // The "not provisioned" path on verify is effectively the same as
      // "no credential" from the user's perspective; surface as
      // network/unknown so the UI falls back to PIN.
      return const Err(WebauthnVerifyFailure.network());
    } catch (e) {
      _logger.warn('webauthn browser getAssertion failed: ${e.runtimeType}');
      return Err(WebauthnVerifyFailure.unknown(e.runtimeType));
    }

    final Map<String, Object?> finishResp;
    try {
      finishResp = await _functions.assertionFinish(
        challengeId: challengeId,
        response: browserResp.toJson(),
      );
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('webauthnAssertionFinish failed: ${e.code}');
      return const Err(WebauthnVerifyFailure.network());
    } catch (e) {
      _logger.error('webauthnAssertionFinish unexpected', error: e);
      return Err(WebauthnVerifyFailure.unknown(e.runtimeType));
    }
    if (finishResp['ok'] != true) {
      return _mapVerifyCode(finishResp['code'], finishResp);
    }
    return const Ok(null);
  }

  @override
  Future<Result<String, WebauthnVerifyFailure>> loginWithSecurityKey() async {
    final Map<String, Object?> startResp;
    try {
      startResp = await _functions.loginStart();
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('webauthnLoginStart failed: ${e.code}');
      return const Err(WebauthnVerifyFailure.network());
    } catch (e) {
      _logger.error('webauthnLoginStart unexpected', error: e);
      return Err(WebauthnVerifyFailure.unknown(e.runtimeType));
    }
    if (startResp['ok'] != true) {
      return _loginErr(startResp['code'], startResp);
    }
    final challengeId = startResp['challengeId'];
    final options = startResp['options'];
    if (challengeId is! String || options is! Map) {
      return const Err(WebauthnVerifyFailure.unknown(null));
    }

    // Usernameless get - the server sent an empty allowCredentials list,
    // so the browser surfaces the resident passkey and returns its
    // userHandle (= uid) in the assertion.
    final WebauthnAssertionResponse browserResp;
    try {
      browserResp = await _browser.getAssertion(
        Map<String, Object?>.from(options),
      );
    } on WebauthnUserCanceledException {
      return const Err(WebauthnVerifyFailure.userCanceled());
    } on WebauthnUnsupportedException {
      return const Err(WebauthnVerifyFailure.network());
    } catch (e) {
      _logger.warn(
        'webauthn browser login getAssertion failed: ${e.runtimeType}',
      );
      return Err(WebauthnVerifyFailure.unknown(e.runtimeType));
    }

    final Map<String, Object?> finishResp;
    try {
      finishResp = await _functions.loginFinish(
        challengeId: challengeId,
        response: browserResp.toJson(),
      );
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('webauthnLoginFinish failed: ${e.code}');
      return const Err(WebauthnVerifyFailure.network());
    } catch (e) {
      _logger.error('webauthnLoginFinish unexpected', error: e);
      return Err(WebauthnVerifyFailure.unknown(e.runtimeType));
    }
    if (finishResp['ok'] != true) {
      return _loginErr(finishResp['code'], finishResp);
    }
    final token = finishResp['token'];
    if (token is! String || token.isEmpty) {
      return const Err(WebauthnVerifyFailure.unknown(null));
    }
    return Ok(token);
  }

  /// Re-wraps the shared [_mapVerifyCode] (typed `Result<void, …>`) into
  /// the `Result<String, …>` the login path returns. Every branch of
  /// [_mapVerifyCode] is an `Err`, so the `Ok` arm is unreachable.
  Result<String, WebauthnVerifyFailure> _loginErr(
    Object? code,
    Map<String, Object?> resp,
  ) {
    return switch (_mapVerifyCode(code, resp)) {
      Err(:final failure) => Err(failure),
      Ok() => const Err(WebauthnVerifyFailure.unknown(null)),
    };
  }

  @override
  Stream<WebauthnCredential?> watchCredential({required String uid}) =>
      _firestore.watch(userId: uid);

  @override
  Future<Result<void, WebauthnRemoveFailure>> removeCredential({
    required String uid,
  }) async {
    final Map<String, Object?> resp;
    try {
      resp = await _functions.removeCredential();
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('webauthnRemoveCredential failed: ${e.code}');
      return const Err(WebauthnRemoveFailure.network());
    } catch (e) {
      _logger.error('webauthnRemoveCredential unexpected', error: e);
      return Err(WebauthnRemoveFailure.unknown(e.runtimeType));
    }
    if (resp['ok'] != true) {
      _logger.warn('webauthnRemoveCredential not-ok: ${resp['code']}');
      return const Err(WebauthnRemoveFailure.network());
    }
    return const Ok(null);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Wire-code → domain-failure mapping.

  Result<WebauthnCredential, WebauthnRegisterFailure> _mapRegisterCode(
    Object? code,
  ) {
    switch (code) {
      case 'pin_required':
        return const Err(WebauthnRegisterFailure.pinRequired());
      case 'webauthn_not_provisioned':
        return const Err(WebauthnRegisterFailure.notProvisioned());
      case 'verification_failed':
        return const Err(WebauthnRegisterFailure.verificationFailed());
      case 'challenge_expired':
        return const Err(WebauthnRegisterFailure.verificationFailed());
      default:
        _logger.warn('webauthn register unknown code: $code');
        return const Err(WebauthnRegisterFailure.network());
    }
  }

  Result<void, WebauthnVerifyFailure> _mapVerifyCode(
    Object? code,
    Map<String, Object?> resp,
  ) {
    switch (code) {
      case 'no_credential':
        return const Err(WebauthnVerifyFailure.noCredential());
      case 'counter_regression':
        return const Err(WebauthnVerifyFailure.counterRegression());
      case 'challenge_expired':
        return const Err(WebauthnVerifyFailure.challengeExpired());
      case 'verification_failed':
        return const Err(WebauthnVerifyFailure.counterRegression());
      case 'rate_limited':
        final lockedUntilMs = resp['lockedUntilMs'];
        DateTime until;
        if (lockedUntilMs is num) {
          until = DateTime.fromMillisecondsSinceEpoch(
            lockedUntilMs.toInt(),
            isUtc: true,
          );
        } else {
          until = _clock().add(const Duration(seconds: 60));
        }
        return Err(WebauthnVerifyFailure.rateLimited(until: until));
      case 'webauthn_not_provisioned':
        return const Err(WebauthnVerifyFailure.network());
      default:
        _logger.warn('webauthn verify unknown code: $code');
        return const Err(WebauthnVerifyFailure.network());
    }
  }
}
