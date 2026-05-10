# ADR-0010 — Ecosystem Model: Plants Never Die

**Status:** Accepted (Sprint 4)
**Date:** 2026-05-09
**Deciders:** orchestrator + architect
**Supersedes:** ADR-0006 (Compassionate Reframing — wilting + rain cloud)
**Related:** ADR-0011 (Client-Side Pattern Engine), CLAUDE.md pivot features 1–11, `.claude/specs/sprint-4-5-spec.md` §1–§3, §5–§6, US-Som-1 ("no user action to clean up a rain cloud")

## Context

Sprint 1–3 shipped a garden visualisation that mapped a logged mood to one of three glyphs by *user-felt intensity*: a flower for any positive entry, a wilting plant for negative entries at intensity 1–3, and a rain cloud for negative entries at intensity 4–5. ADR-0006 locked that taxonomy in. The implementation was tasteful — autonomous fade timers, no user-driven dismiss action, shape-not-colour grayscale a11y — and it satisfied the immediate copy rules ("no streak-shaming", "no fix-your-mood verbs"). It also passed Sprint 3 demo with a v0.3-beta tag.

Three concerns the implementation could not address surfaced in the May 2 academic review and the post-S3 user-testing round:

1. **Wilt-as-mood reads as judgment under sustained low mood.** A user with a heavy week sees their canvas fill with droopy silhouettes. Self-compassion research (Neff 2003; MacBeth & Gumley 2012) shows that *self-judging visual feedback* during low affective states amplifies, rather than soothes, distress. The mood log itself becomes a stressor.
2. **Intensity-as-glyph confounds two axes.** The user is asked to report intensity (a quantitative scalar) on a 5-step slider, then sees that scalar mapped onto a categorical visual ("a wilting plant" vs "a rain cloud"). The discontinuity at intensity 3↔4 — same emotion, different plant species — is jarring and clinically incoherent. PHQ-9 (Kroenke et al. 2001) treats severity as continuous; our visualisation should too.
3. **The visual taxonomy has no answer for the *trend* question.** The professor's most pointed feedback after S3 was "Show real analytics and pattern recognition with math. What happens to a healthy garden when moody comes? Reference or formula?" The wilt + rain cloud model has no smoothing, no inertia, no formal model of the garden's *health*. A single bad entry "breaks" the canvas; a single good entry "heals" it. Under PHQ-9-style observational logic neither is right — affect is auto-correlated, not Markov-1.

Two psychotherapeutic frames offered escape hatches that the wilt model could not accommodate. First, ACT's "emotions as weather" metaphor (Hayes, Strosahl & Wilson 1999; Harris 2008) externalises the affect — *the user is the sky, the moods are the weather passing through it.* Second, narrative externalisation (White & Epston 1990; White 2007) cleanly separates the person from the symptom — *the storm is not you; the garden holds.* Both demand that the **substrate** (plants, soil) remain intact even when the **atmosphere** (sun, rain, storm) changes. The intensity-split-by-plant-species model collapses these two axes onto one glyph and so cannot honour either frame.

A separate engineering force is in tension with these product asks. Garden Health needs to be *smooth* — auto-correlated, with bounded daily delta — for the visualisation to feel honest and for the Pattern Engine downstream to detect *trends* rather than *spikes*. EWMA is the canonical smoother for this in clinical longitudinal-affect literature (Smit, Schat & Ceulemans 2022, *Assessment* 30(4), 1354–1376). PHQ-9's two-week observational window (Kroenke et al. 2001) anchors the smoothing constant: an EWMA effective-window of ~13 days corresponds to α = 2/(N+1) ≈ 0.15. Picking α this way ensures one bad day shifts H by at most 0.15 — the garden cannot drop more than one tier in a single day, which is exactly the auto-correlation-aware behaviour we want.

## Decision

### 1. Plants are NEVER destroyed, wilting, or dying — in any visual state, copy line, animation, or notification

This is the load-bearing rule of the ecosystem model. Every garden state, including the worst (Storm Season), shows plants alive — sheltered, with lanterns brighter, leaves intact. The user's mood becomes *weather around the garden*, never *damage to the plants*. CLAUDE.md's copy block makes this explicit:

> **NEVER use:** "delete," "clear," "reset," "lost," "destroyed," "wilted," "wilting," "dead," "dying"
> **ALWAYS use:** "harvest," "complete," "new chapter," "fresh week," "sheltered," "resting"

