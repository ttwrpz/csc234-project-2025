# Merge Privacy Lock into Biometric System → unified "Privacy Lock" feature

> **Window:** 2026-05-25 (single-day polish task on `feat/s5-v1.5-final`).
> **Approved:** 2026-05-25 15:04 ICT, after a Plan-Mode session with 3 parallel `Explore` agents + 4 `AskUserQuestion` design-decision branches.
> **Scope:** post-v1.5 polish - consolidating two parallel security features that emerged from S2 (biometric gate) and S5 ADR-0013 (History Privacy Lock) into one unified cold-boot Privacy Lock.

## Context

Today we ship **two parallel security features** that confuse each other:

1. **Biometric gate** (Sprint 2 / WBS 2.2) - fires on cold boot; biometric-only, no PIN; opt-in via `BiometricSettingsTile` in the SECURITY zone of Settings; routes to `/biometric-gate`.
2. **History Privacy Lock** (Sprint 5 / v1.5 / ADR-0013) - fires when navigating to `/history*`; biometric-first + PIN fallback; opt-in via `PrivacySettingsTile` in the PRIVACY zone; routes to `/unlock-history`; gated by Remote Config flag `history_privacy_lock_enabled` so it can be rolled back.

This split causes three concrete problems:

- **User cognitive load**: two switches in Settings that look almost identical ("Use biometric to unlock" vs "Require unlock to view history"), two unlock screens, two session-unlock providers (`biometricUnlockedThisSessionProvider` + `historyUnlockedThisSessionProvider`) that constantly hedge against each other to avoid double-prompts.
- **Cold-boot flash-of-home**: `biometricCapabilityProvider` is a `FutureProvider` whose `.value` the router redirect reads **synchronously** at `router.dart:140`. On the first redirect pass the value is `null`, the gate is skipped, the user sees `/home` for one frame, and the gate only fires on the *next* router refresh once the FutureProvider resolves. The comment at `router.dart:134-136` acknowledges this race.
- **Remote Config gating treats the feature as experimental**: the v1.5 spec called Privacy Lock optional / rollback-able. The user wants it to be a real, non-experimental, always-on feature.

The intent of this change is to **merge the two features into one feature called "Privacy Lock"** with biometric as the primary verification method and PIN as the mandatory fallback, protecting the whole app on cold boot, with no Remote Config flag, fully initialized before `runApp()` so the home screen never paints behind a stale lock.

---

## Design decisions (locked by user)

| Question | Decision |
|---|---|
| Scope | **Whole app on cold boot.** One gate. After unlock, History is reachable like any other route. No idle re-lock. |
| PIN required? | **Yes, always.** Enabling Privacy Lock forces a PIN setup. PIN is the universal fallback. |
| Init strategy | **Block `runApp()`** - pre-resolve biometric capability + SharedPreferences in `main.dart` and pass them in as `ProviderScope` overrides. Router redirect reads sync values. No `FutureProvider` race. |
| Migration | **Force PIN setup for existing biometric-opt-in users** on first post-upgrade launch. |

---

## Implementation plan

The merged feature is called **Privacy Lock**. Biometric is the primary verification method *inside* Privacy Lock; PIN is the mandatory fallback. The two existing gates collapse into one cold-boot gate. Existing PIN domain/data code (PBKDF2, Firestore `users/{uid}/security/pin`, rate-limit ladder, all use cases) is **kept as-is** - none of that needs to change. What changes is the *orchestration layer*: providers, router, settings UI, init, tests.

### 1. Eliminate the Remote Config flag

- **`apps/mobile/lib/app/feature_flags.dart`** - drop `historyPrivacyLockEnabled` field from `FeatureFlags` (and its default).
- **`apps/mobile/lib/main.dart:96`** - drop `'history_privacy_lock_enabled': true` from `rc.setDefaults(...)`.
- **`firebase/remoteconfig.template.json`** - remove the `history_privacy_lock_enabled` entry.
- **`apps/mobile/lib/features/auth/data/providers.dart:266-270`** - delete `privacyLockMasterEnabledProvider`.
- **CLAUDE.md "Feature flag (rollback plan)" section** - update narrative: this flag now gates only the Tier 1/2 Gemini quote path (`ai_pattern_analysis_enabled`), no longer the privacy gate.
- **`apps/mobile/test/app/feature_flags_test.dart`** - drop assertions touching `historyPrivacyLockEnabled`.

