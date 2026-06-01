# Sprint 5 - Cross-Platform + Performance Runbook (Day 4)

**Owner:** Theerawat (orchestrator) - run locally before v1.5 tag.
**Audit head:** `f38408c1`.
**Prereqs:** Android emulator (Pixel 6 API 34) booted; Chrome stable installed; `flutter doctor` shows no missing platforms.

This runbook is the manual half of Day 4. The static portions (security re-audit, static perf review, a11y sweep) are already complete in CI-trackable commits; this document covers the parts that need a real device.

## Branch to check out

```powershell
git switch feat/s5-d3-a11y-new-surfaces   # latest S5 head: f38408c1
```

If you want the skin system in scope (`a87a347d` + `11b66274` on `feat/s5-d2-skin-widget-tests`), prepare an integration branch first:

```powershell
git switch -c feat/s5-d4-integration feat/s5-d3-a11y-new-surfaces
git merge --no-ff feat/s5-d2-skin-widget-tests
# resolve any merge conflicts in pubspec / generated files
flutter pub run build_runner build --delete-conflicting-outputs
flutter test       # confirm everything still passes
```

The cross-platform run is most meaningful against the **integration branch** so screenshots include the skin system. If short on time, run against `feat/s5-d3-a11y-new-surfaces` and screenshot the skin system separately from its own branch.

## Part 1 - Cross-platform integration tests

### Android emulator

```powershell
# Boot emulator
& "$env:ANDROID_HOME\emulator\emulator.exe" -avd Pixel_6_API_34 &

# Verify connection
flutter devices
# expect: Android SDK built for x86_64 (emulator) listed

# Run the full integration test suite
cd apps\mobile
flutter test integration_test\ -d emulator-5554
```

Expected: all 18 integration tests in `intervention_tier_1_2_test.dart`, `intervention_tier_3_test.dart`, `auth_smoke_test.dart`, `mood_log_smoke_test.dart`, `ai_override_test.dart`, `harvest_cycle_test.dart` pass.

**TC-40 hard assertion:** `intervention_tier_3_test.dart` asserts `aiRepo.calls.isEmpty` after a Tier 3 dispatch. If this fails on Android, **block the v1.5 tag** - ADR-0012 invariant violated.

If `flutter drive` syntax is preferred (existing convention from `auth_flow_test.dart` et al):

```powershell
flutter drive `
  --driver=test_driver\integration_test.dart `
  --target=integration_test\intervention_tier_3_test.dart `
  -d emulator-5554
```

Repeat for each integration_test/*.dart file.

### Chrome web

```powershell
flutter devices
# expect: Chrome (web) listed

cd apps\mobile
flutter drive `
  --driver=test_driver\integration_test.dart `
  --target=integration_test\intervention_tier_3_test.dart `
  -d chrome
```

Note: per the agent reports on Day 3, web devices may not yet support the `integration_test` plugin in your Flutter version. If `flutter drive -d chrome` reports "Web devices are not supported for integration tests," fall back to **manual** Chrome smoke testing using the demo script below.

If integration tests run successfully on Chrome, repeat for all 6 integration test files.

### Document with screenshots

For each test target (Android emulator + Chrome web):

1. App home (Garden) - light theme + dark theme + each atmosphere (sunny / calm / light-rain / storm).
2. Log Mood - pick joy intensity 4, attach a photo.
3. History - list view + calendar view.
4. Insights - pre-ack dialog (first view) + post-ack chart with seeded 14d data.
5. Settings - preferences zone showing 3 tier toggles.
6. Account → Delete account → both dialog steps.
7. Intervention banner (Tier 1) - Open → BreathingScreen mid-cycle.
8. Intervention banner (Tier 2) → JournalingPromptScreen.
9. Intervention banner (Tier 3) → CrisisResourcesScreen with Hotline 1323 tile.
10. Skin system: SkinModalSheet with one locked + one unlocked skin.

Save screenshots to `docs/test-reports/screenshots/v1.5/android/` and `.../chrome/`. Naming: `<screen>-<theme>-<atmosphere>.png` (e.g. `garden-light-storm.png`).

## Part 2 - Performance profile

### Cold start measurement

```powershell
cd apps\mobile
flutter run --profile --trace-startup -d emulator-5554
# wait for "Tracing startup completed"
```

Open `apps\mobile\build\start_up_info.json`. The fields to extract:

- `timeToFirstFrameMicros` - first frame to be rendered.
- `timeToFrameworkInitMicros` - Flutter engine ready.
- `timeAfterFrameworkInitMicros` - time from framework-ready to first frame.

**CLAUDE.md target:** `timeToFirstFrameMicros < 2_000_000` (2 seconds) on mid-range Android. Pixel 6 emulator is faster than mid-range; aim for < 1.5s here so a real mid-range device has headroom.

Record the numbers in the Audit Report. Run 3 cold starts (kill + relaunch each time) and report the median.

### Frame-rate trace (Insights chart scroll)

```powershell
flutter run --profile -d emulator-5554
# in the running app:
# 1. sign in
# 2. seed 30-day mood history via the dev-only "seed" tile (Settings > Debug)
# 3. open Insights tab
# 4. ack the disclaimer dialog
# 5. scroll the chart vigorously for 10 seconds
# 6. press 'P' in the terminal to capture a frame timeline
```

