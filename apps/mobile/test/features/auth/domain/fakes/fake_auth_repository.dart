import 'package:core/core.dart';
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
  });

  Result<AppUser, AuthFailure>? signInResult;
  Result<AppUser, AuthFailure>? registerResult;
  Result<AppUser, AuthFailure>? googleResult;
  Result<void, AuthFailure>? signOutResult;
  final List<({String email, String password})> signInCalls = [];
  final List<({String email, String password})> registerCalls = [];
  int googleCalls = 0;
  int signOutCalls = 0;

  @override
  AppUser? get currentUser => null;

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
}
