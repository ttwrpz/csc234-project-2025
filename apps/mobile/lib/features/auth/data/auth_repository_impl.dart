import 'package:core/core.dart';

import '../domain/auth_credentials.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import 'datasources/delete_account_functions_datasource.dart';
import 'datasources/firebase_auth_datasource.dart';
import 'mappers/app_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDatasource datasource,
    required DeleteAccountFunctionsDatasource deleteAccountDatasource,
    AppUserMapper mapper = const AppUserMapper(),
    Logger logger = const Logger('auth.repo'),
  }) : _datasource = datasource,
       _deleteAccountDatasource = deleteAccountDatasource,
       _mapper = mapper,
       _logger = logger;

  final FirebaseAuthDatasource _datasource;
  final DeleteAccountFunctionsDatasource _deleteAccountDatasource;
  final AppUserMapper _mapper;
  final Logger _logger;

  @override
  Stream<AppUser?> watchAuthState() {
    return _datasource.authStateChanges().map(
      (user) => user == null ? null : _mapper.fromFirebaseUser(user),
    );
  }

  @override
  AppUser? get currentUser {
    final user = _datasource.currentUser;
    return user == null ? null : _mapper.fromFirebaseUser(user);
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.signInWithEmail(
        email: email,
        password: password,
      );
      return Ok(_mapper.fromFirebaseUser(user));
    } on AuthDatasourceException catch (e) {
      _logger.warn('sign-in failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<AppUser, AuthFailure>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.registerWithEmail(
        email: email,
        password: password,
      );
      return Ok(_mapper.fromFirebaseUser(user));
    } on AuthDatasourceException catch (e) {
      _logger.warn('register failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithGoogle() async {
    try {
      final user = await _datasource.signInWithGoogle();
      return Ok(_mapper.fromFirebaseUser(user));
    } on AuthDatasourceException catch (e) {
      _logger.warn('google sign-in failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithCustomToken(
    String token,
  ) async {
    try {
      final user = await _datasource.signInWithCustomToken(token);
      return Ok(_mapper.fromFirebaseUser(user));
    } on AuthDatasourceException catch (e) {
      _logger.warn('custom-token sign-in failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<void, AuthFailure>> sendPasswordResetEmail(String email) async {
    try {
      await _datasource.sendPasswordResetEmail(email);
      return const Ok(null);
    } on AuthDatasourceException catch (e) {
      _logger.warn('sendPasswordResetEmail failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    try {
      await _datasource.signOut();
      return const Ok(null);
    } on AuthDatasourceException catch (e) {
      _logger.warn('sign-out failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<void, AuthFailure>> reauthenticate(
    AuthCredentials creds,
  ) async {
    try {
      switch (creds) {
        case PasswordCredentials(:final email, :final password):
          await _datasource.reauthenticateWithPassword(
            email: email,
            password: password,
          );
        case GoogleCredentials(:final idToken):
          await _datasource.reauthenticateWithGoogleIdToken(idToken);
        case BiometricCredentials():
          // Biometric reauth path is platform-keystore-backed and lands
          // in a follow-up - no caller wires it today. Surface a marker
          // failure so any caller wiring biometric reauth before that
          // path ships fails loudly rather than silently bypassing the
          // reauth fence.
          _logger.warn('biometric reauth not yet implemented');
          return const Err(
            AuthFailure.unknown('biometric reauth: not implemented'),
          );
      }
      return const Ok(null);
    } on AuthDatasourceException catch (e) {
      _logger.warn('reauthenticate failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<void, AuthFailure>> updateDisplayName(String name) async {
    try {
      await _datasource.updateDisplayName(name);
      return const Ok(null);
    } on AuthDatasourceException catch (e) {
      _logger.warn('updateDisplayName failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    // Server-side cascade via the admin-SDK callable. The CF wipes
    // every subcollection under `users/{uid}/` plus any user-owned
    // Storage media, then resets the profile-doc fields. It
    // deliberately does NOT delete the Firebase Auth record - that's
    // left to `deleteCurrentUser` so the use case can sequence reauth →
    // cascade → local-Auth-delete → signOut with a single recent-login
    // window.
    try {
      await _deleteAccountDatasource.call();
      return const Ok(null);
    } on DeleteAccountDatasourceException catch (e) {
      // Log only the typed exception runtime - no uid, no payload. The
      // caller already knows it's the delete path.
      _logger.warn('deleteAccount CF failed: ${e.runtimeType}');
      return Err(_mapDeleteAccountException(e));
    }
  }

  AuthFailure _mapDeleteAccountException(DeleteAccountDatasourceException e) {
    return switch (e) {
      DeleteAccountUnauthenticatedException() =>
        const AuthFailure.userNotFound(),
      DeleteAccountNetworkException() => const AuthFailure.network(),
      DeleteAccountUnknownException(:final cause) => AuthFailure.unknown(cause),
    };
  }

  @override
  Future<Result<void, AuthFailure>> deleteCurrentUser() async {
    try {
      await _datasource.deleteCurrentUser();
      return const Ok(null);
    } on AuthDatasourceException catch (e) {
      // `requiresRecentLogin` is a normal post-cascade outcome when the
      // CF + Storage cleanup pushes the call out past the ~5-minute
      // window; the caller knows to proceed to signOut anyway. Other
      // failures are still surfaced.
      _logger.warn('deleteCurrentUser failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }
}
