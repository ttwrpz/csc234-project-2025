# ADR-0006 — Compassionate Reframing of Negative Moods (Wilting + Rain Cloud)

**Status:** Superseded by ADR-0010 (2026-05-09)
**Date:** 2026-05-01
**Deciders:** orchestrator + architect
**Related:** ADR-0001 (repo structure & Clean Architecture); CLAUDE.md pivot feature #7 ("compassionate reframing"); user story US-Som-1 ("no user action to clean up a rain cloud")

> **Superseded.** The intensity-split visual taxonomy (wilting plants for negative intensity 1–3, rain clouds for 4–5) is replaced by the ecosystem model in ADR-0010 (Plants Never Die). The wilting silhouette and the rain-cloud-as-mood widget no longer ship in v1.0; their files and tests are deleted on the Sprint 4 redesign branch. This ADR is preserved as a record of *why* the design moved on — the rationale around US-Som-1 (no dismiss action, autonomous fade) carries forward to the new Atmosphere overlay even though the visual taxonomy does not. See `docs/audit/sprint-4-redesign-audit.md` for the full triage.

## Context

Sprint 3 shipped only the positive half of the garden. `DayBloomKind` was scaffolded as a two-value enum (`bloom`, `empty`) at `apps/mobile/lib/features/garden/domain/entities/garden_state.dart:54`, with a TODO comment reserving room for `wilting` and `rainCloud`. `GardenState` exposes only `positiveMoodCount`, `currentStreakDays`, and `last7Days[7]`. `ComputeGardenStateUseCase` (pure Dart) buckets only positives; negative entries currently render nothing on the canvas.

CLAUDE.md pivot feature #7 is unambiguous: **positive moods become flowers; negative intensity 1–3 becomes wilting plants; negative intensity 4–5 becomes rain clouds that fade on their own.** The split is on intensity within the negative band, not on `MoodCategory` (which is a coarser bucket of `negativeMild | negativeStrong` derived from mood-type semantics, not user-felt strength).

US-Som-1 supplies the most important behavioural constraint: **the user must never have to clean up a rain cloud.** A "swipe to dismiss" or "tap to clear" interaction would re-introduce the very fix-your-mood verb pattern that the copy rules forbid. The cloud must dissipate on its own without user input, on a timeline short enough that demo-day visual cohesion is preserved (15–25 seconds per the Sprint 4 acceptance bar).

Two engineering forces are in tension with the product brief. First, presentation state (when did this cloud start fading? how far through the animation is it?) is fundamentally non-domain — it is per-frame visual ephemera with no business meaning and no value in persistence. Second, golden tests demand determinism: a cloud animating on a wall-clock timer would baseline differently every CI run. We need a model where the same `MoodEntry` produces the same fade duration on every render, without storing animation state in Firestore or Drift.

A third concern: distinguishing a wilting plant from a flower in **grayscale** golden snapshots. Colour-only differentiation (a green plant vs a brown one) collapses under the `ColorFiltered(matrix: greyscale)` transform we use for accessibility regression. The visual must differ by **shape**.

## Decision

### 1. Intensity is the splitter, not `MoodCategory`

The classification function lives in `presentation/` (it is a render concern, not a business invariant) and reads:

```dart
DayBloomKind kind(MoodType m, int i) {
  final clamped = i.clamp(1, 5);
  if (m.category == MoodCategory.positive) return DayBloomKind.bloom;
  return clamped <= 3 ? DayBloomKind.wilting : DayBloomKind.rainCloud;
}
```

The domain entity `MoodEntry` already validates `intensity` to `[1, 5]`; the `clamp(1, 5)` is a defensive belt-and-braces against future drift. `MoodCategory.negativeMild` vs `MoodCategory.negativeStrong` is **not** consulted — a `MoodType.angry` (categorised `negativeStrong`) at intensity 2 still becomes a wilting plant, because the user's self-report of "low intensity" outranks the type-level default. Conversely, `MoodType.sad` (categorised `negativeMild`) at intensity 5 becomes a rain cloud, because the user told us this is heavy.

This honours CLAUDE.md's framing — "negative intensity 1–3 = wilting plants; negative intensity 4–5 = rain clouds" — literally. It also keeps the splitter testable: a single 6-mood × 5-intensity table test in `compute_garden_state_test.dart` covers every input.

### 2. Day-aggregation priority `bloom > rainCloud > wilting > empty`

