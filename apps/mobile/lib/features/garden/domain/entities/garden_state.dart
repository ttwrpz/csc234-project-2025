import 'package:freezed_annotation/freezed_annotation.dart';

part 'garden_state.freezed.dart';

/// Snapshot of the user's garden visualization. Computed by
/// `ComputeGardenStateUseCase` from a list of `MoodEntry`s and rendered by
/// `GardenScreen`. The entity is pure Dart so the domain layer stays free of
/// Flutter / Firebase imports.
///
/// Sprint 4 realises the compassionate-reframing variants previously only
/// scaffolded in S3:
///  * positive moods → flowers (drives `positiveMoodCount`)
///  * `negativeMild` (or any negative at intensity ≤ 3) → wilting plants
///    (`wiltingMoodCount`)
///  * `negativeStrong` *or* any negative at intensity ≥ 4 → rain clouds that
///    self-fade (`rainCloudMoodCount`)
///
/// The split between wilting and rain-cloud is driven by the user-felt
/// **intensity**, not the `MoodCategory` bucket — see ADR-0006 and
/// `ComputeGardenStateUseCase` for the rule.
@freezed
class GardenState with _$GardenState {
  const factory GardenState({
    /// Total number of positive mood entries in the user's history. Drives
    /// the canvas density: more positives → more flowers.
    required int positiveMoodCount,

    /// Total number of negative-mood entries at intensity 1–3 (gentler
    /// negatives). Rendered as wilting plants on the garden canvas.
    required int wiltingMoodCount,

    /// Total number of negative-mood entries at intensity 4–5 (stormier
    /// negatives). Rendered as rain clouds that drift and fade on their own
    /// — the user is never asked to clean them up.
    required int rainCloudMoodCount,

    /// Consecutive days, ending today, on which the user logged at least one
    /// positive mood. Empty days break the streak silently — there is no
    /// streak-shaming copy. **Wilting and rain-cloud days do NOT contribute
    /// to the streak**, by design (see ADR-0006).
    required int currentStreakDays,

    /// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
    /// length 7. Drives the weekly bloom bar.
    required List<DayBloom> last7Days,
  }) = _GardenState;

  const GardenState._();

  /// True when the canvas has nothing to render across all three glyph
  /// kinds. Used by the screen to swap in the compassionate empty-state copy.
  bool get isEmpty =>
      positiveMoodCount == 0 &&
      wiltingMoodCount == 0 &&
      rainCloudMoodCount == 0;
}

/// One cell in the weekly bloom bar.
@freezed
class DayBloom with _$DayBloom {
  const factory DayBloom({
    /// Midnight of the day in the user's local time zone.
    required DateTime day,
    required DayBloomKind kind,
  }) = _DayBloom;
}

/// Visual treatment for a single day in the bloom bar.
///
/// S4 realises all four variants:
///  * [bloom] — at least one positive mood that day.
///  * [rainCloud] — at least one negative mood at intensity ≥ 4 that day,
///    and no positives. Highest negative priority.
///  * [wilting] — at least one negative mood at intensity ≤ 3 that day,
///    and no positives or rain-cloud entries.
///  * [empty] — no entries at all that day.
///
/// Day-aggregation priority is `bloom > rainCloud > wilting > empty`.
enum DayBloomKind { bloom, empty, wilting, rainCloud }
