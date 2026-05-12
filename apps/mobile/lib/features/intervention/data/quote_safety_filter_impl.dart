import 'package:core/core.dart';

import '../../pattern_engine/domain/entities/tier.dart';
import '../domain/entities/ai_allowed_tier.dart';
import '../domain/entities/quote.dart';
import '../domain/entities/quote_failure.dart';
import '../domain/services/quote_safety_filter.dart';
import 'quote_library_impl.dart';

/// Concrete fail-closed [QuoteSafetyFilter]. The implementation lives in
/// `data/` (not `domain/`) because it imports [QuoteLibraryImpl]'s approved
/// word sets — the same vocabulary that informs the curated phrases informs
/// what Gemini is allowed to echo (HB-008 §"QuoteSafetyFilter design").
///
/// Three gates, in order:
///   1. **Length** — `text.length > 140` → `FilterReject` (HB-008 length cap).
///   2. **Forbidden-word blacklist** — case-insensitive whole-word match
///      across [_forbiddenWords]. Whole-word means "diagnose" rejects but
///      "diagnosing" does not (HB-008 is explicit).
///   3. **Whitelist ratio** — ≥80% of tokenised words must appear in the
///      tier's approved-word set.
///
/// Tokenisation is delegated to [QuoteLibraryImpl.tokenise] so the curated
/// pool's own tokens are byte-identical to what the filter sees — the
/// sanity-check test in `quote_library_impl_test.dart` depends on this.
///
/// ADR-0012 §"Decision" point 4 — the filter is exclusively on the Tier
/// 1/2 hybrid path. Tier 3 never traverses this code.
class QuoteSafetyFilterImpl implements QuoteSafetyFilter {
  const QuoteSafetyFilterImpl();

  /// Maximum body length, per HB-008. Matches the notification footprint
  /// budget on Android (a longer body is truncated by the OS before the
  /// disclaimer footer is appended downstream).
  static const int maxLength = 140;

  /// Minimum fraction of tokens that must be in the tier's approved set.
  static const double approvedRatioThreshold = 0.80;

  /// Case-insensitive forbidden-word blacklist. Whole-word match only —
  /// "diagnose" matches but "diagnosing" does not. Additions require team
  /// review (HB-008 §"QuoteSafetyFilter design").
  ///
  /// Entries with whitespace (e.g. "anxiety disorder", "fix yourself")
  /// match as a phrase — the gate falls back to a case-insensitive
  /// substring check after asserting that the surrounding context is a
  /// word boundary on either side.
  static const Set<String> _forbiddenWords = {
    'depression',
    'anxiety disorder',
    'bipolar',
    'diagnose',
    'diagnosis',
    'medication',
    'prescribe',
    'therapy',
    'therapist',
    'must',
    'should',
    'now',
    'have to',
    'need to',
    'fix yourself',
    'get better',
    'overcome',
  };

  @override
  Result<Quote, QuoteFailure> gate(String text, {required AiAllowedTier tier}) {
    // Gate 1 — length cap.
    if (text.length > maxLength) {
      return Err(
        QuoteFailure.filterReject(snippet: _snippet(text, reason: 'length')),
      );
    }

    // Gate 2 — forbidden-word blacklist. Whole-word check.
    final blacklistHit = _containsForbiddenTerm(text);
    if (blacklistHit != null) {
      return Err(
        QuoteFailure.filterReject(
          snippet: _snippet(text, reason: 'forbidden:$blacklistHit'),
        ),
      );
    }

    // Gate 3 — whitelist ratio. Tokenise + check membership.
    final tokens = QuoteLibraryImpl.tokenise(text);
    if (tokens.isEmpty) {
      // No semantic content — fail closed.
      return Err(
        QuoteFailure.filterReject(snippet: _snippet(text, reason: 'empty')),
      );
    }
    final approved = QuoteLibraryImpl.approvedWordsFor(tier);
    var hits = 0;
    for (final tok in tokens) {
      if (approved.contains(tok)) hits++;
    }
    final ratio = hits / tokens.length;
    if (ratio < approvedRatioThreshold) {
      return Err(
        QuoteFailure.filterReject(
          snippet: _snippet(
            text,
            reason: 'offScript:${ratio.toStringAsFixed(2)}',
          ),
        ),
      );
    }

    // Pass.
    return Ok(
      Quote(
        id: _stableHashId(text),
        text: text,
        source: QuoteSource.ai,
        tier: switch (tier) {
          AiAllowedTier.one => Tier.one,
          AiAllowedTier.two => Tier.two,
        },
      ),
    );
  }

  /// Returns the matched forbidden term, or `null` if none matched.
  /// Whole-word: for single-token entries, the token (after lowercasing)
  /// must appear as a whole token in [QuoteLibraryImpl.tokenise]'s output.
  /// For multi-word entries (e.g. "anxiety disorder"), the phrase must
  /// appear contiguously in that same tokenised stream.
  String? _containsForbiddenTerm(String text) {
    final tokens = QuoteLibraryImpl.tokenise(text);
    if (tokens.isEmpty) return null;
    final asString = ' ${tokens.join(' ')} ';
    for (final term in _forbiddenWords) {
      // The term is already lowercase ASCII in [_forbiddenWords]; pad with
      // spaces on both ends so whole-word phrases match. A bare "to"
      // suffix on "need to" gives ` need to ` which matches ` ... need to
      // ... ` but not ` ... need too ... `.
      final padded = ' $term ';
      if (asString.contains(padded)) {
        return term;
      }
    }
    return null;
  }

  /// First ~64 chars + reason marker, for the dispatcher's analytics log.
  /// Never surfaced to the user.
  String _snippet(String text, {required String reason}) {
    const cap = 64;
    final clipped = text.length <= cap ? text : text.substring(0, cap);
    return '[$reason] $clipped';
  }

  /// Stable-ish id for the analytics audit trail. Not cryptographic —
  /// just enough to distinguish two different bodies in a structured log
  /// when the body itself is too sensitive to log.
  String _stableHashId(String text) {
    final h = text.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    return 'ai.$h';
  }
}
