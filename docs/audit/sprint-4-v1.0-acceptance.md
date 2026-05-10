# Sprint 4 v1.0 Acceptance Verification

**Date:** 2026-05-12
**Branch:** `feat/s4-redesign-foundation`
**Tip:** `c26d9716`
**Verifier:** orchestrator (architect role)
**Companion:** `docs/audit/sprint-4-redesign-audit.md` (Day-1 triage), `docs/security/audit-2026-05-12-v1.0-redesign.md` (Day-5 security posture).

## Summary

The Sprint 4 ecosystem redesign lands all 25 in-scope test cases from `.claude/specs/sprint-4-5-spec.md` Part 7. Sprint 5 owns the remaining 16 cases (TC-6..TC-10 Skin system; TC-31..TC-39 Intervention notifications + bipolar disclaimer; TC-40..TC-41 Tier 3 determinism). The dispatcher is feature-flagged off in v1.0 (`interventionDispatchEnabled = false`).

**Tip-of-branch verification:**
- `flutter test`: 664 / 664 passed.
- `flutter test --tags=golden`: 24 / 24 passed.
- `flutter analyze`: 1 pre-existing unrelated info-level lint (`test/app/cheer_up_channel_id_consistency_test.dart:33`).
- `dart format --set-exit-if-changed`: clean.
- Domain-purity grep on `apps/mobile/lib/features/*/domain/`: 1 documented exception (`features/settings/domain/services/day_night_strategy.dart`, ADR-0010 Compliance Check whitelist).
- Mood-agnostic grep on `apps/mobile/lib/features/tokens/`: empty (the load-bearing invariant holds).

## Acceptance matrix — 25 in-scope cases

### Token System (TC-1..TC-5)

| TC | Statement | Test |
|---|---|---|
| TC-1 | First log of day → 5–10 tokens within daily cap | `apps/mobile/test/features/tokens/domain/services/award_daily_tokens_test.dart` |
| TC-2 | "Joy ×5" earns same tokens as "Sad ×5" (mood-agnostic) | same file, plus a file-level grep test enforces `award_daily_tokens.dart` imports no `MoodType` / `MoodEntry` / `MoodScore` |
| TC-3 | Cap reached → additional logs award 0 | same file |
| TC-4 | Token counter resets at midnight | same file |
| TC-5 | Missed day → no tokens lost, no streak broken, no punishment | same file |

### Weekly Harvest (TC-11..TC-15)

| TC | Statement | Test |
|---|---|---|
| TC-11 | After 7 days → garden archives, new garden starts H_0 = 0 | `apps/mobile/test/features/harvest/domain/usecases/archive_weekly_garden_test.dart` |
| TC-12 | Archived garden viewable in History | same file (`getByWeekId` round-trip) |
| TC-13 | Tap a flower in archived garden → original mood entry shown | same file (entries preserved post-archive); UI surface in `weekly_harvests_tab.dart` and `archived_week_screen.dart` reuses the existing `mood_entry_tile` |
| TC-14 | Weekly Summary screen appears with correct stats | `apps/mobile/test/features/harvest/domain/usecases/compute_weekly_summary_test.dart` + `apps/mobile/test/features/harvest/presentation/weekly_summary_screen_test.dart` |
| TC-15 | User-facing copy NEVER says "delete," "clear," or "reset" | `apps/mobile/test/features/harvest/copy_audit_test.dart` (recursive grep of every `.dart` under `lib/features/harvest/` for the forbidden lexicon) |

### Atmosphere (TC-16..TC-20)

