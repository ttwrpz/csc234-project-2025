# Sprint 4 Redesign Audit — Pre-flight Triage

**Date:** 2026-05-09
**Author:** architect
**Sprint:** S4 (May 6 → May 12)
**Spec source of truth:** `.claude/specs/sprint-4-5-spec.md`
**Related ADRs:** ADR-0010 (ecosystem model, supersedes 0006), ADR-0011 (client-side pattern engine, supersedes 0007)

## Context

The professor approved a late redesign of Sprints 4–5 between v1.6 wrap and the May 12 demo. The previously-shipped *intensity-split visual taxonomy* — flowers for positive entries, **wilting plants** for negative intensity 1–3, **rain clouds** for negative intensity 4–5 — is replaced by an ecosystem model in which **plants are NEVER destroyed in any state**, every mood is *weather*, and the garden is held together by an EWMA-smoothed *Garden Health* score plus a separate *Daily Atmosphere* overlay. The Pattern Engine grows from two simple rules to five academic-grade algorithms (Mann-Kendall, sliding 5-of-7, 3-consecutive S ≤ -0.6, Z-score, CUSUM), all running client-side as pure-Dart functions.

The team had already implemented most of the OLD S4–S5 design (commits up to `52f98a6`). This audit is therefore the **Day-0 0.5-day spike** the kickoff prompt asked for: re-walk every existing surface that touches mood scoring, garden visualisation, pattern detection, intervention dispatch, theme handling, or the Firestore data model, and triage each into one of five buckets:

- **KEEP** — conforms to the new spec; no changes required this sprint.
- **REVISE** — partially conforms; needs targeted edits.
- **REPLACE** — design contradicts the new spec; rewrite from scratch.
- **PAUSE** — code remains in-tree but is gated off until S5 wires it back in.
- **DELETE** — non-compliant artefact whose existence is itself the bug; remove and replace.
- **GREENFIELD** — no existing code; build new.

The full Sprint 4 plan that this audit feeds is at `C:\Users\user\.claude\plans\groovy-jumping-puddle.md`.

---

## Triage matrix

### Mood layer

| Surface | Path | Bucket | Action |
|---|---|---|---|
| `MoodEntry` entity (id, intensity 1..5, text ≤500, mediaRefs, isLocked) | `apps/mobile/lib/features/mood/domain/entities/mood_entry.dart` | **KEEP** | No change. The intensity field is exactly the input the new Mood Score formula needs. |
| `MoodType.category` mapping (`okay → negativeMild`) | `apps/mobile/lib/features/mood/domain/entities/mood_type.dart:14–18` | **REVISE** | Spec §2.1 maps Joy/Calm/Okay → +1 (positive). Currently `okay` is `negativeMild`. Single-line edit. Cascades to `pattern_detector.dart:54` (`!= positive` predicate) and `functions/src/analyzePatterns.ts:44` (`NEGATIVE_MOOD_CODES` set). Retroactively flips the sign on existing entries with `mood: 'okay'`; accepted because Garden Health and Atmosphere are computed on read (no stored scores) and the new Pattern Engine evaluates current windows only (no back-firing). |
| `MoodScore` service | (none) | **GREENFIELD** | New pure-Dart `S_t = v × i/5` function in `features/mood/domain/services/mood_score.dart`, plus a Freezed `MoodScore` value type. |

### Garden / ecosystem layer

