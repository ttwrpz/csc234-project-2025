# Handoff Brief — Auth (Email/Password + Google)

**WBS:** 2.1
**Sprint:** S2 (Day 3 Apr 24 → Day 4 Apr 27)
**Target branch:** `feat/2.1-auth` (stacked on `feat/3.1-mood-entry-domain`)

## Summary
A first-time user lands on onboarding, then on `/sign-in`. They register with email/password or tap "Continue with Google", and on success route to `/home` inside the bottom-nav shell. A signed-in user who relaunches the app skips both onboarding and sign-in and lands on `/home`. A user can sign out from Settings, which returns them to `/sign-in`. Biometric/keystore is **out of scope (S3)**; Firebase Auth + Google Sign-In only this sprint. UserProfile upsert at `users/{uid}` is **out of scope (HB-002 / S3)**.

## Domain shape

### Entities
- `apps/mobile/lib/features/auth/domain/entities/app_user.dart` — Freezed.
  - Fields: `String uid`, `String? email`, `String? displayName`, `String? photoUrl`, `bool emailVerified`, `DateTime? lastSignInAt`.
  - **No password fields. No tokens. No Firebase types.**
- `apps/mobile/lib/features/auth/domain/entities/auth_credentials.dart` — Freezed.
  - `AuthCredentials.emailPassword({required String email, required String password})`
  - `AuthCredentials.google()` (no payload — provider flow)
  - Override `toString()` to redact password: `AuthCredentials.emailPassword(email: ..., password: <redacted>)`.

### Use cases (one file each, per CLAUDE.md)
- `apps/mobile/lib/features/auth/domain/usecases/sign_in_with_email.dart` — `SignInWithEmailUseCase` with `Future<Result<AppUser, AuthFailure>> call({required String email, required String password})`. Co-locate `signInWithEmailUseCaseProvider`.
- `apps/mobile/lib/features/auth/domain/usecases/register_with_email.dart` — `RegisterWithEmailUseCase` (same signature).
- `apps/mobile/lib/features/auth/domain/usecases/sign_in_with_google.dart` — `SignInWithGoogleUseCase` with `Future<Result<AppUser, AuthFailure>> call()`.
- `apps/mobile/lib/features/auth/domain/usecases/sign_out.dart` — `SignOutUseCase` with `Future<Result<void, AuthFailure>> call()`.
- `apps/mobile/lib/features/auth/domain/usecases/watch_auth_state.dart` — `WatchAuthStateUseCase` with `Stream<AppUser?> call()`.

### Abstract repository
`apps/mobile/lib/features/auth/domain/auth_repository.dart` — match `mood_repository.dart` style:

```dart
import 'package:core/core.dart';
import 'auth_failure.dart';
import 'entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  AppUser? get currentUser;
  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  });
  Future<Result<AppUser, AuthFailure>> registerWithEmail({
    required String email,
    required String password,
  });
  Future<Result<AppUser, AuthFailure>> signInWithGoogle();
  Future<Result<void, AuthFailure>> signOut();
}
```

### `AuthFailure` (sealed, matches `MoodFailure` style)
`apps/mobile/lib/features/auth/domain/auth_failure.dart`:

```dart
sealed class AuthFailure extends Failure {
  const AuthFailure({required super.message});

  const factory AuthFailure.invalidEmail() = _InvalidEmail;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.wrongPassword() = _WrongPassword;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.googleCancelled() = _GoogleCancelled;
  const factory AuthFailure.googleConfigMissing() = _GoogleConfigMissing;
  const factory AuthFailure.network() = _Network;
  const factory AuthFailure.tooManyRequests() = _TooManyRequests;
  const factory AuthFailure.unknown(Object? cause) = _Unknown;
}
```

Map `FirebaseAuthException.code` strings (`invalid-email`, `weak-password`, `wrong-password`, `user-not-found`, `email-already-in-use`, `network-request-failed`, `too-many-requests`) to these in the data layer; never leak the raw exception across the boundary.

### Pure-Dart invariants (qa-engineer test targets)
1. Email validator: non-empty, contains `@`, length ≤ 254. Co-locate `emailIsValid(String)` in `domain/validators/email_validator.dart`.
2. Password validator: length ≥ 8 (Firebase min is 6 — we tighten). Co-locate in `domain/validators/password_validator.dart`.
3. `AppUser.fromFirebase` is **not** a domain concern (lives in data layer mapper).
4. `AuthCredentials.emailPassword.toString()` MUST NOT contain the password literal — assert in unit test.
5. Use cases reject blank inputs by returning `Err(AuthFailure.invalidEmail())` / `Err(AuthFailure.weakPassword())` **before** calling the repository.

## Data shape

