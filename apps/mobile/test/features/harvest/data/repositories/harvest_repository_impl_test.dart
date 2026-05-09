import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/harvest/data/datasources/weekly_gardens_firestore_datasource.dart';
import 'package:moodbloom/features/harvest/data/repositories/harvest_repository_impl.dart';
import 'package:moodbloom/features/harvest/domain/entities/weekly_garden.dart';
import 'package:moodbloom/features/harvest/domain/harvest_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// Recording fake of the Firestore datasource. Mirrors the
/// `_FakeDatasource` pattern from `pattern_repository_impl_test.dart`
/// because `fake_cloud_firestore` is not in pubspec dev_dependencies.
class _FakeDatasource implements WeeklyGardensFirestoreDatasource {
  final List<({String userId, WeeklyGarden garden})> creates = [];

  Object? throwOnNextCreate;
  Object? throwOnNextRead;
  WeeklyGarden? readResult;

  @override
  Future<void> createWeeklyGarden({
    required String userId,
    required WeeklyGarden garden,
  }) async {
    final t = throwOnNextCreate;
    if (t != null) {
      throwOnNextCreate = null;
      throw t;
    }
    creates.add((userId: userId, garden: garden));
  }

  @override
  Stream<List<WeeklyGarden>> watchHistory({required String userId}) {
    return Stream.value(creates.map((c) => c.garden).toList());
  }

  @override
  Future<WeeklyGarden?> getByWeekId({
    required String userId,
    required String weekId,
  }) async {
    final t = throwOnNextRead;
    if (t != null) {
      throwOnNextRead = null;
      throw t;
    }
    return readResult;
  }
}

final _summary = WeeklySummary(
  averageMoodScore: 0.2,
  moodCounts: const {MoodType.happy: 1},
  endingPlantTier: PlantTier.thriving,
  totalEntryCount: 1,
  triggeredTierCount: 0,
);

final _garden = WeeklyGarden(
  weekId: '2026-W19',
  weekStart: DateTime.utc(2026, 5, 4),
  weekEnd: DateTime.utc(2026, 5, 11),
  entries: const [],
  healthHistory: const [0.1],
  summary: _summary,
  archivedAt: DateTime.utc(2026, 5, 11),
);

void main() {
  group('HarvestRepositoryImpl.archive', () {
    late _FakeDatasource ds;
    late HarvestRepositoryImpl repo;

    setUp(() {
      ds = _FakeDatasource();
      repo = HarvestRepositoryImpl(datasource: ds);
    });

    test(
      'happy path → Ok, datasource called once with same userId/garden',
      () async {
        final outcome = await repo.archive(userId: 'uid-1', garden: _garden);
        expect(outcome, isA<Ok<WeeklyGarden, HarvestFailure>>());
        expect(ds.creates, hasLength(1));
        expect(ds.creates.single.userId, 'uid-1');
        expect(ds.creates.single.garden.weekId, '2026-W19');
      },
    );

    test('empty userId → Err(network), no datasource call', () async {
      final outcome = await repo.archive(userId: '', garden: _garden);
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
      expect(ds.creates, isEmpty);
    });

    test('Firestore already-exists → Err(alreadyArchived)', () async {
      ds.throwOnNextCreate = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'doc exists',
      );
      final outcome = await repo.archive(userId: 'uid-1', garden: _garden);
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) =>
            expect(f.runtimeType.toString(), contains('AlreadyArchived')),
      );
    });

    test('Firestore permission-denied → Err(permissionDenied)', () async {
      ds.throwOnNextCreate = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'PERMISSION_DENIED',
      );
      final outcome = await repo.archive(userId: 'uid-1', garden: _garden);
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Permission')),
      );
    });

    test('Firestore unavailable / deadline-exceeded → Err(network)', () async {
      ds.throwOnNextCreate = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'transient',
      );
      final outcome = await repo.archive(userId: 'uid-1', garden: _garden);
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
    });

    test('arbitrary FirebaseException → Err(unknown with code)', () async {
      ds.throwOnNextCreate = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'something-else',
      );
      final outcome = await repo.archive(userId: 'uid-1', garden: _garden);
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Unknown')),
      );
    });

    test('non-FirebaseException catch-all → Err(unknown)', () async {
      ds.throwOnNextCreate = StateError('boom');
      final outcome = await repo.archive(userId: 'uid-1', garden: _garden);
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
    });
  });

  group('HarvestRepositoryImpl.getByWeekId', () {
    test('forwards (userId, weekId) and unwraps Ok on hit', () async {
      final ds = _FakeDatasource()..readResult = _garden;
      final repo = HarvestRepositoryImpl(datasource: ds);
      final outcome = await repo.getByWeekId(
        userId: 'uid-1',
        weekId: '2026-W19',
      );
      expect(outcome, isA<Ok<WeeklyGarden, HarvestFailure>>());
    });

    test('returns Err(unknown) when the doc does not exist', () async {
      final ds = _FakeDatasource(); // readResult left null
      final repo = HarvestRepositoryImpl(datasource: ds);
      final outcome = await repo.getByWeekId(
        userId: 'uid-1',
        weekId: '2026-W30',
      );
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
    });
  });

  group('HarvestRepositoryImpl.watchHistory', () {
    test('returns the datasource stream verbatim', () {
      final ds = _FakeDatasource();
      final repo = HarvestRepositoryImpl(datasource: ds);
      expect(
        repo.watchHistory(userId: 'uid-1'),
        isA<Stream<List<WeeklyGarden>>>(),
      );
    });

    test('empty userId → empty stream (no Firestore round-trip)', () async {
      final ds = _FakeDatasource();
      final repo = HarvestRepositoryImpl(datasource: ds);
      final emitted = await repo
          .watchHistory(userId: '')
          .toList(); // empty stream completes immediately.
      expect(emitted, isEmpty);
    });
  });
}