| TC | Statement | Test |
|---|---|---|
| TC-16 | 1 positive (S=+0.8) + 1 negative (S=-0.4) → avg=+0.2 → positive atmosphere | `apps/mobile/test/features/garden/domain/services/atmosphere_test.dart` |
| TC-17 | Atmosphere resets at midnight | `apps/mobile/test/features/garden/domain/usecases/compute_garden_state_test.dart` (today-only aggregation) |
| TC-18 | Storm shows plants sheltered, NEVER dead | `apps/mobile/test/features/garden/presentation/widgets/atmosphere_overlay_golden_test.dart` (storm golden asserts the child remains visible underneath the overlay; no wilt silhouettes) |
| TC-19 | Day/night theme matches device when "Follow device theme" selected | `apps/mobile/test/features/settings/domain/services/day_night_strategy_test.dart` |
| TC-20 | Day/night theme matches local time when "Follow device time" selected | same file, with explicit boundary tests at 06:59 / 07:00 / 18:59 / 19:00 |

### Garden Health EWMA (TC-21..TC-24)

| TC | Statement | Test |
|---|---|---|
| TC-21 | H starts at 0 for new week | `apps/mobile/test/features/garden/domain/services/garden_health_ewma_test.dart` (empty-list returns 0) + `compute_garden_state_test.dart` (no entries → H=0, plantTier=resting) |
| TC-22 | Joy ×4 (S=+0.8) → H = 0.12 | `garden_health_ewma_test.dart` (single-step worked example) |
| TC-23 | One bad day from H=+0.4 → H still +0.19, NOT crashed | same file |
| TC-24 | Plants alive in EVERY tier including Storm Season | `apps/mobile/test/features/garden/presentation/widgets/plant_tier_group_golden_test.dart` (5 tier goldens) + `apps/mobile/test/features/garden/domain/entities/plant_tier_test.dart` (threshold boundary cases). Manual visual review confirmed plants intact in StormSeason; no wilt silhouettes, no droop arcs, no broken stems. |

### Pattern Detection (TC-25..TC-30)

| TC | Statement | Test |
|---|---|---|
| TC-25 | 5 of last 7 days negative → Tier 2 trigger fires (logged, not surfaced) | `apps/mobile/test/features/pattern_engine/domain/algorithms/sliding_5_of_7_test.dart` + `apps/mobile/test/features/pattern_engine/domain/usecases/run_pattern_engine_test.dart` (tier resolution); `interventionDispatchEnabled=false` ensures no notification surfaces. |
| TC-26 | 3 consecutive S ≤ -0.6 → Tier 3 trigger fires | `apps/mobile/test/features/pattern_engine/domain/algorithms/three_consecutive_test.dart` + the orchestrator test |
| TC-27 | Mann-Kendall on declining 14-day window → Z ≈ -2.21 → Tier 1 trigger | `apps/mobile/test/features/pattern_engine/domain/algorithms/mann_kendall_test.dart`. **Quantization deviation:** Mann-Kendall's `S` is integer-valued so Z is quantized; the closest reachable values to -2.21 with n=14 are Z = -2.190 (S=-41) and Z = -2.2445 (S=-42) — neither lies within the spec's stated ±0.005 tolerance. The test pins both: (a) the user-facing condition `Z < -1.96` on a clearly-declining series; (b) the closest-achievable Z = -2.190. **Approved deviation** by architect on 2026-05-12: spec target softened to ±0.05 in the next ADR-0011 amendment; the algorithm's tier-trigger semantics are unchanged. |
| TC-28 | Z-score: μ_30=+0.3, today=-0.9 → z_day flagged | `apps/mobile/test/features/pattern_engine/domain/algorithms/z_score_test.dart` |
| TC-29 | CUSUM crosses threshold → Tier 3 trigger | `apps/mobile/test/features/pattern_engine/domain/algorithms/cusum_test.dart` |
| TC-30 | Pattern detection works across week boundaries (sliding windows do NOT reset on harvest) | `apps/mobile/test/features/pattern_engine/domain/usecases/run_pattern_engine_test.dart` (the engine reads from the flat `users/{uid}/moods/` collection, never from `weeklyGardens/{weekId}`) |

## Out-of-scope cases (Sprint 5)

| TC | Owner |
|---|---|
| TC-6..TC-10 (Flower Skins) | S5 |
| TC-31..TC-35 (Intervention Notifications — surface) | S5 |
| TC-36..TC-39 (Bipolar Disclaimer) | S5 |
| TC-40..TC-41 (Tier 3 Determinism) | S5 |

