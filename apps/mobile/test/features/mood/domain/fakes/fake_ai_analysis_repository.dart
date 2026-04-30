import 'package:core/core.dart';
import 'package:moodbloom/features/mood/domain/ai_analysis_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/ai_suggestion.dart';
import 'package:moodbloom/features/mood/domain/repositories/ai_analysis_repository.dart';

/// Hand-rolled fake mirroring [FakeMoodRepository]. Tests configure
/// [nextResult] to drive the controller / pill widget through its branches.
class FakeAiAnalysisRepository implements AIAnalysisRepository {
  FakeAiAnalysisRepository({this.nextResult});

  Result<AiSuggestion, AiAnalysisFailure>? nextResult;

  /// Captures every (text, locale) pair passed in.
  final List<({String text, String? locale})> calls = [];

  /// Optional artificial delay so tests can observe loading state.
  Duration delay = Duration.zero;

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
}
