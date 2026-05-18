import '../entities/quote.dart';

/// Deterministic curated phrase library. The Tier 3 arm of the dispatcher
/// reaches ONLY this interface — never the AI repository, never the Safety
/// Filter.
///
/// `seed` is the day's timestamp; the implementation derives a stable index
/// from `dateOnly(seed)` so the same user sees the same phrase per day
/// across cold launches. Rotation across the 8–12 entry pool ensures
/// variety without breaking determinism.
abstract class QuoteLibrary {
  /// Returns a Tier 1 phrase. Selection is deterministic on
  /// `dateOnly(seed)`.
  Quote pickTier1({required DateTime seed});

  /// Returns a Tier 2 phrase. Selection is deterministic on
  /// `dateOnly(seed)`.
  Quote pickTier2({required DateTime seed});

  /// Returns a Tier 3 phrase from the team-reviewed-aloud pool. Selection
  /// is deterministic on `dateOnly(seed)`. NEVER touches Gemini. The
  /// curated text comes verbatim from `tier3Pool`.
  Quote pickTier3({required DateTime seed});
}
