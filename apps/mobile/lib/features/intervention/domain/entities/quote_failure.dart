import 'package:core/core.dart';

/// Failure modes for the Tier 1/2 hybrid quote path.
///
/// The dispatcher treats EVERY one of these as "fall back to curated" - the
/// Safety Filter is fail-closed. The reasons are differentiated only so
/// logs / analytics can attribute the fallback.
sealed class QuoteFailure extends Failure {
  const QuoteFailure({required super.message});

  /// The Safety Filter rejected the Gemini-suggested text - disallowed
  /// substring, clinical label, urgency word, or off-script phrasing.
  const factory QuoteFailure.filterReject({required String snippet}) =
      FilterReject;

  /// The Cloud Function call failed (network / 5xx / non-2xx). Caller still
  /// falls back to curated; this variant exists so analytics can distinguish
  /// "Gemini is broken" from "Gemini is misbehaving".
  const factory QuoteFailure.network() = _Network;

  /// The Cloud Function returned a response we could not parse.
  const factory QuoteFailure.malformedResponse() = _Malformed;

  /// Catch-all wrapped exception. Fall back to curated.
  const factory QuoteFailure.unknown(Object? cause) = _Unknown;
}

class FilterReject extends QuoteFailure {
  const FilterReject({required this.snippet})
    : super(message: 'Safety filter rejected suggestion.');

  /// First ~64 chars of the offending text, for analytics only. Never
  /// surfaced to the user; the dispatcher logs this through the redacted
  /// path in `Logger`.
  final String snippet;
}

class _Network extends QuoteFailure {
  const _Network() : super(message: 'AI quote service unavailable.');
}

class _Malformed extends QuoteFailure {
  const _Malformed() : super(message: 'AI quote response was malformed.');
}

class _Unknown extends QuoteFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