| Surface | Path | Bucket | Action |
|---|---|---|---|
| `GardenState` entity (positiveCount/wiltingCount/rainCloudCount/streak/last7Days, `DayBloomKind`) | `apps/mobile/lib/features/garden/domain/entities/garden_state.dart` | **REPLACE** | Old shape encodes "wilting" + "rainCloud" enum values; both contradict the new spec's plants-never-die rule. New entity holds `gardenHealth: double` (H_t), `plantTier: PlantTier` (5-value: Flourishing/Thriving/Resting/Weathering/StormSeason — all alive), `atmosphere: Atmosphere` (4-value: calmSunny/brightSunny/lightRain/storm), and `last7Days: List<DayScore>` (each cell carries a per-day numeric score, not a kind enum). |
| `ComputeGardenStateUseCase` (counts + streak) | `apps/mobile/lib/features/garden/domain/usecases/compute_garden_state.dart` | **REPLACE** | New use case folds entries → per-day mood-score aggregates → today's `avg_S_today` (drives Atmosphere) and a 7-day series (folded by EWMA into H_t, then mapped to PlantTier). Reuses `localMidnight` from `packages/core/lib/src/date_utils.dart`. |
| `GardenHealthEwma` service | (none) | **GREENFIELD** | New pure-Dart fold: `H_t = 0.15·S_day + 0.85·H_{t-1}`, `H_0 = 0` resets weekly. |
| `Atmosphere` service | (none) | **GREENFIELD** | New pure-Dart: `avg_S_today` → 1 of 4 weather states; resets midnight. |
| `WeeklyBloomBar` widget (DayBloomKind switch) | `apps/mobile/lib/features/garden/presentation/widgets/weekly_bloom_bar.dart` | **DELETE** | Replaced by `DailyScoreStrip` (numeric per-day score, not an enum). |
| `RainCloud` widget + `WiltingPlant` silhouette + `FloraSprite(FloraKind.wilt)` | `apps/mobile/lib/features/garden/presentation/widgets/{rain_cloud,flora_sprite}.dart` | **DELETE** | The very existence of these surfaces violates the no-wilt/no-rain-cloud-as-mood rule. Their tests and goldens (`rain_cloud_test.dart`, `rain_cloud_golden_test.dart`, `weekly_bloom_bar_test.dart`) are deleted with them. |
| `SkyHeader` (320dp gradient + greeting + sprite dispatcher) | `apps/mobile/lib/features/garden/presentation/widgets/sky_header.dart` | **REVISE** | Keep canvas + greeting; replace sprite dispatcher with `PlantTierGroup` + `AtmosphereOverlay` wiring. |
| `BreathingOverlay` widget | `apps/mobile/lib/features/garden/presentation/widgets/breathing_overlay.dart` | **PAUSE** | S5 Tier-1 asset; not surfaced in S4 because the dispatcher is feature-flagged off. |
| `HotlineFooter` widget | `apps/mobile/lib/features/garden/presentation/widgets/hotline_footer.dart` | **PAUSE** | S5 Tier-3 asset. |
| New presentation widgets | (none) | **GREENFIELD** | `PlantTierGroup` (5 tier visuals, all alive), `AtmosphereOverlay` (4 weather treatments; storm shows plants sheltered), `DailyScoreStrip` (replaces `WeeklyBloomBar`). |

### Pattern detection / intervention

