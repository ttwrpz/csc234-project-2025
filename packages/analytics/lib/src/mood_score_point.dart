/// A single (day, score) sample plotted on [MoodScoreLineChart]. The
/// `score` is in the closed range `[-1, +1]` (spec §2.1 `S_t = v × i/5`).
///
/// `health` is the optional EWMA `H_t` overlay value (spec §2.3,
/// α = 0.15). When null, the chart simply skips the overlay marker for
/// that day; the primary mood-score line stays continuous via the
/// `null` allowance below.
///
/// Pure Dart so the chart widget can be unit-tested without an emulator
/// or any Riverpod / Firebase plumbing.
class MoodScorePoint {
  const MoodScorePoint({required this.day, required this.score, this.health});

  /// Local-time midnight for the day the sample is bucketed under.
  final DateTime day;

  /// Mean per-day mood score `S_day` in `[-1, +1]`, or null on gap days.
  final double? score;

  /// EWMA `H_t` in `[-1, +1]`, or null when the user has no entries
  /// in the current week yet.
  final double? health;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodScorePoint &&
          other.day == day &&
          other.score == score &&
          other.health == health;

  @override
  int get hashCode => Object.hash(day, score, health);

  @override
  String toString() =>
      'MoodScorePoint(day: $day, score: $score, health: $health)';
}
