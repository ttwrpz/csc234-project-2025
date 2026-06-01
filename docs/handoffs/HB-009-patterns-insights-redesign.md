# HB-009 - Patterns + Insights Redesign (Mobile / Tablet / Desktop)

**Author:** architect
**For:** flutter-engineer
**Sprint:** 5 polish (v1.5 - deadline May 19, 2026)
**WBS:** v1.5 polish track (no new WBS leaf - refinement of existing 3.x analytics surface and 5.x insights surface)
**Related:** ADR-0011 (client-side Pattern Engine - what the chart visualises); ADR-0012 (Tier 3 determinism - drives the marker-band copy); `.claude/specs/sprint-4-5-spec.md` §2.4 (5 algorithms), §2.6 (pipeline), §7 TC-36/TC-37 (disclaimer ack gate); CLAUDE.md "Copy rules"

## Goal

Resolve two reported UX problems on the v1.5 mainline:

- **P1:** The Patterns tab (`apps/mobile/lib/features/analytics/presentation/analytics_screen.dart:55..65`) shows a chart, a `PatternInsightCard` (legacy Gemini-driven), and an `_InsightsEntryCard` (lines 352..403) that opens a separate Insights screen. The user cannot tell whether Patterns and Insights are the same view or different views.
- **P2:** The Insights screen (`apps/mobile/lib/features/insights/presentation/screens/insights_screen.dart:173..255`) renders the mood-score line, dashed H_t overlay, 5 tier bands, and tier markers without any reading affordances. A first-time viewer cannot read what "Storm Season" means or what a Tier 1/2/3 marker indicates.

Out of scope: changes to the Pattern Engine itself (`features/pattern_engine/**`), changes to the Cloud Function path, changes to `firestore.rules`. This is presentation-layer-only work.

## Decision A - Patterns and Insights become ONE screen ("Insights"); Analytics index becomes the Patterns tab's at-a-glance summary

The chosen structure is option **(b) with a strict copy/role rebrand**:

- The **Patterns** bottom-nav tab keeps its slot (index 3 in `apps/mobile/lib/app/router.dart:225..248`) and route (`/analytics`). It becomes a **"summary dashboard"**: window selector, the existing `_ChartCard` (the 3-category mood-line chart, restyled with a clearer header), the three `_QuickStatsRow` cards, and ONE primary call-to-action card that opens Insights. The legacy `PatternInsightCard` (Gemini insights) stays gated on `featureFlagsProvider.aiPatternAnalysisEnabled` and is otherwise unchanged.
- The **Insights** screen at `/analytics/insights` becomes **the** deep-read surface - the Pattern Engine output (mood-score time series + Garden Health EWMA overlay + tier-band heatmap + marker band + read-affordances). The disclaimer ack gate stays exactly as it is (TC-36/TC-37).

Why not collapse into one screen:

1. The Insights screen is gated behind a non-dismissible bipolar/medical disclaimer (`InsightsDisclaimerGate` at `apps/mobile/lib/features/insights/presentation/widgets/insights_disclaimer_gate.dart`). If we merge Patterns into Insights, every first-time visit to the Patterns bottom-nav tab fires the ack dialog - a regression on TC-36's intent, which is that the deeper Pattern-Engine read requires explicit informed consent. Keeping two surfaces preserves the "look-at-your-rhythm" affordance at /analytics without the modal.
2. The current `/analytics` chart is the 3-category mean-intensity view from `analytics_pkg` - a different dataset than the Insights chart (mood-score S_t + EWMA H_t). They are not duplicate views; they answer different questions ("how often did you log each mood" vs. "where is your garden's rhythm trending"). Merging would either drop one chart (regression) or stack two large charts in one scroll (incoherent).
3. Two surfaces also let us keep the Patterns tab discoverable to users who never acknowledge the disclaimer - they still get summary stats.

What the user perceives is therefore **NOT** "Patterns vs. Insights as two parallel views" but **"Patterns: a quick read of your last weeks → Open Insights for the full chart"**. The redesign below sells that hierarchy with copy and visual weight.

## Decision B - Adaptive scroll on phone, two-column on tablet (≥600 dp), three-column on desktop (≥900 dp)

