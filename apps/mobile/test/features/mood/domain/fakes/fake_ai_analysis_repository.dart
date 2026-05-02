import 'package:core/core.dart';
import 'package:moodbloom/features/analytics/domain/entities/pattern_insight.dart';
import 'package:moodbloom/features/mood/domain/ai_analysis_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/ai_suggestion.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/repositories/ai_analysis_repository.dart';

/// Hand-rolled fake mirroring [FakeMoodRepository]. Tests configure
/// [nextResult] to drive the controller / pill widget through its branches.
class FakeAiAnalysisRepository implements AIAnalysisRepository {
  FakeAiAnalysisRepository({
    this.nextResult,
    this.nextPatternResult,
    this.isEnabledOverride = true,
  });

  Result<AiSuggestion, AiAnalysisFailure>? nextResult;
  Result<List<PatternInsight>, AiAnalysisFailure>? nextPatternResult;
  bool isEnabledOverride;

  /// Captures every (text, locale) pair passed in.
  final List<({String text, String? locale})> calls = [];

  /// Captures every analyzePatterns call (history, windowDays).
  final List<({List<MoodEntry> history, int windowDays})> patternCalls = [];

  /// Optional artificial delay so tests can observe loading state.
  Duration delay = Duration.zero;

  @override
  bool get isEnabled => isEnabledOverride;

  @override
  Future<Result<AiSuggestion, AiAnalysisFailure>> analyzeMoodText({
    required String text,
    String? locale,
  }) async {
    calls.add((text: text, locale: locale));
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return nextResult ?? const Err(AiAnalysisFailure.unknown(null));
  }

  @override
  Future<Result<List<PatternInsight>, AiAnalysisFailure>> analyzePatterns({
    required List<MoodEntry> history,
    int windowDays = 90,
  }) async {
    patternCalls.add((history: history, windowDays: windowDays));
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return nextPatternResult ?? const Ok(<PatternInsight>[]);
  }
}