A single calendar day can contain multiple entries with mixed kinds. `last7Days[7]` (one cell per day) requires a single `DayBloomKind` per cell. The priority is:

1. **`bloom`** — any positive entry on the day wins. The garden visually "remembers" the bright moment.
2. **`rainCloud`** — high-intensity negatives surface above low-intensity ones because they carry more product weight (they are the entries that may eventually trigger the cheer-up intervention in S5).
3. **`wilting`** — low-intensity negatives.
4. **`empty`** — no entries.

Rationale for putting `bloom` ahead of `rainCloud`: the alternative ("worst mood wins") punishes a user who logs a happy lunch and a sad evening by erasing the lunch. The chosen order privileges agency without erasing the storm — the per-entry rendering on the main canvas (decision §4) still draws every cloud individually; the priority only governs the day-summary cell.

### 3. Extend the existing enum, no sealed class

`DayBloomKind` becomes:

```dart
enum DayBloomKind { bloom, empty, wilting, rainCloud }
```

Rejected alternative: a sealed `DayBloomKind` carrying per-cell intensity, fade-start timestamp, or entry-id list. That design would couple the domain entity to presentation concerns (rendering state, animation seeds) and inflate `GardenState` goldens with timestamps that change every frame. The presentation layer can compute everything it needs from the underlying `List<MoodEntry>` without the domain entity carrying any rendering hint.

`GardenState` gains two integer counts in the same edit:

```dart
final int wiltingMoodCount;
final int rainCloudMoodCount;
```

`isEmpty` becomes `positiveMoodCount == 0 && wiltingMoodCount == 0 && rainCloudMoodCount == 0`. The Semantics aggregate label updates to `"Garden, N positive moods, M gentler days, K stormy days drifting away"`.

### 4. Rain-cloud fade is ephemeral, deterministic per-entry-id, not persisted

`RainCloud` is a `StatefulWidget`. Animation duration is seeded from the entry id so the same cloud has the same fade length on every render:

```dart
final duration = Duration(milliseconds: 15000 + (entryId.hashCode.abs() % 11) * 1000);
// → 15000..25000 ms inclusive, deterministic per id
```

A `Tween<double>(begin: 1.0, end: 0.0)` ease-out runs once on `initState` and disposes on `dispose`. Nothing about the animation lifecycle is written to Firestore or Drift. If the user closes and reopens the app mid-fade, the cloud restarts at opacity 1.0 — this is acceptable: the clouds are a rolling visualisation of the most recent week, not a persistent diary.

A `@visibleForTesting final bool animate` flag (default `true`) lets goldens render the static silhouette without the `AnimationController`. Without this flag, golden tests would either flake on timing or require `pump`-ing arbitrary durations. The flag exists only for tests; production callers always omit it.

The visible-cloud cap of **5 simultaneously animating** clouds (with `i * 200ms` stagger) prevents frame drops on mid-range Android (Samsung A-series target per CLAUDE.md performance gate).

### 5. Wilting silhouette differs from flower by shape, not colour

`WiltingPlant` is built as:

```
Transform.rotate(
  angle: -25 * pi / 180,
  child: Icon(Icons.spa, color: MoodBloomColors.moodSad),
)
+ CustomPaint downward arc for drooping stem
```

The `~25°` rotation plus the `CustomPaint` arc give the plant a visibly different silhouette from a flower even when both are rendered through `ColorFiltered(matrix: greyscale)`. The colour difference (sad-mood palette vs flower palette) is supplementary, not load-bearing. This satisfies the WCAG 2.2 "do not rely on colour alone to convey meaning" criterion (a quality gate under the Enterprise Term Assignment R5 accessibility line) and makes the grayscale-golden regression honest.

Both widgets wrap their content in `ExcludeSemantics` — the surrounding `_GardenCanvas` exposes one aggregate Semantics label for the whole garden; per-flower / per-cloud children would create a forest of redundant announcements for screen readers.

## Consequences

**Positive**

- Domain churn is minimal: one enum extension, two integer counts on `GardenState`, three Sets in `ComputeGardenStateUseCase`. No new domain entities, no new use cases.
- Goldens are deterministic: id-hash seeding plus the `animate: false` test flag mean rain-cloud goldens look identical on every CI run.
- Copy and rendering stay in `presentation/`. The pure-Dart domain has zero awareness of "rain", "fade", or "drooping stem" — it sees only counts and `DayBloomKind`. CLAUDE.md's domain-zero-imports rule is preserved.
- US-Som-1 is satisfied by construction: there is no API surface for the user to dismiss a cloud. The cloud's fade is the only way it disappears.
- Wilting vs flower is distinguishable in grayscale, satisfying the a11y quality gate.

