import 'package:core/core.dart';

import '../../../disclaimer/domain/disclaimer_copy.dart';
import '../../../pattern_engine/domain/entities/tier.dart';
import '../entities/ai_allowed_tier.dart';
import '../entities/intervention_dispatch.dart';
import '../entities/intervention_failure.dart';
import '../entities/quote.dart';
import '../entities/quote_context.dart';
import '../repositories/ai_quote_repository.dart';
import '../repositories/quote_library.dart';
import 'quote_safety_filter.dart';

/// Composes [QuoteLibrary], [AIQuoteRepository], and [QuoteSafetyFilter] into
/// a single per-tier dispatch decision. Pure-Dart — no I/O of its own, no
/// Firebase, no Flutter.
///
/// Tier-3 invariant (ADR-0012):
///   * The `if (tier == Tier.three)` branch returns before any AI repo call
///     is reachable. A reviewer should see this branch and understand that
///     Tier 3 cannot route through Gemini.
///   * Belt-and-suspenders: [AiAllowedTier.fromTier] throws on Tier 3. The
///     dispatcher never calls it for Tier 3, but a future refactor that
///     deletes the `if` branch would trip the StateError in tests.
///   * TC-40 in `tiered_intervention_dispatcher_test.dart` asserts the AI
///     repo's `requestSuggestion` is never called when the dispatched tier
///     is Tier 3, using a recording fake.
///
/// Tier 1/2 hybrid path:
///   * Call `aiQuoteRepository.requestSuggestion(allowed, ctx)`.
///   * On `Ok(text)` → run through `safetyFilter.gate(text, tier: allowed)`.
///   * On any failure of either step → fall back to
///     `quoteLibrary.pickTier1/2(seed: now)`. Fail-CLOSED. The Safety Filter
///     is the canonical sieve, but the curated fallback is the safety net
///     under the sieve.
///
/// The dispatcher does NOT write the audit record itself — that's the
/// `DispatchInterventionUseCase` (and the data-layer impl behind it). The
/// dispatcher returns a pure-Dart [InterventionDispatch]; persistence is
/// the use case's job.
class TieredInterventionDispatcher {
  TieredInterventionDispatcher({
    required QuoteLibrary quoteLibrary,
    required AIQuoteRepository aiQuoteRepository,
    required QuoteSafetyFilter safetyFilter,
    required DateTime Function() now,
    Logger logger = const Logger('intervention.dispatcher'),
  }) : _quoteLibrary = quoteLibrary,
       _aiQuoteRepository = aiQuoteRepository,
       _safetyFilter = safetyFilter,
       _now = now,
       _logger = logger;

  final QuoteLibrary _quoteLibrary;
  final AIQuoteRepository _aiQuoteRepository;
  final QuoteSafetyFilter _safetyFilter;
  final DateTime Function() _now;
  final Logger _logger;

  /// Builds a tier-appropriate [InterventionDispatch] for the supplied
  /// [tier]. The caller (the `DispatchInterventionUseCase`) has already
  /// run the cooldown gate.
  Future<Result<InterventionDispatch, InterventionFailure>> dispatch({
    required Tier tier,
    required QuoteContext context,
  }) async {
    try {
      final now = _now();
      final Quote quote;
      if (tier == Tier.three) {
        // ADR-0012 §"Decision" point 1 — Tier 3 is curated-only. Do NOT
        // pass through the AI repo or the Safety Filter. This branch
        // returns before any AI-adjacent type is referenced.
        quote = _quoteLibrary.pickTier3(seed: now);
      } else {
        // Tier 1 / Tier 2. `AiAllowedTier.fromTier` is unreachable for
        // Tier 3 thanks to the branch above — belt-and-suspenders per
        // ADR-0012 §"Decision" point 2.
        final allowed = AiAllowedTier.fromTier(tier);
        quote = await _runHybridPath(allowed, context, now);
      }

      // TC-38 — every Tier 1/2/3 body carries the canonical footer.
      // `DisclaimerCopy.notificationFooter` is the only place that string
      // lives (CLAUDE.md "Pre-approved intervention phrasing"); the
      // dispatcher imports it, never duplicates it.
      final body = '${quote.text}\n\n${DisclaimerCopy.notificationFooter}';

      final dispatch = InterventionDispatch(
        tier: tier,
        body: body,
        ctas: _ctasForTier(tier),
        dispatchId: _dispatchIdFor(tier, now),
        quoteId: quote.id,
        dispatchedAt: now,
      );
      return Ok(dispatch);
    } catch (e, st) {
      _logger.error('Dispatch failed', error: e, stackTrace: st);
      return Err(InterventionFailure.unknown(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Internals
  // ─────────────────────────────────────────────────────────────────────

  /// Hybrid path for Tier 1 / Tier 2 only. Fail-closed: filter reject OR
  /// network failure → curated fallback.
  Future<Quote> _runHybridPath(
    AiAllowedTier allowed,
    QuoteContext ctx,
    DateTime now,
  ) async {
    final ai = await _aiQuoteRepository.requestSuggestion(allowed, ctx);
    final text = ai.getOrNull();
    if (text == null) {
      _logger.info('AI suggestion failed; falling back to curated');
      return _curatedFallback(allowed, now);
    }
    final gated = _safetyFilter.gate(text, tier: allowed);
    final quote = gated.getOrNull();
    if (quote == null) {
      _logger.info('Safety filter rejected; falling back to curated');
      return _curatedFallback(allowed, now);
    }
    return quote;
  }

  Quote _curatedFallback(AiAllowedTier allowed, DateTime seed) =>
      switch (allowed) {
        AiAllowedTier.one => _quoteLibrary.pickTier1(seed: seed),
        AiAllowedTier.two => _quoteLibrary.pickTier2(seed: seed),
      };

  /// Semantic CTA keys, per HB-007 §"Dispatcher state machine":
  ///   Tier 1 → breathing screen.
  ///   Tier 2 → journaling screen.
  ///   Tier 3 → crisis screen (Hotline 1323 lives there — TC-33).
  /// Every tier also carries the opt-out key (TC-34).
  List<String> _ctasForTier(Tier tier) => switch (tier) {
    Tier.one => const ['open_breathing', 'opt_out'],
    Tier.two => const ['open_journal', 'opt_out'],
    Tier.three => const ['open_crisis', 'opt_out'],
  };

  /// Deterministic id so a duplicate dispatch within the same millisecond
  /// for the same tier collapses on the Firestore write (the audit doc
  /// `create` returns `already-exists`, which the data-layer impl treats
  /// as the idempotent path). Format: `${tier.name}-${epochMs}`.
  String _dispatchIdFor(Tier tier, DateTime now) =>
      '${tier.name}-${now.millisecondsSinceEpoch}';
}
