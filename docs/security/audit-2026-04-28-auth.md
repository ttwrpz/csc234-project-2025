# Security Review - PR `feat/2.1-auth`

**Reviewer:** security-reviewer agent
**Date:** 2026-04-28
**Sprint:** S2 Day 4 AM
**Commit:** `bfcc615` on `feat/2.1-auth` (stacked on `feat/3.1-mood-entry-domain`)
**Scope:** Auth feature audit per HB-001 R-001..R-008. Files reviewed:
- `apps/mobile/lib/features/auth/domain/{auth_failure,auth_repository}.dart`
- `apps/mobile/lib/features/auth/domain/entities/{app_user,auth_credentials}.dart`
- `apps/mobile/lib/features/auth/domain/usecases/{sign_in_with_email,register_with_email,sign_in_with_google,sign_out,watch_auth_state}.dart`
- `apps/mobile/lib/features/auth/domain/validators/{email,password}_validator.dart`
- `apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart`
- `apps/mobile/lib/features/auth/data/auth_repository_impl.dart`
- `apps/mobile/lib/features/auth/data/mappers/app_user_mapper.dart`
- `apps/mobile/lib/features/auth/data/providers.dart`
- `apps/mobile/lib/features/auth/presentation/{sign_in,sign_up}_screen.dart`
- `apps/mobile/lib/features/auth/presentation/widgets/{auth_text_field,google_sign_in_button}.dart`
- `apps/mobile/lib/features/auth/presentation/controllers/{sign_in_controller,sign_in_state,sign_up_controller,sign_up_state}.dart`
- `apps/mobile/lib/app/router.dart`
- `apps/mobile/test/features/auth/domain/entities/auth_credentials_test.dart`
- `apps/mobile/web/index.html`
- `apps/mobile/pubspec.yaml`

## Findings

### 🔴 Critical (block merge)
None.

### 🟠 High (block merge unless explicitly waived)
None.

### 🟡 Medium (fix in Sprint 2 follow-up)

- **[R-013] `AuthFailure.unknown(cause)` carries a raw exception across the data/domain boundary as a latent leak.** Location: `apps/mobile/lib/features/auth/domain/auth_failure.dart:20,66-67` and constructed at `firebase_auth_datasource.dart:47,70,122,136,158`. The `cause: Object?` is currently never read by any caller (verified: zero `.cause` access sites in the auth feature). However, `cause` may hold a `FirebaseAuthException` whose `.toString()` typically includes the email argument and the SDK's internal trace, and a `PlatformException` whose `.message` field is opaque but vendor-controlled. If a future controller, telemetry hook, or Crashlytics integration ever does `failure.cause?.toString()` or attaches it to a log payload, PII (email) leaks immediately. **Remediation:** flutter-engineer to either (a) drop the `cause` field entirely from `_Unknown` and log the runtime type at the datasource boundary only (pattern already used at `auth_repository_impl.dart:47,64,75,86`), or (b) document with an inline comment that `cause` is opaque, must never be `toString()`-ed across the boundary, and add a lint-or-test guard. Preferred (a). Track in Sprint 2 backlog as "S2 Hardening: drop AuthFailure.unknown.cause leak surface", due 2026-05-12. Not blocking merge because no current call site reads it.

- **[R-014] SHA-1 fingerprint capture for Google Sign-In Android still pending - carryover from R-002 of HB-001 and re-affirmed here.** Location: GCP Console / Firebase Android app config, not source. Without the debug-keystore SHA-1 registered against the Firebase Android app, `GoogleSignIn.signIn()` at `firebase_auth_datasource.dart:91` will throw `PlatformException(developer_error)`, which the datasource correctly maps to `AuthFailure.googleConfigMissing()` at line 116 - so the failure is graceful, but Google sign-in on Android will not actually work end-to-end. **Remediation:** Theerawat to capture debug SHA-1 via `cd apps/mobile/android && ./gradlew signingReport`, register in Firebase Console, and document in `docs/security/api-key-restrictions.md` before Sprint 2 close (2026-05-12). This is the same item as the foundation-audit follow-up R-002 deferral.