- **Firestore collection changes: NONE for S2.** UserProfile upsert at `users/{uid}` is deferred to HB-002. `cloud_firestore` is unused by this feature.
- **Security rule changes: NONE for S2.** Rules land in S3.
- DTO: `apps/mobile/lib/features/auth/data/dtos/app_user_dto.dart` — thin wrapper over `firebase_auth.User`, exists only to keep mapping logic isolated. Open question below: this may be redundant.
- Mapper: `apps/mobile/lib/features/auth/data/mappers/app_user_mapper.dart` — `AppUser fromFirebaseUser(User u)`.
- Datasource: `apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart` — wraps `FirebaseAuth.instance` and `GoogleSignIn`. Catches `FirebaseAuthException` and `PlatformException`, returns sealed `AuthFailure`.
- Repository impl: `apps/mobile/lib/features/auth/data/auth_repository_impl.dart` — implements `AuthRepository`, depends on the datasource.
- Providers: `apps/mobile/lib/features/auth/data/providers.dart` — exposes `authRepositoryProvider`, plus a `currentUserStreamProvider` (`StreamProvider<AppUser?>`) that the router listens to.

## Presentation shape

### Screens
- `apps/mobile/lib/features/auth/presentation/sign_in_screen.dart` — replaces the placeholder at router.dart line 36–39. Email field, password field (`obscureText: true`), "Sign in" button, "Continue with Google" button, "Create an account" text-button → `/sign-up`.
- `apps/mobile/lib/features/auth/presentation/sign_up_screen.dart` — replaces placeholder at router.dart line 43–46. Email, password, confirm-password fields; "Create account" button; "Already have an account? Sign in" → `/sign-in`.

### Widgets
- `apps/mobile/lib/features/auth/presentation/widgets/google_sign_in_button.dart` — branded button per Google guidelines; uses design-system tokens.
- `apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart` — Material text field bound to design tokens; supports `obscureText`, error text from controller state.

### Controllers
- `apps/mobile/lib/features/auth/presentation/controllers/sign_in_controller.dart` — `@riverpod class SignInController extends _$SignInController` with `SignInState` (Freezed: `email`, `password`, `isSubmitting`, `errorMessage?`).
- `apps/mobile/lib/features/auth/presentation/controllers/sign_up_controller.dart` — analogous, plus `confirmPassword`.

Controllers call use cases via `ref.read(...UseCaseProvider)`. **Never** call the repository directly. **Never** put password into `state` logs; never `print` state.

