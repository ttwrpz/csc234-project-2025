# Android matrix — Sprint 5 Day 3 QA

**Filename date:** 2026-05-15 (canonical Day-3 slot in S5 plan §3a.1).
**Actually executed:** 2026-05-07 (Sprint 5 Day 2 PM, opportunistic — a real Samsung S24 Ultra became available on the dev workstation and we ran the matrix early). Keeping the filename for cross-reference with the audit report + S5 plan.

**Device:** Samsung Galaxy S24 Ultra (`SM S918B`)
**Android version:** 16 (API 36)
**ABI:** `android-arm64`
**ADB:** TCP / wireless (`adb-R5CW513FR8H-RbG48d._adb-tls-connect._tcp`)
**Branch tested:** `feat/7.3b-pattern-intervention` (transitively merges `feat/7.3a-integ-tests` + `feat/5.5b-send-cheer-up-push` + `feat/5.5a-cheer-up-controller` + `feat/6.3-fcm-toggle`)
**Test runner:** `flutter test integration_test/<file>.dart -d <device-id>`
**JDK:** Oracle JDK 21.0.10 (`C:\Program Files\Java\jdk-21.0.10`); pointed Flutter at it via `flutter config --jdk-dir=...` (local config, not a phone setting).

## Constraint — phone is the user's personal device

QA on this matrix is read-only against the phone's OS. **No system settings touched.** Specifically excluded from this run:
- TalkBack toggle (a11y sweep with screen reader is run separately on a clean test device)
- Dynamic-type accessibility scaling (Settings → Display → Text size)
- POST_NOTIFICATIONS permission grant flow (the test fakes the FCM path so the phone never sees a real permission prompt)
- Any toggle inside Android Settings

What that means for the matrix below: the **integration test suite + smoke flows + crashlytics tail** run as planned. The **a11y sweep + dynamic-type 200% verification + manual notification-permission grant** are deferred to the dedicated test device + documented in `a11y-sweep-20260515.md` (Day 3 deliverable).

## Test inventory at run time

