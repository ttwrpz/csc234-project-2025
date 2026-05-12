import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/auth_failure.dart';

/// Thin wrapper around `FirebaseAuth` and `google_sign_in`. This is the
/// boundary between Firebase types and the rest of the app — no domain types
/// here, no widgets here. Methods either return the raw `firebase_auth.User`
/// (mapped upstream by [AppUserMapper]) or throw an [AuthDatasourceException]
/// carrying a sealed [AuthFailure].
///
/// google_sign_in 7.x: the plugin is now a singleton accessed via
/// `GoogleSignIn.instance`, initialised once in `main.dart` before
/// `runApp`. The constructor's `googleSignIn` parameter has been
/// removed — tests can no longer inject a fake; instead they should
/// override `firebaseAuthDatasourceProvider` directly with a fake
/// datasource. (No existing tests inject a `GoogleSignIn` so this is
/// a no-op test-side migration.)
class FirebaseAuthDatasource {
  FirebaseAuthDatasource({required fb.FirebaseAuth auth}) : _auth = auth;

  final fb.FirebaseAuth _auth;

  /// OAuth scope hint for the combined-flow platforms (Android One Tap).
  /// On platforms that don't support a combined flow, the hint is ignored
  /// and authentication proceeds without scope authorization. This app
  /// only needs `idToken` (passed to `GoogleAuthProvider.credential`),
  /// so we never call `authorizationClient.authorizeScopes(...)` —
  /// avoiding a second round-trip and a second consent screen.
  static const List<String> _scopeHint = <String>['email'];

  fb.User? get currentUser => _auth.currentUser;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<fb.User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthDatasourceException(const AuthFailure.unknown(null));
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on PlatformException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } catch (e) {
      throw AuthDatasourceException(AuthFailure.unknown(e));
    }
  }

  Future<fb.User> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthDatasourceException(const AuthFailure.unknown(null));
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on PlatformException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } catch (e) {
      throw AuthDatasourceException(AuthFailure.unknown(e));
    }
  }

  Future<fb.User> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web flow: Firebase's `signInWithPopup` goes through the Google
        // Identity Services script loaded by Firebase Auth on web. The
        // `google_sign_in_web` flow needs an OAuth client id we don't
        // ship for web; using Firebase's popup directly avoids that
        // configuration burden.
        final provider = fb.GoogleAuthProvider()..addScope('email');
        final userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;
        if (user == null) {
          throw AuthDatasourceException(const AuthFailure.unknown(null));
        }
        return user;
      }

      // google_sign_in 7.x: singleton + authenticate(scopeHint:).
      // Throws GoogleSignInException on cancel / config errors.
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: _scopeHint,
      );
      // 7.x's `authentication` is a synchronous getter (not a Future
      // like 6.x). Returns `GoogleSignInAuthentication { idToken }`.
      // We deliberately don't request an `accessToken` — Firebase's
      // `GoogleAuthProvider.credential` only needs `idToken`, and
      // skipping the authorization round-trip removes a second consent
      // screen on first sign-in.
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        // The platform is supposed to attach an idToken when scopes are
        // requested via the scopeHint. If it didn't, treat as config
        // error so the UI surfaces "Google sign-in not configured"
        // rather than a generic "unknown".
        throw AuthDatasourceException(const AuthFailure.googleConfigMissing());
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthDatasourceException(const AuthFailure.unknown(null));
      }
      return user;
    } on GoogleSignInException catch (e) {
      // 7.x: typed exception with a `code` enum. Map cancel/timeout to
      // googleCancelled, configuration / unknown to googleConfigMissing.
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          throw AuthDatasourceException(const AuthFailure.googleCancelled());
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          throw AuthDatasourceException(const AuthFailure.googleCancelled());
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw AuthDatasourceException(
            const AuthFailure.googleConfigMissing(),
          );
        // ignore: no_default_cases
        default:
          throw AuthDatasourceException(AuthFailure.unknown(e));
      }
    } on fb.FirebaseAuthException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on PlatformException catch (e) {
      // Pre-7.x callers could hit raw PlatformExceptions; keep the
      // catch arm as defence-in-depth in case a transitive dependency
      // re-raises one.
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on AuthDatasourceException {
      rethrow;
    } catch (e) {
      throw AuthDatasourceException(AuthFailure.unknown(e));
    }
  }

  Future<void> signOut() async {
    try {
      // Best-effort Google sign-out; ignore if not signed in there.
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut().catchError((_) => null);
      }
      await _auth.signOut();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } catch (e) {
      throw AuthDatasourceException(AuthFailure.unknown(e));
    }
  }

  /// Reauthenticates the locally-signed-in user with [email]/[password].
  /// Required by Firebase Auth to refresh the recent-login window before
  /// destructive operations like `currentUser.delete()`. Maps Firebase
  /// codes to sealed [AuthFailure] variants — no `FirebaseAuthException`
  /// crosses the data/domain boundary.
  Future<void> reauthenticateWithPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthDatasourceException(const AuthFailure.userNotFound());
    }
    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on PlatformException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } catch (e) {
      throw AuthDatasourceException(AuthFailure.unknown(e));
    }
  }

  /// Reauthenticates the locally-signed-in user against a freshly-minted
  /// Google ID token. The token comes from the same `google_sign_in` flow
  /// that powers initial sign-in; the data layer wraps it in a
  /// `GoogleAuthProvider.credential` and calls
  /// `currentUser.reauthenticateWithCredential`.
  Future<void> reauthenticateWithGoogleIdToken(String idToken) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthDatasourceException(const AuthFailure.userNotFound());
    }
    try {
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      await user.reauthenticateWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on PlatformException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } catch (e) {
      throw AuthDatasourceException(AuthFailure.unknown(e));
    }
  }

  /// Deletes the locally-signed-in Firebase Auth user record. Called by
  /// [AuthRepositoryImpl.deleteCurrentUser] AFTER the server cascade has
  /// run (per ADR-0009 §5.2 — the CF deletes data, the client deletes the
  /// Auth user). No-ops when the user is already null (idempotent —
  /// matches the use case's "Ok if already gone" contract).
  ///
  /// Maps `requires-recent-login` to [AuthFailure.requiresRecentLogin] so
  /// the caller can distinguish the recoverable case from a hard
  /// failure. Other Firebase codes map to [AuthFailure.unknown] —
  /// `currentUser.delete()` is otherwise documented to succeed once
  /// reauth has run.
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthDatasourceException(const AuthFailure.requiresRecentLogin());
      }
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on PlatformException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } catch (e) {
      throw AuthDatasourceException(AuthFailure.unknown(e));
    }
  }

  AuthFailure _codeToFailure(String code, Object cause) {
    switch (code) {
      case 'invalid-email':
        return const AuthFailure.invalidEmail();
      case 'weak-password':
        return const AuthFailure.weakPassword();
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure.wrongPassword();
      case 'user-not-found':
        return const AuthFailure.userNotFound();
      case 'email-already-in-use':
        return const AuthFailure.emailAlreadyInUse();
      case 'network-request-failed':
        return const AuthFailure.network();
      case 'too-many-requests':
        return const AuthFailure.tooManyRequests();
      default:
        return AuthFailure.unknown(cause);
    }
  }
}

/// Exception envelope used inside the data layer to carry a sealed
/// [AuthFailure] across `Future` chains. Repository impls catch this and
/// convert to `Result.Err`.
class AuthDatasourceException implements Exception {
  AuthDatasourceException(this.failure);
  final AuthFailure failure;
}
