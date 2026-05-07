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

  /// Reauthenticates the currently signed-in user with email + password.
  /// Required by Firebase Auth before destructive operations like
  /// `currentUser.delete()` (HB-004 + ADR-0009 — recent-login window).
  ///
  /// Throws [AuthDatasourceException] on the same Firebase code mapping
  /// as [signInWithEmail] (`wrong-password`/`invalid-credential` →
  /// `wrongPassword`, etc.). Throws an `AuthFailure.unknown` envelope
  /// when no user is signed in — callers should never reach this without
  /// an active session, but we surface it loudly rather than silently
  /// returning success.
  Future<void> reauthenticateWithPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthDatasourceException(
        const AuthFailure.unknown('reauthenticate: no current user'),
      );
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

  /// Reauthenticates the currently signed-in user with a fresh Google
  /// ID token (the data layer mints the token via the platform sign-in
  /// flow). Mirrors [signInWithGoogle]'s credential shape — only
  /// `idToken` is required because that's what `GoogleAuthProvider`
  /// accepts. `accessToken` is intentionally omitted to keep parity
  /// with the sign-in path (no second consent screen).
  Future<void> reauthenticateWithGoogle({required String idToken}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthDatasourceException(
        const AuthFailure.unknown('reauthenticate: no current user'),
      );
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

  /// Deletes the local Firebase Auth user record. The server-side
  /// cascade (Firestore + Storage + Auth) is owned by the
  /// `deleteAccount` Cloud Function — this call only revokes the local
  /// Auth user. Idempotent: returns silently when `currentUser` is
  /// already null.
  ///
  /// Catches `requires-recent-login` and rethrows as a typed
  /// exception the repository can ignore — the CF has already wiped
  /// the server, so a stale local-session-only error is non-fatal.
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Per HB-004 + ADR-0009: the CF is admin-SDK and has already
        // cascaded server-side. The recent-login window only guards
        // the local session, which the upstream signOut() will tear
        // down anyway. Surface as a typed exception so the repo can
        // ignore it without swallowing other Firebase codes.
        throw const RequiresRecentLoginException();
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

/// Thrown by [FirebaseAuthDatasource.deleteCurrentUser] when Firebase
/// Auth requires a fresher sign-in than the user currently has. The
/// repository swallows this in the account-deletion path because the CF
/// has already cascaded server-side; the local session will be torn
/// down by the upstream signOut() regardless.
class RequiresRecentLoginException implements Exception {
  const RequiresRecentLoginException();
}