| Surface | Path | Bucket | Action |
|---|---|---|---|
| `pattern_detector.dart` (5-of-7 + 3-consec heavy + 48h cooldown + 10-day escalation) | `apps/mobile/lib/features/garden/domain/pattern_detector.dart` | **REPLACE** | Move to `features/pattern_engine/domain/legacy_pattern_detector.dart`, mark `@Deprecated('Replaced by RunPatternEngineUseCase — see ADR-0011')`, retain test file as a regression baseline tagged `@Tags(['legacy'])`. The new engine subsumes both rules and adds three more (Mann-Kendall, Z-score, CUSUM). |
| 5 algorithm functions | (none) | **GREENFIELD** | New under `features/pattern_engine/domain/algorithms/`: `mann_kendall.dart`, `sliding_5_of_7.dart`, `three_consecutive.dart`, `z_score.dart`, `cusum.dart`. |
| `RunPatternEngineUseCase` orchestrator | (none) | **GREENFIELD** | Runs all 5 algorithms over the user's mood history, returns a `PatternResult` Freezed entity with every output + `triggeredTier`. Persists to `users/{uid}/patterns/{yyyy-mm-dd}` (idempotent by date id). |
| `PatternResult` entity | (none) | **GREENFIELD** | Freezed: `mannKendallZ`, `slidingNegCount`, `consecutiveHighIntensity`, `zScoreToday`, `cusumC`, `triggeredTier`. |
| `InterventionState` + `InterventionAnchors` + repo + Firestore datasource | `apps/mobile/lib/features/garden/...` and `firebase/firestore.rules:88–116` | **KEEP** | Existing cooldown/escalation persistence at `users/{uid}/interventionState/current` is shape-compatible with per-tier indexing in S5 (we add a tier dimension by writing `cooldowns/{tier}` then). No S4 changes. |
| `cheerUpEvents` collection + datasource + rule | `firebase/firestore.rules:65–81`, `cheer_up_events_*.dart` | **KEEP** | Append-only audit log; S5 will write per-tier events with the new reason codes. No S4 schema change. |
| `cheer_up_controller.dart` (banner dispatch path) | `apps/mobile/lib/features/garden/presentation/controllers/cheer_up_controller.dart` | **PAUSE** | Wrap dispatch in a Remote Config flag `interventionDispatchEnabled` (default `false` in v1.0). S5 flips the flag once the new dispatcher reads `patterns/{date}.triggeredTier`. |
| `cheer_up_banner.dart` widget | `apps/mobile/lib/features/garden/presentation/widgets/cheer_up_banner.dart` | **PAUSE** | Surfaces nothing in v1.0 because the controller is gated off. |
| `sendCheerUpPush` Cloud Function | `functions/src/sendCheerUpPush.ts` | **PAUSE** | Deployed but quiescent in v1.0 — the client-side gate prevents the upstream `cheerUpEvents` write that triggers it. |
| `analyzePatterns` Cloud Function | `functions/src/analyzePatterns.ts` | **REVISE** | Stays deployed for the existing Insights surface, but role narrows to *insights only* (no longer drives interventions). `NEGATIVE_MOOD_CODES.has('okay')` removed atomically with the client `MoodType.okay` flip. |

### Harvest / tokens / theme

| Surface | Path | Bucket | Action |
|---|---|---|---|
| Weekly Harvest cycle (archive every 7 days, weekly summary, history view) | (none) | **GREENFIELD** | New `features/harvest/`: `WeeklyGarden` Freezed entity, `ArchiveWeeklyGardenUseCase`, `WeeklySummaryScreen` pre-harvest screen. History extension lists archived weeks. |
| Token economy (5–10/day cap, mood-agnostic, never lost) | (none) | **GREENFIELD** | New `features/tokens/`: `AwardDailyTokensUseCase` pure-Dart, write-through to user-doc fields `tokenBalance`, `tokensEarnedToday`, `lastTokenEarnedDate`. |
| `ThemeModeStorage` (system/light/dark) | `apps/mobile/lib/features/settings/data/theme_mode_storage.dart` | **REVISE** | Add fourth value `followDeviceTime`. New `DayNightStrategy` domain service resolves preference + `now()` → concrete `ThemeMode` (light 07:00–19:00 local; dark otherwise). |
| `ThemeModeController` | `apps/mobile/lib/features/settings/presentation/controllers/theme_mode_controller.dart` | **REVISE** | Re-evaluates strategy on app focus + hourly tick when `followDeviceTime` is selected. |
| Settings screen toggle UI | `apps/mobile/lib/features/settings/presentation/settings_screen.dart` | **REVISE** | Add 4-option toggle: Follow device theme / Follow device time / Always light / Always dark. |

### Firebase / data model

