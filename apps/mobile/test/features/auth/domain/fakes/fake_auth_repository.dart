import 'package:core/core.dart';
import 'package:moodbloom/features/auth/domain/auth_credentials.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/auth_repository.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';

/// Hand-rolled fake. We don't use mockito in S2 — keeps generated code count
/// low and tests readable.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signInResult,
    this.registerResult,
    this.googleResult,
    this.signOutResult,
    this.reauthenticateResult,
    this.deleteAccountResult,
    this.deleteCurrentUserResult,
    this.currentUserOverride,
  });

  Result<AppUser, AuthFailure>? signInResult;
  Result<AppUser, AuthFailure>? registerResult;
  Result<AppUser, AuthFailure>? googleResult;
  Result<void, AuthFailure>? signOutResult;
  Result<void, AuthFailure>? reauthenticateResult;
  Result<void, AuthFailure>? deleteAccountResult;
  Result<void, AuthFailure>? deleteCurrentUserResult;
  Result<void, AuthFailure>? sendPasswordResetEmailResult;
  AppUser? currentUserOverride;
  final List<({String email, String password})> signInCalls = [];
  final List<({String email, String password})> registerCalls = [];
  final List<AuthCredentials> reauthenticateCalls = [];
  final List<String> sendPasswordResetEmailCalls = [];
  int googleCalls = 0;
  int signOutCalls = 0;
  int deleteAccountCalls = 0;
  int deleteCurrentUserCalls = 0;

  @override
  AppUser? get currentUser => currentUserOverride;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield const AppUser(uid: 'u-1', email: 'user@example.com');
    yield null;
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email: email, password: password));
    return signInResult ?? const Err(AuthFailure.unknown(null));
  }

  @override
  Future<Result<AppUser, AuthFailure>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    registerCalls.add((email: email, password: password));
    return registerResult ?? const Err(AuthFailure.unknown(null));
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithGoogle() async {
    googleCalls += 1;
    return googleResult ?? const Err(AuthFailure.unknown(null));
  }

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    signOutCalls += 1;
    return signOutResult ?? const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> sendPasswordResetEmail(String email) async {
    sendPasswordResetEmailCalls.add(email);
    return sendPasswordResetEmailResult ?? const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> reauthenticate(
    AuthCredentials creds,
  ) async {
    reauthenticateCalls.add(creds);
    return reauthenticateResult ?? const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    deleteAccountCalls += 1;
    return deleteAccountResult ?? const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> deleteCurrentUser() async {
    deleteCurrentUserCalls += 1;
    return deleteCurrentUserResult ?? const Ok(null);
  }

  Result<void, AuthFailure>? updateDisplayNameResult;
  final List<String> updateDisplayNameCalls = [];

  @override
  Future<Result<void, AuthFailure>> updateDisplayName(String name) async {
    updateDisplayNameCalls.add(name);
    return updateDisplayNameResult ?? const Ok(null);
  }
}