### 2. Unify the two session-unlock providers into one

Today: `biometricUnlockedThisSessionProvider` (StateProvider<bool>) + `historyUnlockedThisSessionProvider` (Notifier with 5-min idle / 30s background reset). The second one exists because the History gate had its own session lifecycle.

**Collapse into one provider:** `privacyLockUnlockedThisSessionProvider` - a simple `StateProvider<bool>` (like today's biometric flag). Flips `true` on successful unlock, resets to `false` on sign-out, **no** idle timer (whole-app cold-boot scope, per user decision #1).

- **Delete** `apps/mobile/lib/features/auth/data/history_unlocked_this_session_provider.dart` entirely (the WidgetsBindingObserver lifecycle work is no longer needed).
- **Rename** `biometricUnlockedThisSessionProvider` → `privacyLockUnlockedThisSessionProvider` at `providers.dart:180`.
- **Update all 6 callers** (grep result):
  - `apps/mobile/lib/app/router.dart` (cold-boot redirect clause)
  - `apps/mobile/lib/features/auth/presentation/biometric_gate_screen.dart` (set on unlock)
  - `apps/mobile/lib/features/auth/presentation/screens/pin_verify_screen.dart` (set on unlock)
  - `apps/mobile/lib/features/auth/data/providers.dart` (definition)
  - `apps/mobile/lib/features/auth/data/history_unlocked_this_session_provider.dart` (deleted)

### 3. Pre-resolve everything in `main.dart` - eliminate the init race

Today `main.dart:179-180` eagerly resolves SharedPreferences for theme. Extend that pattern to also eagerly resolve biometric capability + privacy-lock opt-in, then hand them to `ProviderScope` as overrides.

**`apps/mobile/lib/main.dart`** - after the existing `SharedPreferences.getInstance()` at line 179, add:

```dart
// Pre-resolve Privacy Lock state BEFORE runApp so the router redirect
// reads synchronous values on the very first pass. Without this, the
// biometric capability provider is a FutureProvider whose .value is
// null on first redirect, the gate is skipped, and the user sees the
// home screen for one frame before the gate fires.
final biometricRepo = BiometricRepositoryImpl(
  datasource: BiometricDatasource(),
  preference: BiometricPreferenceDatasource(prefs),
);
final cap = await biometricRepo.capability();
final privacyLockEnabled =
    PrivacyLockPreferenceDatasource(prefs).isEnabled();
```

Then in the `ProviderScope.overrides:` list (currently lines 184-188), add:

```dart
biometricCapabilityProvider.overrideWith((ref) async => cap),
privacyLockEnabledProvider.overrideWith(
  () => _SeededPrivacyLockEnabledNotifier(privacyLockEnabled),
),
privacyLockUnlockedThisSessionProvider.overrideWith((_) => false),
```

(The seeded notifier is one tiny `Notifier<bool>` subclass that returns the pre-resolved bool from `build()` and then delegates `set()` to SharedPreferences - same shape as today's `PrivacyLockEnabledNotifier`, just with the build value injected.)

**Result**: from the very first frame, the router redirect reads `ref.read(biometricCapabilityProvider).value` and gets a real `BiometricCapability` instance, not `null`. No FutureProvider race, no flash-of-home.

**Cost**: ~50-150ms added to cold start (one platform call to `local_auth` + one SharedPreferences read). Acceptable per user decision #3 and consistent with the existing theme-eager-resolve precedent.

### 4. One unlock screen replaces two

Today we have two unlock screens with overlapping logic (`biometric_gate_screen.dart` does biometric-only; `pin_verify_screen.dart` does biometric+PIN). The PIN-verify screen at `apps/mobile/lib/features/auth/presentation/screens/pin_verify_screen.dart` is already the strict superset - it does biometric **then** PIN fallback.

- **Rename file** `pin_verify_screen.dart` → `privacy_lock_screen.dart`; rename class `PinVerifyScreen` → `PrivacyLockScreen`.
- **Delete** `apps/mobile/lib/features/auth/presentation/biometric_gate_screen.dart` entirely.
- **Update** the screen's app-bar title from `'Privacy lock'` (already correct) and body copy `'Unlock your journal'` → `'Unlock MoodBloom'` (since scope is whole-app, not journal).
- **Default `returnTo`** is `'/home'` (was `'/history'`).
- **Route consolidation in `router.dart:230-247`**:
  - Delete `GoRoute('/biometric-gate', ...)`.
  - Delete `GoRoute('/unlock-history', ...)`.
  - Add `GoRoute('/privacy-lock', pageBuilder: (c, s) => _noTransition(PrivacyLockScreen(returnTo: s.uri.queryParameters['returnTo'])))`.
- The "Sign out instead" affordance from `biometric_gate_screen.dart:101-108` moves into `privacy_lock_screen.dart` (so cold-boot users still have an exit hatch). The "Back to home" appbar button at `pin_verify_screen.dart:198-202` is removed - there's no home to go back to when this is the cold-boot gate.

### 5. Router redirect collapses to one gate

In `apps/mobile/lib/app/router.dart`:

- **Delete the entire History-gate clause** (lines 154-209). One gate, one screen.
- **Update the cold-boot gate** (lines 131-152): condition becomes `if user is signed in AND privacyLockEnabled AND not already unlocked → redirect to /privacy-lock`. The `cap.shouldGate` check is gone - Privacy Lock is mandatory-when-enabled per user decision #2, not contingent on biometric hardware (PIN is the universal fallback).

New redirect logic (pseudocode):

```dart
if (refresh.value != null &&
    loc != '/privacy-lock' &&
    ref.read(privacyLockEnabledProvider) &&
    !ref.read(privacyLockUnlockedThisSessionProvider)) {
  return '/privacy-lock?returnTo=${Uri.encodeComponent(loc)}';
}
```

Note: `privacy/setup` modal route is still exempt (so toggling ON from Settings doesn't trigger the lock mid-setup).

### 6. One settings tile replaces two

Today `settings_screen.dart` has SECURITY zone with `BiometricSettingsTile` AND PRIVACY zone with `PrivacySettingsTile`. Both go away; one new tile takes their place.

- **Delete** `apps/mobile/lib/features/auth/presentation/widgets/biometric_settings_tile.dart`.
- **Rename + rewrite** `apps/mobile/lib/features/auth/presentation/widgets/privacy_settings_tile.dart` → `privacy_lock_settings_tile.dart`. New behavior:
  - Single switch: **"Privacy Lock"** with subtitle that adapts to state ("Use biometric or PIN to unlock the app" / "Set up a PIN to enable" / "Add a fingerprint or face on your device for faster unlock").
  - Toggling ON: push `/privacy/setup` modal. On success (PIN set + biometric verified if available), persist enabled = true. Biometric opt-in is **bundled** - if hardware is present, the setup flow auto-runs the OS prompt and persists biometric opt-in too.
  - Toggling OFF: persist enabled = false; invalidate PIN via `removePinUseCase`; also reset biometric opt-in via `setBiometricOptInUseCase(false)`. One-shot disable.
  - Tile below the switch when ON: **"Change PIN"** (always shown if enabled; no need for the loading variant since `pinIsSetProvider` is implicit-true when enabled).
- **`settings_screen.dart` lines 169-201**: delete the entire SECURITY MbCard wrapping `BiometricSettingsTile`. The PRIVACY zone keeps its label but now holds the new `PrivacyLockSettingsTile`. Drop the `ref.watch(privacyLockMasterEnabledProvider)` conditional.

### 7. Setup flow updated to bundle biometric

`privacy_setup_flow_screen.dart` already runs biometric verify → PIN setup → done. Adjust:

- **Biometric step**: if hardware is available but user hasn't opted in to biometric, this is where opt-in happens (call `setBiometricOptInUseCaseProvider(true)` on success). The setup flow becomes the *single source of truth* for opting into biometric.
- If hardware is unavailable: skip biometric step, go straight to PIN setup.
- The PIN setup step is **mandatory** per user decision #2 - there's no path to enable Privacy Lock without a PIN.

### 8. Migration for existing biometric-opt-in users

In `main.dart`, after `prefs` is loaded, check a migration flag:

```dart
const _privacyLockV2MigratedKey = 'auth.privacy_lock_v2_migrated';
if (!prefs.getBool(_privacyLockV2MigratedKey) ?? false) {
  final hadBiometricOptIn =
      BiometricPreferenceDatasource(prefs).isEnabled();
  if (hadBiometricOptIn) {
    // Old biometric-only users: keep biometric opt-in but force-mark
    // Privacy Lock as not-yet-enabled. On first post-upgrade launch,
    // they'll see /home like normal; the new PrivacyLockSettingsTile
    // in Settings will show OFF, and the next time they want the lock
    // they go through the unified setup flow.
    //
    // (We do NOT auto-enable Privacy Lock without a PIN - PIN setup
    // requires user input, can't happen in main().)
  }
  await prefs.setBool(_privacyLockV2MigratedKey, true);
}
```

Plus a **one-time card** on `/home` for migrated users (gated by a separate SharedPreferences flag `auth.privacy_lock_v2_card_dismissed`) explaining: *"Privacy Lock now uses both biometric and PIN. Tap to set up."* Tapping routes to `/privacy/setup`. Dismissable.

This is gentler than a hard block - biometric-opt-in users don't lose their lock; they just see one explanatory card prompting them to add the PIN that's now required.

### 9. Test migration

The PIN domain/data tests (`pin_hasher_impl_test.dart`, `pin_hash_test.dart`, `pin_use_cases_test.dart`, `fake_pin_repository.dart`) stay as-is - the PIN substrate didn't change.

The biometric domain/data tests stay as-is for the same reason.

What changes:

- **`apps/mobile/test/features/settings/presentation/settings_screen_test.dart:114`** - remove `privacyLockMasterEnabledProvider.overrideWith((_) => false)` (provider no longer exists). The SECURITY zone tile is gone; tests asserting its presence must be updated to assert the renamed `PrivacyLockSettingsTile` in the PRIVACY zone.
- **`apps/mobile/test/features/settings/presentation/a11y/settings_screen_a11y_test.dart`** - same updates.
- **`apps/mobile/test/app/feature_flags_test.dart`** - drop assertions referencing `historyPrivacyLockEnabled`.
- **`apps/mobile/integration_test/app_harness.dart:68-74`** - the `biometricCapabilityProvider` override stays. **Add** `privacyLockEnabledProvider.overrideWith((_) => _AlwaysFalseNotifier())` and `privacyLockUnlockedThisSessionProvider.overrideWith((_) => true)` so integration flow tests don't trip the new cold-boot gate. (Mirrors today's harness pattern of pre-seeding session state to bypass gates.)
- **Add a router widget test** at `apps/mobile/test/app/router_privacy_lock_test.dart` covering: (a) cold boot with Privacy Lock OFF → lands on /home; (b) cold boot with Privacy Lock ON but unlocked → lands on /home; (c) cold boot with Privacy Lock ON and not unlocked → redirects to /privacy-lock; (d) sign-out clears the unlock flag.

### 10. Firestore rules - no change needed

The `users/{uid}/security/pin` rule (firebase/firestore.rules:319-381) is unchanged. The merge is purely client-side orchestration; the at-rest PIN format and Firestore rules are identical.

### 11. Documentation updates

- **`docs/adr/0013-biometric-gating-for-mood-history-access.md`** - append a "Superseded by" header pointing at a new ADR.
- **`docs/adr/0014-webauthn-fallback-for-history-privacy-gate.md`** - update narrative: scope is now "Privacy Lock" (whole app), not History.
- **New ADR `docs/adr/0015-privacy-lock-unification.md`** - record this merge decision, the four locked design decisions, and the migration approach.
- **CLAUDE.md** - update the "pivot features" list and the "Feature flag (rollback plan)" section to reflect that `history_privacy_lock_enabled` no longer exists.

---

## Files to modify (representative - pattern repeats)

**Production code (renames + edits):**

- `apps/mobile/lib/main.dart` - pre-resolve capability + opt-in; add ProviderScope overrides; migration check; remove RC flag default.
- `apps/mobile/lib/app/router.dart` - collapse to one gate; remove history clause; rename screen + route.
- `apps/mobile/lib/app/feature_flags.dart` (+ `.freezed.dart` regen) - drop `historyPrivacyLockEnabled`.
- `apps/mobile/lib/features/auth/data/providers.dart` - rename session provider; drop master provider.
- `apps/mobile/lib/features/auth/data/history_unlocked_this_session_provider.dart` - **delete**.
- `apps/mobile/lib/features/auth/presentation/biometric_gate_screen.dart` - **delete**.
- `apps/mobile/lib/features/auth/presentation/screens/pin_verify_screen.dart` → rename to `privacy_lock_screen.dart` + update copy.
- `apps/mobile/lib/features/auth/presentation/widgets/biometric_settings_tile.dart` - **delete**.
- `apps/mobile/lib/features/auth/presentation/widgets/privacy_settings_tile.dart` → rename to `privacy_lock_settings_tile.dart` + bundle biometric opt-in.
- `apps/mobile/lib/features/auth/presentation/screens/privacy_setup_flow_screen.dart` - bundle biometric opt-in into the setup flow.
- `apps/mobile/lib/features/settings/presentation/settings_screen.dart` - drop SECURITY zone; rewire PRIVACY zone to the new tile.
- `firebase/remoteconfig.template.json` - drop the flag entry.

**Tests (renames + edits):**

- `apps/mobile/test/features/settings/presentation/settings_screen_test.dart` + a11y twin - drop master-flag override; update tile-name assertions.
- `apps/mobile/test/app/feature_flags_test.dart` - drop the flag.
- `apps/mobile/integration_test/app_harness.dart` - add `privacyLockEnabledProvider` + `privacyLockUnlockedThisSessionProvider` overrides.
- **New** `apps/mobile/test/app/router_privacy_lock_test.dart` - cold-boot gate behavior matrix.

**Generated code:**

- Run `flutter pub run build_runner build --delete-conflicting-outputs` after editing `feature_flags.dart`.

---

## Reused (do NOT touch)

- All PIN domain/data code (`pin.dart`, `pin_hash.dart`, `pin_hasher.dart`, `pin_hasher_impl.dart`, `pin_repository.dart`, `pin_repository_impl.dart`, `pin_firestore_datasource.dart`, all use cases).
- All biometric domain/data code (`biometric_capability.dart`, `biometric_datasource.dart`, `biometric_preference_datasource.dart`, `biometric_repository_impl.dart`, all use cases).
- `pin_setup_screen.dart` + `pin_keypad.dart` (the keypad widget is fine).
- Firestore rules.

---

## Verification

1. **`flutter analyze`** in `apps/mobile/` - must be clean. Any leftover reference to the deleted providers or screens will surface.
2. **`flutter test`** - full unit + widget suite. Domain coverage ≥80% per CLAUDE.md quality gate. Expect updates to ~5 test files; the rest should pass unchanged.
3. **`flutter test integration_test/ -d chrome`** and **`-d android`** - the four real flows must still pass with the harness updates.
4. **Manual cold-boot check** on Android + Chrome:
   - Fresh install, Privacy Lock disabled → app launches straight to /home, no flash. ✔
   - Fresh install, sign in, enable Privacy Lock from Settings → PIN setup flow → toggle persists. ✔
   - Force-stop → re-open → lands on `/privacy-lock`, biometric prompt fires immediately, PIN keypad visible underneath; either path unlocks to /home. **No frame of /home before the gate.** ✔
   - Sign out → sign back in → lock fires again (session flag reset). ✔
5. **Migration check**: install previous build (biometric-only), enable biometric, sign in, then install the new build. Verify the one-time "Privacy Lock now uses both biometric and PIN" card appears on /home and routes to setup on tap.
6. **Firestore rules emulator** - `firebase emulators:exec --only firestore "flutter test integration_test/firestore_rules_test.dart"` - no rule changes expected, so this is regression-only.