| Surface | Path | Bucket | Action |
|---|---|---|---|
| `users/{uid}/moods/{moodId}` rule | `firebase/firestore.rules:12–50` | **KEEP** | Mood schema unchanged. |
| `users/{uid}/insights/{insightId}` rule | `firebase/firestore.rules:52–55` | **KEEP** | Cloud-Function-write-only collection unchanged. |
| `users/{uid}/cheerUpEvents/{evtId}` rule | `firebase/firestore.rules:65–81` | **KEEP** | Append-only audit log unchanged. |
| `users/{uid}/interventionState/current` rule | `firebase/firestore.rules:88–116` | **KEEP** | S4 retains single-doc shape; S5 adds parallel `cooldowns/{type}` collection. |
| `users/{uid}/settings/notifications` rule | `firebase/firestore.rules:123–148` | **KEEP** | FCM-token-list shape unchanged. |
| `users/{uid}` doc — top-level fields | `firebase/firestore.rules:9–10` | **REVISE** | Current rule is `allow read, write: if isOwner(uid)` (overly permissive). Replace with field-level validation for new top-level fields: `tokenBalance` (monotonic-up except skin-spend), `tokensEarnedToday`, `lastTokenEarnedDate`, `unlockedSkins` (map<emotion, [skinId]>), `gardenSettings.dayNightMode` (enum), `insightsDisclaimerAcked` (false→true once). |
| `users/{uid}/weeklyGardens/{weekId}` | (none) | **GREENFIELD** | Write-once-on-archive, then read-only. Doc shape: `{weekStart, weekEnd, entries[], healthHistory[double], summary, archivedAt}`. |
| `users/{uid}/patterns/{date}` | (none) | **GREENFIELD** | Idempotent by date id (`yyyy-MM-dd`). Doc shape: `{mannKendallZ, slidingNegCount, consecutiveHighIntensity, zScoreToday, cusumC, triggeredTier, schemaV: 1}`. **Carries no mood text** (PII guard). |
| `users/{uid}/interventions/{id}` | (none) | **GREENFIELD-S5** | Rule stub adds `allow read: if isOwner(uid); allow write: if false;` so the collection is reserved without exposing it to client writes in S4. |
| `users/{uid}/cooldowns/{type}` | (none) | **GREENFIELD-S5** | Rule stub same pattern as `interventions/`. |

### ADR layer

| ADR | Path | Bucket | Action |
|---|---|---|---|
| ADR-0001 *Repo structure & Clean Architecture* | `docs/adr/0001-repo-structure-and-clean-architecture.md` | **KEEP** | Layer rule still holds. |
| ADR-0003 *Gemini Cloud Function contract* | `docs/adr/0003-gemini-cloud-function-contract.md` | **KEEP** | The S5 Quote Library safety filter rides on this contract. |
| ADR-0004 *Drift offline-first schema* | `docs/adr/0004-drift-offline-first-schema.md` | **KEEP** | Mood schema unchanged. |
| ADR-0005 *Conflict resolution last-write-wins* | `docs/adr/0005-conflict-resolution-last-write-wins.md` | **KEEP** | Sync semantics unchanged. |
| ADR-0006 *Compassionate Reframing (Wilting + Rain Cloud)* | `docs/adr/0006-compassionate-reframing.md` | **SUPERSEDE** | Header edit: `Status: Superseded by ADR-0010 (2026-05-09)`. The decision is preserved as a record of *why we changed*, not as live design. |
| ADR-0007 *Pattern-Analysis Fallback (CF statistical primary)* | `docs/adr/0007-pattern-analysis-fallback.md` | **SUPERSEDE** | Header edit: `Status: Superseded by ADR-0011 (2026-05-09)`. |
| ADR-0008 *Intervention Cooldown Persistence* | `docs/adr/0008-intervention-cooldown-persistence.md` | **KEEP** | Doc shape generalises to per-tier in S5 by indexing under `cooldowns/{tier}` — no contradiction. |
| ADR-0009 *Account-Deletion Topology* | `docs/adr/0009-account-deletion-topology.md` | **KEEP** | Account lifecycle is orthogonal to the ecosystem redesign. |
| ADR-0010 *Ecosystem Model — Plants Never Die* | (new) | **CREATE** | Authored Day 1. Cites Neff 2003/2023, Linehan 1993, Hayes 1999, White & Epston 1990, Smit et al. 2022, Kroenke et al. 2001. |
| ADR-0011 *Client-Side Pattern Engine* | (new) | **CREATE** | Authored Day 1. Cites Mann 1945, Kendall 1975, Page 1954, Kroenke et al. 2001, Nahum-Shani et al. 2018. |

