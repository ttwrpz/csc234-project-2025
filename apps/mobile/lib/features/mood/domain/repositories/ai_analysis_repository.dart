import 'package:core/core.dart';

import '../../../analytics/domain/entities/pattern_insight.dart';
import '../ai_analysis_failure.dart';
import '../entities/ai_suggestion.dart';
import '../entities/mood_entry.dart';

/// Contract for any backend that surfaces AI-derived signals to the app:
/// per-entry mood classification (`analyzeMoodText`) and pattern insights
/// over history (`analyzePatterns`). Both call into Cloud Functions via
/// the same trust boundary — the Cloud Function reads `request.auth.uid`
/// from the Firebase Auth token. Passing `userId` from the client would
/// be both redundant and a trust-boundary violation.
abstract class AIAnalysisRepository {
  /// Returns `false` when the `ai_pattern_analysis_enabled` Remote Config
  /// flag is off. Callers MUST short-circuit `analyzePatterns` when this
  /// is false — both as defence in depth (the server still runs) and as
  /// the kill-switch hook.
  bool get isEnabled;

  Future<Result<AiSuggestion, AiAnalysisFailure>> analyzeMoodText({
    required String text,
    String? locale,
  });

  /// Calls `analyzePatterns` and returns the deserialised insights.
  /// Returns an empty list when there is not enough data to surface any
  /// pattern (the server applies the sample-size floor; the client never
  /// fabricates insights of its own).
  Future<Result<List<PatternInsight>, AiAnalysisFailure>> analyzePatterns({
    required List<MoodEntry> history,
    int windowDays = 90,
  });
}
