# Sprint 5 - Static Performance Review (Day 4 part 1)

**Reviewer:** orchestrator (static-source sweep, read-only)
**Date:** 2026-05-18
**Audit head:** `f38408c1`
**Methodology:** grep-based source sweep + targeted Read against the S5 surface inventory. Does NOT replace the device-side `flutter run --profile --trace-startup` measurement, which lives in [sprint-5-cross-platform-runbook.md](sprint-5-cross-platform-runbook.md) and runs on Day 4 part 2.

## Summary

Posture is **good**. One MEDIUM finding (`cached_network_image` missing for user-uploaded media in pre-S5 widgets), one LOW finding (`AnimatedBuilder` text rebuild at 60fps in `breathing_screen.dart`). No HIGH findings. Recommend the device-side cold-start + frame-rate measurement to confirm the < 2s target.

Counts: **0 HIGH, 1 MEDIUM, 1 LOW, 2 informational.**

## Findings

### MEDIUM

#### P-M01 - `Image.network` without `cached_network_image` (pre-S5 widgets)

3 raw `Image.network` callsites:
- `apps/mobile/lib/features/mood/presentation/widgets/existing_media_strip.dart:90`
- `apps/mobile/lib/features/history/presentation/widgets/image_viewer.dart:62`
- `apps/mobile/lib/features/history/presentation/widgets/entry_attachments.dart:130`

These load user-uploaded photos from Firebase Storage at `users/{uid}/media/...`. Without caching, every history-screen scroll re-fetches the image; every entry-detail view re-fetches. `pubspec.yaml` does not declare `cached_network_image`.

**Impact:** Wasted bandwidth + slower history-scroll frame rates on cellular. Each photo redownloaded on every viewport entry. Mobile users on a 7-day garden with 20 entries containing photos see ~20 redownloads per scroll session.

**Recommendation:** Add `cached_network_image: ^3.4.1` to `apps/mobile/pubspec.yaml`. Replace the 3 `Image.network(...)` calls with `CachedNetworkImage(imageUrl: ...)`. This is a 6-line diff per call. Also update CLAUDE.md "Quality gates" §4 - the "images cached via `cached_network_image`" line is currently aspirational; this commit makes it true.

**Pre-S5 origin.** These widgets shipped in S3/S4; not introduced by S5. But CLAUDE.md asserts the dependency exists, and a v1.5 release audit is the natural place to close the gap.

**Severity downgrade:** MEDIUM not HIGH because it's a UX/data-cost issue, not a correctness issue. v1.5 ships without the fix if the team prefers; v1.6 is acceptable.

### LOW

#### P-L01 - Breathing-screen `AnimatedBuilder` rebuilds text at 60fps

`apps/mobile/lib/features/intervention/presentation/screens/breathing_screen.dart:165-198` wraps an `AnimatedBuilder` around a `Column` containing the breath circle (which legitimately rebuilds at 60fps via `Transform.scale`) AND a `Text('Breathe in…' / 'Breathe out…', ...)` widget.

The text changes only at the 4-second phase boundary (`_breathController.value < 0.4` for inhale, ≥0.4 for exhale), but the `AnimatedBuilder`'s `builder:` rebuilds the entire subtree 60 times per second.

**Impact:** Negligible. The `Text` widget is small, the `style:` is `theme.textTheme.titleMedium` (already-cached), and Flutter's diffing skips a layout pass when the same string is provided. But over a full 2-minute breathing session that's ~7200 unnecessary `Text` widget reconstructions.

**Recommendation:** Split the `AnimatedBuilder` into two:
- One that rebuilds the `Transform.scale + Container` subtree (60fps, justified).
- One that rebuilds only the cue `Text` (driven by a `ValueListenableBuilder<bool>` derived from `_breathController.value < _inhaleFraction`, which fires only on phase transitions).

OR: leave as-is and rely on Flutter's widget-tree diffing. A device-side `flutter run --profile` frame-rate trace will tell us whether this matters in practice. If frame rate is steady 60fps on the target Android device, skip the fix; if any janks are visible, apply it.

**Defer to v1.6** unless the device-side profile flags it.

### Informational

#### P-I01 - All S5 `ListView(...)` callsites are bounded

All instances of `ListView(...)` (non-builder constructor) found in the S5 + carryover surface load **fixed children**, not user data:
- `settings_screen.dart:40` - settings rows (fixed N≤10).
- `mood/log_mood_screen.dart:287` - log form sections (fixed).
- `history_screen.dart:110-111` - delegates to `_HistoryListView` which itself uses `ListView.builder` for the (bounded by harvest window) entry list.
- `analytics_screen.dart:39` - chart card + insight card (fixed children).
- `entry_detail_screen.dart:110` - bounded by per-entry attachment count (capped at 5).
- `insights_screen.dart:55` - fixed insight cards (window chip + chart + legend).
- `crisis_resources_screen.dart:150` - Hotline tile + 3 resource cards (fixed).

CLAUDE.md "Quality gates" §4 "no unbounded `ListView`" is satisfied across the S5 + carryover surface.

#### P-I02 - `MoodScoreLineChart` is bounded at 30 data points (max insights window)

`packages/analytics/lib/src/mood_score_chart.dart` uses `fl_chart`'s `LineChart`, which is internally optimized for time-series plots up to ~1000 points. The Insights screen caps at a 30-day window (`InsightWindow.thirtyDay`), so the chart sees at most 30 score points + 30 health points. No perf concern.

`fl_chart` itself uses `CustomPainter` internally - the chart's render pass is dominated by stroking 60 line segments, well within a single frame budget.

## What the static review CANNOT tell us

The device-side profile is the source of truth for:

1. **Cold start time** (CLAUDE.md target: < 2s on mid-range Android).
2. **Frame rate during Insights scroll** with 30 data points.
3. **Memory growth across a 50-entry harvest cycle** (the harvest archives `WeeklyGarden.entries` - does it leak any references?).
4. **Breathing screen frame budget** (P-L01 confirmation or dismissal).
5. **Banner-host overhead** - `InterventionBannerHost` wraps the entire `MaterialApp.router` output via `builder:`. It's a `ConsumerWidget` reading `interventionControllerProvider` on every route change. Device profile confirms whether the listen is cheap (expected: yes; the state-shape comparison is fast).

These measurements happen in [sprint-5-cross-platform-runbook.md](sprint-5-cross-platform-runbook.md) under "Performance profile."

## Recommendation

Static-review GO for v1.5. The 2 findings are non-blocking:
- P-M01 can ship as a v1.6 follow-up unless the team wants to land it now (6 lines per callsite × 3 callsites).
- P-L01 is contingent on the device-side profile - measure first.

The Day 4 device-side measurements are the load-bearing gate. If cold start < 2s, frame rate steady, and memory growth bounded, v1.5 is performance-ready.

## Sign-off

Static portion: 2026-05-18, orchestrator, audit head `f38408c1`.
Device-side measurements: pending - see [sprint-5-cross-platform-runbook.md](sprint-5-cross-platform-runbook.md).