This rule is enforced by (a) a copy-audit test that greps every user-facing string under `features/garden/`, `features/harvest/`, and `features/intervention/` for the forbidden vocabulary; (b) a golden-test suite that snapshots all 5 plant tiers and explicitly asserts the Storm Season tier shows plants intact (no wilt silhouettes, no droop arcs, no broken stems); (c) a `qa-engineer` review block on every PR that touches a garden visual asset.

### 2. Mood Score `S_t = v × i/5` is the unit of measurement

Each entry produces a single signed scalar `S_t ∈ [-1, +1]` from its emotion sign and its intensity:

```
S_t = v × (i / 5)
v ∈ {-1, +1} — sign by emotion
i ∈ {1, 2, 3, 4, 5} — user-reported intensity
```

**Sign mapping** (per spec §2.1, citing Russell 1980; Watson, Clark & Tellegen 1988):

| Emotion | Sign |
|---|---|
| Joy, Calm, **Okay** | +1 |
| Sadness, Anger, Anxiety | −1 |

The sign assignment for "Okay" (formerly `MoodCategory.negativeMild` in S3) flips to positive in S4. Russell's circumplex (1980) places "okay/contentment" in the high-valence, low-arousal quadrant; the PANAS Positive Affect schedule (Watson et al. 1988) similarly groups "calm/at-ease/okay" with positive affect items. Treating "Okay" as a mild negative was an artefact of the old `negativeMild` / `negativeStrong` classifier, which itself was a workaround for the absence of an intensity slider in the earliest prototypes. With the slider in place since S3, the band classifier is redundant and the literature-aligned sign mapping wins.

The Mood Score lives at `apps/mobile/lib/features/mood/domain/services/mood_score.dart` as a pure-Dart function, with a Freezed `MoodScore` value type carrying `(value: double, sign: int, intensity: int)`. The domain layer keeps zero Flutter / Firebase imports.

### 3. Garden Health is an EWMA over per-day mood-score aggregates

```
H_t = α × S_day + (1 − α) × H_{t-1}
α = 0.15
H_0 = 0  (resets weekly)
```

`S_day` for any given day is the mean of all `S_t` values logged that local-midnight day. Garden Health folds these in chronological order over the current week (7 days), starting from `H_0 = 0`. The smoothing constant α = 0.15 corresponds to a 2/(N+1) effective-window of ~13 days, mirroring PHQ-9's two-week observational period (Kroenke et al. 2001). Daily clamping is implicit: with `S_day ∈ [-1, +1]` and α = 0.15, `|H_t − H_{t-1}| ≤ 0.15` — the garden cannot drop or climb more than one tier in a single day, which is the bounded-daily-delta property the no-shock, no-instant-bloom UX asks for.

The pure-Dart EWMA fold lives at `apps/mobile/lib/features/garden/domain/services/garden_health_ewma.dart`. `H_0` resets at the start of each Weekly Harvest cycle (see decision §6).

### 4. `H_t` maps to one of 5 plant tiers — all visibly alive

| `H_t` | Plant tier | Visual treatment |
|---|---|---|
| ≥ +0.4 | Flourishing | Full bloom, butterflies, tall stems, bright lanterns. |
| +0.1 ≤ H < +0.4 | Thriving | Steady growth, full leaves, soft glow. |
| −0.1 ≤ H < +0.1 | Resting | Neutral, dormant, leaves at rest. |
| −0.4 ≤ H < −0.1 | Weathering | Overcast canopy, gentle rain on the path (NOT on the plants). |
| < −0.4 | Storm Season | Rain falls *around* the garden; plants are sheltered, lanterns burn brighter. |

The thresholds derive from spec §2.3 and are enforced as enum boundaries on `PlantTier` at `apps/mobile/lib/features/garden/domain/entities/plant_tier.dart`. The Storm Season tier is the canary: every visual asset, every animation, and every golden test for it must show plants intact. The rain belongs to the atmosphere overlay, not to the plant sprites.

### 5. Daily Atmosphere is a separate, ephemeral, midnight-resetting overlay

```
avg_S_today = (1/n) × Σ S_i  for entries i logged today

avg_S_today ≥ 0 ∧ |avg_S| < 0.3 → calm sunny
avg_S_today ≥ 0 ∧ |avg_S| ≥ 0.3 → bright sunny
avg_S_today < 0 ∧ |avg_S| < 0.3 → light rain / overcast
avg_S_today < 0 ∧ |avg_S| ≥ 0.3 → storm
```

