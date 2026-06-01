import 'package:core/core.dart';

import '../entities/pin.dart';
import '../entities/pin_setup_failure.dart';
import '../entities/pin_verify_failure.dart';
import '../repositories/pin_repository.dart';

/// Replaces an existing PIN. Asks for the current PIN first (defence
/// against a hostile bystander grabbing an unlocked phone and just
/// rotating to lock the owner out), then performs the same two-pass
/// shape check as [SetupPinUseCase] before persisting the new hash.
///
/// Failure semantics:
///   - Current PIN wrong → returns the [PinVerifyFailure] from the
///     verify step so the UI can keep its keypad on the same screen
///     and surface remaining-attempts (rate-limit doc was bumped).
///   - New PIN mismatch / bad format → returns the [PinSetupFailure]
///     so the UI clears and re-asks.
///   - Storage error on the replace → returns
///     [PinSetupFailure.storage].
///
/// The two `Result` types are NOT unified into a single sealed type -
/// callers care about the distinction because the affordances differ
/// (current-pin wrong gets a rate-limit countdown; new-pin mismatch
/// just clears the keypad).
class ChangePinUseCase {
  const ChangePinUseCase(this._repository);

  final PinRepository _repository;

  Future<ChangePinResult> call({
    required String userId,
    required String currentPin,
    required String newPinFirstEntry,
    required String newPinConfirmEntry,
  }) async {
    final current = Pin.tryFrom(currentPin);
    if (current == null) {
      return const ChangePinResult.verifyFailure(
        PinVerifyFailure.invalidFormat(),
      );
    }
    final verify = await _repository.verify(userId: userId, pin: current);
    if (verify is Err<void, PinVerifyFailure>) {
      return ChangePinResult.verifyFailure(verify.failure);
    }
    final first = Pin.tryFrom(newPinFirstEntry);
    final confirm = Pin.tryFrom(newPinConfirmEntry);
    if (first == null || confirm == null) {
      return const ChangePinResult.setupFailure(
        PinSetupFailure.invalidFormat(),
      );
    }
    if (first.digits != confirm.digits) {
      return const ChangePinResult.setupFailure(PinSetupFailure.mismatch());
    }
    final setup = await _repository.setup(userId: userId, pin: first);
    if (setup is Err<void, PinSetupFailure>) {
      return ChangePinResult.setupFailure(setup.failure);
    }
    return const ChangePinResult.ok();
  }
}

/// Discriminated outcome of a [ChangePinUseCase] call.
///
/// Sealed so consumers (the Change PIN screen) get exhaustive pattern
/// matching for the three terminal states.
sealed class ChangePinResult {
  const ChangePinResult();

  const factory ChangePinResult.ok() = ChangePinOk;
  const factory ChangePinResult.verifyFailure(PinVerifyFailure failure) =
      ChangePinVerifyFailure;
  const factory ChangePinResult.setupFailure(PinSetupFailure failure) =
      ChangePinSetupFailure;
}

final class ChangePinOk extends ChangePinResult {
  const ChangePinOk();
}

final class ChangePinVerifyFailure extends ChangePinResult {
  const ChangePinVerifyFailure(this.failure);
  final PinVerifyFailure failure;
}

final class ChangePinSetupFailure extends ChangePinResult {
  const ChangePinSetupFailure(this.failure);
  final PinSetupFailure failure;
}
