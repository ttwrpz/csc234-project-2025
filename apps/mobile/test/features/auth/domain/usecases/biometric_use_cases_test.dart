import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/auth/domain/usecases/authenticate_with_biometric.dart';
import 'package:moodbloom/features/auth/domain/usecases/check_biometric_capability.dart';
import 'package:moodbloom/features/auth/domain/usecases/set_biometric_opt_in.dart';

import '../fakes/fake_biometric_repository.dart';

void main() {
  group('AuthenticateWithBiometricUseCase', () {
    test('repository returns true → Ok(null)', () async {
      final repo = FakeBiometricRepository(nextAuthenticateResult: true);
      final useCase = AuthenticateWithBiometricUseCase(repo);
      final result = await useCase(reason: 'unlock');
      expect(result, isA<Ok<void, AuthFailure>>());
      expect(repo.lastAuthenticateReason, 'unlock');
    });

    test('repository returns false → Err(biometricCancelled)', () async {
      final repo = FakeBiometricRepository(nextAuthenticateResult: false);
      final useCase = AuthenticateWithBiometricUseCase(repo);
      final result = await useCase(reason: 'unlock');
      final err = result as Err<void, AuthFailure>;
      expect(err.failure.runtimeType.toString(), contains('Cancel'));
    });

    test('repository throws → Err(biometricFailed) with runtimeType only',
        () async {
      final repo = FakeBiometricRepository(
        authenticateThrows: StateError('hardware'),
      );
      final useCase = AuthenticateWithBiometricUseCase(repo);
      final result = await useCase(reason: 'unlock');
      final err = result as Err<void, AuthFailure>;
      expect(err.failure.runtimeType.toString(), contains('Failed'));
    });
  });

  group('CheckBiometricCapabilityUseCase', () {
    test('forwards to the repository', () async {
      final repo = FakeBiometricRepository(
        nextCapability: const BiometricCapability(
          isAvailable: true,
          hasEnrolledBiometrics: true,
          userOptedIn: true,
        ),
      );
      final useCase = CheckBiometricCapabilityUseCase(repo);
      final result = await useCase();
      expect(result.shouldGate, isTrue);
    });
  });

  group('SetBiometricOptInUseCase', () {
    test('records the opt-in', () async {
      final repo = FakeBiometricRepository();
      final useCase = SetBiometricOptInUseCase(repo);
      await useCase(true);
      expect(repo.setOptInCalls, [true]);
    });

    test('records opt-out', () async {
      final repo = FakeBiometricRepository();
      final useCase = SetBiometricOptInUseCase(repo);
      await useCase(false);
      expect(repo.setOptInCalls, [false]);
    });
  });
}
