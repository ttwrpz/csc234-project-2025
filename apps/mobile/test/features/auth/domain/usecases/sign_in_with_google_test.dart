import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/usecases/sign_in_with_google.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('SignInWithGoogleUseCase', () {
    late FakeAuthRepository repo;
    late SignInWithGoogleUseCase usecase;

    setUp(() {
      repo = FakeAuthRepository();
      usecase = SignInWithGoogleUseCase(repo);
    });

    test('returns Ok on success', () async {
      const user = AppUser(uid: 'g-1', email: 'g@example.com');
      repo.googleResult = const Ok(user);
      final result = await usecase();
      expect(result, isA<Ok<AppUser, AuthFailure>>());
      expect(repo.googleCalls, 1);
    });

    test('returns googleCancelled when user dismisses picker', () async {
      repo.googleResult = const Err(AuthFailure.googleCancelled());
      final result = await usecase();
      expect(result, isA<Err<AppUser, AuthFailure>>());
    });

    test('returns network on connectivity failure', () async {
      repo.googleResult = const Err(AuthFailure.network());
      final result = await usecase();
      expect(result, isA<Err<AppUser, AuthFailure>>());
    });
  });
}
