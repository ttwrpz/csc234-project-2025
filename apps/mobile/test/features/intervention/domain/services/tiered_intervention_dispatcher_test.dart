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

/// Recording fake of the curated [QuoteLibrary]. Returns deterministic
/// placeholder text per tier; the Day-2 HB-008 agent ships the real impl
/// with the team-reviewed pools. TC-40's assertion is on
/// `_RecordingAIQuoteRepository.calls.isEmpty` for Tier 3 — the placeholder
/// text choice does not affect that.
class _FakeQuoteLibrary implements QuoteLibrary {
  final List<DateTime> tier1Seeds = [];
  final List<DateTime> tier2Seeds = [];
  final List<DateTime> tier3Seeds = [];

  @override
  Quote pickTier1({required DateTime seed}) {
    tier1Seeds.add(seed);
    return const Quote(
      id: 'curated-t1-placeholder',
      text: 'curated-tier1-placeholder',
      source: QuoteSource.curated,
      tier: Tier.one,
    );
  }

  @override
  Quote pickTier2({required DateTime seed}) {
    tier2Seeds.add(seed);
    return const Quote(
      id: 'curated-t2-placeholder',
      text: 'curated-tier2-placeholder',
      source: QuoteSource.curated,
      tier: Tier.two,
    );
  }

  @override
  Quote pickTier3({required DateTime seed}) {
    tier3Seeds.add(seed);
    return const Quote(
      id: 'curated-t3-placeholder',
      text: 'curated-tier3-placeholder',
      source: QuoteSource.curated,
      tier: Tier.three,
    );
  }
}

/// Recording fake of [AIQuoteRepository] — the ADR-0012 invariant subject.
/// TC-40 asserts `calls.isEmpty` after a Tier 3 dispatch.
///
/// The codebase does not use `mocktail`; this hand-written fake is the
/// idiomatic alternative (see `cheer_up_events_repository_impl_test.dart`).
class _RecordingAIQuoteRepository implements AIQuoteRepository {
  _RecordingAIQuoteRepository({this.suggestion = 'safe-ai-suggestion'});

  final List<({AiAllowedTier tier, QuoteContext ctx})> calls = [];
  String suggestion;
  QuoteFailure? failNext;

  @override
  Future<Result<String, QuoteFailure>> requestSuggestion(
    AiAllowedTier tier,
    QuoteContext ctx,
  ) async {
    calls.add((tier: tier, ctx: ctx));
    final err = failNext;
    if (err != null) {
      failNext = null;
      return Err(err);
    }
    return Ok(suggestion);
  }
}

/// Permissive filter — accepts any text by default. Override [rejectAll] to
/// flip to a fail-closed path so the fallback-to-curated branch is testable.
class _FakeSafetyFilter implements QuoteSafetyFilter {
  _FakeSafetyFilter({this.rejectAll = false});
  bool rejectAll;
  final List<({String text, AiAllowedTier tier})> calls = [];

  @override
  Result<Quote, QuoteFailure> gate(String text, {required AiAllowedTier tier}) {
    calls.add((text: text, tier: tier));
    if (rejectAll) {
      return Err(QuoteFailure.filterReject(snippet: text));
    }
    return Ok(
      Quote(
        id: 'ai-${text.hashCode}',
        text: text,
        source: QuoteSource.ai,
        tier: tier == AiAllowedTier.one ? Tier.one : Tier.two,
      ),
    );
  }
}

