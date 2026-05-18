import '../../pattern_engine/domain/entities/tier.dart';
import '../domain/entities/ai_allowed_tier.dart';
import '../domain/entities/quote.dart';
import '../domain/repositories/quote_library.dart';

/// Concrete [QuoteLibrary] backed by team-reviewed curated phrase pools.
///
/// The pools are `static const` lists so the phrases ship with the binary —
/// this is on purpose: a Remote Config push CANNOT mutate safety-critical
/// content. Remote Config is for kill-switches, not for quote text.
///
/// **Determinism:** Tier 3 rotation is `seed.toUtc().day % tier3Pool.length`
/// — same calendar day → same phrase across cold launches. Tier 1/2 rotate
/// by ISO week so a same-week 48h-spaced Tier 1 nudge does not echo itself,
/// while a multi-week run cycles through the pool.
///
/// **Tier 3 footer rule:** every Tier 3 entry embeds "Hotline 1323" in the
/// body. The dispatcher appends `DisclaimerCopy.notificationFooter` outside
/// this string; we never duplicate the disclaimer inside the pool.
class QuoteLibraryImpl implements QuoteLibrary {
  const QuoteLibraryImpl();

  // ──────────────────────────────────────────────────────────────────────
  // Tier 1 — breathing-prompt curated pool (12 entries).
  // Read aloud with the team before merge.
  // ──────────────────────────────────────────────────────────────────────
  static const List<String> tier1Pool = [
    'It looks like your garden has had some rainy days. Would you like a 2-minute breathing exercise?',
    'Rainy days happen. A short breath might help — only if you would like.',
    'A gentle breath can help the soil settle. Would you like to try a 2-minute pause?',
    'Storms pass. If it helps, a few slow breaths can soften the moment.',
    'Your garden has weathered a stretch. Want to pause for a slow breath?',
    'When the weather feels heavy, a short breath can be a soft place to rest.',
    'Would you like a quiet breath? Even a minute can help the ground settle.',
    'Nothing here is broken. A gentle breath, if it feels welcome.',
    'A few slow breaths can be enough. Would you like to try a short pause?',
    'Soft breaths help the roots hold. Want to try a 2-minute pause together?',
    'The garden is still here. A gentle breath can help you notice it.',
    'If it feels welcome, a slow breath can be a kind moment to yourself.',
  ];

  // ──────────────────────────────────────────────────────────────────────
  // Tier 2 — journaling-prompt curated pool (12 entries).
  // ──────────────────────────────────────────────────────────────────────
  static const List<String> tier2Pool = [
    'Would you like to write about what has been on your mind?',
    'Sometimes putting feelings into words helps. Want to try?',
    'A few quiet lines can help the weather pass. Would you like to write?',
    'Words on the page can hold what the mind cannot. Want to give it a try?',
    'If it helps, you could write a short note about the week. Only if you would like.',
    'A gentle journal entry can help the soil settle. Would you like to write a few lines?',
    'Writing a little can help notice what the garden has been holding. Want to try?',
    'Would you like to set a few thoughts down on paper? A short note is enough.',
    'A short reflection can be a kind pause. Want to write a few lines?',
    'If it feels welcome, a quiet page can help the moment breathe.',
    'Some weeks feel heavier. Writing a little can help you notice the shape.',
    'A few honest words can be enough. Would you like to write what has been on your mind?',
  ];

  // ──────────────────────────────────────────────────────────────────────
  // Tier 3 — acute-care curated pool (8 entries). Read aloud TWICE with
  // the full team before merge. Every entry contains "Hotline 1323" in
  // the body.
  // ──────────────────────────────────────────────────────────────────────
  static const List<String> tier3Pool = [
    'We care about you. If it helps to talk, the Thai Mental Health Hotline is free at 1323, 24 hours.',
    'These feelings can be very heavy. You do not have to face them alone. Hotline 1323 is available any time.',
    'Reaching out for support is a sign of strength. Hotline 1323 connects to trained listeners, free, 24 hours.',
    'You are not alone in this. If it helps to talk, Hotline 1323 is free and open 24 hours.',
    'The weather has been hard. A kind voice can help — Hotline 1323 is free, any time of day.',
    'It takes courage to notice you are struggling. Hotline 1323 has trained listeners, free, 24 hours.',
    'We are here for you. If a conversation would help, Hotline 1323 is available, free, around the clock.',
    'Heavy stretches deserve support. Hotline 1323 connects you with a kind listener, free, 24 hours.',
  ];

  // ──────────────────────────────────────────────────────────────────────
  // Approved-word sets per tier — fed into the Safety Filter's whitelist
  // gate. Derived from the curated pools themselves (tokenise +
  // normalise) plus a small set of generic connector words. Authored as
  // `static const` so the filter has a stable vocabulary independent of
  // runtime state. The sanity-check unit test asserts every curated
  // entry passes its own tier's filter.
  // ──────────────────────────────────────────────────────────────────────