The shell already breaks at 600 / 900 in `apps/mobile/lib/app/router.dart:274..275`. Match those breakpoints.

### Phone (< 600 dp)

Single-column vertical scroll (current behaviour). Order:

1. Title "Insights" + subtitle (existing).
2. **"What am I looking at?" expansion tile** (NEW - collapsed by default).
3. Window chips (existing `InsightsWindowChips`).
4. Chart card (existing `_ChartCard`).
5. **Tier band legend card** (NEW - always-visible on phone after first ack so the user has a glossary while scrolling the chart).
6. **Recent triggers list card** (NEW - last 5 tier-trigger days with date + tier + plain-English reason; tap a row to scroll the chart to that day).
7. Bottom breathing space.

### Tablet (600..899 dp)

Two columns above the chart-width breakpoint, single scroll. The chart card stretches across both columns to keep the time axis legible; the legend + recent-triggers list flow to the right of the "What am I looking at?" + window-chips column.

```
┌────────────────────────────────────────────────────────────────────┐
│ Insights                                                            │
│ A gentle read of how your garden has been moving lately.            │
├──────────────────────────────────┬─────────────────────────────────┤
│ What am I looking at?  [expand]  │ Tier band legend                │
│ Window: [ 7d  14d  30d ]         │  ● Flourishing  full bloom      │
│                                  │  ● Thriving    open canopy      │
│                                  │  ● Resting     gentle pace      │
│                                  │  ● Weathering  rain-fed         │
│                                  │  ● Storm Season sheltered       │
├──────────────────────────────────┴─────────────────────────────────┤
│ Mood score over time                       higher = brighter        │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │  (line chart fills full width, 220 dp tall)                     │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│ ● ●   ●         ●  ▲      ▲ ●                                       │
│  marker band - Tier 1 amber · Tier 2 coral · Tier 3 deep coral      │
├─────────────────────────────────────────────────────────────────────┤
│ Recent triggers (last 5)                                            │
│  May 11 · Tier 1 · gradual decline (Mann-Kendall)                   │
│  May 09 · Tier 2 · 5 quieter days out of 7                          │
│  May 07 · Tier 1 · gradual decline (Mann-Kendall)                   │
│  …                                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Desktop (≥ 900 dp)

Three columns. Chart fills the centre column (chart needs the width); the left rail holds the affordances and window chips; the right rail holds the legend and recent triggers. This puts the most-glanced content (the chart) in the line of sight and keeps the persistent legend always visible (no toggling).

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Insights                                                                   │
│ A gentle read of how your garden has been moving lately.                   │
├──────────────────┬───────────────────────────────────────┬─────────────────┤
│ What am I        │ Mood score over time                  │ Tier bands       │
│ looking at?      │                          higher = ↑   │  ● Flourishing   │
│                  │ ┌──────────────────────────────────┐  │  ● Thriving      │
│ • Solid line:    │ │   (line chart, 280 dp tall)      │  │  ● Resting       │
│   today's mood   │ │                                  │  │  ● Weathering    │
│ • Dashed line:   │ └──────────────────────────────────┘  │  ● Storm Season  │
│   rolling avg    │  ●  ●    ●          ●  ▲     ▲ ●      │                  │
│ • Coloured bands │  marker band                          │ Recent triggers  │
│   = ecosystem    │                                       │  May 11 · T1     │
│   tiers (always  │                                       │  May 09 · T2     │
│   alive)         │                                       │  May 07 · T1     │
│ • Dots = days a  │                                       │  ⋯               │
│   gentle nudge   │                                       │                  │
│   fired          │                                       │                  │
│                  │                                       │                  │
│ Window           │                                       │                  │
│ [ 7d 14d 30d ]   │                                       │                  │
└──────────────────┴───────────────────────────────────────┴─────────────────┘
```

Implementation note: use a `LayoutBuilder` at the top of `_InsightsBody` keyed on `constraints.maxWidth`. Below 600 dp → existing single-column. 600..899 dp → 2-column `Row` with `Flexible(flex: 1)` columns above the chart, then the chart and marker band span both. ≥ 900 dp → 3-column `Row` with relative weights 2 : 5 : 2 so the chart gets the middle 5/9 of the available width. Reuse the existing widget tree - only the wrapper changes.

