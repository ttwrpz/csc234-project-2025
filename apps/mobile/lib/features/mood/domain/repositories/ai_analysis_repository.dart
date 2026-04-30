import 'package:core/core.dart';

import '../ai_analysis_failure.dart';
import '../entities/ai_suggestion.dart';

/// Contract for any backend that classifies short journal text into one of the
/// six MoodBloom mood categories.
///
/// No `userId` parameter — the Cloud Function reads `request.auth.uid` from
/// the Firebase Auth token. Passing `userId` from the client would be both
/// redundant and a trust-boundary violation.
abstract class AIAnalysisRepository {
  Future<Result<AiSuggestion, AiAnalysisFailure>> analyzeMoodText({
    required String text,
    String? locale,
  });
}
