import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_credentials.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/usecases/delete_account.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('DeleteAccountUseCase', () {
    test('happy path - reauth Ok → deleteAccount Ok → deleteCurrentUser Ok → '
        'signOut Ok → Ok(null)', () async {
      final repo = FakeAuthRepository();
      final useCase = DeleteAccountUseCase(repo);

      final result = await useCase.call(
        reauth: const AuthCredentials.password(
          email: 'user@example.com',
          password: 'pw',
        ),
      );

      expect(result, isA<Ok<void, AuthFailure>>());
      expect(repo.reauthenticateCalls, hasLength(1));
      expect(repo.deleteAccountCalls, equals(1));
      expect(repo.deleteCurrentUserCalls, equals(1));
      expect(repo.signOutCalls, equals(1));
    });

    test('reauth fails - short-circuits; deleteAccount, deleteCurrentUser and '
        'signOut are NOT called', () async {
      final repo = FakeAuthRepository(
        reauthenticateResult: const Err(AuthFailure.wrongPassword()),
      );
      final useCase = DeleteAccountUseCase(repo);

      final result = await useCase.call(
        reauth: const AuthCredentials.password(
          email: 'user@example.com',
          password: 'wrong',
        ),
      );

      expect(result, isA<Err<void, AuthFailure>>());
      expect((result as Err<void, AuthFailure>).failure, isA<AuthFailure>());
      // Critical: server is NEVER touched on a reauth failure. The CF
      // is admin-SDK and would happily delete based on context.auth.uid
      // alone, so the client-side reauth fence is the only thing
      // protecting against a stolen-but-not-yet-revoked ID token.
      expect(repo.deleteAccountCalls, equals(0));
      expect(repo.deleteCurrentUserCalls, equals(0));
      expect(repo.signOutCalls, equals(0));
    });

    test('CF fails - reauth ran, deleteAccount returned Err; deleteCurrentUser '
        'and signOut are NOT called', () async {
      final repo = FakeAuthRepository(
        deleteAccountResult: const Err(AuthFailure.network()),
      );
      final useCase = DeleteAccountUseCase(repo);

      final result = await useCase.call(
        reauth: const AuthCredentials.biometric(),
      );

      expect(result, isA<Err<void, AuthFailure>>());
      expect(repo.reauthenticateCalls, hasLength(1));
      expect(repo.deleteAccountCalls, equals(1));
      // Server cleanup didn't happen; don't proceed with local
      // destruction. User stays signed in so they can retry - the CF
      // is idempotent per ADR-0009 so a retry on a partial-cascade
      // run cleans the tail without orphaning data.
      expect(repo.deleteCurrentUserCalls, equals(0));
      expect(repo.signOutCalls, equals(0));
    });

    test('deleteCurrentUser returns requiresRecentLogin - use case proceeds to '
        'signOut and returns Ok(null) (server already wiped)', () async {
      final repo = FakeAuthRepository(
        deleteCurrentUserResult: const Err(AuthFailure.requiresRecentLogin()),
      );
      final useCase = DeleteAccountUseCase(repo);

      final result = await useCase.call(
        reauth: const AuthCredentials.password(
          email: 'user@example.com',
          password: 'pw',
        ),
      );

      // Per ADR-0009 §"Good" point 5, the server cascade has run, so
      // an orphaned local Auth record is acceptable. The use case
      // proceeds to signOut and returns Ok.
      expect(result, isA<Ok<void, AuthFailure>>());
      expect(repo.deleteAccountCalls, equals(1));
      expect(repo.deleteCurrentUserCalls, equals(1));
      expect(repo.signOutCalls, equals(1));
    });

    test(
      'deleteCurrentUser returns unknown - use case still proceeds to signOut '
      'and returns Ok(null) (best-effort cleanup per ADR-0009)',
      () async {
        final repo = FakeAuthRepository(
          deleteCurrentUserResult: const Err(AuthFailure.unknown('boom')),
        );
        final useCase = DeleteAccountUseCase(repo);

        final result = await useCase.call(
          reauth: const AuthCredentials.password(
            email: 'user@example.com',
            password: 'pw',
          ),
        );

        // Same rationale as requires-recent-login: server is already
        // wiped, the local Auth record is an acceptable orphan.
        expect(result, isA<Ok<void, AuthFailure>>());
        expect(repo.deleteAccountCalls, equals(1));
        expect(repo.deleteCurrentUserCalls, equals(1));
        expect(repo.signOutCalls, equals(1));
      },
    );

    test('signOut fails post-delete - returns the signOut error; data is gone '
        'server-side regardless', () async {
      final repo = FakeAuthRepository(
        signOutResult: const Err(AuthFailure.unknown('disk full')),
      );
      final useCase = DeleteAccountUseCase(repo);

      final result = await useCase.call(
        reauth: const AuthCredentials.google(idToken: 'idt-123'),
      );

      expect(result, isA<Err<void, AuthFailure>>());
      expect(repo.reauthenticateCalls, hasLength(1));
      expect(repo.deleteAccountCalls, equals(1));
      expect(repo.deleteCurrentUserCalls, equals(1));
      expect(repo.signOutCalls, equals(1));
      // Acceptable degraded state - the data is gone; only the local
      // session is stuck. The downstream router's auth-state listener
      // still redirects on the next emission. Documented in HB-004
      // failure-semantics block.
    });

    test(
      'reauth credentials envelope variants - all three reach the repo',
      () async {
        final repo = FakeAuthRepository();
        final useCase = DeleteAccountUseCase(repo);

        await useCase.call(
          reauth: const AuthCredentials.password(
            email: 'a@b.com',
            password: 'pw',
          ),
        );
        await useCase.call(
          reauth: const AuthCredentials.google(idToken: 'idt'),
        );
        await useCase.call(reauth: const AuthCredentials.biometric());

        expect(repo.reauthenticateCalls, hasLength(3));
        expect(repo.reauthenticateCalls[0], isA<PasswordCredentials>());
        expect(repo.reauthenticateCalls[1], isA<GoogleCredentials>());
        expect(repo.reauthenticateCalls[2], isA<BiometricCredentials>());
      },
    );
  });
}
