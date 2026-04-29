import 'package:freezed_annotation/freezed_annotation.dart';

import 'mood_type.dart';

part 'ai_suggestion.freezed.dart';

/// Outcome of an `analyzeMoodText` Cloud Function call once the wire DTO has
/// been validated and mapped into the six-mood domain enum.
///
/// Pure-Dart entity — imports only `freezed_annotation` (annotation-only) and
/// the sibling `mood_type.dart`. No Flutter / Firebase / cloud_functions
/// imports per CLAUDE.md domain-purity rule.
///
/// `confidence` is asserted in `[0, 1]` in the private factory; out-of-range
/// values are programmer errors after the data layer has clamped (server
/// already clamps on the wire). The assert hard-fails dev builds so we catch
/// the bug at the boundary, not in the UI.
@freezed
class AiSuggestion with _$AiSuggestion {
  @Assert('confidence >= 0 && confidence <= 1', 'confidence must be in [0, 1]')
  const factory AiSuggestion({
    required MoodType mood,
    required double confidence,
    required String rationale,
    AiSuggestionAlternative? alternative,
    AiSafetyFlag? safetyFlag,
    required Duration latency,
  }) = _AiSuggestion;
}

/// Optional second-best mood suggested by the model. Surfaced in the override
/// UX so the user can swap from primary → alternative without retyping.
@freezed
class AiSuggestionAlternative with _$AiSuggestionAlternative {
  @Assert('confidence >= 0 && confidence <= 1', 'confidence must be in [0, 1]')
  const factory AiSuggestionAlternative({
    required MoodType mood,
    required double confidence,
  }) = _AiSuggestionAlternative;
}

/// Safety flags raised by the model. S3 ships only `selfHarm` — when set the
/// AI suggestion pill is hidden entirely (S4 will swap in a compassionate
/// banner). Keep the enum open for future flag additions without a schema
/// version bump.
enum AiSafetyFlag { selfHarm }