The dispatcher infrastructure (cheer-up controller + sendCheerUpPush CF + cheerUpEvents Firestore collection) ships in v1.0 but is gated off via `interventionDispatchEnabled = false`. The S5 dispatcher rewires it to read `patterns/{date}.triggeredTier`, attaches the Quote Library safety filter and the Bipolar/medical disclaimer footer, then flips the flag.

## Ecosystem invariants verified

- **Plants never die.** No `wilt`, `wilting`, `dead`, `dying` references in any garden/atmosphere/harvest user-facing string. The 5 plant tiers are all visibly alive in the goldens; Storm Season specifically asserts intact plants under shelter with brighter lanterns.
- **Mood Score sign mapping.** `MoodType.okay` is in `MoodCategory.positive`; the cascading callsites (`pattern_detector.dart` predicate behaviour, `analyzePatterns.ts` `NEGATIVE_MOOD_CODES` set) are aligned.
- **EWMA bounded daily delta.** `α=0.15` ⇒ `|H_t − H_{t-1}| ≤ 0.15`. One bad day cannot crash the canvas; one good day cannot make it bloom. Verified by `garden_health_ewma_test.dart` boundary cases.
- **Atmosphere is independent of plant tier.** Decoupled in code (`features/garden/domain/services/atmosphere.dart` and `garden_health_ewma.dart` are separate pure-Dart services); decoupled in z-order (`atmosphere_overlay.dart` wraps the plant tier group; plants are not children of the storm overlay).
- **Pattern Engine is fully client-side.** No Gemini call on the trigger path. `analyzePatterns` Cloud Function is retained for the Insights surface (S5 reads), not the dispatcher path.
- **Mood-agnostic tokens.** `award_daily_tokens.dart` reads no mood-content type. Enforced by file-level grep in `award_daily_tokens_test.dart`.
- **Day/Night theme.** 4-option `ThemeModePreference` (`system`, `light`, `dark`, `followDeviceTime`); `followDeviceTime` flips at 07:00 / 19:00 local cutoffs; storage backward-compatible with the pre-v1.0 string values.

## Domain purity — exception register

CLAUDE.md "the one rule that cannot break" forbids `package:flutter/*`, `package:firebase_*/*`, `package:cloud_firestore/*` imports under `apps/mobile/lib/features/*/domain/`. The redesign branch contains exactly one documented exception:

- `apps/mobile/lib/features/settings/domain/services/day_night_strategy.dart:14` — `import 'package:flutter/material.dart' show ThemeMode;`. Sanctioned by ADR-0010 Compliance Check section. Re-creating a custom domain-side enum and mapping at every callsite would be pure ceremony for a Material value-type.

Any future addition to this list requires an architect ADR + Compliance Check footnote.

## Sign-off

**APPROVED for v1.0 tag.**

All 25 in-scope acceptance test cases are covered by automated tests on the redesign branch tip. The full test suite is green. Manual visual review of plant-tier and atmosphere goldens confirms TC-18 + TC-24 invariants. Domain purity is preserved with one documented exception. The ecosystem redesign carries forward all S3 functional behaviours (offline-first sync, Drift, biometric auth, FCM scaffolding) and supersedes the wilting/rain-cloud visual model with the ecosystem alive-in-every-state model per ADR-0010 + ADR-0011.

Day-5 sequence:
1. Security-reviewer v1.0 posture audit (in flight at the time of this doc — see `docs/security/audit-2026-05-12-v1.0-redesign.md`).
2. Merge `feat/s4-redesign-foundation` → `main`.
3. Tag `v1.0`.

Sprint 5 picks up the dispatcher rewiring, Quote Library + safety filter, Bipolar/medical disclaimer service, Insights screen with mandatory ack, Skin system, account deletion, cross-platform QA, accessibility sweep, performance profile, final reports.
