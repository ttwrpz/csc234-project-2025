import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart' show featureFlagsProvider;
import '../../../auth/data/providers.dart';
import '../../../garden/data/providers.dart'
    show interventionStateRepositoryProvider;
import '../../../mood/data/providers.dart' show myMoodsStreamProvider;
import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/services/mood_score.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../pattern_engine/data/providers.dart'
    show patternRepositoryProvider;
import '../../../pattern_engine/domain/entities/pattern_result.dart';
import '../../../pattern_engine/domain/entities/tier.dart';
import '../../data/providers.dart';
import '../../domain/entities/intervention_dispatch.dart';
import '../../domain/entities/intervention_failure.dart';
import '../../domain/entities/intervention_record.dart';
import '../../domain/entities/quote_context.dart';
import '../../domain/services/cooldown_guard.dart';
import '../../domain/services/tiered_intervention_dispatcher.dart';
import '../../domain/usecases/dispatch_intervention.dart';

/// View-state of the intervention surface. Sealed so the banner host can
/// pattern-match exhaustively (the analyzer flags an unhandled new variant).
sealed class InterventionControllerState {
  const InterventionControllerState();
}

/// No dispatch is currently pending. The banner host renders nothing.
final class InterventionIdle extends InterventionControllerState {
  const InterventionIdle();
}

/// A tier has fired AND been gated; the user has not yet engaged. The
/// banner host shows the bottom-anchored banner with the dispatch body
/// and CTAs; the dispatch's quote text + disclaimer footer are already
/// composed in `dispatch.body`.
final class InterventionPending extends InterventionControllerState {
  const InterventionPending(this.dispatch);
  final InterventionDispatch dispatch;
}

/// Bridges the Pattern Engine's per-day `triggeredTier` into a routed
/// user-facing surface. Subscribes to today's [PatternResult] via
/// [patternRepositoryProvider.watch]. On each emission whose
/// `triggeredTier` is non-null AND differs from the last seen tier, the
/// controller:
///
///   1. Reads the per-tier toggle from [NotificationsToggleState]. If
///      the user has opted out of THIS tier, the controller skips
///      silently - other tiers stay live (FCM toggle expansion
///      semantics; see [NotificationsController]).
///   2. Builds a [QuoteContext] from `myMoodsStreamProvider`-derived
///      daily averages.
///   3. Invokes [DispatchInterventionUseCase] which already encapsulates
///      cooldown + tier-3 determinism + quote selection + audit-doc
///      write + `lastTriggeredAt` advance. The controller does NOT
///      duplicate any of those writes - that would create two paths to
///      the same Firestore docs.
///   4. On Ok: emits [InterventionPending] so the banner appears.
///   5. On Err(cooldown) | Err(tierDisabled): silent (no UI).
///   6. On Err(anchorReadFailed) | Err(unknown): logged (PII-free,
///      runtimeType only), no UI surface.
///
/// On `optOut()`: marks the audit doc opted-out and advances the cooldown
/// anchor (the spec requires 48h cooldown to apply even after opt-out so
/// the system does not re-nag).
///
/// On `complete()`: clears the pending state. No additional Firestore
/// write - the audit record from step 3 is the source of truth.
class InterventionController extends Notifier<InterventionControllerState> {
  /// Tracks the most-recent tier we've already dispatched for so the
  /// stream's snapshot replay (Firestore re-emits on listener attach
  /// and on every change) does not fire a duplicate dispatch.
  Tier? _lastDispatchedTier;

  StreamSubscription<PatternResult?>? _patternSub;

  @override
  InterventionControllerState build() {
    // Listen to auth state cheaply; only attach the pattern stream once
    // a uid lands. Mirrors the lazy-attach pattern from
    // [NotificationsController].
    ref.listen(currentUserStreamProvider, (_, async) {
      final uid = async.value?.uid;
      if (uid == null || uid.isEmpty) {
        _detach();
        return;
      }
      _attach(uid);
    }, fireImmediately: true);

    ref.onDispose(_detach);
    return const InterventionIdle();
  }

  void _attach(String uid) {
    _detach();
    final now = DateTime.now();
    // dateId = yyyy-MM-dd from local midnight - matches the format
    // produced by RunPatternEngineUseCase when it writes today's
    // PatternResult doc at users/{uid}/patterns/{dateId}.
    final dateId =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final repo = ref.read(patternRepositoryProvider);
    _patternSub = repo.watch(userId: uid, dateId: dateId).listen(_onPattern);
  }

  void _detach() {
    _patternSub?.cancel();
    _patternSub = null;
  }

  void _onPattern(PatternResult? result) {
    final tier = result?.triggeredTier;
    if (tier == null) {
      // Today's pattern doc has no trigger. Clear the de-dup anchor so
      // a future tier flip (after the user logs a darker entry) still
      // fires.
      _lastDispatchedTier = null;
      return;
    }
    if (tier == _lastDispatchedTier) return;
    // Fire-and-forget - the dispatch use case is itself best-effort and
    // already swallows / surfaces failures via the Result type.
    unawaited(_dispatchFor(tier));
  }

