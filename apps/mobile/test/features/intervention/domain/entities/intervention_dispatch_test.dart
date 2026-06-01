import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_copy.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_context.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_failure.dart';
import 'package:moodbloom/features/intervention/domain/repositories/ai_quote_repository.dart';
import 'package:moodbloom/features/intervention/domain/repositories/quote_library.dart';
import 'package:moodbloom/features/intervention/domain/services/quote_safety_filter.dart';
import 'package:moodbloom/features/intervention/domain/services/tiered_intervention_dispatcher.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// Minimal pool - placeholder until HB-008 lands.
class _LibStub implements QuoteLibrary {
  @override
  Quote pickTier1({required DateTime seed}) => const Quote(
    id: 't1',
    text: 'tier1-curated-text',
    source: QuoteSource.curated,
    tier: Tier.one,
  );
  @override
  Quote pickTier2({required DateTime seed}) => const Quote(
    id: 't2',
    text: 'tier2-curated-text',
    source: QuoteSource.curated,
    tier: Tier.two,
  );
  @override
  Quote pickTier3({required DateTime seed}) => const Quote(
    id: 't3',
    text: 'tier3-curated-text',
    source: QuoteSource.curated,
    tier: Tier.three,
  );
}

class _AiStub implements AIQuoteRepository {
  @override
  Future<Result<String, QuoteFailure>> requestSuggestion(
    AiAllowedTier tier,
    QuoteContext ctx,
  ) async => const Ok('ai-suggestion-text');
}

class _FilterStub implements QuoteSafetyFilter {
  @override
  Result<Quote, QuoteFailure> gate(
    String text, {
    required AiAllowedTier tier,
  }) => Ok(
    Quote(
      id: 'ai-${text.hashCode}',
      text: text,
      source: QuoteSource.ai,
      tier: tier == AiAllowedTier.one ? Tier.one : Tier.two,
    ),
  );
}

void main() {
  group('TC-38: every tier body contains the disclaimer footer', () {
    final now = DateTime(2026, 5, 9, 10, 30);
    const ctx = QuoteContext(weekId: '2026-W19', dailyAvgS: -0.7);

    Future<String> bodyFor(Tier t) async {
      final d = TieredInterventionDispatcher(
        quoteLibrary: _LibStub(),
        aiQuoteRepository: _AiStub(),
        safetyFilter: _FilterStub(),
        now: () => now,
      );
      final result = await d.dispatch(tier: t, context: ctx);
      return result.getOrNull()!.body;
    }

    test('Tier 1 body contains the canonical footer', () async {
      final body = await bodyFor(Tier.one);
      expect(body, contains(DisclaimerCopy.notificationFooter));
    });

    test('Tier 2 body contains the canonical footer', () async {
      final body = await bodyFor(Tier.two);
      expect(body, contains(DisclaimerCopy.notificationFooter));
    });

    test('Tier 3 body contains the canonical footer', () async {
      final body = await bodyFor(Tier.three);
      expect(body, contains(DisclaimerCopy.notificationFooter));
    });

    test('footer appears AFTER the quote text (suffix layout)', () async {
      final body = await bodyFor(Tier.one);
      final footerStart = body.indexOf(DisclaimerCopy.notificationFooter);
      final quoteEnd = body.indexOf('\n\n');
      expect(footerStart, greaterThan(quoteEnd));
      expect(quoteEnd, isNonNegative);
    });
  });
}
