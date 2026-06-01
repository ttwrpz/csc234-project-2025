import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';
import 'package:moodbloom/features/intervention/domain/entities/cooldown_decision.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_failure.dart';
import 'package:moodbloom/features/intervention/domain/services/cooldown_guard.dart';

/// In-memory anchor repo for guard tests. Records calls and returns a
/// canned `InterventionAnchors`. Mirrors the codebase's recording-fake
/// idiom (see `cheer_up_events_repository_impl_test.dart`).
class _FakeStateRepo implements InterventionStateRepository {
  _FakeStateRepo({this.anchors = const InterventionAnchors(), this.readError});

  InterventionAnchors anchors;
  InterventionStateFailure? readError;
  int readCalls = 0;

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async {
    readCalls += 1;
    final err = readError;
    if (err != null) return Err(err);
    return Ok(anchors);
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async => const Ok(null);

  @override
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  ) async => const Ok(null);

  @override
  Future<Result<void, InterventionStateFailure>>
  clearFirstTriggeredAt() async => const Ok(null);
}

/// Repo whose `read()` returns `Err` to simulate Firestore + mirror both
/// failing. The real impl swallows the FirebaseException and returns the
/// mirror as `Ok`, so an `Err` here represents the "everything is broken"
/// edge case.
class _BrokenStateRepo extends _FakeStateRepo {
  _BrokenStateRepo()
    : super(readError: const InterventionStateFailure.network());
}

void main() {
  // Pinned "now" - May 9, 2026, 10:30 AM.
  final now = DateTime(2026, 5, 9, 10, 30);
  DateTime nowFn() => now;

  group('CooldownGuard.check', () {
    test('no anchor → Proceed', () async {
      final repo = _FakeStateRepo();
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      expect(await guard.check(), isA<Proceed>());
      expect(repo.readCalls, 1);
    });

    test('TC-31: lastTriggeredAt 1h ago → Blocked(dailyLimit)', () async {
      final repo = _FakeStateRepo(
        anchors: InterventionAnchors(
          lastTriggeredAt: now.subtract(const Duration(hours: 1)),
        ),
      );
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      final decision = await guard.check();
      expect(decision, isA<Blocked>());
      expect((decision as Blocked).reason, CooldownBlock.dailyLimit);
    });

    test('TC-31 edge: lastTriggeredAt 23h59m ago → still dailyLimit', () async {
      final repo = _FakeStateRepo(
        anchors: InterventionAnchors(
          lastTriggeredAt: now.subtract(const Duration(hours: 23, minutes: 59)),
        ),
      );
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      final decision = await guard.check();
      expect((decision as Blocked).reason, CooldownBlock.dailyLimit);
    });

    test('TC-32: lastTriggeredAt 24h ago → Blocked(cooldown48h)', () async {
      final repo = _FakeStateRepo(
        anchors: InterventionAnchors(
          lastTriggeredAt: now.subtract(const Duration(hours: 24)),
        ),
      );
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      final decision = await guard.check();
      expect((decision as Blocked).reason, CooldownBlock.cooldown48h);
    });

    test('TC-32: lastTriggeredAt 40h ago → Blocked(cooldown48h)', () async {
      final repo = _FakeStateRepo(
        anchors: InterventionAnchors(
          lastTriggeredAt: now.subtract(const Duration(hours: 40)),
        ),
      );
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      final decision = await guard.check();
      expect((decision as Blocked).reason, CooldownBlock.cooldown48h);
    });

    test(
      'TC-32 edge: lastTriggeredAt 47h59m ago → still cooldown48h',
      () async {
        final repo = _FakeStateRepo(
          anchors: InterventionAnchors(
            lastTriggeredAt: now.subtract(
              const Duration(hours: 47, minutes: 59),
            ),
          ),
        );
        final guard = CooldownGuard(stateRepo: repo, now: nowFn);
        final decision = await guard.check();
        expect((decision as Blocked).reason, CooldownBlock.cooldown48h);
      },
    );

    test('lastTriggeredAt 48h ago → Proceed', () async {
      final repo = _FakeStateRepo(
        anchors: InterventionAnchors(
          lastTriggeredAt: now.subtract(const Duration(hours: 48)),
        ),
      );
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      expect(await guard.check(), isA<Proceed>());
    });

    test('lastTriggeredAt 72h ago → Proceed', () async {
      final repo = _FakeStateRepo(
        anchors: InterventionAnchors(
          lastTriggeredAt: now.subtract(const Duration(hours: 72)),
        ),
      );
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      expect(await guard.check(), isA<Proceed>());
    });

    test(
      'clock skew (anchor in the future) → Blocked(cooldown48h) - fail-closed',
      () async {
        final repo = _FakeStateRepo(
          anchors: InterventionAnchors(
            lastTriggeredAt: now.add(const Duration(minutes: 5)),
          ),
        );
        final guard = CooldownGuard(stateRepo: repo, now: nowFn);
        final decision = await guard.check();
        expect((decision as Blocked).reason, CooldownBlock.cooldown48h);
      },
    );

    test('anchor read failure → fail-closed Blocked(cooldown48h)', () async {
      final guard = CooldownGuard(stateRepo: _BrokenStateRepo(), now: nowFn);
      final decision = await guard.check();
      expect((decision as Blocked).reason, CooldownBlock.cooldown48h);
    });
  });

  group('CooldownGuard.checkOrError', () {
    test('happy path → decision, no failure', () async {
      final repo = _FakeStateRepo();
      final guard = CooldownGuard(stateRepo: repo, now: nowFn);
      final r = await guard.checkOrError();
      expect(r.decision, isA<Proceed>());
      expect(r.failure, isNull);
    });

    test(
      'anchor read failure → InterventionFailure.anchorReadFailed',
      () async {
        final guard = CooldownGuard(stateRepo: _BrokenStateRepo(), now: nowFn);
        final r = await guard.checkOrError();
        expect(r.decision, isNull);
        expect(r.failure, isA<InterventionFailure>());
      },
    );
  });
}