Atmosphere is a fast feedback loop — *"how is today going so far?"* — orthogonal to the slow EWMA Garden Health that answers *"how is the week trending?"* Decoupling them prevents one bad entry from cascading into a crashed canvas (the EWMA inertia absorbs the shock) while still giving the user same-day visual acknowledgement that today is heavy.

Atmosphere resets at local midnight via the existing `localMidnight` helper in `packages/core/lib/src/date_utils.dart`. The pure-Dart computation lives at `apps/mobile/lib/features/garden/domain/services/atmosphere.dart`. The presentation layer renders Atmosphere as an overlay above the `PlantTierGroup`; in Storm state the rain animates *around* the plants and the lanterns brighten — explicit z-ordering ensures the plant sprites are never children of the storm overlay.

### 6. Weekly Harvest cycle — the garden archives every 7 days, with `H_0` reset

At the close of each 7-day cycle the current week's `WeeklyGarden` (entries, daily H_t history, summary, archived-at timestamp) is written once to `users/{uid}/weeklyGardens/{weekId}` and made read-only thereafter. A new garden begins with `H_0 = 0`. The user is shown a `WeeklySummaryScreen` with dominant emotions, growth highlights, week's average mood, and a "Continue to new week" CTA before the harvest commits.

Copy rule in this surface is non-negotiable: **never** "delete", "clear", "reset", "lost", "destroyed", "gone", "erased". **Always** "harvest", "complete", "new chapter", "fresh week", "archived", "preserved" (White 2007 — narrative chapters; Locke & Latham 2002 — goal cycles). Implementation: `features/harvest/` per the audit doc.

The Pattern Engine's sliding windows (5-of-7, 3-consecutive, 14-day Mann-Kendall, 30-day Z-score and CUSUM baselines) **do NOT reset on harvest** — they read from the flat `users/{uid}/moods/` collection, which is unaffected by archival. This separation matters: the user gets a fresh visual canvas every Monday, but the engine that watches for a sustained downturn keeps its memory across the boundary.

### 7. Token economy is mood-agnostic, never lost, cosmetic-only

Tokens are awarded for *showing up* (a daily login + at least one log), never for the content of what was logged. First log of a day = 5 tokens; each additional log adds 1, capped at 10/day. Logging "Sad intensity 5" earns the same as "Joy intensity 5". Missed days lose nothing. Tokens spend only on cosmetic flower skins; no therapeutic feature is ever locked behind tokens (Cheng et al. 2019 — JMIR Mental Health 6(6), e13717, on the harm of contingent rewards on mood content; Deci & Ryan 2000 — Self-Determination Theory).

The `AwardDailyTokensUseCase` at `apps/mobile/lib/features/tokens/domain/services/award_daily_tokens.dart` is pure-Dart, signature `(currentBalance, tokensEarnedToday, lastEarnedDate, now) → (award, newBalance, tokensEarnedTodayAfter, lastEarnedDateAfter)`. It does not read `MoodScore`, `MoodEntry.text`, or `MoodType`. The mood-agnosticism is a unit-test invariant (TC-2): logging "Sad×5" and "Joy×5" produce equal awards by construction. Any reviewer who sees the use case importing mood-content types fails the PR.

### 8. The Pattern Engine writes to `patterns/{date}` regardless; the dispatcher is feature-flagged off in v1.0

Sprint 4 lands the engine but does NOT surface notifications. The 5 algorithms (Mann-Kendall, sliding 5-of-7, 3-consecutive S ≤ -0.6, Z-score, CUSUM) run client-side on every entry and the result document at `users/{uid}/patterns/{yyyy-mm-dd}` is written deterministically. The existing `cheer_up_controller` + `sendCheerUpPush` CF dispatch path is wrapped in the `interventionDispatchEnabled` Remote Config flag (default `false` in v1.0). Sprint 5 re-wires the dispatcher to read `patterns/{date}.triggeredTier`, sets the flag to `true`, and flips on the Tiered Intervention system end-to-end. ADR-0011 owns that wiring decision; this ADR only locks the engine *output* contract.

