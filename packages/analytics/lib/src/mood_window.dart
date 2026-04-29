/// Window of mood entries surfaced on the line chart. Pure Dart enum so the
/// app and any future analytics consumer share the vocabulary without taking a
/// dependency on the mood feature.
enum MoodWindow {
  week(days: 7, label: '7d'),
  month(days: 30, label: '30d'),
  quarter(days: 90, label: '90d');

  const MoodWindow({required this.days, required this.label});

  /// Number of days this window covers, inclusive of today.
  final int days;

  /// Short label rendered on the segmented selector.
  final String label;
}
