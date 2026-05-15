import 'package:core/core.dart';

import '../entities/pin.dart';
import '../entities/pin_setup_failure.dart';
import '../repositories/pin_repository.dart';

/// First-time setup: validate the two-pass entry matches, then derive
/// and persist the hash via the repository (ADR-0013 Decision G-2).
///
/// The two-pass check lives in the use case rather than the screen so
/// it is unit-testable end-to-end and so the screen can stay a pure
/// stateless keypad. The screen submits `(first, confirm)` and we
/// return the right failure variant.
class SetupPinUseCase {
  const SetupPinUseCase(this._repository);

  final PinRepository _repository;

  Future<Result<void, PinSetupFailure>> call({
    required String userId,
    required String firstEntry,
    required String confirmEntry,
  }) async {
    final first = Pin.tryFrom(firstEntry);
    final confirm = Pin.tryFrom(confirmEntry);
    if (first == null || confirm == null) {
      return const Err(PinSetupFailure.invalidFormat());
    }
    if (first.digits != confirm.digits) {
      return const Err(PinSetupFailure.mismatch());
    }
    return _repository.setup(userId: userId, pin: first);
  }
}
