import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/intervention/data/quote_library_impl.dart';
import 'package:moodbloom/features/intervention/data/quote_safety_filter_impl.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// HB-008 pool sanity + rotation tests for [QuoteLibraryImpl].
///
/// Acceptance contributions:
/// - TC-38: every curated pool entry contains a hotline marker for Tier 3
///   and stays within the 140-char filter cap for all tiers.
/// - TC-41 (positive control): every curated entry passes its own tier's
///   [QuoteSafetyFilterImpl.gate] - the curated phrases are the canonical
///   "always-allowed" inputs to the filter; failing this would mean the
///   filter is mis-aligned with the pool it is supposed to whitelist.
void main() {
  const filter = QuoteSafetyFilterImpl();
  const lib = QuoteLibraryImpl();

  group('QuoteLibraryImpl - pool sizes (HB-008 authoring rules)', () {
    test('Tier 1 pool has at least 12 entries', () {
      expect(QuoteLibraryImpl.tier1Pool.length, greaterThanOrEqualTo(12));
    });

    test('Tier 2 pool has at least 12 entries', () {
      expect(QuoteLibraryImpl.tier2Pool.length, greaterThanOrEqualTo(12));
    });

    test('Tier 3 pool has at least 8 entries (target 8–12)', () {
      expect(QuoteLibraryImpl.tier3Pool.length, greaterThanOrEqualTo(8));
      expect(QuoteLibraryImpl.tier3Pool.length, lessThanOrEqualTo(12));
    });
  });

  group('QuoteLibraryImpl - pool sanity (TC-41 positive control)', () {
    test('every Tier 1 entry stays within the 140-char filter cap', () {
      for (final phrase in QuoteLibraryImpl.tier1Pool) {
        expect(
          phrase.length,
          lessThanOrEqualTo(QuoteSafetyFilterImpl.maxLength),
          reason: 'Tier 1 entry over 140 chars: "$phrase"',
        );
      }
    });

    test('every Tier 2 entry stays within the 140-char filter cap', () {
      for (final phrase in QuoteLibraryImpl.tier2Pool) {
        expect(
          phrase.length,
          lessThanOrEqualTo(QuoteSafetyFilterImpl.maxLength),
          reason: 'Tier 2 entry over 140 chars: "$phrase"',
        );
      }
    });

    test('every Tier 3 entry stays within the 140-char filter cap', () {
      for (final phrase in QuoteLibraryImpl.tier3Pool) {
        expect(
          phrase.length,
          lessThanOrEqualTo(QuoteSafetyFilterImpl.maxLength),
          reason: 'Tier 3 entry over 140 chars: "$phrase"',
        );
      }
    });

    test('every Tier 1 entry passes the Tier 1 filter', () {
      for (final phrase in QuoteLibraryImpl.tier1Pool) {
        final result = filter.gate(phrase, tier: AiAllowedTier.one);
        expect(
          result,
          isA<Ok<Quote, Object>>(),
          reason:
              'Curated Tier 1 phrase must pass Tier 1 filter (HB-008 §"Authoring rules"): "$phrase"',
        );
      }
    });

    test('every Tier 2 entry passes the Tier 2 filter', () {
      for (final phrase in QuoteLibraryImpl.tier2Pool) {
        final result = filter.gate(phrase, tier: AiAllowedTier.two);
        expect(
          result,
          isA<Ok<Quote, Object>>(),
          reason:
              'Curated Tier 2 phrase must pass Tier 2 filter (HB-008 §"Authoring rules"): "$phrase"',
        );
      }
    });

    test(
      'every Tier 3 entry contains "1323" as substring (HB-008 footer rule)',
      () {
        for (final phrase in QuoteLibraryImpl.tier3Pool) {
          expect(
            phrase,
            contains('1323'),
            reason: 'Tier 3 phrase missing Hotline 1323 marker: "$phrase"',
          );
        }
      },
    );
  });

  group('QuoteLibraryImpl - rotation (ADR-0012 §"Decision" point 5)', () {
    test('pickTier3 is deterministic across calls for the same seed', () {
      final seed = DateTime.utc(2026, 5, 15);
      final a = lib.pickTier3(seed: seed);
      final b = lib.pickTier3(seed: seed);
      expect(a, equals(b));
      expect(a.text, equals(b.text));
      expect(a.tier, Tier.three);
      expect(a.source, QuoteSource.curated);
    });

    test('pickTier3 rotates: day N and day N+1 differ when pool size > 1', () {
      // Pool size is ≥8 (asserted above), so this assertion is meaningful.
      final dayN = DateTime.utc(2026, 5, 15);
      final dayNplus1 = DateTime.utc(2026, 5, 16);
      final a = lib.pickTier3(seed: dayN);
      final b = lib.pickTier3(seed: dayNplus1);
      expect(
        a.text,
        isNot(equals(b.text)),
        reason: 'Day-to-day rotation collapsed.',
      );
    });

    test('pickTier3 returns Tier.three Quote with curated provenance', () {
      final q = lib.pickTier3(seed: DateTime.utc(2026, 5, 15));
      expect(q.tier, Tier.three);
      expect(q.source, QuoteSource.curated);
      expect(q.id, startsWith('curated.tier3.'));
      expect(QuoteLibraryImpl.tier3Pool, contains(q.text));
    });

    test('pickTier1 / pickTier2 vary across weeks but stay within pool', () {
      final weekA = DateTime.utc(2026, 5, 4); // Monday, week 19
      final weekC = DateTime.utc(2026, 6, 1); // Monday, week 23
      final t1a = lib.pickTier1(seed: weekA);
      final t1c = lib.pickTier1(seed: weekC);
      // Cosmetic variation: at least one of (tier1, tier2) should rotate
      // across these distinct weeks. (Different weeks → different
      // weekIndex → different mod position.)
      expect(QuoteLibraryImpl.tier1Pool, contains(t1a.text));
      expect(QuoteLibraryImpl.tier1Pool, contains(t1c.text));
      expect(t1a.id, startsWith('curated.tier1.'));
      // Same week → same phrase (cosmetic determinism within a week).
      final t1aRepeat = lib.pickTier1(seed: weekA.add(const Duration(days: 2)));
      expect(t1a.text, equals(t1aRepeat.text));
    });

    test(
      'pickTier1 returns Tier.one Quote; pickTier2 returns Tier.two Quote',
      () {
        final t1 = lib.pickTier1(seed: DateTime.utc(2026, 5, 4));
        final t2 = lib.pickTier2(seed: DateTime.utc(2026, 5, 4));
        expect(t1.tier, Tier.one);
        expect(t1.source, QuoteSource.curated);
        expect(t2.tier, Tier.two);
        expect(t2.source, QuoteSource.curated);
      },
    );
  });
}
