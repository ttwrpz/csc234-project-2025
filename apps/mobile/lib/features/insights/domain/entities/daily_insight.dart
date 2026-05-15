import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../mood/domain/entities/mood_type.dart';
import '../../../pattern_engine/domain/entities/tier.dart';
import 'pattern_engine_trigger_kind.dart';

part 'daily_insight.freezed.dart';

/// One-day rollup that the Insights chart renders. Derived from the
/// per-feature collections (mood entries + pattern documents); never
/// persisted in its own right.
///
/// Field semantics:
///  * `date` — local-midnight `DateTime` for the day.
///  * `avgMoodScore` — average `S_t = v × i/5` across every entry on
///    [date]; null if the user logged nothing that day.
///  * `gardenHealthH` — EWMA `H_t` for the day (the Pattern Engine
///    persists this on the `users/{uid}/patterns/{date}` document);
///    null when no pattern document exists yet (gap day).
///  * `dominantEmotion` — the mood type with the most entries on
///    [date]; null on empty days. Ties resolved by `MoodType.values`
///    declaration order.
///  * `entryCount` — number of mood entries logged on [date].
///  * `triggeredTier` — Pattern Engine output (null = no algorithm
///    fired). Drives the marker band on the chart.
///  * `triggerReasonKey` — which of the 5 algorithms produced the trigger
///    (null on no-trigger days). Surfaced to the marker-tap popover so
///    the popover can render a plain-English reason without re-running
///    the engine. Resolution rule when multiple algorithms fire: highest
///    tier first, then the strongest within the tier — see
///    [PatternEngineTriggerKind] doc.
///
/// Pure-Dart entity — imports only `freezed_annotation` and sibling
/// domain enums, per the domain-purity rule in CLAUDE.md.
@freezed
abstract class DailyInsight with _$DailyInsight {
  const factory DailyInsight({
    required DateTime date,
    required double? avgMoodScore,
    required double? gardenHealthH,
    required MoodType? dominantEmotion,
    required int entryCount,
    required Tier? triggeredTier,
    @Default(null) PatternEngineTriggerKind? triggerReasonKey,
  }) = _DailyInsight;

  /// Convenience factory for an "empty slot" day (no entries, no
  /// pattern document). Empty slots are part of the chart; the
  /// presentation layer renders them as gaps, never as streak shame.
  factory DailyInsight.empty(DateTime date) => DailyInsight(
    date: date,
    avgMoodScore: null,
    gardenHealthH: null,
    dominantEmotion: null,
    entryCount: 0,
    triggeredTier: null,
    triggerReasonKey: null,
  );
}