### Tests

| Test | Path | Bucket | Action |
|---|---|---|---|
| `pattern_detector_test.dart` | `apps/mobile/test/features/garden/domain/pattern_detector_test.dart` | **KEEP-LEGACY** | Tag `@Tags(['legacy'])`; retained as a regression baseline against the deprecated detector. |
| `garden_state_test.dart`, `compute_garden_state_test.dart` | `apps/mobile/test/features/garden/domain/...` | **REPLACE** | Old assertions reference `wiltingMoodCount` / `rainCloudMoodCount`; both fields are deleted. New tests target `gardenHealth`, `plantTier`, `atmosphere`. |
| `rain_cloud_test.dart`, `rain_cloud_golden_test.dart`, `weekly_bloom_bar_test.dart` | `apps/mobile/test/features/garden/presentation/widgets/...` | **DELETE** | The widgets they exercise are being removed. |
| `garden_screen_golden_test.dart` | `apps/mobile/test/features/garden/presentation/garden_screen_golden_test.dart` | **REPLACE** | New golden set covers 5 plant tiers (Storm Season specifically asserts plants-alive) + 4 atmosphere states. |
| `cheer_up_controller_test.dart`, `cheer_up_banner_test.dart`, `cheer_up_dispatch_test.dart`, `cheer_up_banner_golden_test.dart` | `apps/mobile/test/features/garden/...` | **REVISE** | Add a "feature-flag-off" assertion: when `interventionDispatchEnabled=false` the controller writes nothing and the banner does not surface. Existing happy-path tests run with the flag overridden to `true` for backward coverage. |
| `theme_mode_storage_test.dart`, `theme_mode_controller_test.dart` | `apps/mobile/test/features/settings/...` | **REVISE** | Extend round-trip to cover the new `followDeviceTime` value. |
| Mood-Score, EWMA, Atmosphere, 5-algorithm, Harvest, Token, DayNight tests | (none) | **GREENFIELD** | Per the plan's Tests section. |

---

## Risks tracked

1. **`MoodType.okay` retroactive sign flip.** Garden Health and Atmosphere are read-time computations, so historical garden screens for users with past `okay` entries will display differently after the flip. The new Pattern Engine evaluates current windows only, so it will not retroactively trigger a tier on past data. **Decision:** accept the retroactive shift; document in commit message and ADR-0010.
2. **ADR numbering.** Kickoff prompt asks for "ADR-0006"; existing repo has 0006-0009. **Decision:** create ADR-0010 + ADR-0011 and supersede 0006/0007 by header edit. ADR-0006 retains historical record. (Approved by orchestrator 2026-05-09.)
3. **Cheer-up dispatcher carry-over.** Existing `sendCheerUpPush` CF + `cheer_up_banner` ship the OLD 2-rule trigger. **Decision:** gate behind Remote Config `interventionDispatchEnabled` (default `false` in v1.0). Pattern Engine writes its result to `patterns/{date}` regardless; banner does not fire in v1.0. S5 re-wires the dispatcher to read `patterns/{date}.triggeredTier` and flips the flag. (Approved by orchestrator 2026-05-09.)
4. **`features/pattern_engine/` is a new feature folder per CLAUDE.md.** The legacy `pattern_detector.dart` moves there as a deprecated artefact rather than staying under `garden/` to keep `garden/` rendering-only.
5. **Day/Night sunrise/sunset proxy.** `followDeviceTime` uses fixed 07:00–19:00 local cutoffs (no geolocation). Acceptable for KMUTT/Bangkok latitude; flagged as a v1.x refinement candidate.
6. **No `interventions/{id}` writes in S4.** Rules add a stub denying client writes; S5 opens it once the dispatcher is wired.
7. **Domain-purity grep gate.** All new `features/*/domain/` files must have zero imports of `package:flutter`, `package:firebase_*`, or `package:cloud_firestore`. CI grep gate will catch violations.
