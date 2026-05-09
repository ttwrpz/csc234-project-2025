import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/feature_flags.dart';
import 'package:moodbloom/app/providers.dart';
import 'package:moodbloom/features/garden/data/providers.dart';
import 'package:moodbloom/features/garden/domain/cheer_up_events_repository.dart';
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';
import 'package:moodbloom/features/garden/presentation/controllers/cheer_up_controller.dart';

/// Recording fake of [InterventionStateRepository]. Tracks every call so
/// the controller's idempotency, ordering, and write semantics can be
/// asserted directly without a real Firestore.
class _FakeRepo implements InterventionStateRepository {
  int writeLastCalls = 0;
  int writeFirstIfNullCalls = 0;
  int clearCalls = 0;
  int readCalls = 0;

  Result<void, InterventionStateFailure> nextWriteLast = const Ok(null);
  Result<void, InterventionStateFailure> nextWriteFirstIfNull = const Ok(null);

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async {
    readCalls += 1;
    return const Ok(InterventionAnchors());
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async {
    writeLastCalls += 1;
    return nextWriteLast;
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  ) async {
    writeFirstIfNullCalls += 1;
    return nextWriteFirstIfNull;
  }

  @override
  Future<Result<void, InterventionStateFailure>> clearFirstTriggeredAt() async {
    clearCalls += 1;
    return const Ok(null);
  }
}

/// Recording fake of [CheerUpEventsRepository]. Captures the (reason,
/// dayUtc-via-now) pair for every successful create attempt so the
/// 5.5b dispatch can be asserted alongside the anchor writes.
class _FakeEventsRepo implements CheerUpEventsRepository {
  final List<({String reason, DateTime now})> calls =
      <({String reason, DateTime now})>[];

  Result<void, CheerUpEventsFailure> nextResult = const Ok(null);

