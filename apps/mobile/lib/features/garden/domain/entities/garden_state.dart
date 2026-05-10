import 'package:freezed_annotation/freezed_annotation.dart';

import 'atmosphere.dart';
import 'plant_tier.dart';

part 'garden_state.freezed.dart';

/// Snapshot of the user's garden visualization. Computed by
/// `ComputeGardenStateUseCase` from a list of `MoodEntry`s and rendered by
/// `GardenScreen`. Pure Dart so the domain layer stays free of
/// Flutter / Firebase imports.
///
/// The Sprint 4–5 ecosystem redesign (ADR-0010) replaces the previous
/// per-entry glyph counts (positive / wilting / rain-cloud) with two
/// signals on different timescales:
///   * [gardenHealth] — slow weekly EWMA (`H_t` ∈ [-1, +1]) folded over
///     per-day mood-score means. Drives [plantTier] (5 alive states).
///   * [atmosphere] — today-only mean mood-score, mapped to one of 4
///     weather states (calm/bright sun, light rain, storm). Resets
///     at local midnight.
///
/// Plants are NEVER destroyed/wilting/dying in any tier — the Storm
/// Season tier renders rain falling AROUND a sheltered garden, not on
/// the plants themselves. See ADR-0010 §1 for the no-wilt copy rule.
@freezed
abstract class GardenState with _$GardenState {
  const factory GardenState({
    /// Garden Health for the current week (`H_t`, range [-1, +1]).
    /// Resets to 0 at the start of every week (weekly harvest cycle —
    /// see ADR-0010 §3).
    required double gardenHealth,

    /// 5-tier ecosystem state derived from [gardenHealth].
    required PlantTier plantTier,

    /// 4-state weather overlay derived from today's mean mood-score.
    /// Defaults to `calmSunny` when the user has not yet logged today.
    required Atmosphere atmosphere,

    /// Last 7 days, newest first (today, yesterday, …, 6 days ago).
    /// Always length 7. Drives the daily-score strip below the canvas.
    required List<DayScore> last7Days,

    /// Total entry count across all of history. Used by the screen for
    /// diagnostics ("12 entries this week") and to derive [isEmpty].
    required int totalEntryCount,
  }) = _GardenState;

  const GardenState._();

  /// True when the user has logged no entries at all. Used by the
  /// screen to swap in the compassionate empty-state copy.
  bool get isEmpty => totalEntryCount == 0;
}

/// One cell in the daily-score strip. Carries the raw signed magnitude
/// so the widget can shade positive/negative days at varying intensity
/// rather than collapsing each day into a single "kind" enum.
@freezed
abstract class DayScore with _$DayScore {
  const factory DayScore({
    /// Local-midnight `DateTime` of the day this cell represents (in the
    /// user's local time zone).
    required DateTime day,

    /// Mean of `MoodScore.value` for entries logged on [day]. Range
    /// [-1, +1]. `null` when no entry was logged that day — distinct
    /// from "neutral 0", which would be a logged Okay×0 (impossible).
    required double? avgScore,

    /// Number of entries logged on [day]. Used by the strip's a11y
    /// label and by callers that want to surface "tap for entries".
    required int entryCount,
  }) = _DayScore;
}
