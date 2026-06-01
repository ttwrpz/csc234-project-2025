import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_verify_failure.dart';
import 'package:moodbloom/features/auth/domain/usecases/sign_in_with_webauthn.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_webauthn_repository.dart';

void main() {
  group('SignInWithWebauthnUseCase', () {
    test('Ok ceremony → exchanges token → Ok(null)', () async {
      final webauthn = FakeWebauthnRepository()
        ..loginResult = const Ok('minted-token');
      final auth = FakeAuthRepository(
        customTokenResult: const Ok(
          AppUser(uid: 'u-1', email: 'user@example.com'),
        ),
      );
      final useCase = SignInWithWebauthnUseCase(webauthn: webauthn, auth: auth);

      final result = await useCase();

      expect(result, isA<Ok<void, WebauthnVerifyFailure>>());
      expect(webauthn.loginCalls, 1);
      expect(auth.customTokenCalls, ['minted-token']);
    });

    test(
      'ceremony failure → propagates the verify failure, no exchange',
      () async {
        final webauthn = FakeWebauthnRepository()
          ..loginResult = const Err(WebauthnVerifyFailure.userCanceled());
        final auth = FakeAuthRepository();
        final useCase = SignInWithWebauthnUseCase(
          webauthn: webauthn,
          auth: auth,
        );

        final result = await useCase();

        expect(result, isA<Err<void, WebauthnVerifyFailure>>());
        final failure = (result as Err<void, WebauthnVerifyFailure>).failure;
        expect(failure.isUserCanceled, isTrue);
        expect(auth.customTokenCalls, isEmpty);
      },
    );

    test('token valid but Firebase exchange fails → network failure', () async {
      final webauthn = FakeWebauthnRepository()
        ..loginResult = const Ok('minted-token');
      final auth = FakeAuthRepository(
        customTokenResult: const Err(AuthFailure.network()),
      );
      final useCase = SignInWithWebauthnUseCase(webauthn: webauthn, auth: auth);

      final result = await useCase();

      expect(result, isA<Err<void, WebauthnVerifyFailure>>());
      final failure = (result as Err<void, WebauthnVerifyFailure>).failure;
      expect(failure, isA<WebauthnVerifyFailure>());
      expect(auth.customTokenCalls, ['minted-token']);
    });
  });
}
