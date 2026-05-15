import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/entities/pin_setup_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/pin_verify_failure.dart';
import 'package:moodbloom/features/auth/domain/usecases/change_pin.dart';
import 'package:moodbloom/features/auth/domain/usecases/remove_pin.dart';
import 'package:moodbloom/features/auth/domain/usecases/setup_pin.dart';
import 'package:moodbloom/features/auth/domain/usecases/verify_pin.dart';

import '../fakes/fake_pin_repository.dart';

const _uid = 'u1';

void main() {
  group('SetupPinUseCase', () {
    test('two-pass match writes the PIN and returns Ok', () async {
      final repo = FakePinRepository(pinIsSet: false);
      final useCase = SetupPinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        firstEntry: '123456',
        confirmEntry: '123456',
      );
      expect(result, isA<Ok<void, PinSetupFailure>>());
      expect(repo.setupCalls, hasLength(1));
      expect(repo.setupCalls.first.digits, '123456');
    });

    test('mismatch surfaces PinSetupFailure.mismatch without storage', () async {
      final repo = FakePinRepository(pinIsSet: false);
      final useCase = SetupPinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        firstEntry: '123456',
        confirmEntry: '654321',
      );
      final err = result as Err<void, PinSetupFailure>;
      expect(err.failure.isMismatch, isTrue);
      expect(repo.setupCalls, isEmpty);
    });

    test('non-6-digit input surfaces invalidFormat', () async {
      final repo = FakePinRepository(pinIsSet: false);
      final useCase = SetupPinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        firstEntry: '12345',
        confirmEntry: '12345',
      );
      final err = result as Err<void, PinSetupFailure>;
      expect(err.failure.isMismatch, isFalse);
      expect(err.failure.message, contains('6 digits'));
      expect(repo.setupCalls, isEmpty);
    });

    test('non-numeric input surfaces invalidFormat', () async {
      final repo = FakePinRepository(pinIsSet: false);
      final useCase = SetupPinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        firstEntry: 'abcdef',
        confirmEntry: 'abcdef',
      );
      expect(result, isA<Err<void, PinSetupFailure>>());
      expect(repo.setupCalls, isEmpty);
    });

    test('passes storage failure through unchanged', () async {
      final repo = FakePinRepository(
        pinIsSet: false,
        nextSetupResult: const Err(PinSetupFailure.storage()),
      );
      final useCase = SetupPinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        firstEntry: '123456',
        confirmEntry: '123456',
      );
      final err = result as Err<void, PinSetupFailure>;
      expect(err.failure.message, contains('connection'));
    });
  });

  group('VerifyPinUseCase', () {
    test('correct PIN returns Ok', () async {
      final repo = FakePinRepository(correctPin: '111111');
      final useCase = VerifyPinUseCase(repo);
      final result = await useCase(userId: _uid, pinDigits: '111111');
      expect(result, isA<Ok<void, PinVerifyFailure>>());
    });

    test('wrong PIN surfaces wrong failure with remaining attempts', () async {
      final repo = FakePinRepository(correctPin: '111111');
      final useCase = VerifyPinUseCase(repo);
      final result = await useCase(userId: _uid, pinDigits: '222222');
      expect(result, isA<Err<void, PinVerifyFailure>>());
    });

    test('non-6-digit input surfaces invalidFormat without calling repo',
        () async {
      final repo = FakePinRepository();
      final useCase = VerifyPinUseCase(repo);
      final result = await useCase(userId: _uid, pinDigits: '12345');
      expect(result, isA<Err<void, PinVerifyFailure>>());
      expect(repo.verifyCalls, isEmpty);
    });

    test('locked failure carries the until timestamp through the getter',
        () async {
      final until = DateTime.utc(2026, 5, 14, 12, 0);
      final repo = FakePinRepository(
        nextVerifyResult: Err(PinVerifyFailure.locked(until: until)),
      );
      final useCase = VerifyPinUseCase(repo);
      final result = await useCase(userId: _uid, pinDigits: '123456');
      final err = result as Err<void, PinVerifyFailure>;
      expect(err.failure.lockedUntil, equals(until));
    });
  });

  group('ChangePinUseCase', () {
    test('wrong current PIN halts before re-derive', () async {
      final repo = FakePinRepository(correctPin: '111111');
      final useCase = ChangePinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        currentPin: '222222',
        newPinFirstEntry: '333333',
        newPinConfirmEntry: '333333',
      );
      expect(result, isA<ChangePinVerifyFailure>());
      expect(repo.setupCalls, isEmpty);
    });

    test('new-PIN mismatch surfaces setupFailure.mismatch', () async {
      final repo = FakePinRepository(correctPin: '111111');
      final useCase = ChangePinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        currentPin: '111111',
        newPinFirstEntry: '222222',
        newPinConfirmEntry: '333333',
      );
      final err = result as ChangePinSetupFailure;
      expect(err.failure.isMismatch, isTrue);
      expect(repo.setupCalls, isEmpty);
    });

    test('happy path writes the new PIN', () async {
      final repo = FakePinRepository(correctPin: '111111');
      final useCase = ChangePinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        currentPin: '111111',
        newPinFirstEntry: '222222',
        newPinConfirmEntry: '222222',
      );
      expect(result, isA<ChangePinOk>());
      expect(repo.setupCalls, hasLength(1));
      expect(repo.setupCalls.first.digits, '222222');
    });

    test('invalid current-PIN format surfaces verifyFailure.invalidFormat',
        () async {
      final repo = FakePinRepository();
      final useCase = ChangePinUseCase(repo);
      final result = await useCase(
        userId: _uid,
        currentPin: '12345',
        newPinFirstEntry: '222222',
        newPinConfirmEntry: '222222',
      );
      expect(result, isA<ChangePinVerifyFailure>());
      expect(repo.verifyCalls, isEmpty);
    });
  });

  group('RemovePinUseCase', () {
    test('forwards to repository.remove', () async {
      final repo = FakePinRepository();
      final useCase = RemovePinUseCase(repo);
      await useCase(userId: _uid);
      expect(repo.removeCalls, [_uid]);
    });

    test('passes failure through unchanged', () async {
      final repo = FakePinRepository(
        nextRemoveResult: const Err(PinSetupFailure.storage()),
      );
      final useCase = RemovePinUseCase(repo);
      final result = await useCase(userId: _uid);
      expect(result, isA<Err<void, PinSetupFailure>>());
    });
  });
}