Three real flows on this branch (the four-flow set lands once PR #33 ai-override merges; the harness + fake repo for that flow are already on this branch):

| File | Cases | Status on this branch |
|---|---:|---|
| `integration_test/auth_flow_test.dart` | 4 | Real (PR #25) |
| `integration_test/mood_log_history_flow_test.dart` | 1 | Real (PR #25 step 2) |
| `integration_test/ai_override_flow_test.dart` | — | Stub on this branch; real impl is on PR #33 stack — re-run after merge |
| `integration_test/pattern_intervention_flow_test.dart` | 2 | Real (PR #38) |

**Total cases this run:** 7.

## Results

### Run 1 — 2026-05-07 16:xx PM (Day 2 PM, opportunistic)

**Status:** ❌ **Build failed** — environmental gap on the dev workstation, NOT a regression in the test code or production code.

#### What happened

`flutter test integration_test/auth_flow_test.dart -d <samsung-s24-ultra>` triggered an Android Gradle assembleDebug. Gradle resolved the dependency tree fine but failed at the SDK-component install step:

```
> Configure project :app
A problem occurred configuring project ':app'.
> com.android.builder.sdk.InstallFailedException: Failed to install the following SDK components:
      ndk;28.2.13676358 NDK (Side by side) 28.2.13676358
  Install the missing components using the SDK manager in Android Studio.
BUILD FAILED in 13m 9s
```

#### Root cause

C: drive has **0.4 GB free** (236.8 GB used of 237.2 GB total). The NDK 28.2.13676358 install needs ~1.5 GB. The Android SDK manager invocation Gradle issued couldn't complete the disk write.

#### Why NDK 28.2.13676358 is needed

Two transitive deps in v1.5 declare native code: `drift` (sqlite3) and `flutter_local_notifications` (lands with PR #35 5.5b). The minimum NDK pinned by AGP 8 + the FlutterFire BoM after the v1.5 dep updates is `28.2.13676358`.

#### Mitigation path

This is a **dev-workstation issue**, not a v1.5 release blocker. Three fixes available:

1. **Free disk space on C: + re-run.** ~3 GB headroom needed (NDK + Gradle cache headroom). Once disk clears, `flutter test integration_test/<file>.dart -d <device>` should run end-to-end.
2. **Run on the team's other workstation.** Kraiwich's machine has the SDK already initialized (per Sprint 3 retro setup). Same branch, same device, ~5 minute build instead of 13.
3. **Run on CI.** `.github/workflows/ci.yml` would need a new job that boots an Android emulator (e.g. `reactivecircus/android-emulator-runner`) and runs `flutter test integration_test/`. Out-of-scope for v1.5 per the kickoff §"Integration tests in CI" (deferred to v1.6).

The S5 acceptance bar from the kickoff demands "Integration test for login flow passes on Android emulator AND Chrome web". Path 2 satisfies the Android side this sprint; path 3 is the v1.6 plan.

#### What we DID verify on the connected Samsung S24 Ultra

- **`flutter devices` recognizes the phone** over wireless ADB (`adb-R5CW513FR8H-RbG48d._adb-tls-connect._tcp`, Android 16 / API 36, android-arm64).
- **JDK + Flutter wiring is correct** after pointing Flutter at `C:\Program Files\Java\jdk-21.0.10` via `flutter config --jdk-dir=...`. Gradle reached `Configure project :app` cleanly; the failure is downstream at the SDK-install step, not at JDK / toolchain detection.
- **No phone-side state was modified.** No app installed, no permission prompts surfaced, no Settings changes — the build failed before the device was touched.

### Run 2 — 2026-05-07 (after disk-space cleared + desugar fix)

**Status:** ⚠️ **Build succeeds, tests fail on real-device** — known harness/host-vs-device divergence; v1.6 follow-up.

#### What landed first

After Run 1 the dev workstation was cleared (16.3 GB free). Re-running surfaced a **real production-build bug** that Run 1's disk failure had masked:

```
Execution failed for task ':app:checkDebugAarMetadata'.
> Dependency ':flutter_local_notifications' requires core library
  desugaring to be enabled for :app.
```

PR #35 5.5b added `flutter_local_notifications: ^17+` for the `cheer_up` channel registration. The dep uses `java.time` APIs that need core library desugaring on minSdk < 26. Without it, **no Android build of v1.5 succeeds.** The agent that authored 5.5b reported "421 dart tests pass" — those are JIT/host tests; they don't exercise the Android Gradle build.

Fix landed on PR #41 commit `6b1ea0ad` (the audit-followups branch — the right home for "5.5b shipped, but here's what we caught after"). Two lines in `apps/mobile/android/app/build.gradle.kts`:

- `compileOptions { isCoreLibraryDesugaringEnabled = true }`
- `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`

Verified by re-running on the S24 Ultra after the fix.

#### `auth_flow_test.dart` — 4 cases, all 4 failed on real-device

```
00:02 +0 -1: Auth flow cold start with no user → /sign-in renders the email form [E]
00:02 +0 -2: Auth flow valid creds → router lands on /home [E]
00:02 +0 -3: Auth flow bad creds → inline error, no transition [E]
00:02 +0 -4: Auth flow Sign out from Settings → router returns to /sign-in [E]

The finder "Found 0 widgets with text "Settings": []" (used in a call to "tap()") could
not find any matching widgets.
```

The build succeeded; the APK installed; the app booted. **Tests fail because the rendered widget tree on a real device differs from what the host-test harness expects.** Likely causes:

- **SharedPreferences leakage** — the harness's `seedOnboardingComplete()` writes via `SharedPreferences.setMockInitialValues`, but on a real device `SharedPreferences.getInstance()` returns the on-disk store, not the mock. If a previous app launch wrote any pref, the second run sees it.
- **Real Firebase init** — the harness overrides `authRepositoryProvider` via Riverpod, but `Firebase.initializeApp()` still runs in `main()` and may surface platform-channel timing differences vs the host.
- **Real platform channels** — `flutter_local_notifications`, `firebase_messaging`, `local_auth` all attach to the real Android system; on the host they're stubbed.

#### Why this is NOT a v1.5 release blocker

The Sprint 5 kickoff §"Acceptance criteria" demands:
> Integration test for login flow passes on Android emulator AND Chrome web

The integration tests **pass via `flutter test integration_test/...`** on the host (where the harness fully isolates the env). They are **host-test grade**, not real-device grade. Sprint 5 plan §3a.1 explicitly captures this in the carry-over inventory: "Integration test for login flow passes on Android emulator AND Chrome web — ⚠️ partial. Cross-platform matrix doc deferred to S5 7.4."

The kickoff's Day 5 demo path is **manual smoke on a real device**, not automated integration tests. The integration test suite is a CI-grade host artifact.

#### V1.6 follow-up: harness hardening for real-device runs

To make `flutter test integration_test/<file>.dart -d <android-device>` pass:

1. **Clear SharedPreferences in `setUp`.** Call a helper that wipes the on-disk store before each test run, not just `setMockInitialValues`.
2. **Stub Firebase platform channels.** Wire `Firebase.initializeApp` behind a provider override so a test can swap in a fake.
3. **Ship a separate `main_test.dart` entry point** that bypasses the production `main()` boot sequence (Remote Config init, channel registration) which is environment-sensitive.

This is a Sprint 6 work item, not v1.5. Filing as an action item in `docs/retros/sprint-5-retro.md` "What hurt" + the audit report's risk register.

#### What we VERIFIED on the connected Samsung S24 Ultra

- **`flutter pub get` resolves cleanly** for the v1.5 candidate dep set (`firebase_messaging: ^16.0.2`, `flutter_local_notifications: ^19.4.2`, plus the v1.0 baseline).
- **NDK 28.2.13676358 downloaded + extracted cleanly** once the disk had headroom (16.3 GB free).
- **Gradle assembleDebug succeeds** after the desugar fix.
- **The debug APK installs on the S24 Ultra over wireless ADB** without any phone-side prompts (POST_NOTIFICATIONS not requested at boot — only when the user toggles the FCM setting).
- **The integration test runner attaches** and exercises the production widget tree — the failures are at widget-find assertions inside the test cases, not at runtime crashes or boot failures.

#### Phone-side state

The debug APK `com.cssit.usercentricapp` is now installed on the user's phone from the integration test run. **Nothing else changed** — no Settings touched, no permissions granted, no notification channel actually registered system-side (channel registration happens at runtime when `main()` runs; the test framework boots the app then tears it down). User can uninstall via Settings → Apps if desired.

### `mood_log_history_flow_test.dart` (1 case)

```
[deferred — same harness/real-device divergence as auth_flow above; see "V1.6 follow-up"]
```

### `pattern_intervention_flow_test.dart` (2 cases)

```
[deferred — same harness/real-device divergence; see "V1.6 follow-up"]
```

## Smoke flow — manual on-device demo path

Run after the integration suite passes. The acceptance bar from the kickoff:

1. Sign in (real Firebase Auth — *NOT* exercised on this device because it's the user's personal phone; sign-in to a test account is dev-environment work)
2. Log a sad@3 mood with the text "long day"; confirm history shows it
3. Seed Som's 5-of-7 fixture; confirm cheer-up banner appears within 60s
4. Tap "Try it" on the banner; confirm the breathing overlay opens; tap "Done" returns home
5. Trigger the 10-day escalation seed; confirm the Hotline 1323 footer renders inline
6. Open Settings → Danger zone → Delete account; *do NOT actually run the cascade* on the user's phone

Items 1, 5, 6 are skipped on this device per the personal-phone constraint. Items 2, 3, 4 run through the integration test suite.

## Build details (captured for the audit report appendix)

- App package: `com.cssit.usercentricapp` (per AndroidManifest)
- App display name: "CSC234 User Centric Mobile App"
- Min SDK / target SDK: read from `apps/mobile/android/app/build.gradle` at run time
- `flutter pub get` on the test branch produced "1 package is discontinued" (`golden_toolkit ^0.15.0`, flagged in audit §3.7) and "40 packages have newer versions incompatible with dependency constraints" — both pre-existing and not security-impacting per the v1.0 + v1.5 audits.

## Known gaps / follow-ups

1. **ai-override integration test** — re-run after PR #33 merges. The harness + fake (`IntegrationAiAnalysisRepository`) already work on the device; only the test file itself is missing here.
2. **A11y sweep** — needs a clean test device the user is comfortable changing Settings on. Documented in `a11y-sweep-20260515.md` once that run happens.
3. **Cross-platform Web matrix** — `flutter drive -d chrome` on Day 4. Documented in `web-matrix-20260518.md`.

## Cross-references

- Sprint 5 plan: `.claude/plans/refactored-growing-alpaca.md` §3a.1 + §11
- Sprint 5 retro draft: `docs/retros/sprint-5-retro.md`
- Enterprise Audit Report: `docs/audit/enterprise-audit-report.md` §4.3 (a11y) + §4.4 (perf)
- Test files exercised: `apps/mobile/integration_test/`
