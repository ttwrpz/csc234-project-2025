# Sprint 4 Orchestration Plan - v1.0

**Sprint window:** 2026-05-06 → 2026-05-12 (5 working days)
**Tag at end:** `v1.0`
**Status:** awaiting orchestrator approval

---

## Context

Sprint 3 shipped `v0.3-beta`: Gemini mood detection, offline-first sync, biometric fallback, analytics line chart, calendar history, Firestore-rules emulator tests, ≥80% domain coverage. Sprint 4 turns the app **compassionate** - wilting plants and rain clouds replace any "neutral" treatment of negative moods, Gemini-powered pattern analysis arrives with explicit confidence, the repeat-pattern detector lights up the (still-headless) intervention pipeline, dark mode lands, and the widget + golden + integration test suite catches up to feature surface. After this sprint the app is feature-complete on all seven pivot features except the cheer-up intervention UI itself (S5).

This plan produces three planning artifacts (ADR-0006, ADR-0007, HB-003) before any production code is written, then orchestrates five engineering days behind them. Production code is not written until orchestrator approval.

## Critical state observations from current repo (informs the plan)

1. **Mood category vs intensity split.** `MoodCategory` (apps/mobile/lib/features/mood/domain/entities/mood_type.dart:14-22) currently splits by mood **type** (`negativeMild` = okay/sad, `negativeStrong` = angry/anxious). The Sprint 4 reframing rule is **intensity-based** (1–3 wilting, 4–5 rain clouds) regardless of which negative mood. ADR-0006 must reconcile: `MoodCategory` stays as the chart-axis bucket; a new pure-Dart `GardenVisual` enum drives the garden treatment.
2. **`DayBloomKind`** (garden_state.dart:54) already forecasts `wilting` + `rainCloud`. Adding values is forward-compatible.
3. **`AIAnalysisRepository`** (apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart:12-17) has only `analyzeMoodText`; the kickoff requires an `isEnabled` getter for the Insights graceful-fallback. We add it as a synchronous getter that delegates to `featureFlagsProvider`.
4. **`FeatureFlags`** (apps/mobile/lib/app/feature_flags.dart) is scaffolded with `aiPatternAnalysisEnabled` default `true`. Wiring is the missing piece.
5. **Firestore rules** already gate `/users/{uid}/insights/{insightId}` to admin-SDK writes only (firebase/firestore.rules:42-45). No rules change for 5.3 - rules still pass S3 emulator tests.
6. **Theme:** apps/mobile/lib/app/theme.dart only re-exports `buildLightTheme`. Dark mode requires a new `buildDarkTheme()` in `packages/design_system`, plumbed through `MoodBloomApp` (bootstrap.dart) with a persisted `themeMode` setting.
7. **Cloud Functions:** functions/src/analyzeMoodText.ts + rateLimit.ts give us a precedent we mirror for analyzePatterns.ts. rateLimit.ts is reusable as-is (5/min for analyzePatterns is more conservative than 10/min for moodText - see ADR-0007).
8. **`analyticsControllerProvider(MoodWindow)`** (apps/mobile/lib/features/analytics/presentation/controllers/analytics_controller.dart) - the Pattern Insights card hooks the same controller's window selector for parity.
9. **Hot path of S4:** Pattern Detection (5.3) is on the critical path with O=2.0/M=3.0/P=4.5 spread; ADR-0007 must define the fallback before flutter-engineer starts the Cloud Function so the contract is the same shape whether Gemini or statistical patterns produce it.

---

## Day-by-day decomposition

### Day 1 - Mon 2026-05-06 (planning + ground truth)

**architect** writes the three planning artifacts (drafts embedded below in this plan):
- `docs/adr/0006-compassionate-reframing-mechanism.md`
- `docs/adr/0007-pattern-analysis-fallback.md`
- `docs/handoffs/HB-003-pattern-detection.md`

**flutter-engineer (Napat)** starts WBS 4.2 - wilting plant widget. Scope:
- New `apps/mobile/packages/design_system/lib/src/widgets/wilting_plant.dart` (or under `packages/design_system/lib/...` matching existing `garden_flower.dart` location).
- Update `DayBloomKind` enum: add `wilting`, `rainCloud`. Ripple-update `compute_garden_state.dart` and the WeeklyBloomBar widget.
- Update `ComputeGardenStateUseCase` to compute per-day **dominant kind** using ADR-0006's algorithm (positive wins → bloom; else max-intensity negative wins → wilting if 1–3, rainCloud if 4–5; else empty).
- Domain unit tests added in same PR (per CLAUDE.md "every new domain class requires unit tests").

**qa-engineer (Teerin)** starts WBS 7.2 widget tests - 3-day task. Day 1 covers Auth (sign-in, sign-up) + IntensitySlider widget tests. No goldens yet.

### Day 2 - Tue 2026-05-07 (compassionate canvas + flag wiring)

