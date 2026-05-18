/// Identifies which of the 5 Pattern Engine algorithms most
/// strongly fired on a given day. Surfaced to the Insights marker-tap
/// popover so the popover can render a plain-English reason without
/// re-running the engine.
///
/// Resolution rule when multiple algorithms fire on the same day: the
/// `InsightsRepositoryImpl` picks the highest-tier trigger, then within
/// the tier picks the algorithm with the strongest signal. Tier 1 has
/// only one source (Mann-Kendall). Tier 2 has only one source
/// (sliding 5-of-7). Tier 3 sources are ordered by acuity:
/// 3-consecutive (deterministic) > z-score (single-day anomaly) >
/// CUSUM (sustained shift).
///
/// Pure-Dart enum — no Flutter / Firebase imports per the domain-purity
/// rule in CLAUDE.md. Lives next to the sibling [DailyInsight] entity.
enum PatternEngineTriggerKind {
  /// Mann-Kendall Z_trend < -1.96 over the 14-day window → Tier 1.
  /// User-facing copy: "Gradual decline across the past two weeks."
  mannKendall,

  /// 5 or more negative-score days within the trailing 7 → Tier 2.
  /// User-facing copy: "Five quieter days out of the last seven."
  sliding5of7,

  /// 3 consecutive days with `S_day` ≤ -0.6 → Tier 3.
  /// User-facing copy: "Three days in a row of heavier weather."
  threeConsecutive,

  /// Today's `S_day` is below the personal 30-day baseline by more than
  /// 2.5 σ → Tier 3.
  /// User-facing copy: "Today's mood is unusually lower than your own typical."
  zScore,

  /// CUSUM change-point statistic breached its threshold → Tier 3.
  /// User-facing copy: "A sustained shift below your usual ground line."
  cusum,
}
