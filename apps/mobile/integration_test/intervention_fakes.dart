import 'package:core/core.dart';
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_failure.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_record.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_context.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_failure.dart';
import 'package:moodbloom/features/intervention/domain/repositories/ai_quote_repository.dart';
import 'package:moodbloom/features/intervention/domain/repositories/intervention_repository.dart';
import 'package:moodbloom/features/notifications/domain/fcm_token_repository.dart';
import 'package:moodbloom/features/notifications/domain/notification_failure.dart';
import 'package:moodbloom/features/notifications/domain/notifications_settings.dart';

/// Shared fakes for the Tier 1/2 + Tier 3 integration tests
/// (`intervention_tier_1_2_test.dart`, `intervention_tier_3_test.dart`).
///
/// These re-use the SAME shape as the controller unit tests in
/// `apps/mobile/test/features/intervention/presentation/controllers/
/// intervention_controller_test.dart` — recording fakes (hand-written,
/// no `mocktail`) so the test can assert call counts + the captured
/// arguments. The codebase does not depend on `mocktail` so we cannot
/// use `verifyNever` directly; the integration-level TC-40 re-assertion
/// reads from `RecordingAIQuoteRepository.calls.isEmpty` after the
/// dispatch lands.

/// Recording fake of [AIQuoteRepository]. Captures every call and
/// returns the test-seeded [nextSuggestion] (or [failNext] if set).
///
/// **TC-40 invariant subject:** Tier 3 dispatches MUST NEVER call
/// [requestSuggestion]. The integration test asserts
/// `aiRepo.calls.isEmpty` after a Tier 3 emission settles, which is
/// the same invariant the unit test in
/// `tiered_intervention_dispatcher_test.dart` already covers — but
/// re-asserted here at the integration level so a future regression
/// that swaps the dispatcher's tier-3 arm for a hybrid path would fail
/// BOTH the unit and the integration suite.
class RecordingAIQuoteRepository implements AIQuoteRepository {
  RecordingAIQuoteRepository({this.nextSuggestion = 'safe-suggestion'});

  /// The text returned on every call unless [failNext] is set. Tests
  /// re-seed this between sub-flows (happy path → filter-reject path).
  String nextSuggestion;

  /// If set, the NEXT call returns this failure and clears the field.
  /// Used by the Tier 1 network-fail sub-flow.
  QuoteFailure? failNext;

  /// Captured calls, in order. Tier 3 tests assert this list is empty.
  final List<({AiAllowedTier tier, QuoteContext ctx})> calls = [];

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
    return Ok(nextSuggestion);
  }
}

/// Recording fake of [InterventionRepository]. Counts writes + records
/// opted-out dispatch ids so tests can assert the audit-trail wire-up.
class FakeInterventionRepository implements InterventionRepository {
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
      const Stream<List<InterventionRecord>>.empty();
}

/// In-memory [InterventionStateRepository]. Anchors live in `_anchors`;
/// `writeLastTriggeredAt` advances `lastTriggeredAt` and bumps the
/// call counter.
class FakeInterventionStateRepository implements InterventionStateRepository {
  InterventionAnchors _anchors = const InterventionAnchors();
  int writeLastCalls = 0;

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async =>
      Ok(_anchors);

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async {
    writeLastCalls += 1;
    _anchors = _anchors.copyWith(lastTriggeredAt: now);
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

/// Fake [FcmTokenRepository] so the [NotificationsController] can read
/// per-tier toggle state without Firestore. Tests construct one with
/// [allTiersOnSettings] for the default rig.
class FakeFcmTokenRepository implements FcmTokenRepository {
  FakeFcmTokenRepository(this._settings);
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

/// Convenience constructor for the "every tier on" notification
/// settings — the default rig for both integration tests.
NotificationsSettings allTiersOnSettings() => const NotificationsSettings(
  cheerUpEnabled: true,
  tier1Enabled: true,
  tier2Enabled: true,
  tier3Enabled: true,
);
