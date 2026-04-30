import 'package:core/core.dart';

import '../auth_failure.dart';
import '../auth_repository.dart';
import '../entities/app_user.dart';

/// Signs in via the Google OAuth flow. The repository is responsible for
/// platform branching (native picker on Android, popup on Web) and for
/// surfacing [AuthFailure.googleCancelled] / [AuthFailure.googleConfigMissing]
/// cleanly so the UI can hide the button on misconfigured Web builds.
class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser, AuthFailure>> call() {
    return _repository.signInWithGoogle();
  }
}
