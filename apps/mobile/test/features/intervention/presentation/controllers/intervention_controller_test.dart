import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/data/providers.dart'
    show interventionStateRepositoryProvider;
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';
import 'package:moodbloom/features/intervention/data/providers.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_record.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_context.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_failure.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_failure.dart';
import 'package:moodbloom/features/intervention/domain/repositories/ai_quote_repository.dart';
import 'package:moodbloom/features/intervention/domain/repositories/intervention_repository.dart';
import 'package:moodbloom/features/intervention/domain/repositories/quote_library.dart';
import 'package:moodbloom/features/intervention/domain/services/quote_safety_filter.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/mood/data/providers.dart'
    show myMoodsStreamProvider;
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/notifications/data/providers.dart';
import 'package:moodbloom/features/notifications/domain/fcm_token_repository.dart';
import 'package:moodbloom/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:moodbloom/features/notifications/domain/notification_failure.dart';
import 'package:moodbloom/features/notifications/domain/notifications_settings.dart';
import 'package:moodbloom/features/pattern_engine/data/providers.dart'
    show patternRepositoryProvider;
import 'package:moodbloom/features/pattern_engine/domain/entities/pattern_result.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';
import 'package:moodbloom/features/pattern_engine/domain/pattern_failure.dart';
import 'package:moodbloom/features/pattern_engine/domain/repositories/pattern_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hand-written fakes — `mocktail` is not in pubspec; matches the
/// pattern used by `tiered_intervention_dispatcher_test.dart` and the
/// other intervention tests in this folder.

class _FakePatternRepository implements PatternRepository {
  final StreamController<PatternResult?> controller =
      StreamController<PatternResult?>.broadcast();

  @override
  Stream<PatternResult?> watch({
    required String userId,
    required String dateId,
  }) => controller.stream;

  @override
  Future<Result<void, PatternFailure>> save({
    required String userId,
    required PatternResult result,
  }) async => const Ok(null);

  @override
  Stream<List<PatternResult>> watchRange({
    required String userId,
    required String startDateId,
    required String endDateId,
  }) => const Stream.empty();
}

class _FakeInterventionRepo implements InterventionRepository {
  int writeRecordCalls = 0;
  final List<String> optedOutDispatchIds = [];

  @override
  Future<Result<void, InterventionFailure>> writeRecord(
    InterventionRecord record,
  ) async {
    writeRecordCalls += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void, InterventionFailure>> markOptedOut(
    String dispatchId,
  ) async {
    optedOutDispatchIds.add(dispatchId);
    return const Ok(null);
  }

  @override
  Stream<List<InterventionRecord>> watchHistory({int limit = 20}) =>
      const Stream.empty();
}

class _FakeStateRepo implements InterventionStateRepository {
  int writeLastCalls = 0;
  DateTime? lastTriggeredAtPersisted;

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async =>
      const Ok(InterventionAnchors());

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async {
    writeLastCalls += 1;
    lastTriggeredAtPersisted = now;
    return const Ok(null);
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  ) async => const Ok(null);

  @override
  Future<Result<void, InterventionStateFailure>>
  clearFirstTriggeredAt() async => const Ok(null);
}

/// Always-accept Quote Library — returns a fixed phrase per tier so the
/// dispatcher's body composition is observable in tests.
class _FakeQuoteLibrary implements QuoteLibrary {
  @override
  Quote pickTier1({required DateTime seed}) => const Quote(
    id: 'fake.tier1.0',
    text: 'tier-1-curated',
    source: QuoteSource.curated,
    tier: Tier.one,
  );

  @override
  Quote pickTier2({required DateTime seed}) => const Quote(
    id: 'fake.tier2.0',
    text: 'tier-2-curated',
    source: QuoteSource.curated,
    tier: Tier.two,
  );

  @override
  Quote pickTier3({required DateTime seed}) => const Quote(
    id: 'fake.tier3.0',
    text: 'tier-3-curated mention 1323',
    source: QuoteSource.curated,
    tier: Tier.three,
  );
}

/// Recording AI repo — TC-40 / TEST 3 asserts `calls.isEmpty` after a
/// Tier 3 emission. The dispatcher must NEVER reach Gemini for Tier 3.
class _RecordingAIQuoteRepository implements AIQuoteRepository {
  final List<({AiAllowedTier tier, QuoteContext ctx})> calls = [];

