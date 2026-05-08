import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/data/datasources/intervention_state_firestore_datasource.dart';
import 'package:moodbloom/features/garden/data/intervention_state_repository_impl.dart';
import 'package:moodbloom/features/garden/data/intervention_state_storage.dart';
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// In-memory fake of [InterventionStateFirestoreDatasource]. Records every
/// call. Configurable to throw on the next invocation of any method.
///
/// We deliberately do NOT use `mockito` here — the call surface is small
/// (4 methods, 4 call counters) and a hand-rolled fake stays readable.
/// Mirrors the existing `_FakeMoodFirestoreDatasource` pattern.
class _FakeDatasource implements InterventionStateFirestoreDatasource {
  DateTime? lastTriggeredAt;
  DateTime? firstTriggeredAt;

  int readCalls = 0;
  int writeLastCalls = 0;
  int writeFirstIfNullCalls = 0;
  int clearFirstCalls = 0;

  Object? readThrows;
  Object? writeLastThrows;
  Object? writeFirstIfNullThrows;
  Object? clearFirstThrows;

  @override
  Future<({DateTime? lastTriggeredAt, DateTime? firstTriggeredAt})> read(
    String uid,
  ) async {
    readCalls += 1;
    if (readThrows != null) {
      final e = readThrows;
      readThrows = null;
      throw e!;
    }
    return (
      lastTriggeredAt: lastTriggeredAt,
      firstTriggeredAt: firstTriggeredAt,
    );
  }

  @override
  Future<void> writeLastTriggeredAt(String uid, DateTime now) async {
    writeLastCalls += 1;
    if (writeLastThrows != null) {
      final e = writeLastThrows;
      writeLastThrows = null;
      throw e!;
    }
    lastTriggeredAt = now;
  }

  @override
  Future<DateTime?> writeFirstTriggeredAtIfNull(
    String uid,
    DateTime now,
  ) async {
    writeFirstIfNullCalls += 1;
    if (writeFirstIfNullThrows != null) {
      final e = writeFirstIfNullThrows;
      writeFirstIfNullThrows = null;
      throw e!;
    }
    if (firstTriggeredAt == null) {
      firstTriggeredAt = now;
      return now;
    }
    return firstTriggeredAt;
  }

  @override
  Future<void> clearFirstTriggeredAt(String uid) async {
    clearFirstCalls += 1;
    if (clearFirstThrows != null) {
      final e = clearFirstThrows;
      clearFirstThrows = null;
      throw e!;
    }
    firstTriggeredAt = null;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeDatasource datasource;
  late InterventionStateStorage mirror;
  late InterventionStateRepositoryImpl repo;

  Future<void> setupRepo({String? uid = 'u-1'}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    mirror = InterventionStateStorage(prefs);
    datasource = _FakeDatasource();
    repo = InterventionStateRepositoryImpl(
      datasource: datasource,
      mirror: mirror,
      uidGetter: () => uid,
    );
  }

  group('InterventionStateRepositoryImpl.read', () {
    test(
      'Firestore success → returns cloud value AND mirrors locally',
      () async {
        await setupRepo();
        final t = DateTime(2026, 5, 1, 10);
        datasource.lastTriggeredAt = t;

        final result = await repo.read();

        expect(
          result,
          isA<Ok<InterventionAnchors, InterventionStateFailure>>(),
        );
        final anchors =
            (result as Ok<InterventionAnchors, InterventionStateFailure>).value;
        expect(anchors.lastTriggeredAt!.isAtSameMomentAs(t), isTrue);
        // Mirror was warmed.
        expect(mirror.readLastTriggeredAt()!.isAtSameMomentAs(t), isTrue);
      },
    );

    test(
      'Firestore failure → falls back to mirror, returns Ok with mirror values',
      () async {
        await setupRepo();
        final mirrored = DateTime(2026, 4, 30, 8);
        await mirror.writeLastTriggeredAt(mirrored);
        datasource.readThrows = FirebaseException(
          plugin: 'firestore',
          code: 'unavailable',
        );

        final result = await repo.read();

        expect(
          result,
          isA<Ok<InterventionAnchors, InterventionStateFailure>>(),
        );
        final anchors =
            (result as Ok<InterventionAnchors, InterventionStateFailure>).value;
        expect(anchors.lastTriggeredAt!.isAtSameMomentAs(mirrored), isTrue);
      },
    );

    test(
      'signed-out (uid: null) → returns mirror without hitting cloud',
      () async {
        await setupRepo(uid: null);
        final mirrored = DateTime(2026, 4, 30);
        await mirror.writeFirstTriggeredAt(mirrored);

        final result = await repo.read();

        expect(datasource.readCalls, 0);
        final anchors =
            (result as Ok<InterventionAnchors, InterventionStateFailure>).value;
        expect(anchors.firstTriggeredAt!.isAtSameMomentAs(mirrored), isTrue);
      },
    );

    test(
      'cloud says firstTriggeredAt=null → mirror is also cleared (post-48h reconcile)',
      () async {
        await setupRepo();
        await mirror.writeFirstTriggeredAt(DateTime(2026, 4, 1));
        // Cloud has no first anchor (a previous lifecycle clear).
        datasource.firstTriggeredAt = null;
        datasource.lastTriggeredAt = DateTime(2026, 5, 1);

        await repo.read();

        expect(mirror.readFirstTriggeredAt(), isNull);
      },
    );
  });

  group('InterventionStateRepositoryImpl.writeLastTriggeredAt', () {
    test('Firestore success → mirror updated, returns Ok(null)', () async {
      await setupRepo();
      final t = DateTime(2026, 5, 1, 12);

      final result = await repo.writeLastTriggeredAt(t);

      expect(result, isA<Ok<void, InterventionStateFailure>>());
      expect(datasource.writeLastCalls, 1);
      expect(datasource.lastTriggeredAt!.isAtSameMomentAs(t), isTrue);
      expect(mirror.readLastTriggeredAt()!.isAtSameMomentAs(t), isTrue);
    });

    test(
      'Firestore failure → mirror STILL updated, returns Err(network) for unavailable',
      () async {
        await setupRepo();
        datasource.writeLastThrows = FirebaseException(
          plugin: 'firestore',
          code: 'unavailable',
        );
        final t = DateTime(2026, 5, 1, 12);

        final result = await repo.writeLastTriggeredAt(t);

        expect(result, isA<Err<void, InterventionStateFailure>>());
        expect(
          (result as Err<void, InterventionStateFailure>).failure,
          isA<InterventionStateFailure>(),
        );
        // Mirror updated even though cloud failed.
        expect(mirror.readLastTriggeredAt()!.isAtSameMomentAs(t), isTrue);
      },
    );

    test(
      'permission-denied maps to InterventionStateFailure.permission',
      () async {
        await setupRepo();
        datasource.writeLastThrows = FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
        );

        final result = await repo.writeLastTriggeredAt(DateTime(2026, 5, 1));

        final failure = (result as Err<void, InterventionStateFailure>).failure;
        expect(failure.message, equals('Permission denied.'));
      },
    );

    test('signed-out → mirror updated, Err(network)', () async {
      await setupRepo(uid: null);
      final t = DateTime(2026, 5, 1);

      final result = await repo.writeLastTriggeredAt(t);

      expect(datasource.writeLastCalls, 0);
      expect(result, isA<Err<void, InterventionStateFailure>>());
      expect(mirror.readLastTriggeredAt()!.isAtSameMomentAs(t), isTrue);
    });
  });

