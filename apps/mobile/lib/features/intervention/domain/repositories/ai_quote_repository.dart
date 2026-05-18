import 'package:core/core.dart';

import '../entities/ai_allowed_tier.dart';
import '../entities/quote_context.dart';
import '../entities/quote_failure.dart';

/// Wraps the `suggestQuote.ts` Cloud Function.
///
/// The signature is intentionally constrained: [requestSuggestion] takes an
/// [AiAllowedTier], NOT a [Tier]. The type system itself prevents a Tier 3
/// dispatch from reaching this method — to pass Tier 3 a caller would have
/// to deliberately convert via `AiAllowedTier.fromTier`, which throws on
/// Tier 3 by construction. The dispatcher's `if (tier == Tier.three)`
/// branch returns before any such call is reached.
///
/// Returns the raw suggestion text on success — the dispatcher then runs it
/// through the Safety Filter. Fail-closed: any failure here OR a downstream
/// filter reject → the dispatcher falls back to `QuoteLibrary.pickTier1/2`.
abstract class AIQuoteRepository {
  Future<Result<String, QuoteFailure>> requestSuggestion(
    AiAllowedTier tier,
    QuoteContext ctx,
  );
}
