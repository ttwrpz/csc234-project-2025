# Web (Chrome) matrix — Sprint 5 Day 4 QA

**Filename date:** 2026-05-18 (canonical Day-4 slot in S5 plan §3a.1).
**Actually executed:** 2026-05-07 (Sprint 5 Day 2 PM, opportunistic — paired with the Android matrix Run 2). Keeping the filename for cross-reference with the audit report + S5 plan.

**Browser:** Chrome 147.0.7727.138 (already installed on the dev workstation).
**Branch tested (Run 1):** `feat/7.3b-pattern-intervention` (merges `feat/7.3a-integ-tests` + `feat/5.5b-send-cheer-up-push` per the Android matrix doc).
**Branch tested (Run 2):** `origin/main` at `47b15b59` (post-#38 merge) — the Sprint-3-era conditional-Drift fix turned out to be already integrated.
**Driver:** `apps/mobile/test_driver/integration_test.dart` (NEW — canonical Flutter `integration_test` driver entrypoint added in this run; `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<flow>.dart -d chrome`).

## Run 1 — 2026-05-07 (after the Android matrix attempt)

**Status:** ❌ **Build failed** — pre-existing web-build incompatibility, NOT a v1.5 regression. Same `chore/web-build-conditional-drift` branch that's been carrying the fix since Sprint 3 has not been merged to `main`.

### What happened

`flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_flow_test.dart -d chrome` started a Chrome instance and began compiling the test target. Compilation failed at the `sqlite3` package's FFI bindings:

```
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/sqlite3-2.9.4/lib/src/ffi/generated/native.dart:750:14:
  Error: Only JS interop members may be 'external'.
  Try removing the 'external' keyword or adding a JS interop annotation.
external int sqlite3changeset_apply(
             ^
[~70 similar errors]

Waiting for connection from debug service on Chrome...             52.8s
Failed to compile application.
Application exited before the test started.
```

### Root cause

`drift` (the offline-first SQLite layer added in S3 per ADR-0004) depends on `sqlite3 ^2.9.x` whose FFI bindings declare `external` C functions. Web builds need either:
- A web-only conditional import that swaps in `drift_wasm` / `sql.js` for the `dart:ffi` based connector, OR
- Compile-time tree-shaking that excludes the FFI codepath when `kIsWeb`.

The `apps/mobile/lib/features/mood/data/local/mood_database.dart` factory currently uses the `dart:ffi`-based connector unconditionally.

### Existing-but-unmerged solution: `chore/web-build-conditional-drift`

A local branch named `chore/web-build-conditional-drift` carries the fix:

```
e4000869 fix(s3): gate FirebaseCrashlytics calls on !kIsWeb
2ac4d0f1 fix(s3): conditional Drift connector — flutter build web now succeeds
fddf5983 chore(gitignore): anchor /android/ and /ios/ to root...
```

The branch is dated Sprint 3 (per the commit prefix) but **has never been merged to `main`**. This is an audit miss carried across S3 / S4 / S5: the team has been shipping web-broken builds for ~2 sprints without flag-day awareness.

### Why this is NOT new in v1.5

The `sqlite3` FFI errors are pre-existing. v1.5's `firebase_messaging`, `flutter_local_notifications`, and `cloud_functions` deps all support web cleanly (verified by inspecting their pubspec `platforms:` blocks). The blocker is the v0.3-beta-era Drift wiring.

### What this means for the kickoff acceptance bar

The kickoff §"Acceptance criteria" demands:
> Integration test for login flow passes on Android emulator AND Chrome web

The "Chrome web" half is currently **infeasible to verify** without merging `chore/web-build-conditional-drift` first. Three paths:

1. **Pre-tag merge.** Cherry-pick `2ac4d0f1` + `e4000869` onto `main` before the v1.5 tag. ~30 min including review. Lets the kickoff acceptance bar be honestly checked.
2. **Re-scope acceptance.** Note in the v1.5 retro + Audit Report risk register that "AND Chrome web" was carried unverified across S3+S4+S5 due to an unmerged hotfix; defer to v1.6.
3. **Tag v1.5 anyway.** Demo on Android only; document the web build as known-broken in `docs/runbooks/devops-followups.md`.

Recommendation: **Path 1**. The fix exists, the work is done, the merge is mechanical. The audit miss should not propagate into v1.5 by inaction.

### Cherry-pick attempt — too-deep-for-autonomous-resolution (HISTORICAL, superseded by Run 2)

**2026-05-07 follow-up.** Attempted `git cherry-pick 2ac4d0f1 e4000869` from `chore/web-build-conditional-drift` onto `main`. **8 file conflicts** because the S3-era branch predates S4's wilting/rain-cloud refactor:

```
UU apps/mobile/lib/features/garden/domain/usecases/compute_garden_state.dart
UU apps/mobile/lib/features/garden/presentation/garden_screen.dart
DU apps/mobile/lib/features/garden/presentation/widgets/garden_flower.dart
UU apps/mobile/lib/features/mood/presentation/controllers/log_mood_controller.dart
UU apps/mobile/test/features/garden/domain/usecases/compute_garden_state_test.dart
UU apps/mobile/test/features/garden/presentation/garden_screen_test.dart
UU apps/mobile/test/features/garden/presentation/widgets/weekly_bloom_bar_test.dart
UU apps/mobile/tool/check_domain_coverage.dart
```

The `DU` on `garden_flower.dart` (S4 deleted that widget when wilting plants + rain clouds replaced the flat flower model) is the load-bearing conflict — resolving it requires deciding whether the S3 fix's drive-by edits to `garden_flower.dart` should propagate into the new `flora_sprite.dart` etc. That's a deep three-sprint integration question.

**Better approach for v1.5:** **re-create** the conditional-Drift fix on the v1.5 head from scratch. The semantic change is small:

1. Make the Drift connector conditional: `apps/mobile/lib/features/mood/data/local/mood_database.dart` swaps in a stub on `kIsWeb` (or uses `dart.library.io` vs `dart.library.html` conditional imports).
2. Wrap Crashlytics calls in `if (!kIsWeb)` per the second commit's pattern.

Estimated: 30 min if done by someone who knows the current Drift wiring (i.e. Kraiwich). Out-of-scope autonomous because incorrect resolution risks the offline-first invariant (Drift carries the local mood store + sync queue + intervention anchors mirror).

### Run 2 — 2026-05-08 — `flutter build web` succeeds

**Status:** ✅ **Build succeeds on `origin/main` post-#38 merge.**

When I went to re-create the conditional-Drift fix, I discovered the scaffolding was **already on `main`**. Some prior PR (likely a carry-over wrapped into one of the merged PRs) had already integrated:

```
apps/mobile/lib/features/mood/data/local/mood_database.dart
  → conditional import: 'mood_database_web.dart' if (dart.library.io) 'mood_database_native.dart'

apps/mobile/lib/features/mood/data/local/mood_database_native.dart  (new)
  → NativeDatabase via dart:ffi + path_provider

apps/mobile/lib/features/mood/data/local/mood_database_web.dart  (new)
  → throwing-stub LazyDatabase; the offline-first guard never invokes it on web
```

`flutter build web --no-tree-shake-icons` completes in **~245 s** with output `√ Built build\web` and only the expected wasm-dry-run warnings.

**This closes v1.6 backlog item B1 ahead of schedule.** The kickoff acceptance bar's "AND Chrome web" half is now **verifiable for v1.5** — though Run 2 only confirms the build compiles. The integration tests themselves (`flutter drive -d chrome` for the four flows) remain a separate exercise, blocked by the same harness/host-vs-device divergence that v1.6 backlog B2 captures (real platform channels diverge from the host-test scaffolding).

### Run 3 — pending

Re-run `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<flow>.dart -d chrome` for each of the four flows once B2 (harness real-device hardening) lands. v1.6 work.

## Run 2 — pending

After `chore/web-build-conditional-drift` lands on `main` (path 1), re-run this matrix and append results below:

### `auth_flow_test.dart` (4 cases)

```
[pending — re-run after web-build fix merges]
```

### `mood_log_history_flow_test.dart` (1 case)

```
[pending]
```

### `pattern_intervention_flow_test.dart` (2 cases)

```
[pending]
```

## What we VERIFIED on Chrome 147 (despite the build failure)

- **`flutter drive` driver entrypoint added** at `apps/mobile/test_driver/integration_test.dart` per the canonical Flutter pattern. Works for Android and web — single one-liner.
- **Chrome 147 is the dev-workstation default** and is recognized by `flutter devices`.
- **Test target compilation is reached** (the sqlite3 FFI error happens inside the dart2js compile pass, after the harness imports succeed). This means the `integration_test/<flow>.dart` files are syntactically valid for web; only the production-code dependency tree is web-incompatible.

## Build details

- Driver entrypoint: `apps/mobile/test_driver/integration_test.dart` (1 line — `Future<void> main() => integrationDriver();`)
- Compilation duration before failure: 52.8s
- Errors: ~70 instances of "Only JS interop members may be 'external'" against `sqlite3-2.9.4/lib/src/ffi/generated/native.dart`

## Cross-references

- Sprint 5 plan: `.claude/plans/refactored-growing-alpaca.md` §3a.1 + §11 risk #2 (cross-platform divergence)
- Sprint 3 retro: `docs/retros/sprint-3-retro.md` (Drift offline-first per ADR-0004)
- Existing-but-unmerged fix branch: `chore/web-build-conditional-drift` (HEAD `e4000869`)
- Android matrix companion: `docs/qa/android-matrix-20260515.md`
- Sprint 5 retro draft: `docs/retros/sprint-5-retro.md` (this finding feeds "What hurt")
- Audit report: `docs/audit/enterprise-audit-report.md` §4.1 + §6 (cross-platform gaps)
