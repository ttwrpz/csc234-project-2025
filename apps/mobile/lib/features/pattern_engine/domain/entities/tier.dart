/// Tier of intervention triggered by the Pattern Engine.
///
/// Higher tier dominates when multiple algorithms fire on the same day:
/// `three > two > one > null` (no trigger). See HB-004 §"Domain shape — Tier"
/// and ADR-0010 §8 / ADR-0011 §2.
///
/// Pure-Dart enum — no Flutter / Firebase imports per the domain-purity rule
/// in CLAUDE.md.
enum Tier {
  /// Mild — Mann-Kendall trend test fired (gradual worsening).
  one,

  /// Moderate — sliding 5-of-7 fired (sustained lows).
  two,

  /// Acute — 3-consecutive / Z-score / CUSUM fired (lands Day 3).
  three;

  /// Returns the higher of [a] and [b], treating `null` as the lowest tier.
  /// The orchestrator (Day 3) folds per-algorithm Tier hits through this.
  static Tier? escalate(Tier? a, Tier? b) {
    if (a == null) return b;
    if (b == null) return a;
    // Enum index ordering matches severity: one < two < three.
    return a.index >= b.index ? a : b;
  }
}
