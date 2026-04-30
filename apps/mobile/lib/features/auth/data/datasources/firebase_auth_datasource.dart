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
class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    required fb.FirebaseAuth auth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth,
       // OAuth scope minimum: 'email' only — see security review item R-002.
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

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
      final fb.OAuthCredential credential;
      if (kIsWeb) {
        // Web flow: prefer Firebase's signInWithPopup which goes through the
        // Google Identity Services script loaded in web/index.html. The
        // `google_sign_in` web flow is more fragile and requires extra meta
        // tags, so we use Firebase's popup directly.
        final provider = fb.GoogleAuthProvider()..addScope('email');
        final userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;
        if (user == null) {
          throw AuthDatasourceException(const AuthFailure.unknown(null));
        }
        return user;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthDatasourceException(const AuthFailure.googleCancelled());
      }
      final googleAuth = await googleUser.authentication;
      credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthDatasourceException(const AuthFailure.unknown(null));
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthDatasourceException(_codeToFailure(e.code, e));
    } on PlatformException catch (e) {
      // Common: network_error, sign_in_canceled, sign_in_failed (config).
      if (e.code == 'sign_in_canceled' || e.code == 'canceled') {
        throw AuthDatasourceException(const AuthFailure.googleCancelled());
      }
      if (e.code == 'sign_in_failed' ||
          e.code == 'sign_in_required' ||
          e.code == 'developer_error') {
        throw AuthDatasourceException(const AuthFailure.googleConfigMissing());
      }
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
        await _googleSignIn.signOut().catchError((_) => null);
      }
      await _auth.signOut();
    } on fb.FirebaseAuthException catch (e) {
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
