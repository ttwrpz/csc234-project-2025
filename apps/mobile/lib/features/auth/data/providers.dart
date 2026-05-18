import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../app/feature_flags.dart' show kEnableWebauthn;
import '../../../app/providers.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/biometric_capability.dart';
import '../domain/entities/webauthn_credential.dart';
import '../domain/repositories/biometric_repository.dart';
import '../domain/repositories/pin_repository.dart';
import '../domain/repositories/webauthn_repository.dart';
import '../domain/services/pin_hasher.dart';
import '../domain/usecases/authenticate_with_biometric.dart';
import '../domain/usecases/change_pin.dart';
import '../domain/usecases/check_biometric_capability.dart';
import '../domain/usecases/delete_account.dart';
import '../domain/usecases/register_webauthn.dart';
import '../domain/usecases/register_with_email.dart';
import '../domain/usecases/remove_pin.dart';
import '../domain/usecases/set_biometric_opt_in.dart';
import '../domain/usecases/setup_pin.dart';
import '../domain/usecases/send_password_reset_email.dart';
import '../domain/usecases/sign_in_with_email.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/verify_pin.dart';
import '../domain/usecases/verify_webauthn.dart';
import '../domain/usecases/watch_auth_state.dart';
import 'auth_repository_impl.dart';
import 'datasources/biometric_datasource.dart';
import 'datasources/biometric_preference_datasource.dart';
import 'datasources/delete_account_functions_datasource.dart';
import 'datasources/firebase_auth_datasource.dart';
import 'datasources/pin_firestore_datasource.dart';
import 'datasources/privacy_lock_preference_datasource.dart';
import 'datasources/webauthn_browser_datasource.dart';
import 'datasources/webauthn_credential_firestore_datasource.dart';
import 'datasources/webauthn_functions_datasource.dart';
import 'pin_hasher_impl.dart';
import 'pin_repository_impl.dart';
import 'repositories/biometric_repository_impl.dart';
import 'webauthn_repository_impl.dart';

final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource(auth: ref.watch(firebaseAuthProvider));
});

/// Auth-feature-local handle to `FirebaseFunctions` pinned to the same
/// region as the rest of the project's callables (`asia-southeast1`).
/// Defined here rather than reusing `features/mood/data/providers.dart`'s
/// `firebaseFunctionsProvider` because that module already imports from
/// this one — a cross-import would create a cycle. Tests override this
/// provider directly with a fake.
final authFirebaseFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
);

final deleteAccountFunctionsDatasourceProvider =
    Provider<DeleteAccountFunctionsDatasource>(
      (ref) => DeleteAccountFunctionsDatasource(
        ref.watch(authFirebaseFunctionsProvider),
      ),
    );

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    datasource: ref.watch(firebaseAuthDatasourceProvider),
    deleteAccountDatasource: ref.watch(
      deleteAccountFunctionsDatasourceProvider,
    ),
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

final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase>((ref) {
      return SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider));
    });

/// WBS 2.4 — the destructive use case. Composes reauth → server cascade
/// → local Auth delete → signOut in one orchestrated call. Consumed by
/// the Settings screen's delete-account dialog.
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(authRepositoryProvider));
});

final watchAuthStateUseCaseProvider = Provider<WatchAuthStateUseCase>((ref) {
  return WatchAuthStateUseCase(ref.watch(authRepositoryProvider));
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

// ────────────────────────────────────────────────────────────────────────
// PIN fallback factor (ADR-0013)

final pinFirestoreDatasourceProvider = Provider<PinFirestoreDatasource>((ref) {
  return PinFirestoreDatasource(ref.watch(firestoreProvider));
});

final pinHasherProvider = Provider<PinHasher>((ref) => PinHasherImpl());

final pinRepositoryProvider = Provider<PinRepository>((ref) {
  return PinRepositoryImpl(
    firestore: ref.watch(pinFirestoreDatasourceProvider),
    hasher: ref.watch(pinHasherProvider),
  );
});

final setupPinUseCaseProvider = Provider<SetupPinUseCase>((ref) {
  return SetupPinUseCase(ref.watch(pinRepositoryProvider));
});

final verifyPinUseCaseProvider = Provider<VerifyPinUseCase>((ref) {
  return VerifyPinUseCase(ref.watch(pinRepositoryProvider));
});

final changePinUseCaseProvider = Provider<ChangePinUseCase>((ref) {
  return ChangePinUseCase(ref.watch(pinRepositoryProvider));
});

final removePinUseCaseProvider = Provider<RemovePinUseCase>((ref) {
  return RemovePinUseCase(ref.watch(pinRepositoryProvider));
});

/// Reads the user's PIN-set state. Returns `true` when a PIN document
/// exists at `users/{uid}/security/pin`. The Settings PRIVACY card
/// uses this to choose between "Set up PIN" and "Change PIN" tiles.
///
/// `userId` is read from [currentUserStreamProvider]; when signed out,
/// the future resolves to `false` (the PRIVACY card is hidden by
/// upstream conditional anyway — ADR-0013 Open Follow-up #4).
final pinIsSetProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return false;
  final repo = ref.watch(pinRepositoryProvider);
  final hash = await repo.read(userId: user.uid);
  return hash != null;
});

