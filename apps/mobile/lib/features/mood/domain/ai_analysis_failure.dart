import 'package:core/core.dart';

/// All failure modes for the `analyzeMoodText` Cloud Function pipeline.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch help
/// from the analyzer. Extends [Failure] directly (NOT `MoodFailure`) because
/// AI failures are conceptually distinct from mood-entity failures and
/// downstream AI-analysis callers reuse this taxonomy.
///
/// Imports only `package:core/core.dart` - domain-purity rule per CLAUDE.md.
sealed class AiAnalysisFailure extends Failure {
  const AiAnalysisFailure({required super.message});

  const factory AiAnalysisFailure.unauthenticated() = _Unauthenticated;
  const factory AiAnalysisFailure.invalidInput(String reason) = _InvalidInput;
  const factory AiAnalysisFailure.rateLimited(Duration retryAfter) =
      _RateLimited;
  const factory AiAnalysisFailure.geminiUnavailable() = _GeminiUnavailable;
  const factory AiAnalysisFailure.parseError(String reason) = _ParseError;
  const factory AiAnalysisFailure.network() = _Network;
  const factory AiAnalysisFailure.unknown(Object? cause) = _Unknown;
}

class _Unauthenticated extends AiAnalysisFailure {
  const _Unauthenticated() : super(message: 'You need to be signed in.');
}

class _InvalidInput extends AiAnalysisFailure {
  const _InvalidInput(this.reason) : super(message: 'AI input was rejected.');
  final String reason;
}

class _RateLimited extends AiAnalysisFailure {
  const _RateLimited(this.retryAfter)
    : super(message: 'AI is busy - try again shortly.');
  final Duration retryAfter;
}

class _GeminiUnavailable extends AiAnalysisFailure {
  const _GeminiUnavailable()
    : super(message: 'AI service is temporarily unavailable.');
}

class _ParseError extends AiAnalysisFailure {
  const _ParseError(this.reason)
    : super(message: 'Could not interpret AI response.');
  final String reason;
}

class _Network extends AiAnalysisFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _Unknown extends AiAnalysisFailure {
  const _Unknown(this.cause) : super(message: 'Unknown AI error.');
  final Object? cause;
}
