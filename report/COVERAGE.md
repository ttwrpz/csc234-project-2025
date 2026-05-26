# MoodBloom Test Coverage Report

Generated 2026-05-26 on branch `feat/s5-v1.5-final`, after the v1.5.1 sweep
(privacy-lock merge, em-dash normalization, AI Insights threshold relax,
delete-button color, WebAuthn end-to-end).

## Run

```
cd apps/mobile
flutter test --coverage --concurrency=8 --exclude-tags=golden,shader
```

- **Result:** 1038 / 1038 tests passed
- **Duration:** 3 min 50 s (well under the 5-min budget)
- **Output:** `apps/mobile/coverage/lcov.info` (136 KB, 264 production files counted)
- **Excluded from counts:** generated files (`*.g.dart`, `*.freezed.dart`, `*.gen.dart`), goldens, shader-bound tests

## Headline

| Metric | Value |
|---|---|
| **Overall line coverage** | **58.4 %** (6 737 / 11 539) |
| Production files measured | 264 |
| Domain layer coverage | **91.9 %** (795 / 865) |
| Presentation layer coverage | 60.7 % (4 576 / 7 540) |
| Data layer coverage | 45.1 % (1 235 / 2 736) |
| App-shell coverage | 32.9 % (131 / 398) |

The domain layer comfortably passes the CLAUDE.md §"Quality gates" target of ≥ 80 %. The presentation layer is in good shape. The drag on overall coverage is the **data** layer (Firestore datasources, repository impls with try/catch branches) and the **app-shell** (router redirects).

## Per-feature breakdown

| Feature | Coverage | Hit / Found | Files |
|---|---|---|---|
| garden | **84.9 %** | 1 862 / 2 192 | 30 |
| pattern_engine | **82.0 %** | 173 / 211 | 13 |
| disclaimer | 76.1 % | 54 / 71 | 6 |
| intervention | 74.7 % | 639 / 855 | 21 |
| insights | 62.9 % | 416 / 661 | 16 |
| tokens | 62.0 % | 348 / 561 | 18 |
| notifications | 60.2 % | 227 / 377 | 12 |
| mood | 59.5 % | 1 086 / 1 826 | 44 |
| settings | 53.6 % | 279 / 521 | 5 |
| harvest | 48.9 % | 236 / 483 | 11 |
| auth | 45.9 % | 816 / 1 776 | 61 |
| analytics | 42.8 % | 160 / 374 | 9 |
| history | 41.0 % | 309 / 753 | 11 |
| (app-shell) | 32.9 % | 131 / 398 | 5 |
| onboarding | 0.2 % | 1 / 480 | 2 |

## Domain coverage per feature (CLAUDE.md gate ≥ 80 %)

| Feature | Domain coverage | Gate |
|---|---|---|
| disclaimer | 100 % | PASS |
| pattern_engine | 100 % | PASS |
| harvest | 100 % | PASS |
| insights | 100 % | PASS |
| settings | 100 % | PASS |
| history | 100 % | PASS |
| garden | 96.9 % | PASS |
| tokens | 96.4 % | PASS |
| intervention | 88.4 % | PASS |
| mood | 88.4 % | PASS |
| auth | 86.6 % | PASS |
| analytics | 81.4 % | PASS |
| **notifications** | **73.7 %** | **FAIL** |

**One miss:** `features/notifications/domain/` at 73.7 %. The remaining 10 untested lines are in the failure-mapping switch of the FCM token entity. Cheap fix — add a unit-test row per failure code.

## Top 10 best-covered large files

| % | Hit/Found | File |
|---|---|---|
| 100 % | 86 / 86 | `lib/features/garden/presentation/widgets/per_flower_detail_modal.dart` |
| 100 % | 54 / 54 | `lib/features/garden/presentation/widgets/cheer_up_banner.dart` |
| 99.0 % | 205 / 207 | `lib/features/garden/presentation/widgets/plant_tier_group.dart` |
| 98.9 % | 177 / 179 | `lib/features/garden/presentation/widgets/sky_header.dart` |
| 98.0 % | 49 / 50 | `lib/features/auth/presentation/widgets/google_sign_in_button.dart` |
| 96.6 % | 85 / 88 | `lib/features/intervention/presentation/screens/journaling_prompt_screen.dart` |
| 96.5 % | 82 / 85 | `lib/features/auth/presentation/sign_up_screen.dart` |
| 96.0 % | 48 / 50 | `lib/features/mood/presentation/widgets/media_picker_button.dart` |
| 94.6 % | 53 / 56 | `lib/features/history/presentation/widgets/mood_entry_tile.dart` |
| 94.4 % | 67 / 71 | `lib/features/garden/presentation/widgets/atmosphere_overlay.dart` |

## Zero-coverage files (≥ 30 lines)

17 production files with 0 % coverage. Sorted by line count (biggest gaps first):

