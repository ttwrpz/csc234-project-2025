import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../app/providers.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/biometric_capability.dart';
import '../domain/repositories/biometric_repository.dart';
import '../domain/usecases/authenticate_with_biometric.dart';
import '../domain/usecases/check_biometric_capability.dart';
import '../domain/usecases/delete_account.dart';
import '../domain/usecases/register_with_email.dart';
import '../domain/usecases/set_biometric_opt_in.dart';
import '../domain/usecases/sign_in_with_email.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/watch_auth_state.dart';
import 'auth_repository_impl.dart';
import 'datasources/biometric_datasource.dart';
import 'datasources/biometric_preference_datasource.dart';
import 'datasources/firebase_auth_datasource.dart';
import 'repositories/biometric_repository_impl.dart';

final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource(auth: ref.watch(firebaseAuthProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    datasource: ref.watch(firebaseAuthDatasourceProvider),
    functions: ref.watch(firebaseFunctionsProvider),
  );
});

/// Reactive auth-state stream consumed by the router. Emits the current
/// [AppUser] or `null` when signed out.
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

// Use case providers — domain classes themselves are pure Dart; only the
// providers (which need flutter_riverpod) live here.

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final registerWithEmailUseCaseProvider = Provider<RegisterWithEmailUseCase>((
  ref,
) {
  return RegisterWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((
  ref,
) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final watchAuthStateUseCaseProvider = Provider<WatchAuthStateUseCase>((ref) {
  return WatchAuthStateUseCase(ref.watch(authRepositoryProvider));
});

/// Account-deletion orchestration use case (HB-004 step 1 + step 3).
/// Composes reauth → CF → signOut. Settings consumes this via
/// `deleteAccountControllerProvider`.
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(authRepositoryProvider));
});

// ────────────────────────────────────────────────────────────────────────
// Biometric (WBS 2.2)

final biometricDatasourceProvider = Provider<BiometricDatasource>((ref) {
  return BiometricDatasource();
});

/// Reads the async [sharedPreferencesProvider] and exposes a synchronous
/// preference datasource. Throws if read before SharedPreferences is ready —
/// callers should consume [biometricRepositoryProvider] via
/// [biometricCapabilityProvider] which is already a `FutureProvider`.
final biometricPreferenceDatasourceProvider =
    Provider<BiometricPreferenceDatasource>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider).requireValue;
      return BiometricPreferenceDatasource(prefs);
    });

final biometricRepositoryProvider = Provider<BiometricRepository>((ref) {
  return BiometricRepositoryImpl(
    datasource: ref.watch(biometricDatasourceProvider),
    preference: ref.watch(biometricPreferenceDatasourceProvider),
  );
});

final checkBiometricCapabilityUseCaseProvider =
    Provider<CheckBiometricCapabilityUseCase>((ref) {
      return CheckBiometricCapabilityUseCase(
        ref.watch(biometricRepositoryProvider),
      );
    });

final authenticateWithBiometricUseCaseProvider =
    Provider<AuthenticateWithBiometricUseCase>((ref) {
      return AuthenticateWithBiometricUseCase(
        ref.watch(biometricRepositoryProvider),
      );
    });

final setBiometricOptInUseCaseProvider = Provider<SetBiometricOptInUseCase>((
  ref,
) {
  return SetBiometricOptInUseCase(ref.watch(biometricRepositoryProvider));
});

/// Async snapshot of biometric capability + opt-in. Refresh by calling
/// `ref.invalidate(biometricCapabilityProvider)` after the toggle changes.
final biometricCapabilityProvider = FutureProvider<BiometricCapability>((ref) {
  return ref.watch(checkBiometricCapabilityUseCaseProvider)();
});

/// Session-scoped flag flipped to `true` after a successful biometric unlock.
/// Used by the router to avoid re-prompting on every redirect tick within
/// the same app session. Reset to `false` on sign-out so a future re-sign-in
/// re-prompts (correct security behaviour).
///
/// Riverpod 3 retired `StateProvider` from the public API. We import it
/// from `legacy.dart` to keep the trivially-ergonomic toggle without
/// expanding the surface area to a full `Notifier` class for one bool.
final biometricUnlockedThisSessionProvider = StateProvider<bool>((_) => false);