  @override
  Future<Result<void, CheerUpEventsFailure>> createEvent({
    required String reason,
    required DateTime now,
  }) async {
    calls.add((reason: reason, now: now));
    return nextResult;
  }
}

void main() {
  group('CheerUpController', () {
    late _FakeRepo repo;
    late _FakeEventsRepo eventsRepo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeRepo();
      eventsRepo = _FakeEventsRepo();
      container = ProviderContainer(
        overrides: [
          interventionStateRepositoryProvider.overrideWith((_) async => repo),
          cheerUpEventsRepositoryProvider.overrideWithValue(eventsRepo),
          // Existing tests assert dispatch behaviour, so flip the gate
          // ON for them. The dedicated "gate-off" group below overrides
          // this back to false.
          featureFlagsProvider.overrideWithValue(
            FeatureFlags.defaults().copyWith(interventionDispatchEnabled: true),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('build() returns the empty initial state', () {
      final state = container.read(cheerUpControllerProvider);
      expect(state.bannerDismissed, isFalse);
      expect(state.onShownDispatched, isFalse);
    });

    test(
      'onShown() writes both anchors AND the event doc on first call',
      () async {
        await container
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: '5_of_7_negative');

        expect(repo.writeLastCalls, 1);
        expect(repo.writeFirstIfNullCalls, 1);
        // 5.5b — event-doc create runs alongside the anchor writes.
        expect(eventsRepo.calls, hasLength(1));
        expect(eventsRepo.calls.single.reason, '5_of_7_negative');
        expect(
          container.read(cheerUpControllerProvider).onShownDispatched,
          isTrue,
        );
      },
    );

    test('onShown() is idempotent — second call is a no-op', () async {
      await container
          .read(cheerUpControllerProvider.notifier)
          .onShown(reason: '5_of_7_negative');
      await container
          .read(cheerUpControllerProvider.notifier)
          .onShown(reason: '5_of_7_negative');

      expect(repo.writeLastCalls, 1);
      expect(repo.writeFirstIfNullCalls, 1);
      // Event-doc create also collapses to a single attempt — the
      // CF would also dedupe via already-exists, but we'd rather not
      // round-trip at all on the second call.
      expect(eventsRepo.calls, hasLength(1));
    });

    test(
      'onShown() still attempts event-doc create when anchor writes Err',
      () async {
        // Cloud unreachable for anchors but reachable for the event doc:
        // unusual in practice but the contract is "independent paths".
        repo.nextWriteLast = const Err(InterventionStateFailure.network());
        repo.nextWriteFirstIfNull = const Err(
          InterventionStateFailure.network(),
        );

        await container
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: '3_consecutive_high_intensity');

        expect(repo.writeLastCalls, 1);
        expect(repo.writeFirstIfNullCalls, 1);
        // Event-doc create still attempted — independence is the
        // contract. CF only needs the event doc.
        expect(eventsRepo.calls, hasLength(1));
        expect(eventsRepo.calls.single.reason, '3_consecutive_high_intensity');
      },
    );

    test('onShown() reason flows through to the event doc unchanged', () async {
      await container
          .read(cheerUpControllerProvider.notifier)
          .onShown(reason: '3_consecutive_high_intensity');

      expect(eventsRepo.calls.single.reason, '3_consecutive_high_intensity');
    });

    test(
      'onShown() still flips onShownDispatched even when writes Err — no double-fire on retry attempt',
      () async {
        repo.nextWriteLast = const Err(InterventionStateFailure.network());
        repo.nextWriteFirstIfNull = const Err(
          InterventionStateFailure.network(),
        );

        await container
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: '3_consecutive_high_intensity');

        expect(
          container.read(cheerUpControllerProvider).onShownDispatched,
          isTrue,
        );
        // Subsequent re-render does NOT retry — the impl already mirrored
        // locally, so the cooldown gate is honoured offline. A future
        // read() will reconcile from cloud once it succeeds.
        await container
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: '3_consecutive_high_intensity');
        expect(repo.writeLastCalls, 1);
        expect(repo.writeFirstIfNullCalls, 1);
      },
    );

    test('onDismissed() flips bannerDismissed without touching the repo', () {
      container.read(cheerUpControllerProvider.notifier).onDismissed();

      expect(container.read(cheerUpControllerProvider).bannerDismissed, isTrue);
      expect(repo.writeLastCalls, 0);
      expect(repo.writeFirstIfNullCalls, 0);
      expect(eventsRepo.calls, isEmpty);
      expect(
        container.read(cheerUpControllerProvider).onShownDispatched,
        isFalse,
      );
    });
  });

  group('CheerUpController — interventionDispatchEnabled gate (ADR-0011)', () {
    late _FakeRepo repo;
    late _FakeEventsRepo eventsRepo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeRepo();
      eventsRepo = _FakeEventsRepo();
      container = ProviderContainer(
        overrides: [
          interventionStateRepositoryProvider.overrideWith((_) async => repo),
          cheerUpEventsRepositoryProvider.overrideWithValue(eventsRepo),
          // Default v1.0 state: gate off.
          featureFlagsProvider.overrideWithValue(FeatureFlags.defaults()),
        ],
      );
      addTearDown(container.dispose);
    });

    test(
      'onShown() with the gate disabled writes nothing — no anchor, no event doc',
      () async {
        await container
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: '5_of_7_negative');

        expect(repo.writeLastCalls, 0);
        expect(repo.writeFirstIfNullCalls, 0);
        expect(eventsRepo.calls, isEmpty);
      },
    );

    test(
      'onShown() with the gate disabled still flips onShownDispatched',
      () async {
        await container
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: '5_of_7_negative');

        // Hygiene flip prevents the skip-log from firing twice in the
        // same lifecycle. The flag itself is the durable gate.
        expect(
          container.read(cheerUpControllerProvider).onShownDispatched,
          isTrue,
        );
      },
    );

    test('gate is the only difference: default-off matches v1.0 contract', () {
      // Regression guard: if the default ever flips to true, this
      // test fails and the v1.0-engine-on-dispatcher-off invariant
      // breaks. ADR-0011 §4.
      expect(FeatureFlags.defaults().interventionDispatchEnabled, isFalse);
    });
  });
}
