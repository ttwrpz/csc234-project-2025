import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/usecases/watch_auth_state.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('WatchAuthStateUseCase', () {
    test('emits an AppUser then null per the fake stream sequence', () async {
      final repo = FakeAuthRepository();
      final usecase = WatchAuthStateUseCase(repo);
      final emissions = <AppUser?>[];
      await usecase().forEach(emissions.add);
      expect(emissions, hasLength(2));
      expect(emissions.first, isNotNull);
      expect(emissions.last, isNull);
    });
  });
}