**Negative / trade-offs**

- A `@visibleForTesting` flag on a public widget is a small leak of test concerns into production code; we accept it because the alternative (a separate `RainCloudStatic` test-only fork) would split the silhouette implementation between two files.
- The 5-cloud visible cap means a user with seven consecutive intensity-5 negative days will see five animating clouds plus two static. We judge this acceptable — the alternative (animating all seven) risks frame drops, and a user with that profile is the exact target for the S5 cheer-up intervention, not for visual completeness.
- Restarting the fade on app re-open could theoretically be confusing ("I thought that cloud was gone") but the demo script and the per-entry detail screen (already shipped in S3) make the underlying entry traceable.

**Follow-up work this creates**

- `compute_garden_state.dart` migrates to the shared `localMidnight` helper in `packages/core/lib/src/date_utils.dart` (created on Day 3 alongside the pattern detector — see ADR-0007 follow-ups).
- `WeeklyBloomBar` switch-on-`DayBloomKind` must be extended for the two new kinds; without that edit the bar would crash on the new enum values once the use case starts emitting them.
- S5 takes ownership of the cheer-up banner that consumes the `interventionStateProvider`; the rain-cloud and wilting visuals do not have any banner today (decision was made deliberately to keep the visual change scope-bounded).
- The mood palette tokens (`moodSad`, `moodAnxious`, etc.) carry a `// TODO(S5-a11y)` for dark-mode contrast tuning. S4 acceptance does not require it; S5 does.

## Alternatives Considered

- **Sealed `DayBloomKind` carrying intensity and fade timestamp.** Rejected. Leaks presentation state into `domain/`; bloats goldens; couples animation timing to the entity boundary. The product gain (slightly more compact widget code) is not worth the architectural cost.
- **Splitting on `MoodCategory.negativeMild` vs `MoodCategory.negativeStrong`.** Rejected. Contradicts CLAUDE.md's literal "intensity 1–3 / 4–5" wording. More importantly, it ignores the user's self-reported intensity, which is the entire point of the slider — a high-intensity sad entry deserves a rain cloud regardless of mood-type-level categorisation.
- **Persisting fade-start timestamp in Firestore so clouds resume mid-fade across sessions.** Rejected. Write amplification (every cloud render mutates the entry document), no product value (users do not look for a specific cloud to track its fade), and contradicts the "ephemeral by design" mental model the copy rules establish.
- **Swipe-to-dismiss on rain clouds.** Rejected. Directly violates US-Som-1 ("no user action to clean up a rain cloud") and the "no fix-your-mood verbs" copy rule. The cloud must not be something the user is asked to manage.
- **Render wilting plants in a brown palette only (no shape change).** Rejected. Fails the grayscale-golden accessibility test and breaks WCAG 2.2 colour-independence.

## Compliance Check

- Clean Architecture domain-zero-imports rule: satisfied. The `kind(m, i)` helper lives in `presentation/`; the domain entity gains only an enum value and two integer counts, no Flutter or Firebase imports.
- Enterprise Term Assignment requirements touched: **R1** (the user story US-Som-1 is now traceable to an architectural decision); **R3** (architecture quality — the layer boundary is preserved under a new feature); **R5** (a11y quality gate — shape-not-colour differentiation).
- Quality gates affected: **Correctness** (new domain test cases for the bucketing function), **Accessibility** (grayscale-golden distinguishability, Semantics aggregate label updated), **Performance** (visible-cloud cap protects frame budget). Security: N/A (no rule changes, no Cloud Function changes).
- CLAUDE.md copy rules audit:
  - "No clinical language" — no "depression", "anxiety disorder", "symptom", or "diagnosis" in the new strings.
  - "No streak-shaming" — the streak counter remains positive-only and is unaffected; missing days remain empty cells.
  - "No fix-your-mood verbs" — the new Semantics label uses "drifting away" (descriptive) not "clear" or "remove" (imperative). The widget exposes no dismiss action.
  - "Compassionate imperatives" — N/A; no new user-prompting text.
  - "Hotline 1323 is footer-only" — N/A; this ADR does not introduce hotline copy.
- US-Som-1 traceability: the rain-cloud has no dismiss API at any layer. The fade is autonomous, deterministic, and bounded. The user is asked to do nothing.