**flutter-engineer (Napat)** completes WBS 4.3:
- New `RainCloudOverlay` widget that uses `AnimatedPositioned` + `AnimatedOpacity`. Drift duration randomised 15–25s per `DayBloomKind.rainCloud` cell. Self-fades to 0 opacity at end of drift; no user action required (Som's US-Som-1).
- Reduced motion: respect `MediaQuery.disableAnimations` - when true, render at 0.4 opacity static, no drift. (WCAG 2.3.3.)
- Wire `featureFlagsProvider.aiPatternAnalysisEnabled` → new `AIAnalysisRepository.isEnabled` getter (synchronous, reads the latest `FeatureFlags` from `ref`).
- Graceful UI fallback: Insights card on AnalyticsScreen renders a "Pattern Insights paused" placeholder when `isEnabled == false` (no error chrome).

**architect** reviews wilting + rain cloud against Som's acceptance criterion (no user action required to clean up). Files: WBS 4.2 + 4.3 widgets and the use-case diff. **Sign-off only** - no edits.

**qa-engineer** writes goldens for: empty garden, garden with flowers, garden with wilting plants, garden with rain cloud (state pinned via fake `MoodRepository`). Goldens live under `apps/mobile/test/features/garden/presentation/golden/`. `flutter test --update-goldens` is the regen path; CI runs without `--update-goldens` and fails on diff.

### Day 3 - Wed 2026-05-08 (Cloud Function + detector + dark mode)

**flutter-engineer (Kraiwich)** starts WBS 5.3 - `analyzePatterns` Cloud Function (HB-003 §A is the canonical brief).
- New `functions/src/analyzePatterns.ts` mirrors analyzeMoodText.ts validation pipeline.
- New `functions/src/patternsClient.ts` - Gemini wrapper for the patterns prompt.
- New `functions/src/types.ts` additions for `AnalyzePatternsRequest/Response`.
- **Reuses** existing `rateLimit.ts` with a 5-req/min cap (lower than moodText's 10/min - pattern calls are heavier, less interactive).
- Server-side statistical fallback (`functions/src/statisticalPatterns.ts`) computed unconditionally; Gemini output is layered on top when present and confident.

**security-reviewer** audits the new Cloud Function (HB-003 §C): rate limiting present, input validation rejects history > 500 entries, **no mood text** sent to Gemini (only `{date, moodCode, intensity}` triples), `gemini.rationale` not logged, App Check enforcement decision recorded.

**flutter-engineer (Kraiwich)** also starts WBS 5.4 - repeat-pattern detector. Scope:
- `apps/mobile/lib/features/garden/domain/pattern_detector.dart` - pure-Dart function: `InterventionState detectIntervention({required List<MoodEntry> last10Days, required DateTime now, DateTime? lastInterventionAt})`.
- `apps/mobile/lib/features/garden/domain/entities/intervention_state.dart` - Freezed: `triggered`, `escalated`, `reason`, `cooldownExpiresAt`.
- Domain tests cover all 5 trigger paths (5-of-7 rule, 3-consecutive rule, cooldown gate, 10-day escalation, no-trigger baseline) per HB-003 §B.

**flutter-engineer (Teerin, parallel)** WBS 6.2 - dark mode. Scope:
- New `buildDarkTheme()` in `packages/design_system/lib/src/theme/` (mirror of `buildLightTheme`).
- `apps/mobile/lib/features/settings/` (NEW feature folder) - `theme_mode_repository.dart` (domain abstract + SharedPreferences impl), `theme_mode_controller.dart` (Riverpod), `ThemeSettingsTile` widget.
- `MoodBloomApp` (apps/mobile/lib/app/bootstrap.dart): wire `theme:`, `darkTheme:`, `themeMode:` from controller.
- All MoodBloom token uses must respect `Theme.of(context).colorScheme` - sweep `MoodBloomColors.*` for hardcoded light values; replace with semantic refs where they exist.

### Day 4 - Mon 2026-05-11 (Insights UI + detector wire-in + integration tests + report)

**flutter-engineer (Kraiwich)** WBS 5.3 client side:
- New `apps/mobile/lib/features/analytics/domain/entities/pattern_insight.dart` (Freezed, fromJson).
- `analytics_controller` extension: `patternInsightsProvider(MoodWindow)` - fetches via callable function, returns `AsyncValue<List<PatternInsight>>` with `isEnabled` short-circuit.
- New `InsightCard` widget on AnalyticsScreen below the line chart - confidence badge (`low`/`medium`/`high`), sample-size pill, copy follows ADR-0006 §"Copy".
- Empty/disabled/error states.

**flutter-engineer (Kraiwich)** WBS 5.4 wire-in:
- New provider `repeatPatternStateProvider` in `features/garden/presentation/providers.dart` - reads `watchMyMoodsProvider`, runs `detectIntervention`, exposes `InterventionState`. Garden screen *watches* it (so S5 can show a banner/notification later) but renders **nothing** in the UI yet - Sprint 4 is detection-only.

**qa-engineer** starts WBS 7.3 integration tests:
- `integration_test/auth_flow_test.dart` - sign-in + sign-out happy paths, on Android emulator + Chrome.
- `integration_test/log_history_detail_flow_test.dart` - log mood → assert in History → tap detail.
- (AI override flow + pattern intervention stub roll into S5 - kickoff explicitly says "starts S4, finishes S5".)

**Theerawat** drafts WBS 8.1 - Enterprise Audit & Orchestration Report Sections 1–4 (project context, agile cadence, architecture, security posture). Lives at `docs/reports/enterprise-audit-2026-05-12.md`. Continues into S5.

### Day 5 - Tue 2026-05-12 (presentation day)

**flutter-engineer** completes any remaining integration-test scaffolding to unblock S5.

**security-reviewer** produces `docs/security/posture-v1.0-2026-05-12.md` - covers Cloud Functions hardening (App Check decision, Gemini key handling), Firestore rules audit, dependency vulnerabilities (`flutter pub deps` + `npm audit`), secret scan, PII-in-logs audit.

**Demo rehearsal & flag rollback rehearsal** (kickoff demands rehearse-on-stage):
- log a sad mood @ intensity 3 → wilting plant appears
- log an anxious mood @ intensity 5 → rain cloud drifts away on its own
- open Analytics → Pattern Insight visible with confidence + sample size
- Flip `ai_pattern_analysis_enabled` to `false` in Firebase console → Insights card replaced with "paused" placeholder within 60s
- Flip back → reappears
- Toggle dark mode → every screen swaps tokens

**Tag `v1.0`** after all four quality gates pass (CLAUDE.md §"Quality gates"). Push tag to `origin`.

---

## Files to be created (post-approval)

| Path | Purpose | Owner |
|---|---|---|
| `docs/adr/0006-compassionate-reframing-mechanism.md` | reframing mechanism ADR (draft below) | architect |
| `docs/adr/0007-pattern-analysis-fallback.md` | Gemini-vs-statistical fallback ADR (draft below) | architect |
| `docs/handoffs/HB-003-pattern-detection.md` | Pattern Detection brief (draft below) | architect |
| `docs/runbooks/feature-flag-rollback.md` | demo-day rehearsal script | architect |
| `apps/mobile/lib/features/garden/domain/entities/garden_visual.dart` | new pure-Dart enum: `flower / wilting / rainCloud / empty` | flutter-engineer |
| `apps/mobile/lib/features/garden/domain/entities/intervention_state.dart` | Freezed entity for detector output | flutter-engineer |
| `apps/mobile/lib/features/garden/domain/pattern_detector.dart` | pure-Dart detector | flutter-engineer |
| `apps/mobile/packages/design_system/.../wilting_plant.dart` | widget | flutter-engineer |
| `apps/mobile/packages/design_system/.../rain_cloud_overlay.dart` | widget + drift animation | flutter-engineer |
| `apps/mobile/packages/design_system/.../theme/dark_theme.dart` | dark theme tokens | flutter-engineer |
| `apps/mobile/lib/features/settings/...` | settings feature folder (theme mode) | flutter-engineer |
| `apps/mobile/lib/features/analytics/domain/entities/pattern_insight.dart` | Freezed entity | flutter-engineer |
| `apps/mobile/lib/features/analytics/presentation/widgets/insight_card.dart` | UI | flutter-engineer |
| `functions/src/analyzePatterns.ts` | onCall Cloud Function | flutter-engineer |
| `functions/src/patternsClient.ts` | Gemini wrapper | flutter-engineer |
| `functions/src/statisticalPatterns.ts` | server-side fallback | flutter-engineer |
| `apps/mobile/test/features/garden/presentation/golden/*.png` | goldens | qa-engineer |
| `apps/mobile/test/features/.../widget_test.dart` (multiple) | widget tests | qa-engineer |
| `apps/mobile/integration_test/auth_flow_test.dart` | integration | qa-engineer |
| `apps/mobile/integration_test/log_history_detail_flow_test.dart` | integration | qa-engineer |
| `docs/security/posture-v1.0-2026-05-12.md` | release-gate posture report | security-reviewer |
| `docs/reports/enterprise-audit-2026-05-12.md` (S1–4 only) | enterprise audit draft | Theerawat |

## Files to be modified (post-approval)

| Path | Change |
|---|---|
| `apps/mobile/lib/features/garden/domain/entities/garden_state.dart` | extend `DayBloomKind` with `wilting`, `rainCloud`; add `gardenVisual` field to entries-with-context if needed |
| `apps/mobile/lib/features/garden/domain/usecases/compute_garden_state.dart` | implement dominant-kind algorithm per ADR-0006 |
| `apps/mobile/lib/features/garden/presentation/garden_screen.dart` | render wilting + rain cloud cells; thread overlay anchor |
| `apps/mobile/lib/features/garden/presentation/widgets/weekly_bloom_bar.dart` | render new `DayBloomKind` values |
| `apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart` | add `bool get isEnabled` |
| `apps/mobile/lib/features/mood/data/repositories/ai_analysis_repository_impl.dart` | implement `isEnabled` (reads `featureFlagsProvider`) + `analyzePatterns()` method |
| `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart` | append InsightCard list |
| `apps/mobile/lib/app/bootstrap.dart` | `theme:` + `darkTheme:` + `themeMode:` |
| `apps/mobile/lib/app/theme.dart` | re-export `buildDarkTheme` too |
| `apps/mobile/lib/app/router.dart` (architect sign-off) | add settings route subtree for theme tile if needed (likely just plumbed inside existing `/settings` shell branch) |

`apps/mobile/lib/app/router.dart`, `firebase/firestore.rules`, `apps/mobile/lib/main.dart`, `firebase_options.dart`, `*.g.dart`, `*.freezed.dart` are off-limits per CLAUDE.md without explicit sign-off. The router change above is in scope only because it's adding a child widget to an existing branch, not changing the route table - architect signs off in PR review.

---

# === ADR-0006 (DRAFT) ===

```markdown
# ADR-0006 - Compassionate Reframing Mechanism

**Status:** Proposed
**Date:** 2026-05-06
**Deciders:** orchestrator + architect + Napat (UI/UX Lead)
**Related:** ADR-0001 (clean architecture); CLAUDE.md §"Compassionate reframing"; pivot feature #7

## Context

CLAUDE.md commits the product to a three-tier visual treatment of the user's
mood log on the Garden screen:

- positive moods → flowers
- negative intensity 1–3 → wilting plants
- negative intensity 4–5 → rain clouds (which fade on their own)

Som's Journey Map (US-Som-1) makes the rain-cloud self-fade an explicit
acceptance criterion - the user must NOT have to dismiss it. The clouds
self-care, mirroring the design promise that the app does not nag.

Two open mechanism questions surfaced when the team began implementation:

1. **What axis splits negative-mild from negative-strong - mood type or
   intensity?** The existing `MoodCategory` enum
   (`apps/mobile/lib/features/mood/domain/entities/mood_type.dart:14-22`) maps
   `okay/sad → negativeMild`, `angry/anxious → negativeStrong`. The S4 kickoff
   prescribes intensity 1–3 → wilting, 4–5 → rain clouds *regardless of which
   negative mood*. The two are not equivalent; we must pick one and mean it.
2. **How does a day with mixed-mood entries map to a single visual on the
   weekly bloom bar?** A user can log happy in the morning and angry-5 at
   night.

## Decision

### 1. Visual treatment is INTENSITY-driven, not mood-type-driven.

Rationale: the metaphor is about *severity of distress*, not *flavor of
distress*. A sad-5 ("I am drowning today") is closer in user experience to an
anxious-5 ("I am drowning today") than either is to a sad-2 ("a bit blue, but
fine"). The journey map evidence backs this: Som's "rain cloud day" interview
quote referred to the *weight* of the feeling, not the category.

We keep `MoodCategory` (positive / negativeMild / negativeStrong) as the
**chart-axis bucket** for the analytics line chart - that's a different
question (color-coding, not visual metaphor). The Garden uses a new pure-Dart
enum:

```dart
enum GardenVisual { flower, wilting, rainCloud, empty }

GardenVisual visualFor(MoodType mood, int intensity) {
  if (mood.category == MoodCategory.positive) return GardenVisual.flower;
  return intensity <= 3 ? GardenVisual.wilting : GardenVisual.rainCloud;
}
```

This function lives in `apps/mobile/lib/features/garden/domain/garden_visual.dart`
and is unit-tested with all 6 moods × 5 intensities (30 cases).

### 2. Per-day dominant-visual algorithm

For the weekly bloom bar, each day cell is a single `DayBloomKind`. When a
day contains multiple entries, the rule is:

1. If **any** positive entry that day → `bloom`. (Positive logged → garden
   blooms, even if a sad-3 was also logged. We optimise for celebrating
   self-care, not auditing distress.)
2. Else if **any** entry has intensity ≥ 4 → `rainCloud`. (Rain clouds
   dominate wilting in mixed-severity negative days because the heavier
   moment is what the user remembers.)
3. Else if **any** negative entry → `wilting`.
4. Else (no entries) → `empty`.

`ComputeGardenStateUseCase` is updated to apply this rule per local-day
bucket (matching the existing midnight-local-time semantics, S3 line 70-73).

Reasoning for rule #1 favoring positive: streak-shaming is a CLAUDE.md
red-line. If a user logs one happy moment, the bar should celebrate it.
Reasoning for #2 over #3 (rain-cloud dominates): the metaphor's emotional
weight goes with the *worst* moment, and surfacing wilting in a 4-or-5 day
would understate. Rain-cloud days have the self-fade animation, so the
visual weight clears itself - the dominance does not punish the user.

### 3. Rain-cloud self-fade animation

- `RainCloudOverlay` widget composes `AnimatedPositioned` (drift left→right
  across the cell's bounds) and `AnimatedOpacity` (fade 1.0 → 0.0 over the
  drift duration).
- Drift duration: random per cloud, **uniformly between 15s and 25s**, seeded
  per cloud-id (so a rebuild does not reset the in-flight animation).
  Implementation note: `math.Random(cloudHash).nextInt(11) + 15` keeps it
  pure and predictable.
- Reduced motion: when `MediaQuery.of(context).disableAnimations == true`,
  render the cloud at static 0.4 opacity, no drift, no fade. (WCAG 2.3.3
  Animation From Interactions; tested via `MediaQuery` override in goldens.)
- Performance: rain cloud animations use `RepaintBoundary` so the rest of the
  garden does not invalidate per frame. Performance-budget check at S5 will
  verify cold-start unaffected.
- The cloud does NOT block input; tapping passes through to the day cell.

### 4. Wilting plant visual

- `WiltingPlant` is a static SVG-driven widget (no animation; the wilt is
  in the artwork). Same dimensions as `GardenFlower` so layout is preserved
  when a flower turns into a wilting plant.
- Color tokens: drawn from `MoodBloomColors.wiltingStem` and
  `MoodBloomColors.wiltingLeaf` (added in this sprint). Both have dark-theme
  variants (ADR is silent on tokens; design_system PR carries them).
- Semantics label: `"Wilting plant - you logged a negative mood that day"`
  (no clinical language, no severity number, no streak shaming).

### 5. Copy rules for the empty + mixed states

- Empty: "Your garden is waiting." (unchanged from S3.)
- All-rain-cloud week: NO new banner. The clouds drifting away IS the copy.
  We do not add "It's been a heavy week" - that is the cheer-up
  intervention's job in S5, not the Garden's job in S4.

## Alternatives Considered

- **Mood-type split** (re-use existing `MoodCategory.negativeMild` /
  `negativeStrong`). Rejected: the type/severity coupling is a categorical
  artefact for charting, not a user-facing severity model. A sad-5 is heavy;
  a sad-2 is not. Treating them identically would either trivialise the
  heavy day or melodramatise the light one.
- **Sum-of-intensities daily aggregate.** Rejected: a day with three sad-3
  entries (cumulative 9) would be classed rainCloud; that is a user with a
  consistently mild bad day, not a crisis.
- **Most-recent entry wins.** Rejected: gives the *last* moment veto power
  over the day's tone. A happy morning followed by an angry-5 evening would
  show rainCloud - fine - but two happy moments followed by an okay-2
  would show wilting, which understates the day.
- **Per-entry visuals (multiple visuals per day cell).** Rejected for the
  weekly bar (visual chaos at scale); revisit for the canvas if S5 adds
  density work.

## Consequences

- Positive: visuals match user-felt severity; `GardenVisual` enum is one
  small pure-Dart file with a 30-case truth table; intensity becomes a
  first-class visual driver, reinforcing pivot feature #1; the
  `MoodCategory` enum is preserved for the chart, so S3 analytics is not
  disturbed.
- Negative: `DayBloomKind` grows from 2 values to 4, every switch-exhaustive
  use site requires update (compute_garden_state.dart, weekly_bloom_bar.dart,
  goldens). `WiltingPlant` and `RainCloudOverlay` are new widgets that need
  goldens × 2 themes (light + dark) - 4 new golden files plus the empty/full
  garden goldens already required.
- Operational: `featureFlagsProvider` is NOT used to gate this - the
  reframing is core product, not a Gemini-dependent feature.

## Compliance Check

- [ ] CLAUDE.md "Compassionate reframing" (positive=flowers, negMild=wilting,
      negStrong=rainCloud) - satisfied with intensity reinterpretation.
- [ ] CLAUDE.md "No streak-shaming" - satisfied (rule #1 favors positive).
- [ ] CLAUDE.md "No clinical language" - satisfied (semantics labels reviewed).
- [ ] WCAG 2.3.3 Animation From Interactions - satisfied (reduced-motion
      branch in `RainCloudOverlay`).
- [ ] Domain layer purity - `GardenVisual` enum and `visualFor()` function
      are pure-Dart; only `MoodType`/`MoodCategory` (already pure) imports.
```

# === ADR-0007 (DRAFT) ===

```markdown
# ADR-0007 - Pattern Analysis: Gemini Layered on Statistical Fallback

**Status:** Proposed
**Date:** 2026-05-06
**Deciders:** orchestrator + architect
**Related:** ADR-0003 (analyzeMoodText contract); CLAUDE.md §"Feature flag (rollback plan)"; HB-003 (Pattern Detection brief)

## Context

Sprint 4 introduces a second Cloud Function - `analyzePatterns` - which the
Analytics dashboard calls to surface pattern insights ("Your Monday mood
averages 1.8 lower than Thursday - high confidence, 42 Monday samples"). The
S4 kickoff flags this as the highest-risk item: PERT spread O=2.0 / M=3.0 /
P=4.5, with the failure mode being Gemini hallucinating insights or producing
inconsistent confidence labels.

Two design pressures collide:

1. The user-visible promise is "explicit confidence + sample size", and we
   cannot ship a feature whose insights drift in tone or content.
2. The PERT pessimistic case (4.5 days) eats Sprint 4's slack. We need a
   contract that lets us ship even if Gemini's prompt-engineering loop
   does not converge by Day 4.

The kickoff explicitly authorises the fallback strategy: "If Gemini's pattern
output is inconsistent, fall back to statistical patterns computed
server-side (e.g., z-scores over weekdays) and document in ADR-0007. The
user sees confidence labels either way."

## Decision

### 1. Compute statistical patterns FIRST, unconditionally.

Every `analyzePatterns` call computes a deterministic statistical baseline
on the server before considering Gemini at all. This baseline is the
**source of truth** for pattern existence, sample size, and confidence
labels. Statistical patterns currently in scope:

| Pattern | Detection rule |
|---|---|
| Weekday lift/dip | Z-score of mean intensity per weekday vs the user's overall mean across the window. |z| ≥ 1.5 with sample size ≥ 7 → emit. |
| Time-of-day lift/dip | Same as above bucketed into morning (06–12) / afternoon (12–18) / evening (18–24) / night (00–06). |
| Streak of negativity | ≥ 5 consecutive days where every entry is intensity ≥ 3 negative. |
| Recovery streak | ≥ 7 consecutive days with at least one positive entry. |

Each statistical pattern produces a `PatternInsight` with:
- `text` - formatted from a copy template (e.g., "Your Monday mood averages
  1.8 lower than your weekly average").
- `confidence: 'low' | 'medium' | 'high'` - derived from sample size and
  z-magnitude (low <0.5, medium 0.5–0.8, high >0.8) plus a sample-size
  floor (n≥7 medium, n≥21 high).
- `sampleSize: int`.
- `kind: 'weekday' | 'time-of-day' | 'streak-negative' | 'streak-recovery'`.

### 2. Layer Gemini ONLY for narrative reframing.

When Gemini is enabled and the response parses, its job is to *humanise* a
statistical pattern's text - never to introduce a new insight. Wire shape:

```ts
// Server-side after statistical pass:
const baselineInsights = computeStatisticalPatterns(history);
if (baselineInsights.length === 0 || !geminiEnabled) {
  return { ok: true, insights: baselineInsights };
}
const reframed = await reframeWithGemini(baselineInsights, ac.signal);
// reframed[i].text replaces baselineInsights[i].text IFF Gemini returned a
// valid replacement; confidence/sampleSize/kind are NEVER touched.
```

This means the user sees the same number of insights with the same
confidence and sample size whether Gemini answered or not - only the
phrasing softens.

### 3. Fallback triggers (Gemini-output ignored)

Gemini's reframed text is dropped (server falls back to template text) on:

- HTTP 5xx / abort / timeout (5s budget).
- Zod schema fail on Gemini's response.
- Gemini returns a different number of items than statistical baseline.
- Gemini's `text` field for any item is empty, > 200 chars, or contains a
  banned token (regex `/(diagnos|symptom|disorder|depression|anxiety
  disorder|cure|fix|broken)/i` - clinical-language guard from CLAUDE.md
  copy rules).
- Gemini's `text` does not contain the same sample-size number that the
  baseline carries (catches hallucination of the headline number).

A logged fallback is a structured log event `outcome: 'fallback_triggered',
reason: '<one-of>'`. Aggregated at week's end as a Gemini-quality KPI.

### 4. Client never knows the difference.

`PatternInsight` Freezed entity has no "source" field. The
`AnalyzePatternsResponse.insights[]` is the contract; Gemini-vs-stat is a
server detail. This keeps S5 free to swap in a different LLM without a
client release.

### 5. Feature flag relationship.

`ai_pattern_analysis_enabled = false` (Remote Config) is the master kill
switch for the **entire** Insights feature, including the statistical
fallback. The intent is a single, predictable rollback path: when ops flips
the flag, the Insights card disappears entirely (graceful UI placeholder).
This matches the demo-day rehearsal protocol.

If the team later wants a "stats-only, no Gemini" mode (cheaper, no API
spend), we add a second flag `ai_pattern_gemini_layer_enabled` in S5+; for
S4 the master flag is sufficient.

### 6. Rate limit

`analyzePatterns` reuses `consumeToken` from `rateLimit.ts` with a stricter
cap: **5 requests per minute per uid** (vs 10/min for `analyzeMoodText`).
Pattern analysis is heavier (full-history payload, longer Gemini prompt),
runs on a tab open / window-change, and does not need keystroke
responsiveness.

## Alternatives Considered

- **Gemini-only, no statistical baseline.** Rejected: hallucinated insights
  + missing fallback path = unacceptable demo risk. The kickoff specifically
  authorises statistical fallback as the answer.
- **Statistical-only, no Gemini.** Rejected: the kickoff's user-facing copy
  example ("Your Monday mood averages 1.8 lower than Thursday") is more
  human than a templated string and the feature flag still gives us a
  rollback. Layering Gemini at low-risk surface (text only, never numbers)
  buys the warmth without the hallucination risk.
- **Gemini decides which patterns to surface.** Rejected: that re-introduces
  hallucination of pattern existence, which is exactly what the fallback
  decision is meant to prevent.
- **Cache patterns in Firestore (`/users/{uid}/insights/`) and skip
  re-compute.** Considered for S5; deferred. The collection exists in
  rules but caching has not been measured against compute cost. S4 computes
  on every dashboard open with a memoised provider TTL of 60s on the
  client.

## Consequences

- Positive: a green path exists even if Gemini is fully unavailable;
  confidence labels are explicit, deterministic, and tied to real
  statistics; demo-day flag-flip rehearsal is honest (Insights card hides;
  it doesn't degrade silently).
- Negative: dual implementation overhead (statistical pass + Gemini
  prompt); two test surfaces. Prompt engineering for Gemini reframe is
  bounded in scope (text only) - easier to converge than a
  pattern-from-scratch prompt.
- Operational: server-side statistical compute is bounded by `historyLen`;
  HB-003 caps history at 500 entries (rejection above that). Compute is
  O(n) and cheaper than the Gemini call it precedes.

## Compliance Check

- [ ] CLAUDE.md "AI pattern-analysis gated" - satisfied (master flag).
- [ ] CLAUDE.md "No clinical language" - satisfied (server-side regex guard
      drops Gemini text and falls back to template).
- [ ] CLAUDE.md "explicit confidence + sample size" - satisfied (always
      computed statistically).
- [ ] CLAUDE.md "Gemini via Cloud Functions proxy" - satisfied (extends
      ADR-0003 architecture).
```

# === HB-003 (DRAFT) ===

```markdown
# HB-003 - Pattern Detection (WBS 5.3 + 5.4) - Architect → Flutter Engineer

**Status:** Awaiting orchestrator approval
**Date:** 2026-05-06
**Sprint:** 4
**Owner:** flutter-engineer (Kraiwich)
**Related:** ADR-0003 (Cloud Function precedent); ADR-0007 (Gemini-vs-stat fallback); CLAUDE.md §"Feature flag"

## Goals

1. **WBS 5.3** - Ship `analyzePatterns` Cloud Function + client wiring + Pattern
   Insights UI on AnalyticsScreen.
2. **WBS 5.4** - Ship the pure-Dart `pattern_detector.dart` and wire its
   `InterventionState` into `repeatPatternStateProvider` (Garden screen
   *watches* it but does NOT show UI in S4).

## Non-Goals (S5 scope)

- Cheer-up banner / FCM notification / hotline 1323 footer.
- Breathing exercise screen.
- Per-pattern dismissal UX.

## Section A - `analyzePatterns` Cloud Function

### Wire format

```ts
interface AnalyzePatternsRequest {
  v: 1;
  requestId: string;            // UUID v4
  windowDays: 7 | 30 | 90;      // matches MoodWindow
  history: Array<{
    date: string;               // 'YYYY-MM-DD' local (no time-of-day-only entries - bucketed client-side)
    moodCode: 'happy'|'calm'|'okay'|'sad'|'angry'|'anxious';
    intensity: number;          // 1..5
    timeBucket: 'morning'|'afternoon'|'evening'|'night';
  }>;
  // history.length <= 500 - server rejects above with `invalid_input`
  locale?: string;              // ISO-639-1
}

type AnalyzePatternsResponse = AnalyzePatternsSuccess | AnalyzePatternsError;

interface AnalyzePatternsSuccess {
  ok: true; v: 1; requestId: string;
  insights: Array<{
    kind: 'weekday' | 'time-of-day' | 'streak-negative' | 'streak-recovery';
    text: string;               // <=200 chars; clinical-language guard applied
    confidence: 'low' | 'medium' | 'high';
    sampleSize: number;
    detail?: { weekday?: 0|1|2|3|4|5|6; bucket?: 'morning'|'afternoon'|'evening'|'night' };
  }>;
  source: 'statistical' | 'statistical+gemini';   // diagnostic only; client ignores
  latencyMs: number;
  modelVersion: string;
}

interface AnalyzePatternsError {
  ok: false; v: 1; requestId: string;
  code: 'unauthenticated' | 'invalid_input' | 'rate_limited' | 'gemini_unavailable' | 'parse_error' | 'internal';
  message: string;
  retryAfterSec?: number;
}
```

`unauthenticated` throws `HttpsError` (matches ADR-0003 §"Wire format").

### Validation pipeline (extends ADR-0003 §"Validation order")

1. Auth check.
2. Zod-parse request schema.
3. `history.length` ∈ [0, 500] - else `invalid_input`. Empty history returns
   `{ok: true, insights: []}`.
4. `consumeToken(uid, RATE_LIMIT_PATTERNS_MAX_PER_WINDOW=5)`.
5. **Statistical pass** (always - no Gemini dependency). Uses pure functions
   in `functions/src/statisticalPatterns.ts`. See ADR-0007 §1 for rules.
6. If `featureFlagsProvider.aiPatternAnalysisEnabled === false` server-side
   (read from Remote Config server SDK at handler entry), short-circuit at
   step 4 already with `ok: true, insights: []`. Belt-and-braces: client
   already short-circuits before calling - but a client with stale flags
   might call.
7. **Gemini reframe pass** (when `historyLen > 0` and statistical insights
   are non-empty). Time-budgeted 4s (vs 5s for `analyzeMoodText` because
   the patterns prompt is fatter). On timeout/parse-fail, swallow and
   return statistical text untouched.
8. Apply clinical-language guard regex (ADR-0007 §3). Failed Gemini text →
   replace with statistical template.
9. Truncate every `text` to 200 chars.
10. Emit one structured log line per call (schema below).
11. Return success envelope.

### Logging schema

Allowed fields: `event, requestId, uid, outcome, historyLen, windowDays,
locale, model, latencyTotalMs, latencyGeminiMs, statisticalCount,
geminiAccepted, geminiFallbackReason, rateLimit.{remaining, retryAfterSec}`.

Forbidden fields: any item from `history[]`, full prompt, raw Gemini
response, any item's `text`. (Same PII discipline as ADR-0003 - Gemini
output is PII-adjacent.)

### Files (server)

```
functions/src/
├── analyzePatterns.ts          # onCall handler, mirrors analyzeMoodText.ts
├── patternsClient.ts           # Gemini wrapper, system prompt, response Zod
├── statisticalPatterns.ts      # pure-TS functions; unit-tested in isolation
├── types.ts                    # extended with AnalyzePatternsRequest/Response Zod
└── __tests__/
    ├── analyzePatterns.test.ts
    └── statisticalPatterns.test.ts
```

`functions/src/index.ts` exports `analyzePatterns` alongside `analyzeMoodText`.

### Test plan (server)

Mirrors ADR-0003 §"Test plan" structure. Required cases:
1. Unauth → `HttpsError('unauthenticated')`.
2. Invalid payload (history > 500) → `invalid_input`.
3. Empty history → `{ok: true, insights: []}` (no Gemini call).
4. Rate-limited (consume 6th token) → `rate_limited` with `retryAfterSec`.
5. Statistical-only path (Gemini disabled) - assert insights match
   deterministic baseline.
6. Gemini accepted - assert text differs from baseline, confidence/sampleSize
   unchanged.
7. Gemini timeout → fallback; `outcome: success`, `geminiFallbackReason: 'timeout'`.
8. Gemini hallucinates a sample-size number → fallback; banned-token
   reason logged.
9. Clinical-language token in Gemini text → fallback.
10. Mismatched item count → fallback.
11. PII canary: assert log line does not contain any `text` value or any
    history item.

## Section B - `pattern_detector.dart` (pure domain)

### Contract

```dart
@freezed
class InterventionState with _$InterventionState {
  const factory InterventionState({
    required bool triggered,
    required bool escalated,           // true on 10-day rule
    required InterventionReason? reason,
    DateTime? cooldownExpiresAt,       // null when not in cooldown
  }) = _InterventionState;

  const InterventionState._();

  factory InterventionState.idle() =>
    const InterventionState(triggered: false, escalated: false, reason: null);
}

enum InterventionReason {
  fiveOfSevenNegative,
  threeConsecutiveHighIntensity,
}

InterventionState detectIntervention({
  required List<MoodEntry> history,        // any window; we slice
  required DateTime now,
  DateTime? lastInterventionAt,            // for 48h cooldown
});
```

### Trigger rules (exact)

A day is "negative" if **any** non-positive entry that day has intensity ≥ 1
(i.e., the user logged at least one bad moment).

A day is "high-intensity-negative" if **any** non-positive entry that day
has intensity ≥ 4.

1. **Five-of-seven rule.** Within the 7-day window ending today (inclusive),
   ≥ 5 distinct local-time days are "negative" → set `reason =
   fiveOfSevenNegative`, `triggered = true`.
2. **Three-consecutive rule.** Within the same window, 3 consecutive
   local-time days (no gaps) are "high-intensity-negative" → set `reason =
   threeConsecutiveHighIntensity`, `triggered = true`. If both rules fire,
   threeConsecutive wins (more specific).
3. **Cooldown.** If `lastInterventionAt != null` and `now <
   lastInterventionAt + 48h`, return `triggered = false,
   cooldownExpiresAt = lastInterventionAt + 48h`. Cooldown gates trigger
   *output*, not detection - the reason is still computed and exposed for
   logging/test.
4. **Escalation.** Within the 10-day window ending today, if ≥ 8 distinct
   days are "negative", set `escalated = true`. Escalation is independent
   of cooldown (S5 will use it to swap in the hotline 1323 footer copy).

### Files (client)

```
apps/mobile/lib/features/garden/domain/
├── entities/intervention_state.dart      # Freezed
├── pattern_detector.dart                 # pure function
apps/mobile/lib/features/garden/presentation/
└── providers.dart                        # repeatPatternStateProvider
```

### Test plan (detector)

Pure-Dart unit tests under `apps/mobile/test/features/garden/domain/`. Cases:
1. Empty history → idle.
2. Five-of-seven exact boundary (5 negative days, 2 empty) → triggered,
   reason=fiveOfSeven.
3. Five-of-seven with cooldown active → not-triggered, cooldownExpiresAt set.
4. Three-consecutive intensity-4 days → triggered, reason=threeConsecutive.
5. Three-consecutive intensity-3 days → not triggered (intensity floor is 4).
6. Both rules fire same day → threeConsecutive wins.
7. Escalation: 8 negative days in a 10-day window → escalated=true.
8. Time-zone boundary: entries at 23:55 vs 00:05 of consecutive local days
   are correctly bucketed (matches `compute_garden_state` time discipline).

## Section C - security-reviewer audit checklist (Day 3)

Required findings before merge:
- [ ] App Check decision recorded (S4 enables it on `analyzePatterns` if
      ADR-0003's S4 follow-up landed; otherwise documented why not).
- [ ] Rate-limit constant 5 req/min/uid is enforced and tested.
- [ ] Input validation: history.length ≤ 500 (TC #2 above).
- [ ] PII boundary: only `{date, moodCode, intensity, timeBucket}` sent to
      Gemini; mood `text` never crosses into the patterns codepath. Verified
      by re-reading `analyzePatterns.ts` end-to-end and grepping for
      `MoodEntry.text`.
- [ ] Logs do not contain any item from `history`, the full prompt, or
      Gemini's response text. Verify TC #11.
- [ ] Gemini API key handling matches ADR-0003 (`defineSecret`, lazy
      `.value()`).
- [ ] `firestore.rules` /users/{uid}/insights/{insightId} stays admin-write
      only - no rules diff in this PR.

## Section D - risks + cutlines

If we are behind on Day 4 EOD:
1. **First cut**: drop the Gemini reframe layer. Ship statistical-only.
   Insights card still shows confidence + sample size; copy is templated.
   ADR-0007's master flag relationship still holds.
2. **Second cut**: drop weekday + time-of-day patterns; ship only streak
   patterns (simpler, lower test burden).
3. **Last cut**: Pattern Insights UI ships disabled-by-default Remote
   Config (`ai_pattern_analysis_enabled = false` in production), enable
   for the demo only.

Detector (5.4) cannot be cut - its output is required for S5's banner
work and is small enough to land regardless of 5.3's state.
```

---

## Verification (post-implementation)

After all S4 PRs merge, the orchestrator must verify:

1. `flutter test` passes (unit + widget + golden suites green).
2. `flutter test integration_test/auth_flow_test.dart -d <android|chrome>` -
   passes on both platforms.
3. `flutter analyze` clean.
4. `npm test` in `functions/` - passes for new analyzePatterns suite.
5. Manual demo rehearsal:
   a. log mood sad@3 → wilting plant on the Garden tab.
   b. log mood anxious@5 → rain cloud appears, drifts, fades within 25s.
   c. open Analytics → ≥1 Insight card visible with confidence + sample size.
   d. flip `ai_pattern_analysis_enabled` to `false` in Firebase console →
      Insights card replaced with placeholder within 60s.
   e. flip back → reappears.
   f. Settings → toggle dark mode → every screen swaps tokens.
6. Tag `v1.0` after demo.
7. Quality gates per CLAUDE.md §"Quality gates":
   - Correctness: domain coverage ≥ 80%.
   - Security: posture report (Day 5) shows no HIGH/CRITICAL deps, secret
     scan clean, rules emulator tests pass.
   - Accessibility: Semantics labels on Wilting + RainCloud verified;
     reduced-motion path golden tests pass.
   - Performance: cold-start < 2s on mid-range Android (S5 owns the formal
     profile; S4 spot-checks only).

---

## Awaiting orchestrator approval before any code is written.
