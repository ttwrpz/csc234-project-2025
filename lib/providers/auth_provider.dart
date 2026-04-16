import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/local_db_service.dart';

/// Manages authentication state, user profile, and auth-related actions.
///
/// Listens to Firebase auth state changes and exposes the current user,
/// profile data, loading state, and error messages to the UI.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final LocalDbService _localDbService;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  AuthProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
    required StorageService storageService,
    required LocalDbService localDbService,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        _storageService = storageService,
        _localDbService = localDbService {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadUserProfile(user.uid);
    } else {
      _userProfile = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      _userProfile = await _firestoreService.getUserProfile(uid);
    } catch (_) {
      // Profile may not exist yet
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authService.getErrorMessage(e);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.registerWithEmail(
        email,
        password,
        displayName,
      );
      // Create user profile in Firestore
      final profile = UserProfile(
        uid: credential.user!.uid,
        displayName: displayName.trim(),
        email: email.trim(),
        photoUrl: credential.user!.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserProfile(profile);
      _userProfile = profile;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authService.getErrorMessage(e);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user!;

      // Check if profile exists, create if not
      var profile = await _firestoreService.getUserProfile(user.uid);
      if (profile == null) {
        profile = UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUserProfile(profile);
      }
      _userProfile = profile;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authService.getErrorMessage(e);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authService.getErrorMessage(e);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.updateDisplayName(displayName);
      if (_user != null) {
        await _firestoreService.updateUserProfile(
          _user!.uid,
          {'displayName': displayName.trim()},
        );
        _userProfile = _userProfile?.copyWith(displayName: displayName.trim());
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _error = null;
    try {
      final uid = _user!.uid;
      await _firestoreService.deleteAllUserMoods(uid);
      await _storageService.deleteAllUserAttachments(uid);
      await _firestoreService.deleteUserProfile(uid);
      await _localDbService.clearUserEntries(uid);
      await _authService.deleteAccount();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authService.getErrorMessage(e);
      return false;
    } catch (e) {
      _error = 'Failed to delete account.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
