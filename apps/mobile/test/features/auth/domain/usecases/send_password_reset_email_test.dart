import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/usecases/send_password_reset_email.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('SendPasswordResetEmailUseCase', () {
    late FakeAuthRepository repo;
    late SendPasswordResetEmailUseCase usecase;

    setUp(() {
      repo = FakeAuthRepository();
      usecase = SendPasswordResetEmailUseCase(repo);
    });

    test('rejects empty input without calling the repo', () async {
      final result = await usecase('');
      expect(result, isA<Err<void, AuthFailure>>());
      expect(repo.sendPasswordResetEmailCalls, isEmpty);
    });

    test('rejects whitespace-only input without calling the repo', () async {
      final result = await usecase('   ');
      expect(result, isA<Err<void, AuthFailure>>());
      expect(repo.sendPasswordResetEmailCalls, isEmpty);
    });

    test('rejects malformed email without calling the repo', () async {
      final result = await usecase('not-an-email');
      expect(result, isA<Err<void, AuthFailure>>());
      expect(repo.sendPasswordResetEmailCalls, isEmpty);
    });

    test('trims the email before forwarding to the repo', () async {
      repo.sendPasswordResetEmailResult = const Ok(null);
      await usecase('  user@example.com  ');
      expect(repo.sendPasswordResetEmailCalls.single, 'user@example.com');
    });

    test('returns Ok on repo success', () async {
      repo.sendPasswordResetEmailResult = const Ok(null);
      final result = await usecase('user@example.com');
      expect(result, isA<Ok<void, AuthFailure>>());
    });

    test('passes through network failures from the repo', () async {
      repo.sendPasswordResetEmailResult = const Err(AuthFailure.network());
      final result = await usecase('user@example.com');
      expect(result, isA<Err<void, AuthFailure>>());
    });
  });
}