## Decision C - Reading affordances (4 of them, all compassionate-copy compliant)

### C-1. "What am I looking at?" expansion tile

**Placement:** top of the body, above the window chips on phone; left rail on tablet/desktop.
**Component:** new widget `apps/mobile/lib/features/insights/presentation/widgets/chart_reading_guide.dart`. Uses `ExpansionTile` on phone (collapsed by default - saves vertical real estate); always-expanded plain `Column` inside a card on tablet/desktop.
**Title (collapsed):** `"What am I looking at?"`
**Body (expanded), three lines, Nunito 13/regular:**

```
• The solid line is the mood you've been logging - higher is brighter,
  lower is rainier. Empty spots are quiet days, never a streak break.
• The dashed line is the rolling rhythm - a 7-week weighted average that
  smooths the daily wobbles so a single rough day doesn't tilt it.
• The soft coloured bands are the garden's tiers. Every tier is alive -
  even Storm Season is sheltered, never withered.
```

Copy obeys CLAUDE.md "no clinical language" and "no streak-shaming" rules. The phrase "rolling rhythm" replaces the technical "EWMA H_t" the engineer might be tempted to surface; the academic term stays in the spec, not the UI.

### C-2. Persistent tier band legend

**Placement:** below the chart card on phone (always visible after first chart render); right rail above recent-triggers on tablet/desktop (always-on, never collapsed).
**Component:** new widget `apps/mobile/lib/features/insights/presentation/widgets/tier_band_legend.dart`. Card with five rows; each row is a 12 dp colour swatch + two-line text block.
**Rows (top-to-bottom, colour swatches reuse exactly the alpha/colour map already in `mood_score_chart.dart:43..49`):**

| Swatch (existing colour token) | Title | Subtitle |
|---|---|---|
| `softGreen α=0.55` (flourishing) | **Flourishing** | full bloom |
| `softGreen α=0.28` (thriving) | **Thriving** | open canopy |
| `mb.line α=0.18` (resting) | **Resting** | a gentle pace |
| `softCoral α=0.45` (weathering) | **Weathering** | rain-fed, growing |
| `coral α=0.30` (storm season) | **Storm Season** | sheltered, never withered |

Copy obeys the "plants are NEVER destroyed" rule (CLAUDE.md "NEVER use" list). The subtitle on Storm Season explicitly says "sheltered, never withered" so the visual coral red doesn't read as alarm.

### C-3. Marker tooltips (tap-to-explain)

**Placement:** the existing `PatternMarkerBand` already supplies a `Tooltip(message: 'Tier N · MMM D')` (`apps/mobile/lib/features/insights/presentation/widgets/pattern_marker_band.dart:71..81`). Extend it.
**Change:** tap on a marker shows a popover (mobile: `showModalBottomSheet`; tablet/desktop: anchored popover) with:

- The date (existing).
- The tier name + colour swatch.
- ONE plain-English reason from the Pattern Engine output. Surface the `triggeredTier` field's *which-algorithm-fired* via a new optional `DailyInsight.triggerReason` enum (`Pattern Engine` already knows; pipe it through). Mapping:

| Algorithm (from spec §2.4) | Plain-English copy |
|---|---|
| Mann-Kendall Z_trend < -1.96 | "Gradual decline across the past two weeks." |
| Sliding 5-of-7 | "Five quieter days out of the last seven." |
| 3-consecutive S ≤ -0.6 | "Three days in a row of heavier weather." |
| z_day < -2.5 | "Today's mood is unusually lower than your own typical." |
| CUSUM breach | "A sustained shift below your usual ground line." |

(All five obey CLAUDE.md "no fix-your-mood verbs" - "decline" is acceptable as observation, not prescription.)

- A one-line affordance link: `"Want to talk through it? Open the gentle next step →"` - taps navigate to whichever intervention surface the Pattern Engine dispatched for that day (already persisted in `users/{uid}/interventions/{id}`). If no intervention exists for that day (e.g. the user opted out, or the cooldown blocked), the link is omitted (no UI dead end).