  @override
  Future<Result<String, QuoteFailure>> requestSuggestion(
    AiAllowedTier tier,
    QuoteContext ctx,
  ) async {
    calls.add((tier: tier, ctx: ctx));
    // Make Tier 1/2 fall through to curated by returning a network err;
    // the body assertion stays simple either way.
    return const Err(QuoteFailure.network());
  }
}

class _FakeSafetyFilter implements QuoteSafetyFilter {
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

/// Fake FCM token repo so the `NotificationsController.build()` listener
/// has somewhere to read settings. Returns the per-test [_settings].
class _FakeFcmTokenRepository implements FcmTokenRepository {
  _FakeFcmTokenRepository(this._settings);
  NotificationsSettings _settings;

  void updateSettings(NotificationsSettings s) => _settings = s;

  @override
  Stream<NotificationsSettings>? watchSettings({required String uid}) =>
      Stream.value(_settings);

  @override
  Future<Result<void, NotificationFailure>> upsertToken({
    required String uid,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setEnabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setTier1Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setTier2Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setTier3Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);
}

PatternResult _patternFor(Tier? tier) => PatternResult(
  dateId: '2026-05-13',
  mannKendallZ: null,
  slidingNegCount: 0,
  consecutiveHighIntensity: 0,
  zScoreToday: null,
  cusumC: 0.0,
  triggeredTier: tier,
);

ProviderContainer _makeContainer({
  required _FakePatternRepository patternRepo,
  required _FakeInterventionRepo interventionRepo,
  required _FakeStateRepo stateRepo,
  required _RecordingAIQuoteRepository aiRepo,
  required _FakeQuoteLibrary quoteLib,
  required _FakeSafetyFilter safetyFilter,
  required NotificationsSettings settings,
}) {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return ProviderContainer(
    overrides: [
      currentUserStreamProvider.overrideWith(
        (_) => Stream.value(const AppUser(uid: 'u-1', email: 'u@example.com')),
      ),
      patternRepositoryProvider.overrideWithValue(patternRepo),
      interventionRepositoryProvider.overrideWithValue(interventionRepo),
      interventionStateRepositoryProvider.overrideWith((_) async => stateRepo),
      quoteLibraryProvider.overrideWithValue(quoteLib),
      aiQuoteRepositoryProvider.overrideWithValue(aiRepo),
      quoteSafetyFilterProvider.overrideWithValue(safetyFilter),
      fcmTokenRepositoryProvider.overrideWithValue(
        _FakeFcmTokenRepository(settings),
      ),
      myMoodsStreamProvider.overrideWith(
        (_) => Stream.value(const <MoodEntry>[]),
      ),
      notificationsPreferenceDatasourceProvider.overrideWithValue(null),
    ],
  );
}

NotificationsSettings _allTiersOn() => const NotificationsSettings(
  cheerUpEnabled: true,
  tier1Enabled: true,
  tier2Enabled: true,
  tier3Enabled: true,
);

NotificationsSettings _tier1Off() => const NotificationsSettings(
  cheerUpEnabled: true,
  tier1Enabled: false,
  tier2Enabled: true,
  tier3Enabled: true,
);

Future<void> _waitForState(
  ProviderContainer container,
  bool Function(InterventionControllerState) predicate, {
  Duration step = const Duration(milliseconds: 5),
  int maxSteps = 100,
}) async {
  for (var i = 0; i < maxSteps; i += 1) {
    if (predicate(container.read(interventionControllerProvider))) return;
    await Future<void>.delayed(step);
  }
}

/// Pre-warms the container so:
///  - the auth StreamProvider has delivered its first event,
///  - the FutureProvider for [interventionStateRepositoryProvider] has
///    resolved,
///  - the [InterventionController] notifier has had a chance to attach
///    its pattern-stream subscription.
/// Without this, the first pattern emission races the use-case wire-up
/// and `_useCase()` short-circuits because the state-repo's
/// `AsyncValue` is still `loading`.
Future<void> _primeContainer(ProviderContainer container) async {
  // Subscribe to surfaces the controller reads via `ref.read`. Bare
  // `read` does not initialise a provider (no subscriber → no
  // emission); a single `listen()` is enough.
  container.listen(currentUserStreamProvider, (_, _) {});
  container.listen(interventionStateRepositoryProvider, (_, _) {});
  container.listen(myMoodsStreamProvider, (_, _) {});
  container.listen(notificationsControllerProvider, (_, _) {});
  // Bootstrap the controller (subscribes the pattern stream once auth
  // lands).
  container.read(interventionControllerProvider);
  // Let the auth + state-repo futures resolve.
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  // The controller spins up a Notifier that listens to current-user +
  // pattern-stream lazily. Every test seeds the container with a fake
  // pattern stream and emits a synthetic [PatternResult] to drive the
  // dispatcher path under test.

  group('InterventionController', () {
    test('TEST 1 — Tier.one + tier1Enabled=true + cooldown clear → '
        'state transitions to InterventionPending; repo + state-repo '
        'each receive exactly one write', () async {
      final patternRepo = _FakePatternRepository();
      final interventionRepo = _FakeInterventionRepo();
      final stateRepo = _FakeStateRepo();
      final aiRepo = _RecordingAIQuoteRepository();
      final quoteLib = _FakeQuoteLibrary();
      final filter = _FakeSafetyFilter();

      final container = _makeContainer(
        patternRepo: patternRepo,
        interventionRepo: interventionRepo,
        stateRepo: stateRepo,
        aiRepo: aiRepo,
        quoteLib: quoteLib,
        safetyFilter: filter,
        settings: _allTiersOn(),
      );
      addTearDown(container.dispose);

      await _primeContainer(container);

      patternRepo.controller.add(_patternFor(Tier.one));
      await _waitForState(container, (s) => s is InterventionPending);

      expect(
        container.read(interventionControllerProvider),
        isA<InterventionPending>(),
      );
      expect(interventionRepo.writeRecordCalls, 1);
      expect(stateRepo.writeLastCalls, 1);
    });

    test('TEST 2 — Tier.one + tier1Enabled=false → state stays Idle; '
        'no repo writes', () async {
      final patternRepo = _FakePatternRepository();
      final interventionRepo = _FakeInterventionRepo();
      final stateRepo = _FakeStateRepo();
      final aiRepo = _RecordingAIQuoteRepository();
      final quoteLib = _FakeQuoteLibrary();
      final filter = _FakeSafetyFilter();

      final container = _makeContainer(
        patternRepo: patternRepo,
        interventionRepo: interventionRepo,
        stateRepo: stateRepo,
        aiRepo: aiRepo,
        quoteLib: quoteLib,
        safetyFilter: filter,
        settings: _tier1Off(),
      );
      addTearDown(container.dispose);

      await _primeContainer(container);

      patternRepo.controller.add(_patternFor(Tier.one));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        container.read(interventionControllerProvider),
        isA<InterventionIdle>(),
      );
      expect(interventionRepo.writeRecordCalls, 0);
      expect(stateRepo.writeLastCalls, 0);
    });

    test('TEST 3 — Tier.three with tier3Enabled=true → InterventionPending '
        'AND AIQuoteRepository.requestSuggestion is NEVER called '
        '(re-asserts TC-40 at the controller layer)', () async {
      final patternRepo = _FakePatternRepository();
      final interventionRepo = _FakeInterventionRepo();
      final stateRepo = _FakeStateRepo();
      final aiRepo = _RecordingAIQuoteRepository();
      final quoteLib = _FakeQuoteLibrary();
      final filter = _FakeSafetyFilter();

      final container = _makeContainer(
        patternRepo: patternRepo,
        interventionRepo: interventionRepo,
        stateRepo: stateRepo,
        aiRepo: aiRepo,
        quoteLib: quoteLib,
        safetyFilter: filter,
        settings: _allTiersOn(),
      );
      addTearDown(container.dispose);

      await _primeContainer(container);

      patternRepo.controller.add(_patternFor(Tier.three));
      await _waitForState(container, (s) => s is InterventionPending);

      final state =
          container.read(interventionControllerProvider) as InterventionPending;
      expect(state.dispatch.tier, Tier.three);
      // ADR-0012 §"Decision" point 1: Tier 3 must never reach Gemini.
      expect(
        aiRepo.calls,
        isEmpty,
        reason:
            'Tier 3 dispatches must never invoke AIQuoteRepository.requestSuggestion '
            '(ADR-0012 + TC-40).',
      );
    });

    test('TEST 4 — Same tier emitted twice → only one dispatch is fired '
        '(snapshot-replay de-duplication)', () async {
      final patternRepo = _FakePatternRepository();
      final interventionRepo = _FakeInterventionRepo();
      final stateRepo = _FakeStateRepo();
      final aiRepo = _RecordingAIQuoteRepository();
      final quoteLib = _FakeQuoteLibrary();
      final filter = _FakeSafetyFilter();

      final container = _makeContainer(
        patternRepo: patternRepo,
        interventionRepo: interventionRepo,
        stateRepo: stateRepo,
        aiRepo: aiRepo,
        quoteLib: quoteLib,
        safetyFilter: filter,
        settings: _allTiersOn(),
      );
      addTearDown(container.dispose);

      await _primeContainer(container);

      // First emission → dispatch fires.
      patternRepo.controller.add(_patternFor(Tier.one));
      await _waitForState(container, (s) => s is InterventionPending);
      expect(interventionRepo.writeRecordCalls, 1);
      expect(stateRepo.writeLastCalls, 1);

      // Snapshot-replay: same tier re-emitted (Firestore re-sends on
      // listener attach / on every change).
      patternRepo.controller.add(_patternFor(Tier.one));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(interventionRepo.writeRecordCalls, 1);
      expect(stateRepo.writeLastCalls, 1);
    });

    test('TEST 5 — optOut() advances cooldown anchor AND marks audit '
        'record opted-out; state returns to Idle', () async {
      final patternRepo = _FakePatternRepository();
      final interventionRepo = _FakeInterventionRepo();
      final stateRepo = _FakeStateRepo();
      final aiRepo = _RecordingAIQuoteRepository();
      final quoteLib = _FakeQuoteLibrary();
      final filter = _FakeSafetyFilter();

      final container = _makeContainer(
        patternRepo: patternRepo,
        interventionRepo: interventionRepo,
        stateRepo: stateRepo,
        aiRepo: aiRepo,
        quoteLib: quoteLib,
        safetyFilter: filter,
        settings: _allTiersOn(),
      );
      addTearDown(container.dispose);

      await _primeContainer(container);

      patternRepo.controller.add(_patternFor(Tier.one));
      await _waitForState(container, (s) => s is InterventionPending);

      final pending =
          container.read(interventionControllerProvider) as InterventionPending;

      await container.read(interventionControllerProvider.notifier).optOut();

      expect(
        container.read(interventionControllerProvider),
        isA<InterventionIdle>(),
      );
      expect(
        interventionRepo.optedOutDispatchIds,
        contains(pending.dispatch.dispatchId),
      );
      // Initial dispatch wrote 1; opt-out also advances the anchor
      // so the system does not re-nag → expect 2 writes total.
      expect(stateRepo.writeLastCalls, 2);
    });

    test('TEST 6 — complete() clears the pending state without writing '
        'to the audit doc or the cooldown anchor', () async {
      final patternRepo = _FakePatternRepository();
      final interventionRepo = _FakeInterventionRepo();
      final stateRepo = _FakeStateRepo();
      final aiRepo = _RecordingAIQuoteRepository();
      final quoteLib = _FakeQuoteLibrary();
      final filter = _FakeSafetyFilter();

      final container = _makeContainer(
        patternRepo: patternRepo,
        interventionRepo: interventionRepo,
        stateRepo: stateRepo,
        aiRepo: aiRepo,
        quoteLib: quoteLib,
        safetyFilter: filter,
        settings: _allTiersOn(),
      );
      addTearDown(container.dispose);

      await _primeContainer(container);

      patternRepo.controller.add(_patternFor(Tier.one));
      await _waitForState(container, (s) => s is InterventionPending);

      final priorWriteRecord = interventionRepo.writeRecordCalls;
      final priorAnchorWrites = stateRepo.writeLastCalls;

      container.read(interventionControllerProvider.notifier).complete();

      expect(
        container.read(interventionControllerProvider),
        isA<InterventionIdle>(),
      );
      // No new writes occurred — the audit row from the dispatch is
      // the source of truth; complete() is a UI-only state reset.
      expect(interventionRepo.writeRecordCalls, priorWriteRecord);
      expect(stateRepo.writeLastCalls, priorAnchorWrites);
      expect(interventionRepo.optedOutDispatchIds, isEmpty);
    });
  });
}