This split — engine on, dispatcher off — exists so that v1.0 can demo the academic-grade pattern detection with logged outputs (the professor's "show real analytics and pattern recognition with math" feedback) without firing notifications on a copy-and-tier system that has not yet had the Quote Library safety filter merged.

## Consequences

**Positive.**

- Self-compassion alignment (Neff 2003/2023): no visual ever judges the user. Even Storm Season says "the roots hold."
- Continuous severity (Kroenke et al. 2001): one signed scalar per entry, smoothed by EWMA. No discontinuity at intensity 3↔4.
- Bounded daily delta: |H_t − H_{t-1}| ≤ 0.15 by construction. The garden cannot crash on a single bad entry; it cannot bloom on a single good one.
- Two-axis decoupling: weekly Health (slow, smoothed) and daily Atmosphere (fast, midnight-resetting) answer different questions and never collide.
- Pattern Engine has clean numerical inputs (per-entry `S_t`, per-day mean, EWMA H_t) — every algorithm in spec §2.4 reads from the same scalar series, no special-casing of "wilting" vs "rain-cloud" days.
- Token economy is provably mood-agnostic: the use case has no mood-content imports, and the equality invariant is a unit test.

**Negative / trade-offs.**

- Retroactive sign change for `Okay` entries. Past entries logged with `mood: 'okay'` will be re-scored as +0.2 (intensity 1) … +1.0 (intensity 5) instead of -0.2 … -1.0. Garden Health and Atmosphere are computed on read, so historical garden screens shift. The Pattern Engine evaluates current windows only, so it does NOT retroactively trigger a tier on past data. We accept the shift; the new sign is the literature-correct one (Russell 1980; Watson et al. 1988) and the wrong sign was a known artefact.
- Five plant-tier visual assets must be designed and golden-tested, where S3 had three (flower / wilt / cloud). Storm Season especially needs a reviewer eye to ensure plants stay intact under animation.
- The EWMA fold is week-scoped (`H_0 = 0` weekly), which means cross-week comparisons must read from `weeklyGardens/{weekId}.healthHistory[]` rather than from a continuous H_t series. The Pattern Engine's 14-day and 30-day windows side-step this by reading from `moods/` directly, but any future "year-long Health" view will need a separate cross-week aggregator.
- ADR-0006 is superseded but kept on disk. New contributors will see two ADRs that disagree about the garden's visual language; the supersession header on 0006 is the only signal that 0010 is canon. Mitigation: the audit doc and the v1.0 release notes explicitly call this out.

**Follow-up work this creates.**

- ADR-0011 *Client-Side Pattern Engine* (companion decision; superseding ADR-0007).
- HB-004 *Pattern Engine handoff* for `flutter-engineer`.
- Sprint 5: Tiered Intervention dispatcher (Tier 1 breathing / Tier 2 journaling / Tier 3 crisis + Hotline 1323), Quote Library with the Tier-3-curated-only rule, Bipolar/medical disclaimer service, Insights screen with mandatory ack, Skin system, Account deletion.
- v1.x: replace the fixed 07:00–19:00 day/night cutoff with a sunrise/sunset table (Czeisler et al. 2014; Erickson et al. 2020).
- v1.x: cross-week Health view reading from `weeklyGardens/{weekId}.healthHistory[]`.

## Alternatives Considered

- **Keep ADR-0006 (wilting + rain cloud) and add only the EWMA + Pattern Engine on top.** Rejected. The visual taxonomy is the load-bearing self-compassion failure; smoothing the underlying number does not fix the moment a user opens the app to find their canvas full of wilting silhouettes. Self-compassion research (Neff 2003; MacBeth & Gumley 2012) is unambiguous about this.
- **Single Garden Health score *with no Atmosphere overlay*.** Rejected. The slow EWMA delays the user's same-day acknowledgement: they log a heavy entry and see no immediate change in the canvas because EWMA inertia absorbs it. Decoupling daily Atmosphere from weekly Health gives the user a fast "today is heavy, the garden holds" signal without crashing the substrate.
- **Per-entry "weather sprite" instead of per-day Atmosphere.** Rejected. Multiple entries in a single day with mixed signs would render contradictory weather sprites side by side, which is visually incoherent. Aggregating to `avg_S_today` is the cleanest summary statistic and matches how the user actually thinks about their day.
- **Continuous EWMA with no weekly reset.** Rejected. Without `H_0 = 0` resets the user has no fresh-start moment; a hard month bakes into the canvas indefinitely. The Weekly Harvest cycle (decision §6) gives the user a narrative chapter break (White 2007) — a structured fresh start that preserves history (in the archive) without dragging it forward visually.
- **Sign mapping by `MoodCategory` (keep `Okay` as `negativeMild`).** Rejected. The Russell circumplex and PANAS literature place "okay/contentment" in positive affect; the existing classifier was a pre-slider workaround.
- **Mechanical or therapeutic features behind tokens.** Rejected explicitly (Cheng et al. 2019). Pattern detection, intervention notifications, the disclaimer, breathing exercises, journaling prompts, crisis resources, and the Hotline 1323 link are ALWAYS free.

## Compliance Check

- **Clean Architecture domain-zero-imports rule (ADR-0001):** satisfied. `MoodScore`, `GardenHealthEwma`, `Atmosphere`, `AwardDailyTokensUseCase`, the 5 pattern algorithms, and the `RunPatternEngineUseCase` orchestrator all live under `features/*/domain/` with zero Flutter / Firebase imports. CI grep gate enforces. **Documented exception (S4 Day 4, HB-005 Track 4.4/7.2):** `apps/mobile/lib/features/settings/domain/services/day_night_strategy.dart` carries the single sanctioned `import 'package:flutter/material.dart' show ThemeMode` because `ThemeMode` is a Material enum-like value with no domain analog; the exception is documented in the file header and the CI domain-purity grep is configured to whitelist this exact path.
- **Enterprise Term Assignment requirements touched:** **R1** (the redesign is traceable to professor's S3 feedback "show real analytics with math" and to user-testing post-S3); **R3** (architecture quality — the layer boundary is preserved under a major redesign); **R5** (a11y quality gate — every plant tier has a golden asserting alive rendering, including grayscale).
- **Quality gates affected:** Correctness (new pure-Dart unit tests for Mood Score, EWMA, Atmosphere, Tokens; the 25 Sprint-4-scoped acceptance test cases must pass before v1.0 tag), Accessibility (5-tier + 4-atmosphere golden suite asserts shape-not-colour distinguishability and plants-alive in Storm Season), Performance (EWMA fold is O(7) per render; Atmosphere is O(n_today)). Security: N/A on this ADR; ADR-0011 owns the pattern-detection-path security surface.
- **CLAUDE.md copy rules audit:**
  - "No clinical language": no "depression", "anxiety disorder", "symptom", "diagnosis", or "bipolar" (the last only in the disclaimer text per ADR-0011's siblings in S5).
  - "No streak-shaming": tokens never lost on missed days; Weekly Harvest copy is celebratory not punitive.
  - "No fix-your-mood verbs": every plant tier reads as descriptive ("Resting", "Weathering", "Storm Season"), never imperative ("Improve", "Fix", "Recover").
  - "Compassionate imperatives": tier-name copy uses gentle language; intervention copy (S5) uses "Want to…?" / "If it helps…".
  - "Hotline 1323": footer-only and Tier-3 only (S5).
- **US-Som-1 traceability:** the rain belongs to the Atmosphere overlay; plant sprites have no rain in their own widget tree. There is no API surface — at any layer — for the user to dismiss weather. The fade is autonomous.
- **Citations:**
  - Self-compassion: Neff (2003), *Self and Identity* 2(2), 85–101; Neff (2023), *Annual Review of Psychology* 74, 193–218; MacBeth & Gumley (2012), *Clinical Psychology Review* 32(6), 545–552.
  - DBT validation: Linehan (1993), *Cognitive-Behavioral Treatment of Borderline Personality Disorder*, Guilford.
  - ACT weather metaphor: Hayes, Strosahl & Wilson (1999), *ACT*, Guilford; Harris (2008), *The Happiness Trap*.
  - Narrative externalisation: White & Epston (1990), *Narrative Means to Therapeutic Ends*, Norton; White (2007), *Maps of Narrative Practice*, Norton.
  - EWMA in clinical longitudinal affect: Smit, Schat & Ceulemans (2022), *Assessment* 30(4), 1354–1376.
  - PHQ-9 anchor for α=0.15: Kroenke, Spitzer & Williams (2001), *J Gen Intern Med* 16, 606–613.
  - Affect circumplex (sign mapping for Okay): Russell (1980), *JPSP* 39, 1161–1178; Watson, Clark & Tellegen (1988), *JPSP* 54, 1063–1070.
  - Goal cycles for Weekly Harvest: Locke & Latham (2002), *American Psychologist* 57, 705–717.
  - Anti-pattern guardrails on token economy: Deci & Ryan (2000), *American Psychologist* 55, 68–78; Cheng et al. (2019), *JMIR Mental Health* 6(6), e13717.