**Domain change required:** add `String? triggerReasonKey` (a stable enum-as-string) to `DailyInsight` so the marker popover can label the marker without re-running the engine. Source: the engineer reads it from the existing `users/{uid}/patterns/{date}` document, which the Pattern Engine writes (per ADR-0011); the document already contains the algorithm flags. Surface a single dominant reason - if multiple algorithms fired the same day, pick the highest-tier one; within a tier, pick the algorithm with the strongest signal (the existing `RunPatternEngineUseCase` already returns a `Tier` enum, not the algorithm; add an optional second field `PatternEngineTriggerKind?` to that result so it can be persisted).

### C-4. Inline "How to read this" footnote under the marker band

**Placement:** directly under the marker band, inside the chart card, on every layout.
**Component:** in-line, no new widget - replace the existing `_LegendRow` (`insights_screen.dart:233..255`) with a two-row Wrap:

- Row 1 - the chart's two lines: `● Mood score    ┄ Rolling rhythm`.
- Row 2 - the markers: `● Tier 1 gentle    ● Tier 2 invitation    ● Tier 3 care`. The current legend uses tier-1/2/3 numerals; replace with the public-facing words "gentle / invitation / care" - these match the dispatcher's surface copy in HB-007 and avoid leaking the tier number, which is engineering jargon.

Below that, one Nunito-11 line in `mb.textDim`: `"Empty slots are quiet days - never a streak break."` (already in the screen).

## Decision D - Patterns tab redesign (when separate from Insights)

`analytics_screen.dart` keeps its current four sections, with the following changes:

1. **Keep:** `_Header` ("Patterns"), `MoodWindowSelector`, `_ChartCard` (mean-intensity-by-category chart), `_QuickStatsRow` (three stat cards), `PatternInsightCard` (Gemini-flag-gated, no change).
2. **Replace `_InsightsEntryCard` (lines 352..403)** with a more decisive primary CTA card - same widget skeleton, new copy and visual prominence:

    - Tile becomes a full-width `MbCard` with `primary`-tinted background (use `theme.colorScheme.primary.withValues(alpha: 0.08)`), 56 dp leading icon circle (vs. 40 dp today), and a "→" trailing chevron.
    - **Headline (Nunito 16/700):** `"Open detailed insights"`.
    - **Subtitle (Nunito 13/regular):** `"See your mood-score timeline, rolling rhythm, and the gentle nudges your garden has noticed lately."`.
    - **No body padding change**; just visual weight. The card sits where the existing `_InsightsEntryCard` sits in the column (between `_ChartCard` and `PatternInsightCard`).

3. **Reorder:** move the CTA card to the slot **directly under** `_ChartCard` (i.e. between lines 56 and 58 in current source). The CTA is the most important affordance on this tab now that the rebranding works, so it should sit above the lower-priority `PatternInsightCard` (which is feature-flag-gated and may even be invisible).

4. **`PatternInsightCard` retains its current copy and code path.** It is independent of the Insights screen - it surfaces Gemini text insights (e.g. "You tend to log calm on weekends") not the Pattern Engine output. No edits to this card or its provider chain in this brief.

## Files to create / extend

### New files

| Path | Purpose |
|---|---|
| `apps/mobile/lib/features/insights/presentation/widgets/chart_reading_guide.dart` | C-1 expansion / always-on guide. `ConsumerWidget` - accepts a `bool alwaysExpanded` constructor flag. |
| `apps/mobile/lib/features/insights/presentation/widgets/tier_band_legend.dart` | C-2 legend card. Stateless. Pulls swatch colours from the same `MbColors` extension already in scope. |
| `apps/mobile/lib/features/insights/presentation/widgets/recent_triggers_card.dart` | Phone bottom / tablet+desktop right rail. Renders the last 5 non-null `triggeredTier` days from the `insightsStreamProvider` data. Each row tappable to scroll the chart to that date (use a `ScrollController` exposed by the chart card - see "Engineering notes" below). |
| `apps/mobile/lib/features/insights/presentation/widgets/marker_detail_sheet.dart` | C-3 tap-target. Bottom sheet on phone; anchored popover via `showMenu` or `OverlayPortal` on tablet+desktop. Takes a `DailyInsight` + an optional `InterventionRecord?` for the affordance link. |
| `apps/mobile/lib/features/insights/presentation/widgets/insights_layout.dart` | The `LayoutBuilder` wrapper that picks phone / tablet / desktop layout. Returns `_InsightsBody` (extracted) with the same children re-arranged. |

