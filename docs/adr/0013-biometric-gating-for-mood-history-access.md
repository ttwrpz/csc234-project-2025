# ADR-0013 - Biometric Gating for Mood History + Entry Detail Access (with PIN fallback)

**Status:** Accepted (Sprint 5 polish - v1.5)
**Date:** 2026-05-14
**Deciders:** orchestrator + architect (security-reviewer to ratify the PIN hashing choice before merge)
**Related:** CLAUDE.md "Stack (locked)" (`local_auth` + platform keystore - biometric fallback required); ADR-0009 (account-deletion reauth via `reauthenticate`); WBS 2.2 (existing cold-boot biometric gate); `apps/mobile/lib/features/auth/domain/entities/biometric_capability.dart`; `apps/mobile/lib/features/auth/data/providers.dart:142..154` (`biometricCapabilityProvider`, `biometricUnlockedThisSessionProvider`); `apps/mobile/lib/app/router.dart:96..109` (existing cold-boot gate redirect)

## Context

The v1.0 design already ships a cold-boot biometric gate: when the user has opted in via Settings (`BiometricSettingsTile`), the router redirects to `/biometric-gate` once per session (`router.dart:96..109`). Successful biometric flips `biometricUnlockedThisSessionProvider` to `true` and the user proceeds to `/home`. This is an **app-launch** gate; it does NOT re-prompt when the user later opens the journal mid-session.

The user's v1.5 polish request is narrower and more sensitive: gate **viewing of mood entries and the History page** behind biometric - i.e. a privacy wall around the journal text itself, distinct from "the app is running at all." A spouse picking up an unlocked phone should see the garden home, but should NOT see the journal.

CLAUDE.md "Stack (locked)" commits the team to `local_auth` with platform keystore and "biometric fallback required." `local_auth` is unavailable on Flutter Web; many Android devices do not have any biometric enrolled. Both cases need a fallback that is real, not a hand-wave.

The v1.5 deadline is May 19, 2026 (five days from this ADR). Any decision that pushes work past that date is explicitly deferred to v1.6.

## Decision

### Summary (one paragraph)

A History-access biometric gate, **optional and Settings-toggled** (default OFF), gates two routes (`/history` and `/history/:id`) via a GoRouter `redirect` callback. Unlock state is session-scoped with a sliding 5-minute idle window (whichever expires first). On platforms where biometric is unavailable (Web; Android-without-enrolled-biometric), a **PIN fallback** is the secondary unlock - 6 digits, PBKDF2-hashed and stored at `users/{uid}/security/pin` (subcollection doc, never the root user doc). **WebAuthn is explicitly deferred to v1.6** - the server-side Relying Party setup, attestation handling, and Cloud Function additions are out of v1.5's scope.

### Decision A - Optional with a Settings toggle (default OFF)

Three options were considered:

- (A.1) Optional, default OFF.
- (A.2) Required for all capable devices.
- (A.3) Required by default, toggleable off.

**Chosen: A.1.** Default OFF.

Rationale:

1. CLAUDE.md's wording is "biometric fallback required" - i.e. the team commits to having a fallback when biometric is the auth mechanism, not to forcing biometric on every user. Defaulting OFF respects that wording.
2. The journal is the app's primary feature. Forcing a re-auth wall on a primary feature in the FIRST polish release is a UX regression for users who chose this app over a generic mood-tracker. Privacy-conscious users opt in; everyone else gets the existing in-app affordances unimpeded.
3. We have a forcing function in v1.6: if `users/{uid}.insightsDisclaimerAcked` and `users/{uid}.security.pinSet` adoption analytics show low uptake, we can flip the default in v1.6 with a one-line config change. We cannot reverse a default-ON in v1.5 without a louder migration prompt.

The Settings toggle is the single switch. Flipping it ON triggers the first-time setup flow described in Decision G.

### Decision B - Gates `/history` AND `/history/:id`; does NOT gate Insights

