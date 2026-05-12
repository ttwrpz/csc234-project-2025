import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../pattern_engine/domain/entities/tier.dart';

part 'quote.freezed.dart';

/// Provenance of a [Quote]. Surfaced for analytics + the `_TierDisabled`
/// fallback path — production code never branches on this.
///
/// Per ADR-0012 §"Decision" point 1, every Tier 3 [Quote] in the wild has
/// `source == QuoteSource.curated`. Tests assert this invariant.
enum QuoteSource { curated, ai }

/// A single delivered quote. `text` is the user-visible body BEFORE the
/// disclaimer footer is appended (the dispatcher appends
/// `DisclaimerCopy.notificationFooter` at build time so the footer is the
/// dispatcher's responsibility, not the library's — TC-38).
@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    /// Stable identifier for analytics + the `interventions/{id}.quoteId`
    /// audit field. For curated entries this is a slugified hash of the
    /// pool index + tier; for AI entries this is a hash of the text body.
    required String id,
    required String text,
    required QuoteSource source,
    required Tier tier,
  }) = _Quote;
}
