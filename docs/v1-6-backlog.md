# v1.6 backlog — items deferred from Sprint 5

**Status:** Living document; appended as items surface during Sprint 5.
**Authored:** Sprint 5 Day 5 (post-tag draft).
**Owner:** orchestrator + team (Sprint 6 kickoff revisits).

This doc captures everything Sprint 5 explicitly deferred to v1.6. The Enterprise Audit Report appendix and the Sprint 5 retro both reference it. **Each item has a concrete trigger that surfaced it + a sized estimate so Sprint 6 planning can proceed without re-discovery.**

If you close one of these in v1.6, mark `Closed (date)` + a one-line note. Do not delete the row — the trace matters.

---

## Critical path for v1.6 (≥ 1 day)

### B1 · Web build — re-create conditional Drift connector on v1.5 head

**Trigger:** Sprint 5 Day 4 web matrix Run 1 — `flutter drive -d chrome` failed at `sqlite3-2.9.4` FFI errors. Pre-existing block since S3.

**Background:** A local branch `chore/web-build-conditional-drift` (S3-era, two commits: `2ac4d0f1` conditional connector + `e4000869` Crashlytics `!kIsWeb` gate) carries the fix but **was never merged**. Cherry-pick onto v1.5 head produced 8 file conflicts because S4's wilting / rain-cloud refactor deleted `garden_flower.dart` that the S3 fix touched.

**Approach:** ~~Re-create the fix on the v1.5 head, don't cherry-pick.~~

**✅ Closed (2026-05-08).** While preparing the re-creation, discovered the conditional-import scaffolding was **already on `origin/main`** post-Wave-1 merge train — `mood_database.dart` carries the conditional import (`'mood_database_web.dart' if (dart.library.io) 'mood_database_native.dart'`); `mood_database_native.dart` + `mood_database_web.dart` exist with the canonical native-FFI / throwing-stub pair. `flutter build web --no-tree-shake-icons` completes in ~245s on `origin/main` at `47b15b59` with `√ Built build\web`. The fix landed via a carry-over wrapped into one of the merged PRs without being explicitly called out as an S3 import.

**Reference:** `docs/qa/web-matrix-20260518.md` Run 2; `apps/mobile/lib/features/mood/data/local/mood_database{,_native,_web}.dart` on `origin/main`.

**Remaining v1.6 work** — the build compiles but `flutter drive -d chrome` for the four integration flows is still blocked by **B2 (harness real-device hardening)** below — same SharedPrefs / real-Firebase / real-platform-channels divergence that the Android matrix Run 2 surfaced. Closing B1 unblocks the v1.5 tag's "Chrome web" acceptance bar (build compiles); B2 unblocks the actual flow-level verification on Chrome + Android emulator.

---

### B2 · Integration-test harness real-device hardening

**Trigger:** Sprint 5 Day 3 Android matrix Run 2 on Samsung S24 Ultra — Gradle assembleDebug succeeded after the desugar fix, the APK installed, the runner attached, but **all 4 `auth_flow_test.dart` cases failed** with "could not find any matching widgets". The harness was authored for host context; the real-device boot path differs.

**Three required changes:**

1. **Clear `SharedPreferences` in `setUp`.** The harness uses `SharedPreferences.setMockInitialValues`, but on a real device `getInstance()` returns the on-disk store. Add a helper that wipes `/data/data/<pkg>/shared_prefs/` (or equivalent) before each test run.
2. **Stub Firebase platform channels.** `Firebase.initializeApp()` runs in `main()` and surfaces platform-channel timing differences vs the host. Wire it behind a provider override.
3. **Ship a separate `main_test.dart` entrypoint** that bypasses the production `main()` boot sequence (Remote Config init, channel registration, Crashlytics) which is environment-sensitive.

**Estimate:** 1–1.5 days. qa-engineer + flutter-engineer collaboration.

**Reference:** `docs/qa/android-matrix-20260515.md` Run 2 "V1.6 follow-up" section.

---

### B3 · CI Android emulator job for `flutter test integration_test/`