### Files to extend

| Path | Change |
|---|---|
| `apps/mobile/lib/features/insights/presentation/screens/insights_screen.dart` | Replace the inline `ListView` in `_InsightsBody` with `InsightsLayout(child: _InsightsContent(...))`. Drop the inline `_LegendRow` (replaced by `TierBandLegend` + new "chart key" row inside `_ChartCard`). No change to the disclaimer gate logic - it stays at the outer `Scaffold` body level. |
| `apps/mobile/lib/features/insights/domain/entities/daily_insight.dart` | Add optional `PatternEngineTriggerKind? triggerReasonKey`. Pure-Dart enum sibling to `Tier`; values mirror the five spec §2.4 algorithms. **Domain-layer change - keep `freezed_annotation` only, no new imports.** |
| `apps/mobile/lib/features/insights/data/insights_repository_impl.dart` | Read the algorithm-flag fields off the persisted `users/{uid}/patterns/{date}` document and populate `triggerReasonKey`. If the doc predates the Pattern Engine's write of those flags, leave the new field null - the marker popover renders without the algorithm copy (graceful degradation). |
| `apps/mobile/lib/features/insights/presentation/widgets/pattern_marker_band.dart` | Wrap each `_Marker` in a `GestureDetector` (mobile) / `InkResponse` (tablet+desktop) that opens `MarkerDetailSheet`. Preserve the existing `Semantics(label: …)` for screen readers. |
| `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart` | Rewrite `_InsightsEntryCard` to the "primary CTA" shape described in Decision D. Reorder so the CTA is the slot directly under `_ChartCard` (move from line 57 to line ~56 - between chart and feature-flagged insights card). |

### Files not to touch

- `apps/mobile/lib/features/insights/domain/repositories/insights_repository.dart` - repository contract is unchanged; the new `triggerReasonKey` field is filled in by the impl from existing persistence. No new abstract method.
- `apps/mobile/lib/features/pattern_engine/**` - engine writes the algorithm flags already (per ADR-0011 §"Pattern Engine output"). Confirm before coding; if it does not, file a separate domain task - this brief stops there. **Architect sign-off required** before any pattern-engine edit.
- `apps/mobile/lib/app/router.dart` - no route changes. **Architect sign-off required** if route changes are needed; none are anticipated.
- `firestore.rules` - no rule changes; the data is already readable per-user. **security-reviewer sign-off required** if rules need to be touched; they should not.
- `packages/analytics/**` - chart package stays as-is. The new affordances live in the app, not the package.

## Engineering notes

1. **Layout DRY.** Pull the existing `ListView` children into a typed list of widgets and let `InsightsLayout` decide how to arrange them. Do NOT duplicate the chart card body in three layouts.
2. **Chart-to-marker scroll integration (Recent Triggers tap).** The fl_chart-based `MoodScoreLineChart` accepts an index but does not currently focus a day. Implement Recent-Triggers-tap as an `Inherited`/`Provider`-published `int? focusedDayIndex` that the chart reads to draw a vertical highlight line - `fl_chart` supports a `LineTouchData(touchTooltipData)` for tooltips, but not programmatic focus. The simplest v1.5 cut: tap-to-scroll-marker-band-to-that-marker (the marker-band animates a scale on the tapped dot). Defer chart-focus to v1.6 if it costs more than half a day.
3. **Domain layer purity.** `PatternEngineTriggerKind` lives in `apps/mobile/lib/features/insights/domain/entities/`. It is a pure-Dart enum with `freezed_annotation` only. The Pattern-Engine feature already has a `Tier` enum at `apps/mobile/lib/features/pattern_engine/domain/entities/tier.dart`; mirror the import style - relative-from-domain within feature, absolute `package:moodbloom/...` across features (per CLAUDE.md "Imports" rule).
4. **Tablet/desktop semantics.** When two columns share scroll, the right rail (legend + recent triggers) should NOT have its own scrollable. The whole body is one `SingleChildScrollView`; the rails are `Column`s. Avoid nested scroll views.
5. **Disclaimer ack gate is unchanged.** The new affordance widgets all render inside the `gate == InsightsGateState.ready` branch. The `_PreAckCard` still covers the chart slot pre-ack. The new layout wrapper sits AROUND that switch - confirm by reading `insights_screen.dart:89..100` before refactoring.

