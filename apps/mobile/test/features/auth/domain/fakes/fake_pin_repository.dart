import 'package:core/core.dart';
import 'package:moodbloom/features/auth/domain/entities/pin.dart';
import 'package:moodbloom/features/auth/domain/entities/pin_hash.dart';
import 'package:moodbloom/features/auth/domain/entities/pin_setup_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/pin_verify_failure.dart';
import 'package:moodbloom/features/auth/domain/repositories/pin_repository.dart';

/// Hand-rolled fake for [PinRepository] — mirrors the
/// `FakeBiometricRepository` style used elsewhere in the auth tests.
///
/// Holds an in-memory `Pin → bool` matcher: `verify(pin)` succeeds iff
/// the supplied PIN matches the stored "correct" PIN (defaults to
/// "123456"). The use cases under test exercise the orchestration
/// logic, not the cryptographic correctness — that's the data layer's
/// concern.
class FakePinRepository implements PinRepository {
  FakePinRepository({
    this.correctPin = '123456',
    this.pinIsSet = true,
    this.nextSetupResult = const Ok<void, PinSetupFailure>(null),
    this.nextVerifyResult,
    this.nextRemoveResult = const Ok<void, PinSetupFailure>(null),
  });

  String correctPin;
  bool pinIsSet;
  Result<void, PinSetupFailure> nextSetupResult;

  /// When null, `verify` resolves dynamically against [correctPin].
  /// When non-null, that fixed result is returned (used for the
  /// rate-limit scenarios).
  Result<void, PinVerifyFailure>? nextVerifyResult;
  Result<void, PinSetupFailure> nextRemoveResult;

  final List<Pin> setupCalls = [];
  final List<Pin> verifyCalls = [];
  final List<String> removeCalls = [];

  @override
  Future<PinHash?> read({required String userId}) async {
    if (!pinIsSet) return null;
    return PinHash(
      algorithm: 'pbkdf2-sha256',
      iterations: 100000,
      saltBase64: 'AAAA',
      hashBase64: 'BBBB',
      createdAt: DateTime.utc(2026, 5, 14),
    );
  }

  @override
  Future<Result<void, PinSetupFailure>> setup({
    required String userId,
    required Pin pin,
  }) async {
    setupCalls.add(pin);
    if (nextSetupResult is Ok<void, PinSetupFailure>) {
      correctPin = pin.digits;
      pinIsSet = true;
    }
    return nextSetupResult;
  }

  @override
  Future<Result<void, PinVerifyFailure>> verify({
    required String userId,
    required Pin pin,
  }) async {
    verifyCalls.add(pin);
    if (nextVerifyResult != null) return nextVerifyResult!;
    if (pin.digits == correctPin) return const Ok(null);
    return const Err(PinVerifyFailure.wrong(remainingAttempts: 4));
  }

  @override
  Future<Result<void, PinSetupFailure>> remove({
    required String userId,
  }) async {
    removeCalls.add(userId);
    if (nextRemoveResult is Ok<void, PinSetupFailure>) {
      pinIsSet = false;
    }
    return nextRemoveResult;
  }
}
