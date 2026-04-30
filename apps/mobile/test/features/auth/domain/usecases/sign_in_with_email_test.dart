import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/usecases/sign_in_with_email.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('SignInWithEmailUseCase', () {
    late FakeAuthRepository repo;
    late SignInWithEmailUseCase usecase;

    setUp(() {
      repo = FakeAuthRepository();
      usecase = SignInWithEmailUseCase(repo);
    });

    test(
      'returns invalidEmail without calling repo when email is malformed',
      () async {
        final result = await usecase(
          email: 'not-an-email',
          password: 'longenoughpw',
        );
        expect(result, isA<Err<AppUser, AuthFailure>>());
        expect((result as Err).failure, isA<AuthFailure>());
        expect(repo.signInCalls, isEmpty);
      },
    );

    test(
      'returns weakPassword without calling repo when password < 8 chars',
      () async {
        final result = await usecase(
          email: 'user@example.com',
          password: 'short',
        );
        expect(result, isA<Err<AppUser, AuthFailure>>());
        expect(repo.signInCalls, isEmpty);
      },
    );

    test('forwards to repo on valid input and returns Ok on success', () async {
      const user = AppUser(uid: 'u-1', email: 'user@example.com');
      repo.signInResult = const Ok(user);
      final result = await usecase(
        email: 'user@example.com',
        password: 'longenoughpw',
      );
      expect(result, isA<Ok<AppUser, AuthFailure>>());
      expect(repo.signInCalls.single.email, 'user@example.com');
    });

    test('trims email before forwarding to repo', () async {
      const user = AppUser(uid: 'u-1', email: 'user@example.com');
      repo.signInResult = const Ok(user);
      await usecase(email: '  user@example.com  ', password: 'longenoughpw');
      expect(repo.signInCalls.single.email, 'user@example.com');
    });

    test('passes through repo failure on network error', () async {
      repo.signInResult = const Err(AuthFailure.network());
      final result = await usecase(
        email: 'user@example.com',
        password: 'longenoughpw',
      );
      expect(result, isA<Err<AppUser, AuthFailure>>());
    });
  });
}
