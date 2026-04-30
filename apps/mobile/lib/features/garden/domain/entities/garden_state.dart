import 'package:freezed_annotation/freezed_annotation.dart';

part 'garden_state.freezed.dart';

/// Snapshot of the user's garden visualization. Computed by
/// `ComputeGardenStateUseCase` from a list of `MoodEntry`s and rendered by
/// `GardenScreen`. The entity is pure Dart so the domain layer stays free of
/// Flutter / Firebase imports.
///
/// Sprint 3 only renders the *positive* half of the seven pivot features:
/// flowers for happy/calm. The compassionate-reframing variants (wilting
/// plants for `negativeMild`, rain clouds for `negativeStrong`) land in S4 —
/// see [DayBloomKind] for the forward-compatible enum.
@freezed
class GardenState with _$GardenState {
  const factory GardenState({
    /// Total number of positive mood entries in the user's history. Drives
    /// the canvas density: more positives → more flowers.
    required int positiveMoodCount,

    /// Consecutive days, ending today, on which the user logged at least one
    /// positive mood. Empty days break the streak silently — there is no
    /// streak-shaming copy.
    required int currentStreakDays,

    /// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
    /// length 7. Drives the weekly bloom bar.
    required List<DayBloom> last7Days,
  }) = _GardenState;

  const GardenState._();

  /// True when the canvas has nothing to render. Used by the screen to swap
  /// in the compassionate empty-state copy.
  bool get isEmpty => positiveMoodCount == 0;
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
/// S3 only emits [bloom] (any positive mood that day) or [empty] (no positive
/// mood — whether the day was missing entirely or contained only negatives).
/// S4 will introduce `wilting` and `rainCloud` for `negativeMild` and
/// `negativeStrong` dominant days respectively. The enum is open by design.
enum DayBloomKind { bloom, empty }
