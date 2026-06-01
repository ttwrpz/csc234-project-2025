import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/auth_repository_impl.dart';
import 'package:moodbloom/features/auth/data/datasources/delete_account_functions_datasource.dart';
import 'package:moodbloom/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';

/// Hand-rolled fake of [FirebaseAuthDatasource] that covers only the
/// surface area exercised by these tests. The mapper / sign-in / Google
/// flows aren't tested here - those need a real `firebase_auth.User`,
/// which would pull in the platform plugin. The brief calls out
/// `deleteCurrentUser` only, so this is intentionally narrow.
class _FakeFirebaseAuthDatasource implements FirebaseAuthDatasource {
  /// When non-null, [deleteCurrentUser] throws this exception. Mirrors
  /// the typed envelope the real datasource raises.
  AuthDatasourceException? deleteCurrentUserThrows;

  /// Set to `false` to mimic "no current user" - the real datasource
  /// short-circuits to a no-op in that case.
  bool hasCurrentUser = true;

  int deleteCurrentUserCalls = 0;

  @override
  Future<void> deleteCurrentUser() async {
    deleteCurrentUserCalls += 1;
    if (!hasCurrentUser) return;
    if (deleteCurrentUserThrows != null) {
      throw deleteCurrentUserThrows!;
    }
  }

  // Every other public method is unused - fall through to noSuchMethod
  // so the test compiles without re-implementing the full surface.
  @override
  // ignore: unused_element
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Hand-rolled fake of [DeleteAccountFunctionsDatasource]. The
/// repository's `deleteAccount()` path is tested via this fake; the CF
/// itself is exercised by the TypeScript-side tests under
/// `functions/test/`.
class _FakeDeleteAccountFunctionsDatasource
    implements DeleteAccountFunctionsDatasource {
  DeleteAccountDatasourceException? throwOnCall;
  int calls = 0;

  @override
  Future<void> call() async {
    calls += 1;
    if (throwOnCall != null) {
      throw throwOnCall!;
    }
  }
}

void main() {
  group('AuthRepositoryImpl.deleteCurrentUser', () {
    late _FakeFirebaseAuthDatasource fakeAuth;
    late _FakeDeleteAccountFunctionsDatasource fakeFns;
    late AuthRepositoryImpl repo;

    setUp(() {
      fakeAuth = _FakeFirebaseAuthDatasource();
      fakeFns = _FakeDeleteAccountFunctionsDatasource();
      repo = AuthRepositoryImpl(
        datasource: fakeAuth,
        deleteAccountDatasource: fakeFns,
      );
    });

    test('happy path - datasource succeeds → Ok(null)', () async {
      final result = await repo.deleteCurrentUser();
      expect(result, isA<Ok<void, AuthFailure>>());
      expect(fakeAuth.deleteCurrentUserCalls, equals(1));
    });

    test(
      'no current user - datasource no-ops → Ok(null) (idempotent contract)',
      () async {
        fakeAuth.hasCurrentUser = false;
        final result = await repo.deleteCurrentUser();
        expect(result, isA<Ok<void, AuthFailure>>());
        // The repository still calls through to the datasource; the
        // datasource itself decides to no-op when currentUser is null.
        expect(fakeAuth.deleteCurrentUserCalls, equals(1));
      },
    );

    test(
      'requires-recent-login - surfaces AuthFailure.requiresRecentLogin '
      'so the use case can branch into the "proceed to signOut" arm',
      () async {
        fakeAuth.deleteCurrentUserThrows = AuthDatasourceException(
          const AuthFailure.requiresRecentLogin(),
        );
        final result = await repo.deleteCurrentUser();
        expect(result, isA<Err<void, AuthFailure>>());
        final failure = (result as Err<void, AuthFailure>).failure;
        expect(
          identical(failure, const AuthFailure.requiresRecentLogin()),
          isTrue,
        );
      },
    );

    test('other FirebaseAuthException - maps to AuthFailure.unknown via '
        'the datasource envelope', () async {
      fakeAuth.deleteCurrentUserThrows = AuthDatasourceException(
        AuthFailure.unknown(
          fb.FirebaseAuthException(code: 'internal', message: 'boom'),
        ),
      );
      final result = await repo.deleteCurrentUser();
      expect(result, isA<Err<void, AuthFailure>>());
      final failure = (result as Err<void, AuthFailure>).failure;
      // Not the requires-recent-login sentinel - it's the unknown
      // variant with an embedded cause.
      expect(
        identical(failure, const AuthFailure.requiresRecentLogin()),
        isFalse,
      );
    });
  });

  group('AuthRepositoryImpl.deleteAccount', () {
    late _FakeFirebaseAuthDatasource fakeAuth;
    late _FakeDeleteAccountFunctionsDatasource fakeFns;
    late AuthRepositoryImpl repo;

    setUp(() {
      fakeAuth = _FakeFirebaseAuthDatasource();
      fakeFns = _FakeDeleteAccountFunctionsDatasource();
      repo = AuthRepositoryImpl(
        datasource: fakeAuth,
        deleteAccountDatasource: fakeFns,
      );
    });

    test('CF succeeds → Ok(null)', () async {
      final result = await repo.deleteAccount();
      expect(result, isA<Ok<void, AuthFailure>>());
      expect(fakeFns.calls, equals(1));
    });

    test('CF network failure → AuthFailure.network()', () async {
      fakeFns.throwOnCall = const DeleteAccountDatasourceException.network();
      final result = await repo.deleteAccount();
      expect(result, isA<Err<void, AuthFailure>>());
      final failure = (result as Err<void, AuthFailure>).failure;
      expect(identical(failure, const AuthFailure.network()), isTrue);
    });

    test('CF unauthenticated → AuthFailure.userNotFound()', () async {
      fakeFns.throwOnCall =
          const DeleteAccountDatasourceException.unauthenticated();
      final result = await repo.deleteAccount();
      expect(result, isA<Err<void, AuthFailure>>());
      final failure = (result as Err<void, AuthFailure>).failure;
      expect(identical(failure, const AuthFailure.userNotFound()), isTrue);
    });

    test('CF unknown → AuthFailure.unknown', () async {
      fakeFns.throwOnCall = const DeleteAccountDatasourceException.unknown(
        'boom',
      );
      final result = await repo.deleteAccount();
      expect(result, isA<Err<void, AuthFailure>>());
      final failure = (result as Err<void, AuthFailure>).failure;
      expect(failure, isA<AuthFailure>());
      // Sentinel checks: not one of the named variants.
      expect(identical(failure, const AuthFailure.network()), isFalse);
      expect(identical(failure, const AuthFailure.userNotFound()), isFalse);
    });
  });
}