## Acceptance criteria (the engineer's done-when)

The feature is complete when, on the v1.5 mainline:

- [ ] On phone (e.g. 360x800), the Insights screen shows: title, "What am I looking at?" collapsed tile, window chips, chart card with restyled key row, tier band legend, recent triggers card. All five fit in one scroll without nested scrolls. Tap the expansion → reveals the 3 bullet points without re-firing the disclaimer dialog.
- [ ] On tablet (e.g. 768x1024), the two-column layout shows guide + chips on the left, legend + recent triggers on the right above the chart. The chart spans the full width below. No overflow at 600 dp width exactly.
- [ ] On desktop (e.g. 1440x900), the three-column layout shows guide on the left, chart in the centre, legend + triggers on the right. The chart card width is ≥ 540 dp at 1280 dp container max-width (per the `_desktopBodyMax` cap in `router.dart:280`).
- [ ] Tapping any tier marker on the marker band opens a popover/sheet showing date, tier name, plain-English reason. If the day has an intervention record, the "Open the gentle next step" link routes to `/intervention/{breathing|journal|crisis}` with the existing `InterventionDispatch` extra (per HB-007 §"Files to extend").
- [ ] The Patterns tab's CTA card reads "Open detailed insights" with the new copy, is visually primary-tinted, and sits directly under the chart card (above the flag-gated `PatternInsightCard`).
- [ ] No copy regression: a CLAUDE.md banned word ("delete", "clear", "lost", "destroyed", "wilted", "dying", "fix", "boost", clinical "depression / anxiety disorder / bipolar / diagnosis" used as user labels) does not appear in any added widget text. The architect's reviewer agent runs the secret-scan + the copy linter that flags those words.
- [ ] All added widgets carry a `Semantics(label: ...)` on interactive nodes; expanding the guide and tapping a marker each announce a meaningful label on TalkBack/VoiceOver.
- [ ] No domain layer import of `package:flutter/*` or `package:firebase_*/*` is introduced. `dart analyze` is clean.
- [ ] Existing test suites pass; one new widget test per added widget (5 new files → 5 widget tests minimum); one integration test that walks: log a mood → ack disclaimer → tap marker → see popover → tap "next step" → land on `/intervention/breathing` (or the relevant tier).

## Open questions (resolve before coding)

1. **Marker tap on the chart line itself (not just the marker band):** out of scope for v1.5? Yes - keep marker-band-only taps. Chart-line dot taps deferred to v1.6.
2. **Long Pattern Engine history (> 90 days) recent-triggers list:** cap the list at 5 always; no "see all" affordance in v1.5. v1.6 may add a `/insights/triggers` sub-route.
3. **Wide desktops (> 1280 dp container):** the chart never exceeds `_desktopBodyMax = 1280` (`router.dart:280`). The right rail naturally caps at the container edge. No special-case needed.

## Compliance check

- Clean Architecture domain-zero-imports rule: satisfied. Only one domain edit (`daily_insight.dart` - new enum + optional field, both pure Dart).
- Enterprise Term Assignment requirements touched: **R3** (architecture quality - adaptive layout is the canonical responsive pattern; the layout wrapper consolidates a single source of truth); **R4** (user-centric - addresses two named user complaints with named copy + glossary affordances).
- CLAUDE.md feature-flag rollback: unaffected. `ai_pattern_analysis_enabled` still gates `PatternInsightCard` on the Patterns tab. The Insights screen is not Gemini-driven.
- CLAUDE.md do-not-do list: no edits to `firestore.rules`, `functions/src/*`, `main.dart`, or `router.dart`. One feature-domain edit (`daily_insight.dart`) but no cross-feature contract change.
- Quality gates affected: **A11y** (new Semantics labels on every new widget); **Performance** (no new network calls, no new streams - all data already on the existing `insightsStreamProvider`).