The frame timeline is saved as `apps\mobile\build\<timestamp>.timeline.json`. Open it in Chrome → `chrome://tracing/` (or DevTools' Performance tab). Look for:

- **Median frame time < 16.7 ms** (60fps target).
- **No frames over 33.4 ms** (sub-30fps jank).
- **P-L01 follow-up** - check `breathing_screen.dart`'s `AnimatedBuilder` rebuild cost. If the breathing-circle frame budget exceeds 8ms, file the split-AnimatedBuilder fix from `sprint-5-perf-static-review.md`.

### Memory growth (50-entry harvest cycle)

Manually drive the app through a 50-entry harvest cycle:

```powershell
flutter run --profile -d emulator-5554
# in the running app:
# 1. sign in to a test account
# 2. log 50 mood entries across 7 days (use the dev-only seed tile to accelerate)
# 3. wait for the harvest cycle (or manually trigger via the harvest debug tile)
# 4. open DevTools (press 'd' in the terminal, follow the URL)
# 5. switch to Memory tab
# 6. take a snapshot before the harvest, after the harvest, and 30 seconds later
```

Compare the three snapshots. The harvest cycle should:
- Reduce live entry references (the archived week's `MoodEntry` instances should be eligible for GC).
- Not accumulate `_LatestCombiner` instances from `InsightsRepositoryImpl` (the rxdart-replacement combinator the Insights agent built - verify it disposes correctly on widget unmount).
- Not retain canceled `StreamSubscription`s - check the intervention controller's `_patternSub` is cancelled on auth-state changes.

If you see steady memory growth across 3 harvest cycles, file a v1.6 leak finding.

## Part 3 - Manual cross-platform QA (no test framework)

For each platform (Android emulator, Chrome desktop, Chrome on Android), run the **v1.5 demo script** end-to-end:

1. Fresh install → sign up flow → onboarding slides → Garden.
2. Log mood `Joy intensity 4` with photo attachment → see flower bloom on Garden.
3. View History → tap the new flower → entry detail opens.
4. Settings → Notifications → toggle each of the 3 tier switches; verify they persist.
5. Settings → About → confirm the full disclaimer text is verbatim from spec §4 (TC-39).
6. Trigger Tier 1: seed a steadily-declining 14-day window via the dev-only seed tile.
7. Wait for the banner. Tap Open → BreathingScreen runs through a 2-minute cycle.
8. Trigger Tier 2: seed 5/7 negative days.
9. Tier 2 banner → Open → JournalingPromptScreen → write something → Save → confirm a mood entry was created with intensity 3.
10. Trigger Tier 3: seed 3 consecutive S ≤ -0.6 days.
11. Tier 3 banner → Open → CrisisResourcesScreen → verify Hotline 1323 tile is prominent.
12. Tap "Call Hotline 1323" tile:
    - Android: dialer opens with `1323` pre-filled.
    - Chrome desktop: dialog displays the number with a "Close" button.
13. First time opening Insights tab → mandatory ack dialog → tap "I understand" → chart renders.
14. Skin system (if integration branch): Settings → Customize → SkinModalSheet → unlock a sunflower skin → return to Garden → confirm all sunflowers display the new skin (TC-6).
15. Settings → Account → Delete account → step 1 confirm → step 2 enter password → confirm → app returns to onboarding.

Document each step in the Audit Report with a screenshot. Any step that fails on either platform is a v1.5 blocker.

## Part 4 - Final smoke pass (Day 5 morning)

Before tagging `v1.5`:

```powershell
cd apps\mobile
flutter analyze   # must be clean
flutter test      # all 959 tests pass
cd ..\functions
npm run lint
npx tsc --noEmit
npm test          # all 73 CF tests pass
```

Then run the v1.5 demo script one final time on Android emulator. If everything is green:

```powershell
cd C:\Users\user\Desktop\FlutterProjects\csc234-project-2025
git switch main
git merge --no-ff feat/s5-d4-integration   # or whichever branch is the v1.5 head
git tag -a v1.5 -m "Sprint 5 - Tiered Intervention + Quote Library + Disclaimer + Final QA"
git push origin main --tags
```

## Done criteria

- [ ] All 18 integration tests pass on Android emulator.
- [ ] Integration tests pass on Chrome (or manual smoke OK if `flutter drive` blocks).
- [ ] Cold start < 2s on Pixel 6 API 34 emulator (target: < 1.5s with headroom).
- [ ] Insights scroll: median frame time < 16.7ms, zero frames > 33.4ms.
- [ ] 50-entry harvest cycle does not grow memory monotonically across 3 cycles.
- [ ] Manual demo script passes on Android + Chrome.
- [ ] Screenshots collected and filed under `docs/test-reports/screenshots/v1.5/`.
- [ ] All `flutter analyze` / `flutter test` / CF lint+test green.
- [ ] Security Posture Report final says GO.
- [ ] `v1.5` tag pushed.

## Day 4 → Day 5 hand-off

If any "Done criteria" item fails, file a fix dispatch from the orchestrator before tagging. The static-source reviews on Day 4 part 1 found 0 HIGH issues, so the most likely failure path is a regression-during-merge (skin system not playing well with intervention dispatcher, etc.). Run `flutter test` after every merge to catch regressions early.
