import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/data/providers.dart';
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

void main() {
  group('CheerUpController', () {
    late _FakeRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeRepo();
      container = ProviderContainer(
        overrides: [
          interventionStateRepositoryProvider.overrideWith((_) async => repo),
        ],
      );
      addTearDown(container.dispose);
    });

    test('build() returns the empty initial state', () {
      final state = container.read(cheerUpControllerProvider);
      expect(state.bannerDismissed, isFalse);
      expect(state.onShownDispatched, isFalse);
    });

    test('onShown() writes both anchors on first call', () async {
      await container
          .read(cheerUpControllerProvider.notifier)
          .onShown(reason: '5_of_7_negative');

      expect(repo.writeLastCalls, 1);
      expect(repo.writeFirstIfNullCalls, 1);
      expect(
        container.read(cheerUpControllerProvider).onShownDispatched,
        isTrue,
      );
    });

    test('onShown() is idempotent — second call is a no-op', () async {
      await container
          .read(cheerUpControllerProvider.notifier)
          .onShown(reason: '5_of_7_negative');
      await container
          .read(cheerUpControllerProvider.notifier)
          .onShown(reason: '5_of_7_negative');

      expect(repo.writeLastCalls, 1);
      expect(repo.writeFirstIfNullCalls, 1);
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
      expect(
        container.read(cheerUpControllerProvider).onShownDispatched,
        isFalse,
      );
    });
  });
}
