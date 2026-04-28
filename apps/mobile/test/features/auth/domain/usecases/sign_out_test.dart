import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/usecases/sign_out.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('SignOutUseCase', () {
    late FakeAuthRepository repo;
    late SignOutUseCase usecase;

    setUp(() {
      repo = FakeAuthRepository();
      usecase = SignOutUseCase(repo);
    });

    test('returns Ok on success and increments call count', () async {
      repo.signOutResult = const Ok(null);
      final result = await usecase();
      expect(result, isA<Ok<void, AuthFailure>>());
      expect(repo.signOutCalls, 1);
    });

    test('passes through repo failure', () async {
      repo.signOutResult = const Err(AuthFailure.unknown(null));
      final result = await usecase();
      expect(result, isA<Err<void, AuthFailure>>());
    });
  });
}