**Trigger:** S5 plan §3a.1 explicitly deferred this; Sprint 5 ran integration tests via `flutter test` on the host only (which is `widget_test`-grade, not real-emulator-grade).

**Approach:** Add a fourth job to `.github/workflows/ci.yml`:
- Use `reactivecircus/android-emulator-runner@v2` to boot a Pixel-class emulator (API 34 to match the Day-3 Samsung S24 Ultra target).
- Run `flutter test integration_test/<file>.dart -d emulator-5554` for the four flows.
- Cache the AVD between runs so the cold start cost amortises.

**Blocked on:** B2 — without the harness hardening, the emulator job will fail the same way the Day-3 Samsung run did.

**Estimate:** 0.5 day after B2 lands. orchestrator authors the YAML; the team verifies one full run before merging.

---

## Feature gaps (≥ 0.5 day)

### B4 · Biometric reauth for Settings Danger zone

**Trigger:** PR #37 HB-004 step 3. `AuthRepositoryImpl.reauthenticate(BiometricCredentials())` returns `AuthFailure.biometricUnavailable()` because S4's `local_auth` setup doesn't cache a Firebase Auth credential. The Settings Danger zone falls back to password reauth.

**Approach:** Thread the cached credential through `BiometricCredentials` so the data-layer arm can use it. S4's biometric setup uses platform-keystore for the prefs flag only; v1.6 extends that to wrap a `EmailAuthProvider.credential` (or Google `idToken` — depending on the user's last sign-in method) keyed under the same biometric protection.

**Risk:** Storing a Firebase credential in the platform keystore needs a security-reviewer audit because the credential is reauth-equivalent to a password. ADR likely needed.

**Estimate:** 1 day flutter-engineer + 0.5 day security-reviewer.

**Reference:** PR #37 description "Out of scope" section.

---

### B5 · Per-token shape validation as Firestore sub-collection

**Trigger:** HB-003 OQ-A. Firestore rules cannot iterate list elements with arbitrary structure; v1.5 ships a 25-element cap on `users/{uid}/settings/notifications.tokens` plus client-side per-token shape validation. The 25-cap is the only server-side guard.

**Approach:** Model `tokens` as `users/{uid}/settings/notifications/tokens/{tokenId}` so per-token shape (`token: string`, `platform: 'android'|'web'`, `lastSeenAt: timestamp`) can be rule-validated.

**Cost:** Rewrites the FCM token registry shape — touches `notifications_dto.dart`, `fcm_token_repository_impl.dart`, the rules block, and `sendCheerUpPush.ts` (which iterates the tokens list today). Migration script needed for any existing production data — but at v1.5 there is no production data yet, so this is a pre-launch greenfield change.

**Estimate:** 1 day flutter-engineer + emulator rules cases + functions test updates.

**Reference:** HB-003 OQ-A; PR #30 + PR #35 5.5b.

---

### B6 · `analytics_screen` golden test

**Trigger:** S5 plan §3a.2 listed it among the seven missing scenarios; PR #43 closed 6 of 7 but skipped this one because the analytics screen depends on `AIAnalysisRepository` + feature flags + several other providers; scaffolding from scratch is deeper than autonomous budget.

**Approach:** Mirror `garden_screen_golden_test.dart`'s `_pumpGarden` pattern but with `aiAnalysisRepositoryProvider` overridden via a fake that returns canned `PatternInsight` data, plus `featureFlagsProvider` overridden to flip `aiPatternAnalysisEnabled` on.

**Estimate:** 0.5 day qa-engineer.

**Reference:** PR #43 commit message "Out of scope" section.

---

## Hardening (< 0.5 day)

### B7 · Drift encryption-at-rest (`drift_sqlcipher`)

**Trigger:** S3 retro R-6 carry-over. ADR-0004 didn't mandate encryption-at-rest. Sprint 5 plan O10 marked this out-of-scope for v1.5.

**Approach:** Adopt `drift_sqlcipher` package; thread the encryption key through `secure_storage` (already present for biometric prefs); migrate the existing local DB on first launch.