- **[R-015] `pubspec.yaml` still uses `^` ranges on auth-sensitive packages - carryover from foundation R-010.** Location: `apps/mobile/pubspec.yaml:13-15,21` (`firebase_core ^4.3.0`, `firebase_auth ^6.1.3`, `cloud_firestore ^6.1.1`, `google_sign_in ^6.2.2`). CLAUDE.md explicitly says "no `^` ranges on security-sensitive packages like auth, crypto, http clients". `feat/2.1-auth` adds new code paths that exercise `firebase_auth` and `google_sign_in`, increasing the blast radius of a malicious patch release. **Remediation:** flutter-engineer to drop `^` from those four entries (pin to the exact resolved `pubspec.lock` versions) in a follow-up PR before Sprint 2 close. Spoiler from HB-001: this PR did not introduce the `^`; foundation audit already flagged it. Re-flagging because the surface area grew. Not blocking merge because `pubspec.lock` still pins transitively.

### 🟢 Low / informational

- **[R-016] Web Google sign-in is hidden but Firebase popup path is wired. Document the gap.** Location: `sign_in_screen.dart:18` (`final showGoogle = !kIsWeb;`) and `firebase_auth_datasource.dart:77-89` (Web path uses `_auth.signInWithPopup(GoogleAuthProvider()..addScope('email'))`). The kIsWeb gate hides the button correctly per R-008. The datasource still has a working Web popup path which is unreachable from UI today; that's defensible - it lights up the moment the gate is removed. `apps/mobile/web/index.html` has zero `google-signin-client_id` meta tag (verified) but the popup flow does not require it (Firebase's `signInWithPopup` uses GIS loaded by `firebase_auth` itself). Real Web Google sign-in still requires Theerawat to verify the OAuth consent screen + register the production domain in GCP Console. **Action:** until that lands, the kIsWeb hide stays. When Theerawat clears the OAuth setup, flutter-engineer flips line 18 to `const showGoogle = true;` (or a Remote Config flag) in a follow-up. No code change needed now. Track in `docs/security/api-key-restrictions.md` alongside R-002/R-014.

- **[R-017] `signOut()` swallows Google-sign-out errors with a silent catchError.** Location: `firebase_auth_datasource.dart:130` (`await _googleSignIn.signOut().catchError((_) => null);`). This is intentional - if the user wasn't signed into Google we still want Firebase sign-out to proceed - but the `(_) => null` discards both the error type and any unexpected platform errors. Defence-in-depth: log the type via `_logger.debug` so we have a breadcrumb if Google's sign-out starts misbehaving in the field. **Action:** flutter-engineer can add a one-line `_logger.debug` (no payload, type only) in a follow-up. Not blocking; not even Medium.

- **[R-018] Google OAuth scope on Web uses `addScope('email')` not the GIS default.** Location: `firebase_auth_datasource.dart:82`. Verified: only `email` is added. Firebase's `GoogleAuthProvider` ships with implicit `openid` and `profile` scopes baked in by Google Identity Services regardless of what you pass - that is a Google-side behavior, not a client misconfiguration, and matches the de-facto minimum for Firebase Auth. **No action.** Documenting so future reviewers don't re-litigate.

## Cleared

- **R-001 No password logging:** ✅ Verified. Four `_logger.warn` call sites in `auth_repository_impl.dart:47,64,75,86` log only `'<op> failed: ${e.failure.runtimeType}'` - runtime-type only, no email, no password, no exception payload. No `print(`, `debugPrint(`, `dev.log(`, `developer.log(` calls in `apps/mobile/lib/features/auth/` (verified by full-tree grep). `AuthCredentials.toString()` redaction asserted by `auth_credentials_test.dart:6-21` (assertion: password literal absent from `toString()` output, `<redacted>` substring present). Controllers do not log state.

