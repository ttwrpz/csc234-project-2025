import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/auth_credentials.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/usecases/delete_account.dart';
import 'package:moodbloom/features/settings/presentation/controllers/delete_account_controller.dart';

import '../../../auth/domain/fakes/fake_auth_repository.dart';

/// Unit tests for [DeleteAccountController].
///
/// The controller is a thin orchestrator over [DeleteAccountUseCase].
/// These tests exercise the four paths the Settings screen reacts to:
///
/// 1. **happy path** — biometric/password-agnostic; reauth Ok →
///    deleteAccount Ok → signOut Ok → state becomes `Success`.
/// 2. **biometric forwarding** — controller does NOT alter the
///    credential envelope; whatever the screen passes in flows
///    straight to the use case. Structural assertion: the fake
///    repository's `reauthenticateCalls` list contains the same
///    `BiometricCredentials` instance type.
/// 3. **wrong password** — reauth returns `Err(wrongPassword)` →
///    state becomes `Errored(wrongPassword)`; signOut is NOT called.
/// 4. **network failure** — CF returns `Err(network)` → state
///    becomes `Errored(network)`; signOut is NOT called.
void main() {
  ProviderContainer makeContainer(FakeAuthRepository fake) {
    return ProviderContainer(
      overrides: [
        deleteAccountUseCaseProvider.overrideWithValue(
          DeleteAccountUseCase(fake),
        ),
      ],
    );
  }

  group('DeleteAccountController', () {
    test(
      'happy path — biometric reauth → success state; CF + signOut both fire',
      () async {
        final repo = FakeAuthRepository(
          reauthenticateResult: const Ok(null),
          deleteAccountResult: const Ok(null),
          signOutResult: const Ok(null),
        );
        final container = makeContainer(repo);
        addTearDown(container.dispose);

        final controller = container.read(
          deleteAccountControllerProvider.notifier,
        );
        expect(
          container.read(deleteAccountControllerProvider),
          isA<DeleteAccountIdle>(),
        );

        final outcome = await controller.run(
          creds: const AuthCredentials.biometric(),
        );

        expect(outcome, isA<DeleteAccountSuccess>());
        expect(
          container.read(deleteAccountControllerProvider),
          isA<DeleteAccountSuccess>(),
        );
        // Biometric envelope was forwarded unchanged — proves the
        // controller is credential-agnostic and that screen's choice
        // (biometric vs. password fallback) flows straight through.
        expect(repo.reauthenticateCalls.single, isA<BiometricCredentials>());
        expect(repo.deleteAccountCalls, equals(1));
        expect(repo.signOutCalls, equals(1));
      },
    );

    test(
      'password reauth flows through — controller does not transform creds',
      () async {
        final repo = FakeAuthRepository(
          reauthenticateResult: const Ok(null),
          deleteAccountResult: const Ok(null),
          signOutResult: const Ok(null),
        );
        final container = makeContainer(repo);
        addTearDown(container.dispose);

        final controller = container.read(
          deleteAccountControllerProvider.notifier,
        );
        await controller.run(
          creds: const AuthCredentials.password(
            email: 'a@b.com',
            password: 'pw',
          ),
        );

        // The screen passes a PasswordCredentials envelope when
        // biometric is unavailable (the documented degraded mode for
        // HB-004 step 3); assert the controller forwarded the same
        // variant so a future biometric-cached path swap works
        // without a controller change.
        expect(repo.reauthenticateCalls.single, isA<PasswordCredentials>());
      },
    );

    test(
      'wrong password — state becomes Errored(wrongPassword); signOut NOT called',
      () async {
        final repo = FakeAuthRepository(
          reauthenticateResult: const Err(AuthFailure.wrongPassword()),
        );
        final container = makeContainer(repo);
        addTearDown(container.dispose);

        final controller = container.read(
          deleteAccountControllerProvider.notifier,
        );
        final outcome = await controller.run(
          creds: const AuthCredentials.password(
            email: 'a@b.com',
            password: 'wrong',
          ),
        );

        expect(outcome, isA<DeleteAccountErrored>());
        expect(
          (outcome as DeleteAccountErrored).reason,
          DeleteAccountErrorReason.wrongPassword,
        );
        // Critical: the use case short-circuits on reauth failure,
        // so the CF is NEVER called and the user is still signed in
        // for retry. The wrong-password state keeps the password
        // modal open with an inline error per HB-004.
        expect(repo.deleteAccountCalls, equals(0));
        expect(repo.signOutCalls, equals(0));
      },
    );

    test(
      'network failure on CF — state becomes Errored(network); signOut NOT called',
      () async {
        final repo = FakeAuthRepository(
          reauthenticateResult: const Ok(null),
          deleteAccountResult: const Err(AuthFailure.network()),
        );
        final container = makeContainer(repo);
        addTearDown(container.dispose);

        final controller = container.read(
          deleteAccountControllerProvider.notifier,
        );
        final outcome = await controller.run(
          creds: const AuthCredentials.password(
            email: 'a@b.com',
            password: 'pw',
          ),
        );

        expect(outcome, isA<DeleteAccountErrored>());
        expect(
          (outcome as DeleteAccountErrored).reason,
          DeleteAccountErrorReason.network,
        );
        // The user stays signed in for retry; the CF is idempotent
        // per ADR-0009 so a re-run will finish whatever the first
        // run started.
        expect(repo.signOutCalls, equals(0));
      },
    );

    test('unknown error class falls through to Errored(unknown)', () async {
      final repo = FakeAuthRepository(
        reauthenticateResult: const Err(AuthFailure.unknown('boom')),
      );
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final controller = container.read(
        deleteAccountControllerProvider.notifier,
      );
      final outcome = await controller.run(
        creds: const AuthCredentials.password(email: 'a@b.com', password: 'pw'),
      );

      expect(outcome, isA<DeleteAccountErrored>());
      expect(
        (outcome as DeleteAccountErrored).reason,
        DeleteAccountErrorReason.unknown,
      );
    });

    test('reset() returns to Idle so a future re-entry starts clean', () async {
      final repo = FakeAuthRepository(
        reauthenticateResult: const Err(AuthFailure.network()),
      );
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final controller = container.read(
        deleteAccountControllerProvider.notifier,
      );
      await controller.run(
        creds: const AuthCredentials.password(email: 'a@b.com', password: 'pw'),
      );
      expect(
        container.read(deleteAccountControllerProvider),
        isA<DeleteAccountErrored>(),
      );

      controller.reset();
      expect(
        container.read(deleteAccountControllerProvider),
        isA<DeleteAccountIdle>(),
      );
    });

    test('concurrent run() while already Running is a no-op', () async {
      final repo = FakeAuthRepository(
        reauthenticateResult: const Ok(null),
        deleteAccountResult: const Ok(null),
        signOutResult: const Ok(null),
      );
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final controller = container.read(
        deleteAccountControllerProvider.notifier,
      );

      // Fire two runs back-to-back without awaiting the first. The
      // second should observe `Running` and bail without invoking the
      // use case a second time.
      final first = controller.run(
        creds: const AuthCredentials.password(email: 'a@b.com', password: 'pw'),
      );
      final second = controller.run(
        creds: const AuthCredentials.password(email: 'a@b.com', password: 'pw'),
      );
      await Future.wait([first, second]);

      // Use case ran once: reauth + deleteAccount + signOut all
      // executed exactly once, regardless of the second invocation.
      expect(repo.reauthenticateCalls, hasLength(1));
      expect(repo.deleteAccountCalls, equals(1));
      expect(repo.signOutCalls, equals(1));
    });
  });
}