  /// Generic connector tokens that any compassionate sentence may use —
  /// pronouns, articles, prepositions. Kept tiny so an off-script
  /// sentence cannot drift past the 80%-tokens-in-set ratio just by
  /// stacking common English filler.
  static const Set<String> _genericConnectors = {
    'the',
    'a',
    'an',
    'and',
    'or',
    'but',
    'to',
    'of',
    'in',
    'on',
    'at',
    'for',
    'with',
    'from',
    'is',
    'are',
    'was',
    'be',
    'been',
    'has',
    'have',
    'had',
    'do',
    'does',
    'did',
    'can',
    'could',
    'will',
    'would',
    'may',
    'might',
    'you',
    'your',
    'yours',
    'we',
    'our',
    'ours',
    'us',
    'i',
    'me',
    'my',
    'it',
    'its',
    'this',
    'that',
    'these',
    'those',
    'if',
    'so',
    'as',
    'than',
    'then',
    'when',
    'while',
    'just',
    'only',
    'also',
    'too',
    'not',
    'no',
    'yes',
    'one',
    'two',
    'few',
    'some',
    'any',
    'all',
    'every',
    'each',
    'about',
    'around',
    'over',
    'under',
    'up',
    'down',
    'into',
    'through',
    'out',
    'off',
    'by',
    'like',
    'how',
    'what',
    'why',
    'where',
    'who',
    'whose',
    'which',
    'much',
    'many',
    'more',
    'most',
    'less',
    'least',
  };

  /// Tier 1 approved word set: union of tokenized tier-1 phrases + generic
  /// connectors. Computed lazily so the cost is paid once per process.
  static final Set<String> tier1ApprovedWords = _tokeniseAll(tier1Pool)
    ..addAll(_genericConnectors);

  /// Tier 2 approved word set.
  static final Set<String> tier2ApprovedWords = _tokeniseAll(tier2Pool)
    ..addAll(_genericConnectors);

  /// Pure-Dart tokeniser: lowercase, strip punctuation, split on whitespace,
  /// drop empty / pure-digit tokens. Mirror of the Safety Filter so the
  /// "every curated entry passes its own filter" sanity check works.
  static Set<String> _tokeniseAll(List<String> phrases) {
    final out = <String>{};
    for (final phrase in phrases) {
      for (final tok in tokenise(phrase)) {
        out.add(tok);
      }
    }
    return out;
  }

  /// Public so [QuoteSafetyFilterImpl] can share the canonical tokeniser.
  /// Lowercases, strips ASCII punctuation, splits on whitespace, drops
  /// empty tokens. Numeric tokens like "1323" are kept — they appear in
  /// the Tier 3 pool by design.
  static List<String> tokenise(String s) {
    // Replace every char not in [a-z0-9] (after lowercasing) with a space,
    // then collapse runs of whitespace. Avoids regex-engine-specific
    // word-boundary quirks across platforms.
    final lowered = s.toLowerCase();
    final buf = StringBuffer();
    for (final code in lowered.codeUnits) {
      final isLower = code >= 0x61 && code <= 0x7a; // a..z
      final isDigit = code >= 0x30 && code <= 0x39; // 0..9
      buf.writeCharCode(isLower || isDigit ? code : 0x20);
    }
    return buf
        .toString()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  // ──────────────────────────────────────────────────────────────────────
  // QuoteLibrary contract
  // ──────────────────────────────────────────────────────────────────────

  @override
  Quote pickTier1({required DateTime seed}) {
    final index = _weekIndex(seed) % tier1Pool.length;
    return Quote(
      id: 'curated.tier1.$index',
      text: tier1Pool[index],
      source: QuoteSource.curated,
      tier: Tier.one,
    );
  }

  @override
  Quote pickTier2({required DateTime seed}) {
    final index = _weekIndex(seed) % tier2Pool.length;
    return Quote(
      id: 'curated.tier2.$index',
      text: tier2Pool[index],
      source: QuoteSource.curated,
      tier: Tier.two,
    );
  }

  @override
  Quote pickTier3({required DateTime seed}) {
    // Deterministic on `dateOnly(seed)`: same day → same phrase across
    // devices; next day → next phrase.
    final index = seed.toUtc().day % tier3Pool.length;
    return Quote(
      id: 'curated.tier3.$index',
      text: tier3Pool[index],
      source: QuoteSource.curated,
      tier: Tier.three,
    );
  }

  /// Returns a non-negative integer that rolls over weekly. The dispatcher
  /// hits at most once per 48h, so this gives Tier 1/2 cosmetic variation
  /// across weeks without flipping within a single week.
  ///
  /// Uses the ISO-week number derived from the UTC date so devices on
  /// different timezones still agree on the rotation slot.
  int _weekIndex(DateTime seed) {
    final utc = seed.toUtc();
    final thursday = utc.add(Duration(days: 4 - ((utc.weekday + 6) % 7 + 1)));
    final firstOfYear = DateTime.utc(thursday.year, 1, 1);
    final daysOffset = thursday.difference(firstOfYear).inDays;
    final weekNumber = (daysOffset / 7).floor() + 1;
    return thursday.year * 100 + weekNumber;
  }

  /// Convenience for the filter impl — `AiAllowedTier.one` → tier 1 set,
  /// `AiAllowedTier.two` → tier 2 set.
  static Set<String> approvedWordsFor(AiAllowedTier tier) => switch (tier) {
    AiAllowedTier.one => tier1ApprovedWords,
    AiAllowedTier.two => tier2ApprovedWords,
  };
}