**Risk:** Migration on the user's existing local DB cannot fail — would lose all offline-saved moods. Needs a rehearsal on seeded test data.

**Estimate:** 1 day flutter-engineer + architect ADR.

**Reference:** S3 retro action item; ADR-0004; v1.0 audit §"Open hardening items".

---

### B8 · Web Google OAuth consent screen

**Trigger:** S2 audit R-016 carry-over; explicitly deferred to v2.0 in S5 plan O10. Listed here so it doesn't get lost between v1.5 and any v2.0 planning.

**Approach:** Configure the OAuth consent screen in Google Cloud Console; flip the `kIsWeb` gate in `sign_in_screen.dart`.

**Risk:** None code-side; this is a console configuration step + a UI flag flip.

**Estimate:** 0.25 day DevOps + 0.25 day flutter-engineer for the UI flag + smoke test.

**Reference:** S2 audit R-016; CLAUDE.md "Stack (locked)" — Google Sign-In bullet.

---

## Feature gaps (≥ 1 day) — added v1.5 polish round

### B9 · Biometric gate on History view + WebAuthn fallback for web

**Trigger:** v1.5 user testing (2026-05-09). Mood entries are personal — the user opened History on a shared device and felt exposed. WBS 2.2 already wires `local_auth` for sign-in; that capability isn't surfaced anywhere else in the app.

**Two parts:**

1. **Per-feature biometric guard on `/history` (and `/history/:id`)** — opt-in toggle in Settings → Privacy zone (new). When enabled, opening the History tab from the bottom nav routes through `BiometricGateScreen` first (re-using the existing widget); a session-scoped unlocked flag (similar to `biometricUnlockedThisSessionProvider`) prevents repeated prompts within the same app launch but rolls back on tab-switch-away (configurable: "always require" vs "session"). Calendar view + entry detail follow the same gate.

2. **WebAuthn for web platforms** — `local_auth` is Android/iOS only. Web needs an equivalent: WebAuthn (`navigator.credentials.create/get`) using a platform authenticator (Touch ID on macOS/iOS Safari, Windows Hello on Edge, fingerprint on Chrome Android). Cross-platform package candidates: [`webauthn_dart`](https://pub.dev/packages/webauthn_dart) or a thin `dart:js_interop` wrapper around the browser API. Server-side credential registration would write to `users/{uid}/webauthnCredentials/{credId}` with `{publicKey, createdAt, transports[]}`; rules deny client-side reads of `publicKey` (read-only metadata).

**Risk:** WebAuthn registration needs a real RP ID (`csc234-user-centric-mobile-app.web.app` or the custom domain). Stage: capture in an ADR before any code lands. Also: per CLAUDE.md "Do-not-do list", changes to auth surface require security-reviewer + architect sign-off.

**Estimate:** 1 day flutter-engineer (history gate + Settings toggle + ADR) + 1 day flutter-engineer (WebAuthn integration) + 0.5 day security-reviewer.

**Reference:** v1.5 user testing 2026-05-09 feedback round; WBS 2.2 biometric setup; HB-004 (account-deletion reauth) for the parallel local_auth integration.

---

## Cross-references

- Sprint 5 plan: `.claude/plans/refactored-growing-alpaca.md`
- Sprint 5 retro: `docs/retros/sprint-5-retro.md` (cites this doc in "Action items entering v1.6")
- Audit Report appendix: `docs/audit/enterprise-audit-report.md` §6 (agent challenges + mitigations) cross-references B2, B3, B6
- v1.5 Security Posture supplement: `docs/security/audit-2026-05-19-v1.5.md` (cites B4, B5)
- DevOps follow-ups (production deploy, separate from feature backlog): `docs/runbooks/devops-followups.md`

## Closure protocol

When you close an item in v1.6:

1. Add `**Closed (YYYY-MM-DD)**` after the trigger paragraph.
2. One sentence summarising what was done + linking the PR.
3. Do **not** delete the row — keeps the audit trail intact.
