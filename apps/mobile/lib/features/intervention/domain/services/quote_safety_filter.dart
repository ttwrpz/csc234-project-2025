import 'package:core/core.dart';

import '../entities/ai_allowed_tier.dart';
import '../entities/quote.dart';
import '../entities/quote_failure.dart';

/// Allow-list gate for AI-suggested quote text. Built by the Day-2 HB-008
/// agent; this abstract exists so the dispatcher compiles in Day 1.
///
/// Contract: [gate] returns `Ok(Quote)` when `text` matches one of the
/// pre-approved phrase templates after light normalization, or
/// `Err(FilterReject)` when it does not. Fail-CLOSED — any error → curated
/// fallback at the dispatcher.
///
/// Per ADR-0012 §"Decision" point 4, the filter is ONLY exercised on the
/// Tier 1/2 hybrid path. Tier 3 bypasses the filter entirely (it bypasses
/// the AI repo too); the curated pool is the guarantee, not the filter.
abstract class QuoteSafetyFilter {
  Result<Quote, QuoteFailure> gate(String text, {required AiAllowedTier tier});
}
