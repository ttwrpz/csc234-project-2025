import 'package:core/core.dart';

import 'auth_credentials.dart';
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

  /// Sends a Firebase password-reset email to [email]. Implementations
  /// map `FirebaseAuthException` codes to sealed [AuthFailure] variants.
  /// Newer Firebase Auth versions silently succeed on unknown emails for
  /// privacy, so callers treat a successful return as "request accepted"
  /// rather than "an email was definitely delivered."
  Future<Result<void, AuthFailure>> sendPasswordResetEmail(String email);

  /// Reauthenticates the currently signed-in user against [creds]. Required
  /// by Firebase Auth before `currentUser.delete()` will accept the
  /// operation — see HB-004 + ADR-0009 for the recent-login window
  /// rationale. On success the authenticated session has a fresh
  /// sign-in timestamp.
  ///
  /// Returns `AuthFailure.wrongPassword()` for password mismatches,
  /// `AuthFailure.network()` for transport failures, and
  /// `AuthFailure.unknown(cause)` for everything else. Implementations
  /// must NOT throw — every Firebase error code maps to a sealed
  /// variant before crossing the data/domain boundary.
  Future<Result<void, AuthFailure>> reauthenticate(AuthCredentials creds);

  /// Calls the admin-SDK Cloud Function that cascades the user's
  /// Firestore + Storage data per ADR-0009. **Does not** touch the
  /// local Firebase Auth user — that's owned by [deleteCurrentUser],
  /// which the use case calls right after. Idempotent: a re-run on a
  /// uid whose data is already gone returns `Ok(null)` because the CF
  /// returns `{ ok: true, alreadyDeleted: true }`.
  ///
  /// Reauth must precede this call — the use case orchestrates that
  /// sequencing via [DeleteAccountUseCase].
  Future<Result<void, AuthFailure>> deleteAccount();

  /// Updates the locally-signed-in user's display name in Firebase Auth.
  /// The change is propagated to `fb.User.displayName` and the next
  /// `watchAuthState` emission carries the new value. Returns
  /// `AuthFailure.userNotFound()` when no one is signed in.
  ///
  /// Email/password sign-up does NOT capture a display name (Firebase
  /// only stores email + password on createUserWithEmailAndPassword), so
  /// new accounts land with a null displayName until the user sets one
  /// here.
  Future<Result<void, AuthFailure>> updateDisplayName(String name);

  /// Deletes the locally-signed-in Firebase Auth user via
  /// `currentUser.delete()`. Called by [DeleteAccountUseCase] AFTER the
  /// server cascade has run, so the data is already gone by the time
  /// this method executes.
  ///
  /// Returns:
  ///   - `Ok(null)` when the auth user is gone (or was already gone).
  ///   - `Err(AuthFailure.requiresRecentLogin())` when Firebase Auth's
  ///     recent-login window has expired. The caller proceeds to
  ///     signOut anyway per ADR-0009 §"Good" point 5 — the local
  ///     session is the only thing the window guards against, and
  ///     the server data is already gone.
  ///   - `Err(AuthFailure.unknown(cause))` for any other failure.
  ///
  /// Implementations must NOT throw; every Firebase error must map to
  /// a sealed variant before crossing the data/domain boundary.
  Future<Result<void, AuthFailure>> deleteCurrentUser();
}
