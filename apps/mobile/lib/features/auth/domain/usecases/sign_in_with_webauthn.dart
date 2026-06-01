import 'package:core/core.dart';

import '../auth_repository.dart';
import '../entities/webauthn_verify_failure.dart';
import '../repositories/webauthn_repository.dart';

/// Cold-boot sign-in with a security key (ADR-0014).
///
/// Orchestrates the two domain repositories so the presentation layer
/// stays thin:
///   1. [WebauthnRepository.loginWithSecurityKey] runs the usernameless
///      ceremony and returns a Firebase custom token.
///   2. [AuthRepository.signInWithCustomToken] exchanges that token for a
///      real session; the auth-state stream then drives the router
///      redirect to `/home`.
///
/// Returns `Ok(null)` once the session is established. Any ceremony
/// failure surfaces as the matching [WebauthnVerifyFailure]; a token
/// exchange that fails Firebase-side collapses to
/// [WebauthnVerifyFailure.network] (the token was valid but the session
/// couldn't be established - a transient/server condition from the user's
/// perspective).
class SignInWithWebauthnUseCase {
  const SignInWithWebauthnUseCase({
    required WebauthnRepository webauthn,
    required AuthRepository auth,
  }) : _webauthn = webauthn,
       _auth = auth;

  final WebauthnRepository _webauthn;
  final AuthRepository _auth;

  Future<Result<void, WebauthnVerifyFailure>> call() async {
    final tokenResult = await _webauthn.loginWithSecurityKey();
    switch (tokenResult) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final signIn = await _auth.signInWithCustomToken(value);
        return switch (signIn) {
          Ok() => const Ok(null),
          Err() => const Err(WebauthnVerifyFailure.network()),
        };
    }
  }
}