Three scopes considered:

- (B.1) `/history` only.
- (B.2) `/history` + `/history/:id`.
- (B.3) The above + `/analytics/insights` (chart visualises mood patterns).

**Chosen: B.2.** Gate `/history` AND `/history/:id`.

Rationale:

1. The user's request named "mood entry" and "history page" - that is exactly (B.2). A deep link to `/history/{id}` from an FCM notification or a tier intervention's "see the entry that triggered this" link must NOT bypass the gate by skipping the list view. The redirect runs on every navigation, so guarding both routes is one configuration, not two.
2. **Insights is explicitly NOT gated.** The Insights chart shows aggregates (mood scores, EWMA, tier markers) but never raw entry text. The argument that the chart "reveals patterns" is weaker than the spouse-with-phone threat model - anyone can infer the user's recent mood from looking at the user. Gating Insights would also collide with the bipolar/medical disclaimer ack gate (TC-36): a user who opens Insights for the first time would face *two* full-screen modals back-to-back. Bad UX, no incremental security benefit.
3. **Log Mood is explicitly NOT gated.** A user in distress reaching for the app to capture a feeling must not face a fingerprint prompt at that moment. Capturing the feeling is the priority; viewing it later is what the gate protects.
4. **Settings is NOT gated.** The user must always be able to turn the gate OFF without re-authenticating it. A bricked-by-toggle device with no biometric and a forgotten PIN cannot be the failure mode of a polish feature.

### Decision C - GoRouter `redirect` callback, single source of enforcement

Three architectures considered:

- (C.1) `GoRouter` `redirect` callback.
- (C.2) `BiometricGate` wrapper widget per gated screen.
- (C.3) Hybrid: router-level for first visit, widget-level for re-prompts on re-foreground.

**Chosen: C.1.** Router-level redirect.

Rationale:

1. The existing cold-boot biometric gate is already implemented as a router redirect (`router.dart:96..109`). The new history gate plugs into the same `redirect` callback as a sibling clause - one file change, one place to test. Widget-level wrappers would spread the policy across `HistoryScreen` AND `EntryDetailScreen` AND any future read-of-journal surface, and each could drift independently.
2. Single source of enforcement is the textbook security pattern (Saltzer & Schroeder 1975 - "economy of mechanism"). Adding a new gated route in v1.6 (e.g. a journal-search screen) is one line in the redirect, not a new wrapper to remember.
3. Testability: the redirect callback is already exercised by router widget tests. The new clause is testable with a fake `historyUnlockedThisSessionProvider` override.
4. The unlock flow itself reuses the existing `BiometricGateScreen` pattern (`apps/mobile/lib/features/auth/presentation/biometric_gate_screen.dart`) - same shape, different target route. A new screen `HistoryUnlockScreen` lives at route `/unlock-history` and on success flips `historyUnlockedThisSessionProvider` then `context.go('/history')`.

### Decision D - Session unlock, 5-minute idle re-lock - whichever expires first

Three policies considered:

- (D.1) Unlock for the whole session (until app backgrounded / signed out).
- (D.2) Re-prompt on every access.
- (D.3) Unlock for 5 minutes (sliding idle window).

**Chosen: composite of D.1 and D.3.** Unlock persists until **EITHER** the session ends (app backgrounded for > 30 s OR explicit sign-out) **OR** 5 minutes of inactivity have elapsed within the History route - whichever fires first.

Rationale:

1. CLAUDE.md notes Firebase Auth's recent-login window is 5 minutes (ADR-0009 context). Parallelism here is intentional - the user's mental model for "I just verified, so the app trusts me for a few minutes" is the same.
2. Re-prompting on every entry tap (D.2) is friction the user did not ask for and that defeats the affordance of scrolling the history.
3. "Whole session" (D.1) is too long when a session can last hours on a phone left unlocked.
4. The sliding idle window is reset by any tap inside the History route. Tapping back to `/home` does NOT reset the timer; if the user returns to `/history` more than 5 minutes after their last tap there, they re-auth.
5. App-background for > 30 s clears the session unlock outright (existing pattern: `biometricUnlockedThisSessionProvider` is reset on sign-out per `router.dart:71..73`; we add a parallel reset on AppLifecycleState.paused-then-resumed-after-30s for the History flag).

