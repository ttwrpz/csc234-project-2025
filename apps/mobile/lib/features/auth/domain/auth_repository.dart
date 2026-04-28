import 'package:core/core.dart';

import 'auth_failure.dart';
import 'entities/app_user.dart';

/// Contract for any backing store that authenticates users.
///
/// Implementations live in `data/`; they may use Firebase Auth, an emulator,
/// or a fake. UserProfile upsert at `users/{uid}` is **not** part of S2 — it
/// lands in HB-002.
abstract class AuthRepository {
  /// Streams the currently signed-in user, or `null` when signed out. The
  /// router subscribes to this to redirect on auth-state changes.
  Stream<AppUser?> watchAuthState();

  /// Synchronous current user snapshot. May be stale; prefer
  /// [watchAuthState] for reactive UI.
  AppUser? get currentUser;

  /// Signs in with email and password. Domain-side validation is performed
  /// by the use case before this is invoked; implementations still map
  /// Firebase error codes to [AuthFailure] variants.
  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new account with email and password.
  Future<Result<AppUser, AuthFailure>> registerWithEmail({
    required String email,
    required String password,
  });

  /// Launches the Google OAuth flow. Returns
  /// [AuthFailure.googleCancelled] when the user dismisses the picker, and
  /// [AuthFailure.googleConfigMissing] on Web builds where the OAuth client
  /// ID is not configured.
  Future<Result<AppUser, AuthFailure>> signInWithGoogle();

  /// Signs out of any currently authenticated session.
  Future<Result<void, AuthFailure>> signOut();
}