  Future<void> _dispatchFor(Tier tier) async {
    const logger = Logger('intervention.controller');
    if (!_isTierEnabled(tier)) {
      // User opted out of this tier; treat as if the engine did not
      // fire. Set the de-dup anchor so the same tier from the same
      // day's pattern doc does not re-evaluate on every snapshot.
      _lastDispatchedTier = tier;
      return;
    }

    final ctx = await _buildContext();
    final useCase = await _useCase();
    if (useCase == null) {
      logger.warn('dispatch skipped - use case unavailable');
      return;
    }

    final result = await useCase(tier: tier, context: ctx);
    _lastDispatchedTier = tier;
    switch (result) {
      case Ok(:final value):
        state = InterventionPending(value);
        // Fire the FCM push fire-and-forget - gated on Remote Config so
        // the in-app banner ships independent of the push surface. The
        // CF call is best-effort; transport failures are swallowed at
        // the datasource so they cannot unwind the in-app experience.
        if (ref.read(featureFlagsProvider).interventionDispatchEnabled) {
          unawaited(_dispatchFcm(value));
        }
      case Err(:final failure):
        _logFailure(failure, logger);
    }
  }

  /// Fires the per-tier FCM push by invoking `dispatchIntervention` with
  /// the dispatch id the audit doc already carries. The CF reads the
  /// audit doc back, validates tier + opt-out, and sends a LOCKED
  /// per-tier payload - the request never carries body text.
  ///
  /// Errors are logged PII-free (runtimeType only) and discarded. The
  /// in-app banner is the source of truth for the user-visible surface.
  Future<void> _dispatchFcm(InterventionDispatch dispatch) async {
    const logger = Logger('intervention.controller.fcm');
    try {
      final ds = ref.read(dispatchInterventionFunctionsDatasourceProvider);
      final outcome = await ds.call(
        tier: dispatch.tier,
        dispatchId: dispatch.dispatchId,
        requestId: dispatch.dispatchId,
      );
      if (outcome != null && outcome != 'sent') {
        logger.info('fcm dispatch non-sent', data: outcome);
      }
    } catch (e) {
      logger.warn('fcm dispatch failed', data: e.runtimeType.toString());
    }
  }

  bool _isTierEnabled(Tier tier) {
    final toggles = ref.read(notificationsControllerProvider);
    return switch (tier) {
      Tier.one => toggles.tier1Enabled,
      Tier.two => toggles.tier2Enabled,
      // Tier 3 still respects the user's explicit opt-out (every
      // notification includes opt-out). The cooldown gate is independent
      // and applies identically across tiers (max 1 notification per
      // day).
      Tier.three => toggles.tier3Enabled,
    };
  }

  Future<QuoteContext> _buildContext() async {
    final entries = await _readMoodsOrEmpty();
    final today = DateTime.now();
    final todayLocal = DateTime(today.year, today.month, today.day);
    final todays = entries.where((e) {
      final d = e.createdAt;
      return d.year == todayLocal.year &&
          d.month == todayLocal.month &&
          d.day == todayLocal.day;
    });
    final scores = todays
        .map((e) => computeMoodScore(e.mood, e.intensity).value)
        .toList(growable: false);
    final avg = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
    return QuoteContext(
      weekId: _isoWeekId(today),
      dailyAvgS: avg,
      dominantEmotion: _dominantEmotion(todays),
    );
  }

  Future<List<MoodEntry>> _readMoodsOrEmpty() async {
    try {
      return await ref.read(myMoodsStreamProvider.future);
    } catch (_) {
      return const <MoodEntry>[];
    }
  }

  /// Picks the most-frequent mood among today's entries; null when the
  /// user hasn't logged today. The Cloud Function uses this to pick a
  /// template; never echoed back verbatim.
  static dynamic _dominantEmotion(Iterable<MoodEntry> todays) {
    if (todays.isEmpty) return null;
    final counts = <Object, int>{};
    for (final e in todays) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    Object? best;
    int bestN = 0;
    counts.forEach((k, n) {
      if (n > bestN) {
        bestN = n;
        best = k;
      }
    });
    return best;
  }

