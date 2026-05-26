import '../../../pattern_engine/domain/entities/tier.dart';

/// Compiler-level fence for the Tier 3 determinism invariant.
///
/// `AIQuoteRepository.requestSuggestion` accepts this type, NOT [Tier]. The
/// dispatcher's `if (tier == Tier.three)` arm returns before any call to
/// [fromTier] is reached, so a Tier 3 request can never traverse the Gemini
/// path. The `StateError` below is belt-and-suspenders — a reviewer reading
/// the dispatcher should see two layers of fence (the `if` branch and the
/// enum constraint) and understand the invariant at a glance.
enum AiAllowedTier {
  one,
  two;

  /// Lifts [Tier] to [AiAllowedTier]. Throws on [Tier.three] by construction
  /// — the dispatcher's tier-3 branch returns before reaching this, so the
  /// throw path is unreachable in practice. Kept so a future refactor that
  /// deletes the `if` branch trips the StateError in tests before reaching
  /// production.
  static AiAllowedTier fromTier(Tier t) => switch (t) {
    Tier.one => AiAllowedTier.one,
    Tier.two => AiAllowedTier.two,
    Tier.three => throw StateError(
      'AiAllowedTier.fromTier called with Tier.three - '
      'invariant violated. Tier 3 must never reach the AI path.',
    ),
  };
}
