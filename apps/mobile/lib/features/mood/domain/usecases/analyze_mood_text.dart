import 'package:core/core.dart';

import '../ai_analysis_failure.dart';
import '../entities/ai_suggestion.dart';
import '../repositories/ai_analysis_repository.dart';

/// Single-purpose use case for the AI suggestion pill. Sits between the
/// presentation controller and the repository per CLAUDE.md's "Use cases" rule
/// (controllers must not depend on repositories directly).
class AnalyzeMoodTextUseCase {
  const AnalyzeMoodTextUseCase({required AIAnalysisRepository repository})
    : _repository = repository;

  final AIAnalysisRepository _repository;

  Future<Result<AiSuggestion, AiAnalysisFailure>> call({
    required String text,
    String? locale,
  }) {
    return _repository.analyzeMoodText(text: text, locale: locale);
  }
}