  /// ISO-8601 week id `YYYY-Www` - for log correlation only. Pulled
  /// inline rather than importing the harvest helper because that helper
  /// is currently a private static on `ArchiveWeeklyGardenUseCase`.
  static String _isoWeekId(DateTime date) {
    final thursday = date.add(Duration(days: 4 - ((date.weekday + 6) % 7 + 1)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstThursdayWeekday = (firstThursday.weekday + 6) % 7 + 1;
    final week1Start = firstThursday.subtract(
      Duration(days: firstThursdayWeekday - 1),
    );
    final week = ((thursday.difference(week1Start).inDays) / 7).floor() + 1;
    final ww = week.toString().padLeft(2, '0');
    return '${thursday.year}-W$ww';
  }

  /// Builds the use case from current providers. Returns null when the
  /// anchor repository hasn't resolved yet (`FutureProvider` is in
  /// loading state - happens on first frame after sign-in).
  Future<DispatchInterventionUseCase?> _useCase() async {
    final dispatcher = TieredInterventionDispatcher(
      quoteLibrary: ref.read(quoteLibraryProvider),
      aiQuoteRepository: ref.read(aiQuoteRepositoryProvider),
      safetyFilter: ref.read(quoteSafetyFilterProvider),
      now: DateTime.now,
    );
    final stateRepoAsync = ref.read(interventionStateRepositoryProvider);
    final stateRepo = stateRepoAsync.value;
    if (stateRepo == null) return null;
    final cooldownGuard = CooldownGuard(
      stateRepo: stateRepo,
      now: DateTime.now,
    );
    return DispatchInterventionUseCase(
      dispatcher: dispatcher,
      cooldownGuard: cooldownGuard,
      interventionRepository: ref.read(interventionRepositoryProvider),
      stateRepository: stateRepo,
      cooldownWindow: CooldownGuard.cooldownWindow,
    );
  }

  /// Logs the failure with the runtimeType only - no PII, no body, no
  /// uid. The cooldown / tierDisabled cases are the silent paths (no
  /// banner should surface); the anchor / unknown cases are observability
  /// signals only.
  void _logFailure(InterventionFailure failure, Logger logger) {
    switch (failure) {
      case _ when failure.toString().contains('Cooldown'):
        return; // silent path
      case _ when failure.toString().contains('TierDisabled'):
        return; // silent path
      default:
        logger.warn('dispatch failed', data: failure.runtimeType.toString());
    }
  }

  /// Records the user's opt-out and advances the cooldown anchor. The
  /// 48h cooldown applies even after opt-out so the system does not
  /// re-nag.
  Future<void> optOut() async {
    final current = state;
    if (current is! InterventionPending) return;
    final dispatchId = current.dispatch.dispatchId;
    final repo = ref.read(interventionRepositoryProvider);
    await repo.markOptedOut(dispatchId);

    final stateRepo = ref.read(interventionStateRepositoryProvider).value;
    await stateRepo?.writeLastTriggeredAt(DateTime.now());

    state = const InterventionIdle();
  }

  /// Clears the pending state without recording an opt-out. Called when
  /// the user engages with the tier surface (breathing completed,
  /// journal saved, crisis screen dismissed via a resource link, etc).
  void complete() {
    state = const InterventionIdle();
  }

  /// Debug-only manual trigger for a specific tier. Bypasses the cooldown
  /// gate AND the user's per-tier opt-out flags so QA / demo can drive
  /// each banner → screen flow on demand AND can re-trigger repeatedly
  /// without waiting 24h between fires. Production callers MUST gate
  /// invocations behind `kDebugMode` - there is no production surface
  /// that should reach this path. The Tier 3 determinism guarantee is
  /// preserved: the dispatcher's type-level fence still routes Tier 3
  /// to the curated pool only.
  ///
  /// Implementation: we call the dispatcher DIRECTLY rather than going
  /// through `DispatchInterventionUseCase`, which would consult the
  /// `CooldownGuard` and reject the second-and-subsequent calls in a
  /// 24-hour window. We do still write the audit doc to
  /// `users/{uid}/interventions/{id}` so the dispatch is observable in
  /// Firestore - that's harmless for production observability and
  /// keeps the integration tests happy. We do NOT advance the cooldown
  /// anchor (which would be the production behaviour) - that's what
  /// lets debug-trigger fire repeatedly.
  Future<void> debugDispatch(Tier tier) async {
    const logger = Logger('intervention.controller.debug');
    final ctx = await _buildContext();
    final dispatcher = TieredInterventionDispatcher(
      quoteLibrary: ref.read(quoteLibraryProvider),
      aiQuoteRepository: ref.read(aiQuoteRepositoryProvider),
      safetyFilter: ref.read(quoteSafetyFilterProvider),
      now: DateTime.now,
    );
    final result = await dispatcher.dispatch(tier: tier, context: ctx);
    switch (result) {
      case Ok(:final value):
        // Write the audit doc best-effort (don't block the banner if
        // Firestore is unreachable - debug path).
        final repo = ref.read(interventionRepositoryProvider);
        unawaited(
          repo.writeRecord(
            InterventionRecord(
              dispatchId: value.dispatchId,
              tier: value.tier,
              dispatchedAt: value.dispatchedAt,
              quoteId: value.quoteId,
              cooldownUntil: value.dispatchedAt.add(
                CooldownGuard.cooldownWindow,
              ),
            ),
          ),
        );
        state = InterventionPending(value);
      case Err(:final failure):
        logger.warn(
          'debug dispatch failed',
          data: failure.runtimeType.toString(),
        );
    }
  }
}

/// Public Riverpod provider for the controller. The view (the banner host
/// + the tier screens) reads this provider; tests override its
/// dependencies. The cooldown-anchor `interventionStateRepositoryProvider`
/// is imported from `garden/data/providers.dart` (its canonical home) and
/// read as `AsyncValue<InterventionStateRepository>` inside the
/// controller; tests override that provider directly.
final interventionControllerProvider =
    NotifierProvider<InterventionController, InterventionControllerState>(
      InterventionController.new,
    );
