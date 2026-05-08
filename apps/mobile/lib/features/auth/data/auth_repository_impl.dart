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
    AppUserMapper mapper = const AppUserMapper(),
    Logger logger = const Logger('auth.repo'),
  }) : _datasource = datasource,
       _mapper = mapper,
       _logger = logger;

  final FirebaseAuthDatasource _datasource;
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
    // Stub for HB-004 step 1 — the real Firebase Auth wiring lands in
    // step 2 (HB-004 brief §"Data shape"). Returns a marker failure so
    // any caller that hits this path before step 2 ships fails loudly.
    _logger.warn('reauthenticate not yet implemented (HB-004 step 2)');
    return const Err(AuthFailure.unknown('reauthenticate: not implemented'));
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    // Stub for HB-004 step 1 — the Cloud Function call + local
    // currentUser.delete() land in step 2.
    _logger.warn('deleteAccount not yet implemented (HB-004 step 2)');
    return const Err(AuthFailure.unknown('deleteAccount: not implemented'));
  }
}