### Navigation extension (exact)
Modify `apps/mobile/lib/app/router.dart` lines 15–28. Replace the existing `routerProvider` body so `redirect` consults BOTH onboarding and auth, and so the router refreshes on auth changes:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AppUser?>(null);
  ref.onDispose(refresh.dispose);
  ref.listen<AsyncValue<AppUser?>>(currentUserStreamProvider, (_, next) {
    refresh.value = next.valueOrNull;
  });

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool(_onboardingCompleteKey) ?? false;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/sign-in' || loc == '/sign-up';

      // 1. Onboarding gate (preserve existing behavior).
      if (!onboardingDone && loc != '/onboarding') return '/onboarding';
      if (onboardingDone && loc == '/onboarding') {
        return refresh.value == null ? '/sign-in' : '/home';
      }
      // 2. Auth gate (new).
      if (onboardingDone && refresh.value == null && !isAuthRoute) {
        return '/sign-in';
      }
      if (refresh.value != null && isAuthRoute) return '/home';
      return null;
    },
    routes: [ /* existing routes; replace placeholders at lines 34-47 with SignInScreen / SignUpScreen */ ],
  );
});
```

Add a `Sign out` ListTile to the Settings placeholder (router.dart line 87–93) wired to `SignOutUseCase`. The router `refreshListenable` will redirect to `/sign-in` automatically when `currentUser` becomes null.

## Handoffs

### → flutter-engineer
Create files in this order:

1. `apps/mobile/lib/features/auth/domain/entities/app_user.dart`
2. `apps/mobile/lib/features/auth/domain/entities/auth_credentials.dart`
3. `apps/mobile/lib/features/auth/domain/auth_failure.dart`
4. `apps/mobile/lib/features/auth/domain/auth_repository.dart`
5. `apps/mobile/lib/features/auth/domain/validators/{email,password}_validator.dart`
6. `apps/mobile/lib/features/auth/domain/usecases/{sign_in_with_email,register_with_email,sign_in_with_google,sign_out,watch_auth_state}.dart`
7. `apps/mobile/lib/features/auth/data/dtos/app_user_dto.dart`
8. `apps/mobile/lib/features/auth/data/mappers/app_user_mapper.dart`
9. `apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart`
10. `apps/mobile/lib/features/auth/data/auth_repository_impl.dart`
11. `apps/mobile/lib/features/auth/data/providers.dart`
12. `apps/mobile/lib/features/auth/presentation/widgets/{auth_text_field,google_sign_in_button}.dart`
13. `apps/mobile/lib/features/auth/presentation/controllers/{sign_in,sign_up}_controller.dart`
14. `apps/mobile/lib/features/auth/presentation/{sign_in,sign_up}_screen.dart`
15. Update `apps/mobile/lib/app/router.dart` (lines 15–28 redirect + lines 34–47 routes + Settings sign-out tile). Architect sign-off pre-granted by this brief.
16. Run `flutter pub run build_runner build --delete-conflicting-outputs`.

Follow conventions: 100-char lines; design-system tokens for colors/spacing; copy rules from CLAUDE.md (no clinical language; "Want to sign in?" not "You must sign in").

**Do not touch:**
- `apps/mobile/lib/features/mood/**`
- `firebase/firestore.rules` (no rule changes this brief)
- `functions/**`
- `apps/mobile/lib/main.dart` (no entry-point changes needed)
- Android `applicationId` / `google-services.json` (deferred to ADR-0002)

### → qa-engineer (Day 5)
Unit tests (write alongside domain files, in same PR):
- `test/features/auth/domain/validators/email_validator_test.dart` — boundary cases.
- `test/features/auth/domain/validators/password_validator_test.dart` — < 8 chars rejected.
- `test/features/auth/domain/entities/auth_credentials_test.dart` — `toString()` redaction (invariant 4).
- `test/features/auth/domain/usecases/*_test.dart` — each use case with a fake `AuthRepository` (override `authRepositoryProvider` via `ProviderContainer`); cover happy path + each `AuthFailure` variant.

Widget tests (Day 5):
- `test/features/auth/presentation/sign_in_screen_test.dart` — empty submit shows error; valid submit calls controller; Google button taps invoke `SignInWithGoogleUseCase`.
- `test/features/auth/presentation/sign_up_screen_test.dart` — password mismatch shown; success navigates.

Integration test (Day 5, time-permitting):
- `integration_test/auth_flow_test.dart` — boot → onboarding → sign-up → home (uses Firebase Auth emulator).

### → security-reviewer (Day 4 audit)
Audit checklist:
- [ ] **R-001 No password logging.** Grep `lib/features/auth/` for `Logger.`, `print(`, `debugPrint(`, `log(`. No call site may pass `password`, `state.password`, or `AuthCredentials` content. Verify `AuthCredentials.toString()` redaction test exists.
- [ ] **R-002 Google OAuth scope minimal.** `GoogleSignIn` constructed with `scopes: ['email']` only — no `profile`, no Drive, no Calendar. Confirm SHA-1 fingerprint registered in Firebase console matches debug + release keystores (capture from Theerawat).
- [ ] **R-003 No tokens in domain.** Domain layer must not import `firebase_auth` (re-run domain-purity hook on `apps/mobile/lib/features/auth/domain/**`).
- [ ] **R-004 Error messages PII-safe.** `AuthFailure.message` strings contain no email, uid, or password fragment. `Logger` calls in datasource log only the failure type, not user input.
- [ ] **R-005 Re-auth on sensitive ops.** N/A this sprint (no account deletion / password change UI).
- [ ] **R-006 Auth state listener cleanup.** `firebaseAuthDatasource` exposes `authStateChanges()` stream; `currentUserStreamProvider` must dispose subscriptions; router `refresh` `ValueNotifier` disposed via `ref.onDispose` (verify in router.dart diff).
- [ ] **R-007 No anonymous sign-in code paths** unless explicitly enabled (defense-in-depth).
- [ ] **R-008 Web OAuth client ID** present in `apps/mobile/web/index.html` `<meta name="google-signin-client_id">` if Google Web ships; otherwise the Web Google button is hidden behind a platform check.

## Acceptance Criteria
From `.claude/prompts/sprint-2-kickoff.md` lines 80–87, the auth-relevant items:
- [ ] User can register with email/password and sign in with Google
- [ ] App builds for both Android (debug APK) and Web (Chrome) from a clean checkout
- [ ] Onboarding shows on first launch only (regression check — redirect chain still correct)
- [ ] At least one widget test covers auth (counts toward the four-test minimum)
- [ ] Domain layer has zero Flutter/Firebase imports (`apps/mobile/lib/features/auth/domain/**` clean)
- [ ] CI green on `feat/2.1-auth`

Plus brief-specific:
- [ ] Signed-in user relaunching the app lands on `/home` (no sign-in flash)
- [ ] Sign-out from Settings returns to `/sign-in` within one frame
- [ ] No password string appears in any log line during a full sign-in run

## Open Questions for orchestrator
1. **Google Sign-In on Web:** OAuth client ID + verified consent screen in GCP. Theerawat must confirm by Day 3 EOD. If unverified, demo Web auth = email-only fallback and Google button is hidden on `kIsWeb`.
2. **SHA-1 capture for R-002:** debug keystore SHA-1 (and release if available) must be added to Firebase Android app config. Capture from Jedsarit or via `cd apps/mobile/android && ./gradlew signingReport`.
3. **`AppUserDto` necessity:** since there is no Firestore persistence this sprint, `AppUserDto` may be redundant — the mapper can convert `firebase_auth.User` directly to `AppUser`. Decision: keep the DTO file as a one-line typedef stub for forward-compat with HB-002 UserProfile upsert, or delete it now and add when needed. Architect default: **delete now, add in HB-002**; flutter-engineer may push back if codegen ergonomics suffer.