void main() {
  final now = DateTime(2026, 5, 9, 10, 30);
  DateTime nowFn() => now;
  const ctx = QuoteContext(weekId: '2026-W19', dailyAvgS: -0.7);

  group('TieredInterventionDispatcher — Tier 3 determinism (TC-40)', () {
    test(
      'Tier.three dispatch NEVER calls AIQuoteRepository.requestSuggestion',
      () async {
        final lib = _FakeQuoteLibrary();
        final ai = _RecordingAIQuoteRepository();
        final filter = _FakeSafetyFilter();
        final dispatcher = TieredInterventionDispatcher(
          quoteLibrary: lib,
          aiQuoteRepository: ai,
          safetyFilter: filter,
          now: nowFn,
        );

        final result = await dispatcher.dispatch(
          tier: Tier.three,
          context: ctx,
        );

        // Invariant 1: AI repo was not touched. TC-40 + ADR-0012 §1.
        expect(
          ai.calls,
          isEmpty,
          reason:
              'ADR-0012 §"Decision" point 1: Tier 3 must never reach Gemini.',
        );
        // Invariant 2: Safety filter was not touched either (ADR-0012 §4).
        expect(filter.calls, isEmpty);
        // Invariant 3: curated Tier 3 path was the source.
        expect(lib.tier3Seeds, hasLength(1));
        expect(lib.tier3Seeds.first, equals(now));

        // Invariant 4: returned body carries the curated text + the
        // disclaimer footer — TC-38 for Tier 3 in one shot.
        final dispatch = result.getOrNull()!;
        expect(dispatch.body, contains('curated-tier3-placeholder'));
        expect(dispatch.body, contains(DisclaimerCopy.notificationFooter));
        expect(dispatch.tier, Tier.three);
        expect(dispatch.ctas, contains('open_crisis'));
        expect(dispatch.ctas, contains('opt_out'));
      },
    );
  });

  group('TieredInterventionDispatcher — Tier 1 hybrid path', () {
    test('happy path: AI suggestion + filter accept → AI quote', () async {
      final lib = _FakeQuoteLibrary();
      final ai = _RecordingAIQuoteRepository(suggestion: 'gemini-safe-phrase');
      final filter = _FakeSafetyFilter();
      final dispatcher = TieredInterventionDispatcher(
        quoteLibrary: lib,
        aiQuoteRepository: ai,
        safetyFilter: filter,
        now: nowFn,
      );

      final dispatch = (await dispatcher.dispatch(
        tier: Tier.one,
        context: ctx,
      )).getOrNull()!;

      expect(ai.calls, hasLength(1));
      expect(ai.calls.first.tier, AiAllowedTier.one);
      expect(filter.calls, hasLength(1));
      expect(dispatch.body, contains('gemini-safe-phrase'));
      expect(dispatch.body, contains(DisclaimerCopy.notificationFooter));
      expect(dispatch.ctas, contains('open_breathing'));
    });

    test('AI network failure → curated Tier 1 fallback', () async {
      final lib = _FakeQuoteLibrary();
      final ai = _RecordingAIQuoteRepository()
        ..failNext = const QuoteFailure.network();
      final filter = _FakeSafetyFilter();
      final dispatcher = TieredInterventionDispatcher(
        quoteLibrary: lib,
        aiQuoteRepository: ai,
        safetyFilter: filter,
        now: nowFn,
      );

      final dispatch = (await dispatcher.dispatch(
        tier: Tier.one,
        context: ctx,
      )).getOrNull()!;

      expect(ai.calls, hasLength(1)); // attempted
      expect(filter.calls, isEmpty); // never reached
      expect(lib.tier1Seeds, hasLength(1));
      expect(dispatch.body, contains('curated-tier1-placeholder'));
    });

    test('filter reject → curated Tier 1 fallback (fail-closed)', () async {
      final lib = _FakeQuoteLibrary();
      final ai = _RecordingAIQuoteRepository(suggestion: 'gemini-naughty');
      final filter = _FakeSafetyFilter(rejectAll: true);
      final dispatcher = TieredInterventionDispatcher(
        quoteLibrary: lib,
        aiQuoteRepository: ai,
        safetyFilter: filter,
        now: nowFn,
      );

      final dispatch = (await dispatcher.dispatch(
        tier: Tier.one,
        context: ctx,
      )).getOrNull()!;

      expect(ai.calls, hasLength(1));
      expect(filter.calls, hasLength(1));
      expect(lib.tier1Seeds, hasLength(1));
      expect(dispatch.body, contains('curated-tier1-placeholder'));
    });
  });

  group('TieredInterventionDispatcher — Tier 2 hybrid path', () {
    test(
      'Tier.two → AIQuoteRepository called with AiAllowedTier.two',
      () async {
        final lib = _FakeQuoteLibrary();
        final ai = _RecordingAIQuoteRepository(suggestion: 'journal-prompt');
        final filter = _FakeSafetyFilter();
        final dispatcher = TieredInterventionDispatcher(
          quoteLibrary: lib,
          aiQuoteRepository: ai,
          safetyFilter: filter,
          now: nowFn,
        );

        final dispatch = (await dispatcher.dispatch(
          tier: Tier.two,
          context: ctx,
        )).getOrNull()!;

        expect(ai.calls, hasLength(1));
        expect(ai.calls.first.tier, AiAllowedTier.two);
        expect(dispatch.tier, Tier.two);
        expect(dispatch.ctas, contains('open_journal'));
        expect(dispatch.body, contains('journal-prompt'));
      },
    );
  });
}
