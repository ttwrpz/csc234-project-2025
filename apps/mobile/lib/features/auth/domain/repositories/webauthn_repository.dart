import 'package:core/core.dart';

import '../entities/webauthn_credential.dart';
import '../entities/webauthn_register_failure.dart';
import '../entities/webauthn_verify_failure.dart';

/// Contract for the storage + verification of the WebAuthn fallback
/// factor (ADR-0014).
///
/// Implementations live in `data/`; they own:
///   - the four Cloud Function callables
///     (`webauthnRegisterStart`, `webauthnRegisterFinish`,
///      `webauthnAssertionStart`, `webauthnAssertionFinish`)
///   - the browser-side `navigator.credentials` JS-interop binding
///   - the Firestore read of the registered-credential doc for the
///     Privacy UI status tile.
///
/// Domain consumers (use cases, controllers) speak only in terms of the
/// abstract result types.
///
/// **Threat model boundary:** unlike PIN (which is verified client-side
/// via PBKDF2), WebAuthn verification happens **server-side** via
/// `@simplewebauthn/server` in the Cloud Function. The repository's job
/// is to orchestrate the four-step ceremony (call CF → invoke browser
/// API → call CF → return result), not to verify the assertion itself.
abstract class WebauthnRepository {
  /// Register a new authenticator for [uid].
  ///
  /// Orchestrates the two-step registration ceremony:
  ///   1. `webauthnRegisterStart` (CF) — server issues challenge.
  ///   2. `navigator.credentials.create()` — browser shows the platform
  ///      authenticator prompt; user presents key.
  ///   3. `webauthnRegisterFinish` (CF) — server verifies attestation,
  ///      persists credential.
  ///
  /// v1.5 ships single-credential; calling this when a credential is
  /// already registered overwrites the prior one. Multi-credential
  /// management is v1.6.
  Future<Result<WebauthnCredential, WebauthnRegisterFailure>> register({
    required String uid,
  });

  /// Verify the user's registered authenticator for [uid].
  ///
  /// Orchestrates the two-step assertion ceremony:
  ///   1. `webauthnAssertionStart` (CF) — server issues challenge.
  ///   2. `navigator.credentials.get()` — browser shows the platform
  ///      authenticator prompt; user presents key.
  ///   3. `webauthnAssertionFinish` (CF) — server verifies signature,
  ///      bumps counter.
  ///
  /// On success, the Privacy Lock session flag is flipped by the
  /// calling controller (mirroring the PIN verify flow's
  /// `privacyLockUnlockedThisSessionProvider` set-to-true call).
  Future<Result<void, WebauthnVerifyFailure>> verify({required String uid});

  /// Cold-boot sign-in with a security key — runs BEFORE any Firebase
  /// session exists, so there is no [uid] to pass.
  ///
  /// Orchestrates the usernameless (discoverable-credential) ceremony:
  ///   1. `webauthnLoginStart` (CF, unauthenticated) — server issues a
  ///      challenge with an empty allow-list.
  ///   2. `navigator.credentials.get()` — the authenticator offers its
  ///      resident passkey and returns the `userHandle` (= the uid).
  ///   3. `webauthnLoginFinish` (CF, unauthenticated) — server verifies
  ///      the assertion against the stored public key and mints a Firebase
  ///      custom token.
  ///
  /// On success returns the custom token; the caller exchanges it via
  /// `AuthRepository.signInWithCustomToken`. Failures reuse the assertion
  /// failure taxonomy ([WebauthnVerifyFailure]).
  Future<Result<String, WebauthnVerifyFailure>> loginWithSecurityKey();

  /// Reactive stream of the user's registered credential, or null when
  /// no credential is registered.
  ///
  /// Used by:
  ///   - the Privacy UI status tile (shows "Security key registered —
  ///     last used May 17" when non-null);
  ///   - the PIN verify screen (renders the "Use security key" button
  ///     when non-null).
  Stream<WebauthnCredential?> watchCredential({required String uid});
}
