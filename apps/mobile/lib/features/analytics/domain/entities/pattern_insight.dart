import 'package:freezed_annotation/freezed_annotation.dart';

part 'pattern_insight.freezed.dart';
part 'pattern_insight.g.dart';

/// One pattern insight surfaced on the Analytics dashboard.
///
/// Lives in the domain layer and is decoded directly from the
/// `analyzePatterns` Cloud Function payload. Confidence is server-clamped
/// to [0, 1] and respects the sample-size floor (n < 10 → confidence
/// ≤ 0.5) regardless of effect size.
@freezed
abstract class PatternInsight with _$PatternInsight {
  const factory PatternInsight({
    required String id,
    required PatternInsightKind kind,
    required String text,
    required double confidence,
    required int sampleSize,
    required DateTime generatedAt,
  }) = _PatternInsight;

  factory PatternInsight.fromJson(Map<String, Object?> json) =>
      _$PatternInsightFromJson(json);
}

/// Insight families. The UI maps `kind` to a chip tone + copy template.
enum PatternInsightKind {
  weekday,
  streak,
  trend,
  gemini;

  /// Hand-rolled JSON mapping so the wire string stays lowercase even if
  /// future generated code adopts `name` differently.
  static PatternInsightKind fromWire(String wire) => switch (wire) {
    'weekday' => PatternInsightKind.weekday,
    'streak' => PatternInsightKind.streak,
    'trend' => PatternInsightKind.trend,
    'gemini' => PatternInsightKind.gemini,
    _ => PatternInsightKind.weekday,
  };
}