/// SharedPreferences-backed user-opt-in flag for the History privacy
/// gate (ADR-0013 Decision A — default OFF).
final privacyLockPreferenceDatasourceProvider =
    Provider<PrivacyLockPreferenceDatasource>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider).requireValue;
      return PrivacyLockPreferenceDatasource(prefs);
    });

/// Notifier exposing the user's "Require unlock to view history" toggle.
/// The router redirect reads `state.value` synchronously to decide
/// whether to gate `/history`; the Settings tile updates it on flip.
class PrivacyLockEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(privacyLockPreferenceDatasourceProvider).isEnabled();
  }

  /// Persists the new state to SharedPreferences and refreshes the
  /// reactive value. Callers (the Settings switch) should only call
  /// this once the setup flow has actually completed — the toggle is
  /// not the source of truth for "is there a PIN to verify against."
  Future<void> set(bool enabled) async {
    await ref.read(privacyLockPreferenceDatasourceProvider).setEnabled(enabled);
    state = enabled;
  }
}

final privacyLockEnabledProvider =
    NotifierProvider<PrivacyLockEnabledNotifier, bool>(
      PrivacyLockEnabledNotifier.new,
    );

/// Derived from the Remote Config kill-switch. Hidden from the
/// Settings UI and short-circuited by the router redirect when `false`.
/// Separate from [privacyLockEnabledProvider] (the user's per-account
/// opt-in) so the rollback path can be tested independently of any
/// stored preferences. ADR-0013 "Compliance Check" §"feature-flag".
final privacyLockMasterEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    featureFlagsProvider.select((f) => f.historyPrivacyLockEnabled),
  );
});

// ────────────────────────────────────────────────────────────────────────
// WebAuthn fallback factor (ADR-0014) — v1.5 ships DARK behind
// `kEnableWebauthn` (build-time const in `feature_flags.dart`). When the
// flag is `false` (the v1.5 default), every consumer of these providers
// short-circuits to a hidden / no-op state — the JS-interop datasource
// is never instantiated and the Firestore credential stream is never
// subscribed. See ADR-0014 §"Cuts to make first if a day slips" #3.

/// True only when WebAuthn is reachable on the current platform AND the
/// build-time flag enables the surface. v1.5 always returns `false`
/// because `kEnableWebauthn` is `false` — the JS-interop binding is
/// never instantiated. v1.5.1 (or v1.6) flips the const, at which point
/// the second clause (`kIsWeb` — Android/iOS use `local_auth`) becomes
/// the gating check.
final webauthnAvailableProvider = Provider<bool>((_) {
  if (!kEnableWebauthn) return false;
  return kIsWeb;
});

final webauthnFunctionsDatasourceProvider =
    Provider<WebauthnFunctionsDatasource>(
      (ref) =>
          WebauthnFunctionsDatasource(ref.watch(authFirebaseFunctionsProvider)),
    );

final webauthnCredentialFirestoreDatasourceProvider =
    Provider<WebauthnCredentialFirestoreDatasource>(
      (ref) =>
          WebauthnCredentialFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// The JS-interop seam over `navigator.credentials.create()` / `.get()`.
/// v1.5 hands out the unsupported stub — the production `package:web`
/// binding lands in v1.5.1 when `kEnableWebauthn` flips. Widget tests
/// override this provider directly with a `_FakeWebauthnBrowserDatasource`.
final webauthnBrowserDatasourceProvider = Provider<WebauthnBrowserDatasource>(
  (_) => const WebauthnBrowserDatasourceUnsupportedStub(),
);

final webauthnRepositoryProvider = Provider<WebauthnRepository>((ref) {
  return WebauthnRepositoryImpl(
    functions: ref.watch(webauthnFunctionsDatasourceProvider),
    browser: ref.watch(webauthnBrowserDatasourceProvider),
    firestore: ref.watch(webauthnCredentialFirestoreDatasourceProvider),
  );
});

final registerWebauthnUseCaseProvider = Provider<RegisterWebauthnUseCase>(
  (ref) => RegisterWebauthnUseCase(ref.watch(webauthnRepositoryProvider)),
);

final verifyWebauthnUseCaseProvider = Provider<VerifyWebauthnUseCase>(
  (ref) => VerifyWebauthnUseCase(ref.watch(webauthnRepositoryProvider)),
);

/// Streams the registered credential (or null when none). When
/// `kEnableWebauthn` is `false`, this provider returns a closed stream
/// that always emits `null` — the JS-interop binding is never reached
/// and the Firestore subscription is never opened.
final webauthnCredentialProvider = StreamProvider<WebauthnCredential?>((ref) {
  if (!kEnableWebauthn) {
    return Stream<WebauthnCredential?>.value(null);
  }
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) {
    return Stream<WebauthnCredential?>.value(null);
  }
  return ref.watch(webauthnRepositoryProvider).watchCredential(uid: user.uid);
});
