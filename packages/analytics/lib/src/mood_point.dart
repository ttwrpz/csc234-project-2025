import 'chart_mood_category.dart';

/// A single (day, category, mean-intensity) sample plotted on the mood line
/// chart. Pure Dart so the chart widget can be unit-tested without an emulator
/// or any Riverpod / Firebase plumbing.
class MoodPoint {
  const MoodPoint({
    required this.day,
    required this.category,
    required this.meanIntensity,
  });

  /// Local-time midnight for the day the sample is bucketed under.
  final DateTime day;

  /// Which line on the chart this point belongs to.
  final ChartMoodCategory category;

  /// Aggregate intensity, expected to be in `[1, 5]`. The chart does not
  /// validate this — callers must ensure the input domain.
  final double meanIntensity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodPoint &&
          other.day == day &&
          other.category == category &&
          other.meanIntensity == meanIntensity;

  @override
  int get hashCode => Object.hash(day, category, meanIntensity);

  @override
  String toString() =>
      'MoodPoint(day: $day, category: $category, meanIntensity: $meanIntensity)';
}
