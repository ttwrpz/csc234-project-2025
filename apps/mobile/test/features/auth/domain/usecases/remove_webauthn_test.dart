import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_remove_failure.dart';
import 'package:moodbloom/features/auth/domain/usecases/remove_webauthn.dart';

import '../fakes/fake_webauthn_repository.dart';

void main() {
  group('RemoveWebauthnUseCase', () {
    test('delegates to repository.removeCredential with the uid', () async {
      final repo = FakeWebauthnRepository();
      final useCase = RemoveWebauthnUseCase(repo);

      final result = await useCase(userId: 'u-9');

      expect(result, isA<Ok<void, WebauthnRemoveFailure>>());
      expect(repo.removeCalls, ['u-9']);
    });

    test('propagates a failure from the repository unchanged', () async {
      final repo = FakeWebauthnRepository()
        ..removeResult = const Err(WebauthnRemoveFailure.network());
      final useCase = RemoveWebauthnUseCase(repo);

      final result = await useCase(userId: 'u-1');

      expect(result, isA<Err<void, WebauthnRemoveFailure>>());
      expect(repo.removeCalls, ['u-1']);
    });
  });
}
