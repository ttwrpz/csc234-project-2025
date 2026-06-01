import 'package:core/core.dart';

import '../entities/pin_setup_failure.dart';
import '../repositories/pin_repository.dart';

/// Invalidates the user's stored PIN by writing an unrecoverable
/// random hash over the existing doc. Used by the PRIVACY toggle's
/// OFF branch in Settings.
///
/// Does NOT also reset the "user has opted in" SharedPreferences flag -
/// that is the controller's responsibility. The use case is purely
/// the data-side invalidation.
class RemovePinUseCase {
  const RemovePinUseCase(this._repository);

  final PinRepository _repository;

  Future<Result<void, PinSetupFailure>> call({required String userId}) {
    return _repository.remove(userId: userId);
  }
}