- **R-002 Google OAuth scope minimal:** ✅ Verified `GoogleSignIn(scopes: const ['email'])` at `firebase_auth_datasource.dart:19` - only `email`, no `profile`, no Drive, no Calendar, no Contacts. Web path at `firebase_auth_datasource.dart:82` uses `GoogleAuthProvider()..addScope('email')` - same. Tracker R-014 (SHA-1 capture) is the open follow-up.

- **R-003 No tokens in domain:** ✅ Verified. Full grep of `apps/mobile/lib/features/auth/domain/` for `package:firebase_`, `package:cloud_firestore`, `package:google_sign_in`, `firebase_auth` returns zero matches. Domain imports are limited to `package:core/core.dart`, `package:freezed_annotation/freezed_annotation.dart`, and relative `../...dart`. Re-confirms foundation R-009 invariant.

- **R-004 Error messages PII-safe:** ✅ Verified. All ten `AuthFailure._<Variant>` message strings in `auth_failure.dart:24-67` are static literals with zero string interpolation; none contain `$email`, `$password`, or any user input. The `_logger.warn` format strings in `auth_repository_impl.dart:47,64,75,86` are fixed prefixes plus `e.failure.runtimeType` - type name only.

- **R-005 Re-auth on sensitive ops:** ✅ N/A. No account deletion or password-change UI in this sprint per HB-001. To be revisited in HB-002 / S3 when UserProfile lands.

- **R-006 Auth state listener cleanup:** ✅ Verified. `router.dart:20-21` constructs a `ValueNotifier<AppUser?>` and immediately registers `ref.onDispose(refresh.dispose)`. `router.dart:22-24` is the sole `ref.listen<AsyncValue<AppUser?>>(currentUserStreamProvider, ...)` subscription. `currentUserStreamProvider` in `providers.dart:26-28` is a plain `StreamProvider` which Riverpod auto-disposes when the last listener detaches; the underlying `_datasource.authStateChanges()` stream from Firebase is owned by FirebaseAuth and is process-lifetime, which is correct.

- **R-007 No anonymous sign-in code paths:** ✅ Verified. Case-insensitive grep of `apps/mobile/lib/features/auth/` for `signInAnonymously` and `anonymous` returns zero matches.

- **R-008 Web OAuth client ID:** ✅ Cleared as informational. `apps/mobile/web/index.html` has no `google-signin-client_id` meta tag, which is acceptable because `sign_in_screen.dart:18` hides the Google button on `kIsWeb`. Tracking R-016 as the documentation follow-up.

- **Secret scan delta:** ✅ Clean. Grep of `apps/mobile/lib/features/auth/` for `(AIza|sk-|xox[baprs]-|ghp_|AKIA)[A-Za-z0-9_-]{16,}` returns zero matches. `firebase_options.dart` exception out of scope for this audit.

- **Domain purity recap:** ✅ See R-003. Re-confirmed for the auth feature.

- **Pubspec dep additions:** ✅ Verified. `feat/2.1-auth` did not add new auth deps; it consumes `firebase_auth ^6.1.3` and `google_sign_in ^6.2.2` already present. R-015 re-flags the existing `^` ranges.

## Sign-off

- [x] ⚠️ **Approved with conditions.** R-013 (`AuthFailure.unknown.cause` latent leak), R-014 (SHA-1 capture, carryover from foundation R-002), R-015 (pin `^` ranges, carryover from foundation R-010), R-016 (Web Google docs), R-017 (signOut error swallow) are all Medium/Low and tracked for Sprint 2 close (2026-05-12). None blocks merge of `feat/2.1-auth`. R-001..R-008 from HB-001 all clear with cited evidence.

**Merge of `feat/2.1-auth` is approved.** Track R-013 + R-015 + R-017 as a single Sprint 2 hardening ticket assigned to flutter-engineer. R-014 + R-016 stay with Theerawat under the existing "S2 Hardening: Firebase API key console restrictions" ticket.
