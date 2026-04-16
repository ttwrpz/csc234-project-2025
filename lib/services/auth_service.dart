import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/error_handler.dart';

/// Service handling Firebase Authentication operations.
///
/// Supports email/password registration and login, Google Sign-In,
/// password reset, and sign-out.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently signed-in user, or null if not authenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits whenever the authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in a user with email and password.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new user with email, password, and display name.
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await credential.user?.reload();
    return credential;
  }

  /// Signs in with Google. Uses popup on web, native flow on mobile.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return await _auth.signInWithPopup(provider);
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Updates the current user's display name.
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName.trim());
    await _auth.currentUser?.reload();
  }

  /// Signs out the current user from both Firebase and Google.
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// Deletes the current user's Firebase account.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  /// Returns a user-friendly error message for a [FirebaseAuthException].
  String getErrorMessage(FirebaseAuthException e) {
    return ErrorHandler.getFirebaseAuthMessage(e.code);
  }
}
