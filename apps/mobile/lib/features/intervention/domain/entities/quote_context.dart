import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../mood/domain/entities/mood_type.dart';

part 'quote_context.freezed.dart';

/// Read-only context handed to [AIQuoteRepository.requestSuggestion] so the
/// Cloud Function can shape a personalized Tier 1/2 suggestion.
///
/// Carries only AGGREGATE signals — no raw mood text, no entry ids, no
/// timestamps. Mood text never leaves the client (CLAUDE.md "Never log PII"
/// rule). The Cloud Function receives a summary, picks one of N templates,
/// and Gemini fills in a phrase under the Safety Filter's allow-list.
@freezed
abstract class QuoteContext with _$QuoteContext {
  const factory QuoteContext({
    /// ISO-8601 weekId (`YYYY-Www`) — for log correlation only.
    required String weekId,

    /// Today's average score `S` in [-1, +1]. Negative = rough day.
    required double dailyAvgS,

    /// The most-logged mood today, or null if the user has not logged today.
    /// Used by the Cloud Function to pick a template; never echoed back to
    /// the user verbatim.
    MoodType? dominantEmotion,
  }) = _QuoteContext;
}