  group('InterventionStateRepositoryImpl.writeFirstTriggeredAtIfNull', () {
    test('cloud value is null → writes now, returns Ok', () async {
      await setupRepo();
      final t = DateTime(2026, 5, 1, 12);

      final result = await repo.writeFirstTriggeredAtIfNull(t);

      expect(result, isA<Ok<void, InterventionStateFailure>>());
      expect(datasource.firstTriggeredAt!.isAtSameMomentAs(t), isTrue);
      expect(mirror.readFirstTriggeredAt()!.isAtSameMomentAs(t), isTrue);
    });

    test(
      'cloud value already set → no overwrite, mirror reflects existing value',
      () async {
        await setupRepo();
        final existing = DateTime(2026, 4, 25);
        datasource.firstTriggeredAt = existing;

        final result = await repo.writeFirstTriggeredAtIfNull(
          DateTime(2026, 5, 1),
        );

        expect(result, isA<Ok<void, InterventionStateFailure>>());
        // Cloud preserved the original.
        expect(datasource.firstTriggeredAt!.isAtSameMomentAs(existing), isTrue);
        expect(
          mirror.readFirstTriggeredAt()!.isAtSameMomentAs(existing),
          isTrue,
        );
      },
    );

    test(
      'Firestore failure → mirror updated only if null, Err returned',
      () async {
        await setupRepo();
        datasource.writeFirstIfNullThrows = FirebaseException(
          plugin: 'firestore',
          code: 'unavailable',
        );
        final t = DateTime(2026, 5, 1);

        final result = await repo.writeFirstTriggeredAtIfNull(t);

        expect(result, isA<Err<void, InterventionStateFailure>>());
        expect(mirror.readFirstTriggeredAt()!.isAtSameMomentAs(t), isTrue);
      },
    );

    test(
      'Firestore failure with mirror already populated → mirror unchanged',
      () async {
        await setupRepo();
        final mirrored = DateTime(2026, 4, 25);
        await mirror.writeFirstTriggeredAt(mirrored);
        datasource.writeFirstIfNullThrows = FirebaseException(
          plugin: 'firestore',
          code: 'unavailable',
        );

        await repo.writeFirstTriggeredAtIfNull(DateTime(2026, 5, 1));

        // Original mirror value preserved (idempotent local-side too).
        expect(
          mirror.readFirstTriggeredAt()!.isAtSameMomentAs(mirrored),
          isTrue,
        );
      },
    );
  });

  group('InterventionStateRepositoryImpl.clearFirstTriggeredAt', () {
    test('Firestore success → cloud null, mirror cleared, Ok', () async {
      await setupRepo();
      datasource.firstTriggeredAt = DateTime(2026, 4, 25);
      await mirror.writeFirstTriggeredAt(DateTime(2026, 4, 25));

      final result = await repo.clearFirstTriggeredAt();

      expect(result, isA<Ok<void, InterventionStateFailure>>());
      expect(datasource.firstTriggeredAt, isNull);
      expect(mirror.readFirstTriggeredAt(), isNull);
    });

    test(
      'Firestore failure → mirror still cleared, Err(network) returned',
      () async {
        await setupRepo();
        datasource.firstTriggeredAt = DateTime(2026, 4, 25);
        await mirror.writeFirstTriggeredAt(DateTime(2026, 4, 25));
        datasource.clearFirstThrows = FirebaseException(
          plugin: 'firestore',
          code: 'unavailable',
        );

        final result = await repo.clearFirstTriggeredAt();

        expect(result, isA<Err<void, InterventionStateFailure>>());
        expect(mirror.readFirstTriggeredAt(), isNull);
      },
    );
  });
}