Implementation: add a new provider `historyUnlockedThisSessionProvider` (`StateProvider<DateTime?>` - null = locked; non-null = the timestamp of the last activity in the History route). The router redirect treats `null` OR `now - value > 5 minutes` as "needs unlock."

### Decision E - Platform unsupported fallback: PIN for v1.5; WebAuthn deferred to v1.6

Three options for Web AND for Android-without-enrolled-biometric:

- (E.1) Disable the gate on web entirely; on Android without biometric, the toggle is disabled.
- (E.2) 6-digit PIN fallback. Hashed at rest. Verified locally on the device; cloud-stored hash so re-install on a trusted device can restore the gate.
- (E.3) WebAuthn API (web only) - real platform authenticators via FIDO2.

**Chosen: E.2.** PIN fallback for both Web AND Android-without-biometric, for v1.5. **E.3 (WebAuthn) is deferred to v1.6.**

Rationale:

1. CLAUDE.md explicitly says "biometric fallback required." E.1 (disable on web) is a non-answer to the CLAUDE.md commitment. A PIN is the canonical fallback for `local_auth`-unavailable platforms (Google's Account Manager UX uses the same pattern).
2. WebAuthn is real engineering: a server-side Relying Party (new Cloud Function), attestation parse, credential storage in Firestore, browser-credential UI flow, recovery flow. Conservatively two engineer-days plus security-reviewer time. **It would not land before May 19.** Deferring to v1.6 is the correct call.
3. PIN can be implemented in v1.5 in under a day:
    - A new `PinSetupScreen` + `PinVerifyScreen` (numeric keypad, 6 digits, no biometric stack).
    - PBKDF2-SHA-256 with a per-user random salt (16 bytes), 100 000 iterations, output 32 bytes. Use the `crypto` package's `Hmac<Sha256>` in a loop (PBKDF2 is not a one-call API in `crypto` but is < 20 lines pure Dart). If the `pointycastle` package is already in scope from `local_auth` transitive deps, use `pointycastle/key_derivators/pbkdf2.dart` instead; verify in `pubspec.lock` before adding a new dep.
    - Storage: `users/{uid}/security/pin` (a sub-document; do NOT add `pinHash` to the root user doc, which is read on many screens and has a wider field allow-list). Fields: `algorithm: "pbkdf2-sha256"`, `iterations: 100000`, `saltBase64`, `hashBase64`, `createdAt`, `failedAttempts: int`, `lockedUntil: timestamp?`.
    - **Rate-limit:** after 5 failed attempts, lock PIN verification for 60 seconds (`lockedUntil = now + 60s`, `failedAttempts` resets on success). After 10 cumulative failures within an hour, lock for 30 minutes. Both bounds enforced server-side via Firestore rules - the rules check `request.time < resource.data.lockedUntil` blocks the read of the hash doc.
    - **Security rules:** `users/{uid}/security/pin` is readable only by `request.auth.uid == uid` AND only when the rate-limit allows. Writeable on create / replace by the same uid; never deletable from the client (PIN reset goes through account-recovery, not a one-tap delete). **security-reviewer sign-off required** for this rule addition (CLAUDE.md do-not-do list).
4. PIN verification happens **client-side** - the app reads the hash doc, recomputes PBKDF2 with the user-entered PIN + stored salt, compares hashes constant-time. Firestore is the durable store; verification never leaves the device. This is identical to the Apple/Android device-pin model and is the canonical PIN UX.
5. **WebAuthn deferral note:** v1.6 ADR-0014 (TBD) will document the WebAuthn migration. The Firestore doc shape designed for PIN (`users/{uid}/security/`) has room for a parallel `users/{uid}/security/webauthn/{credentialId}` sub-document - no schema migration required to add it later.

### Decision F - Settings UI (Privacy section)

The Settings screen at `apps/mobile/lib/features/settings/presentation/settings_screen.dart` adds a new section labelled **PRIVACY** between SECURITY (lines 107..114, the biometric opt-in) and ACCOUNT (lines 118..167). The PRIVACY section is a single `MbCard` with these tiles in order:

```
PRIVACY
┌─────────────────────────────────────────────────────────────────┐
│ ⌥ Require unlock to view history          [ Switch: OFF ]        │
│   Ask for your fingerprint or PIN before showing the journal.   │
├─────────────────────────────────────────────────────────────────┤
│ ⌥ Set up PIN                              [ Configure → ]        │  ← only when switch ON
│   PIN is the fallback when biometric isn't available.           │
├─────────────────────────────────────────────────────────────────┤
│ ⌥ Change PIN                              [ Change → ]           │  ← only when PIN set
│   Replace your existing PIN.                                    │
└─────────────────────────────────────────────────────────────────┘
```

States:

1. **Toggle OFF, no PIN set, no biometric capability.** Switch enabled. PIN tiles hidden. Flipping ON enters the first-time setup flow (Decision G).
2. **Toggle OFF, no PIN set, biometric capability present.** Switch enabled. PIN tiles hidden until ON.
3. **Toggle ON, PIN set, biometric capability present.** Switch ON. Both "Change PIN" and (no "Set up PIN") visible.
4. **Toggle ON, PIN set, no biometric capability (web; Android no-enrol).** Switch ON. "Change PIN" visible. The switch's subtitle reads: `"PIN is the only unlock method on this device."`
5. **Toggle ON requested by user with no biometric AND no PIN setup yet.** Cannot happen - the toggle is gated through setup (Decision G). If the user somehow lands in this state (data corruption), the switch reverts itself with a snackbar: `"Set up a PIN to enable this protection."`

Disabled-state copy (when both biometric is unavailable AND no PIN possible - e.g. signed-out user, which should not happen but defence in depth): switch is greyed out with `"Sign in first to set up a privacy lock."` subtitle.

### Decision G - First-time setup flow

When the user flips the PRIVACY switch ON for the first time, navigate to a modal route `/privacy/setup` (top-of-stack, no bottom nav) that walks two screens in sequence:

**Screen G-1 - Biometric verification (skipped on platforms without capability):**

- Title: `"Verify your fingerprint"`.
- Subtitle: `"This is the same biometric you use to sign in. We use it to unlock your journal."`
- A "Continue" primary button triggers `AuthenticateWithBiometricUseCase` immediately. On success → advance to G-2. On cancellation → revert switch + back to Settings.
- If `BiometricCapability.isAvailable && hasEnrolledBiometrics` is false, this screen is skipped - go straight to G-2.

**Screen G-2 - PIN setup (always required):**

- Title: `"Set a 6-digit PIN"`.
- Subtitle: `"PIN is the fallback when biometric isn't available - for example on the web, or if your device's fingerprint stops working."`
- Numeric keypad, two passes (entry → confirm). On mismatch, clear and message: `"PINs didn't match - try again."`. On match, derive PBKDF2 hash, write to `users/{uid}/security/pin`, advance to G-3.

**Screen G-3 - Confirmation:**

- `"Privacy lock is on. Your journal will ask for biometric or PIN to open."`
- Single button: `"Done"` → pops back to Settings with the switch persisted ON.

Cancellation at any step (back button, system gesture) reverts the switch to OFF and clears any partial state. The PIN document is written ONLY at the end of G-2; a half-completed setup never persists.

**Reset flow (v1.5):** there is no in-app PIN reset for v1.5 - a user who forgets their PIN can flip the Settings toggle OFF after biometric-or-account-deletion-reauth and re-run setup. If they have no biometric AND forgot the PIN, the only path is account deletion. **This is acceptable for v1.5** because the gate is opt-in and the user took on the protection knowingly; v1.6 will add a "forgot PIN - reset via email" flow that re-uses the existing password-reset email pipeline.

## Consequences

**Good**

- The user's privacy request is delivered in v1.5 without expanding scope into WebAuthn engineering.
- The Settings UI is consistent with the existing SECURITY zone (`BiometricSettingsTile` pattern) and the existing PREFERENCES zone - same `MbCard` + tile aesthetic; no design-system drift.
- The router-level enforcement is one source of truth; future gated routes are one-line additions.
- PIN-as-fallback satisfies CLAUDE.md "biometric fallback required" with real cryptography (PBKDF2-SHA-256, 100 000 iterations, per-user salt) - not a hand-wave.
- The Firestore document shape leaves room for v1.6 WebAuthn without schema migration.
- Insights screen and the cold-boot biometric gate are unchanged - no regression to existing TC-36 / WBS 2.2 tests.

**Bad / Trade-offs**

- A user who forgets their PIN AND has no biometric must delete and re-create their account to recover. **v1.5 accepts this risk** because the gate is opt-in; the user opts in knowingly and the same protection (no recovery path) is exactly what makes the PIN meaningful. v1.6 adds an email-reset path.
- PIN verification is client-side. A determined attacker with the user's UID and Firestore read access (which would imply the user is already compromised) could brute-force the PIN offline. The 100 000 PBKDF2 iterations slow this to seconds-per-PIN on consumer hardware; the rate-limit doc adds a second layer; the threat model is "spouse holding the unlocked phone" not "nation-state offline crack." Acceptable.
- The History page now has a routing prerequisite. Deep-link share URLs (e.g. `/history/abc123`) hit the gate first - this is the correct behaviour but the engineer must verify FCM tap-actions also route through the redirect (`GoRouter.go` does; `Navigator.push` does NOT - confirm we use the former throughout).
- Five days to deadline. The work split:
    - Day 1 (May 14): PIN entities + use cases + repository abstract (pure-Dart, fully unit-testable).
    - Day 2 (May 15): PBKDF2 implementation + Firestore rules + security-reviewer sign-off pass 1.
    - Day 3 (May 16): Setup flow screens (G-1, G-2, G-3); Settings PRIVACY section UI.
    - Day 4 (May 17): Router redirect clause; `HistoryUnlockScreen`; `historyUnlockedThisSessionProvider` + 5-minute idle logic.
    - Day 5 (May 18): Integration tests + a11y sweep + security-reviewer sign-off pass 2.
    - Buffer (May 19): release tag.

If any day slips, the **first** thing cut is the 5-minute idle window - fall back to "session-lifetime unlock" (D.1) for v1.5 and add the idle window in v1.6. The 5-minute window is a privacy win but not a privacy floor; the gate still functions without it.

## Alternatives Considered

- **No gate, just keep the existing cold-boot gate (WBS 2.2).** Rejected - fails the user request; spouse-with-phone scenario unaddressed.
- **Require biometric for all capable devices, no toggle.** Rejected per Decision A - defaults-ON in a primary feature is a UX regression that we cannot back out of within v1.5.
- **Gate Insights too.** Rejected per Decision B - collides with the disclaimer ack gate; no incremental security benefit.
- **Widget-wrapper enforcement (per-screen `BiometricGate`).** Rejected per Decision C - multiple enforcement points drift; the router-redirect is the single source.
- **Per-access re-prompt (no session unlock at all).** Rejected per Decision D - friction without proportional security.
- **WebAuthn-on-Web in v1.5.** Rejected per Decision E - engineering cost overruns the deadline.
- **Disable gate entirely on Web.** Rejected per Decision E - violates CLAUDE.md "biometric fallback required."
- **PIN stored only locally (SharedPreferences/Keystore), no cloud sync.** Rejected - a reinstall would silently clear the gate, surprising the user. Cloud-stored hash with local verification is the right model.
- **PIN length 4 digits.** Rejected - 6 digits is the modern minimum (10^6 vs 10^4 entropy; 100x the brute-force time at the same iteration count). The numeric keypad UX cost of two extra digits is negligible.

## Compliance Check

- **Clean Architecture domain-zero-imports rule:** satisfied. The new domain entities (`Pin`, `PinSetupFailure`, `PinVerifyFailure`, `PinHashAlgorithm` enum) and use cases (`SetupPinUseCase`, `VerifyPinUseCase`, `ChangePinUseCase`) live in `apps/mobile/lib/features/auth/domain/`. PBKDF2 is invoked through a pure-Dart `PinHasher` abstraction; the concrete implementation in `data/` is the only place that touches `crypto`/`pointycastle`.
- **Enterprise Term Assignment requirements touched:** **R3** (architecture quality - single-source enforcement, clean separation of domain/data); **R5** (security - adds a real second-factor gate with PBKDF2 hashing, salt, rate-limit, and per-user rule isolation, all enumerated above; the security-reviewer audit covers the Firestore rules addition and the PBKDF2 parameters).
- **CLAUDE.md feature-flag rollback (Remote Config kill-switch):** the gate is guarded by a NEW Remote Config flag `history_privacy_lock_enabled` (default `true`). If a critical bug surfaces post-release, flipping the flag to `false` short-circuits the router redirect - users are not locked out, the toggle in Settings is hidden, and the existing-PIN documents remain at rest (no data loss). The redirect callback reads `ref.read(featureFlagsProvider).historyPrivacyLockEnabled` before consulting `historyUnlockedThisSessionProvider`; off → no gate.
- **CLAUDE.md do-not-do list:**
    - `apps/mobile/lib/app/router.dart` - touched (adds a new redirect clause and a new route `/unlock-history` plus `/privacy/setup`). **Architect sign-off: this ADR is the sign-off.**
    - `firebase/firestore.rules` - touched (adds `match /users/{uid}/security/pin`). **security-reviewer sign-off required before merge.** Rules spec: read-by-owner-only; write-by-owner-only with field allow-list (`algorithm`, `iterations`, `saltBase64`, `hashBase64`, `createdAt`, `failedAttempts`, `lockedUntil`); delete denied from clients; `lockedUntil > request.time` blocks reads.
    - `functions/src/*` - NOT touched in v1.5. PIN verification is client-side. WebAuthn (v1.6) will introduce a Cloud Function; that is a future ADR.
    - `apps/mobile/lib/main.dart` - NOT touched.
    - `android/app/build.gradle`, `AndroidManifest.xml` - NOT touched. `local_auth` already declared from WBS 2.2.

## Open follow-ups (for the engineer)

1. Confirm whether `pointycastle` is already in `pubspec.lock` via a `flutter pub deps` run before adding a new dependency. If absent, prefer a hand-rolled PBKDF2 in pure Dart using the `crypto` package's `Hmac` primitive (< 20 lines; testable). Either choice is acceptable; the choice should not block this ADR.
2. Confirm `GoRouter` does not call the `redirect` callback during back-stack pop transitions in a way that would re-trigger an unlock loop. Reviewing the v1.0 cold-boot gate behaviour (which has not exhibited this) is sufficient.
3. The AppLifecycleState observer that resets the unlock on background > 30 s should live in a Riverpod `Notifier` next to `historyUnlockedThisSessionProvider`, NOT in the router file. Keep router lean.
4. The PIN setup flow should NOT be reachable when the user is signed out (the Settings screen already conditions on `user != null` for most tiles - confirm the PRIVACY section is similarly gated).
5. The reviewer agent runs the secret-scan over the new strings - every user-facing copy line in this ADR is intentionally free of clinical terms and CLAUDE.md banned words.
