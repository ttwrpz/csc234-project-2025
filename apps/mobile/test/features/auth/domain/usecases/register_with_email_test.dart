import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/usecases/register_with_email.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('RegisterWithEmailUseCase', () {
    late FakeAuthRepository repo;
    late RegisterWithEmailUseCase usecase;

    setUp(() {
      repo = FakeAuthRepository();
      usecase = RegisterWithEmailUseCase(repo);
    });

    test('rejects malformed email locally', () async {
      final result = await usecase(email: 'bogus', password: 'longenoughpw');
      expect(result, isA<Err<AppUser, AuthFailure>>());
      expect(repo.registerCalls, isEmpty);
    });

    test('rejects weak password locally', () async {
      final result = await usecase(
        email: 'user@example.com',
        password: 'short',
      );
      expect(result, isA<Err<AppUser, AuthFailure>>());
      expect(repo.registerCalls, isEmpty);
    });

    test('forwards to repo on valid input', () async {
      const user = AppUser(uid: 'new-uid', email: 'new@example.com');
      repo.registerResult = const Ok(user);
      final result = await usecase(
        email: 'new@example.com',
        password: 'longenoughpw',
      );
      expect(result, isA<Ok<AppUser, AuthFailure>>());
      expect(repo.registerCalls.single.email, 'new@example.com');
    });

    test('passes through emailAlreadyInUse from repo', () async {
      repo.registerResult = const Err(AuthFailure.emailAlreadyInUse());
      final result = await usecase(
        email: 'used@example.com',
        password: 'longenoughpw',
      );
      expect(result, isA<Err<AppUser, AuthFailure>>());
    });
  });
}
