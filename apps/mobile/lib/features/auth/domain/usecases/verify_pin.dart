import 'package:core/core.dart';

import '../entities/pin.dart';
import '../entities/pin_verify_failure.dart';
import '../repositories/pin_repository.dart';

/// Verifies a user-entered PIN against the stored hash via the
/// repository (ADR-0013 Decision E §4).
///
/// The use case owns input shape validation so the controller can
/// forward raw `String` from the keypad without leaking that contract
/// into the data layer.
class VerifyPinUseCase {
  const VerifyPinUseCase(this._repository);

  final PinRepository _repository;

  Future<Result<void, PinVerifyFailure>> call({
    required String userId,
    required String pinDigits,
  }) async {
    final pin = Pin.tryFrom(pinDigits);
    if (pin == null) return const Err(PinVerifyFailure.invalidFormat());
    return _repository.verify(userId: userId, pin: pin);
  }
}
