// Hide cloud_functions' `Result` to avoid colliding with core's sealed
// `Result<T, F>` (the one we use across every repository return).
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:core/core.dart';

import '../domain/auth_credentials.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import 'datasources/firebase_auth_datasource.dart';
import 'mappers/app_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDatasource datasource,
    required FirebaseFunctions functions,
    AppUserMapper mapper = const AppUserMapper(),
    Logger logger = const Logger('auth.repo'),
  }) : _datasource = datasource,
       _functions = functions,
       _mapper = mapper,
       _logger = logger;

  final FirebaseAuthDatasource _datasource;
  final FirebaseFunctions _functions;
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
          await _datasource.reauthenticateWithGoogle(idToken: idToken);
        case BiometricCredentials():
          // No platform-keystore-cached Firebase credential exists in the
          // S4 biometric setup — local_auth only confirms presence; it
          // does not mint a Firebase Auth credential. Until that lands
          // (out of scope for HB-004), biometric reauth is unavailable
          // and the controller falls back to the password modal. This
          // is the documented degradation per the brief.
          _logger.warn(
            'biometric reauth requested but no cached credential available',
          );
          return const Err(AuthFailure.biometricUnavailable());
      }
      return const Ok(null);
    } on AuthDatasourceException catch (e) {
      _logger.warn('reauthenticate failed: ${e.failure.runtimeType}');
      return Err(e.failure);
    }
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    final uid = _datasource.currentUser?.uid;
    try {
      // 1. Server cascade — admin SDK callable per ADR-0009. The CF reads
      //    context.auth.uid; no body required. Region must match deploy
      //    target (asia-southeast1) — see firebaseFunctionsProvider in
      //    mood/data/providers.dart.
      final callable = _functions.httpsCallable('deleteAccount');
      await callable.call<Object?>(<String, Object?>{});
    } on FirebaseFunctionsException catch (e) {
      _logger.warn('deleteAccount CF failed code=${e.code}');
      switch (e.code) {
        case 'unauthenticated':
          return const Err(AuthFailure.unknown('unauthenticated'));
        case 'unavailable':
        case 'deadline-exceeded':
          return const Err(AuthFailure.network());
        default:
          return Err(AuthFailure.unknown(e.code));
      }
    } catch (e) {
      _logger.warn('deleteAccount CF failed runtimeType=${e.runtimeType}');
      return Err(AuthFailure.unknown(e));
    }

    // 2. Local Auth user delete. The CF has already cascaded server-side
    //    (Firestore + Storage + Auth user via admin SDK), so a stale
    //    `requires-recent-login` here is non-fatal — the data is gone
    //    regardless and the upstream signOut() will tear down the
    //    session. Catch it via the typed exception and proceed.
    try {
      await _datasource.deleteCurrentUser();
    } on RequiresRecentLoginException {
      _logger.info('deleteAccount: local delete needed recent login; ignored');
    } on AuthDatasourceException catch (e) {
      _logger.warn(
        'deleteAccount local delete failed: ${e.failure.runtimeType}',
      );
      return Err(e.failure);
    }

    _logger.info('deleteAccount ok uid=${uid ?? 'null'} outcome=deleted');
    return const Ok(null);
  }
}
