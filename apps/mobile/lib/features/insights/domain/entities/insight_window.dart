import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight_window.freezed.dart';

/// User-visible window over which the Insights screen aggregates mood +
/// pattern history. Default is 14 days — the Mann-Kendall trend test's
/// natural span (spec §2.4 algorithm 1) and a comfortable mid-month read.
///
/// Pure-Dart entity — no Flutter / Firebase imports per the
/// domain-purity rule in CLAUDE.md.
enum InsightWindowPreset {
  week(days: 7, label: '7d'),
  fortnight(days: 14, label: '14d'),
  month(days: 30, label: '30d');

  const InsightWindowPreset({required this.days, required this.label});

  /// Number of days the window covers, inclusive of today.
  final int days;

  /// Short label rendered on the segmented selector.
  final String label;
}

/// Resolved [start, end] day pair for a preset, computed against an
/// injectable "now" so use cases stay deterministic in tests.
///
/// Both endpoints are local-midnight `DateTime`s, inclusive. `dayCount`
/// equals the preset's `days` so the call-site does not have to subtract.
@freezed
abstract class InsightWindow with _$InsightWindow {
  const factory InsightWindow({
    required DateTime startDate,
    required DateTime endDate,
    required int dayCount,
    required InsightWindowPreset preset,
  }) = _InsightWindow;

  /// Resolves [preset] against [now]. `endDate` is today's local-midnight;
  /// `startDate` is today minus (preset.days - 1) so the window is
  /// inclusive on both sides.
  factory InsightWindow.from({
    required InsightWindowPreset preset,
    required DateTime now,
  }) {
    final local = now.toLocal();
    final end = DateTime(local.year, local.month, local.day);
    final start = end.subtract(Duration(days: preset.days - 1));
    return InsightWindow(
      startDate: start,
      endDate: end,
      dayCount: preset.days,
      preset: preset,
    );
  }
}