| Lines | File | Notes |
|---|---|---|
| 102 | `lib/features/insights/presentation/widgets/marker_detail_sheet.dart` | Adaptive modal; needs a sheet/dialog widget test |
| 84 | `lib/features/auth/data/pin_repository_impl.dart` | **Surprising** — PIN logic has heavy domain tests but the repo orchestrator isn't covered. Add `pin_repository_impl_test.dart` with a fake `PinFirestoreDatasource`. |
| 79 | `lib/features/auth/data/webauthn_repository_impl.dart` | Just landed in the WebAuthn work; tile + screen tests exist but the repo wasn't unit-tested. |
| 79 | `lib/app/widgets/mb_side_nav.dart` | Desktop-only widget; never mounted under the 600 dp default test surface. |
| 56 | `lib/features/history/presentation/widgets/entry_attachments.dart` | Image attachment row |
| 53 | `lib/features/auth/presentation/screens/pin_setup_screen.dart` | PIN setup keypad screen |
| 49 | `lib/features/harvest/presentation/archived_week_screen.dart` | Historical week viewer |
| 48 | `lib/features/mood/presentation/widgets/existing_media_strip.dart` | Edit-mode media strip |
| 44 | `lib/features/intervention/data/datasources/interventions_firestore_datasource.dart` | Plain Firestore wrapper |
| 44 | `lib/features/history/presentation/widgets/image_viewer.dart` | Lightbox |
| 37 | `lib/features/tokens/data/datasources/token_balance_firestore_datasource.dart` | Plain Firestore wrapper |
| 37 | `lib/features/notifications/data/datasources/notifications_firestore_datasource.dart` | Plain Firestore wrapper |
| 36 | `lib/features/mood/presentation/widgets/media_thumbnail_strip.dart` | Media row |
| 33 | `lib/features/onboarding/presentation/widgets/onboarding_slide.dart` | The 5 onboarding slides — never tested |
| 33 | `lib/features/notifications/data/datasources/fcm_datasource.dart` | Platform-channel wrapper |
| 32 | `lib/features/harvest/data/datasources/weekly_gardens_firestore_datasource.dart` | Plain Firestore wrapper |
| 30 | `lib/features/mood/data/datasources/image_picker_datasource.dart` | Plain platform wrapper |

## Where the drag is — and how to lift the number

### 1. Onboarding (0.2 %)
Two widget files, 480 lines, no widget tests. Onboarding is shown once per install and is currently exercised only via integration tests (which don't contribute to unit coverage here). A small `onboarding_screen_test.dart` that pumps each slide variant would lift the whole-app number by ~4 percentage points.

### 2. Auth data layer (45.9 % overall on auth)
`pin_repository_impl.dart` (84 lines) and `webauthn_repository_impl.dart` (79 lines) are both at 0 %. Both have hand-rolled fakes available (`fake_pin_repository.dart`, `fake_webauthn_repository.dart`) — but they only cover the *consumers* of these repos, not the repo orchestration logic itself. A 100-line `pin_repository_impl_test.dart` + 100-line `webauthn_repository_impl_test.dart` would lift the auth feature from 45.9 % → ~65 %.

### 3. Plain Firestore datasources (several at 0 %)
`interventions_`, `notifications_`, `weekly_gardens_`, `token_balance_firestore_datasource.dart` are all thin wrappers around `_firestore.collection(...).doc(...).set(...)`. The way every other datasource in the repo gets covered is via the **emulator-backed rules tests** in `integration_test/firestore_rules_test.dart`. Those tests run separately and don't write into `coverage/lcov.info` because they target an emulator process. There's no easy unit-test win here — the choice is "live with 0 % unit coverage on these wrappers" (what we do today) or "switch to fakes" (loses the wire-format assertion). Recommend: **live with it** and surface this as a known limitation.

### 4. App-shell router (32.9 %)
`router.dart` redirect branches are exercised by `test/app/router_*_test.dart` files, but the cold-boot biometric/privacy gate branches need a signed-in user + opted-in privacy lock, which the existing tests don't seed. Adding 3-4 router scenario tests would push the shell over 60 %.

## What this represents

- **Strong:** domain layer coverage is the single most important number per the Enterprise Term Assignment rubric, and it sits at **91.9 %** with 12 of 13 features ≥ 80 %.
- **Adequate:** presentation layer at 60.7 % — the visible/important widgets are well-tested; the long tail of media strips and helper widgets isn't.
- **Known gap:** data layer at 45.1 % — driven by the "plain Firestore wrapper" pattern and a couple of newly-landed repo impls that haven't been backfilled with unit tests yet.

If you want to push overall coverage past 65 % with the smallest amount of work, the highest-leverage tests to add (in priority order) are:

1. `apps/mobile/test/features/auth/data/pin_repository_impl_test.dart` (~+0.7 pp)
2. `apps/mobile/test/features/auth/data/webauthn_repository_impl_test.dart` (~+0.6 pp)
3. `apps/mobile/test/features/onboarding/presentation/onboarding_screen_test.dart` (~+4 pp — biggest single jump)
4. `apps/mobile/test/features/insights/presentation/widgets/marker_detail_sheet_test.dart` (~+0.9 pp)
5. Two router scenario tests covering the cold-boot privacy-lock branch (~+0.5 pp + de-risks regressions)

Estimated total lift: **65–68 %** overall, **>95 %** on the domain layer (the gate that matters for grading).

## How to regenerate

```
cd apps/mobile
flutter test --coverage --concurrency=8 --exclude-tags=golden,shader
# Then optionally:
genhtml coverage/lcov.info -o coverage/html
# Or just re-run the parser:
pwsh .tmp_parse_lcov.ps1   # see git history; the script was removed after use
```

The lcov.info file lives in `apps/mobile/coverage/lcov.info` and is gitignored.
