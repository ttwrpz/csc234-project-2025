import '../auth_repository.dart';
import '../entities/app_user.dart';

/// Streams the currently signed-in user. The router subscribes to this via a
/// `StreamProvider` in `data/providers.dart` and rebuilds its `redirect` on
/// every emission.
class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.watchAuthState();
}
