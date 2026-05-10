import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/data/datasources/patterns_firestore_datasource.dart';
import 'package:moodbloom/features/pattern_engine/data/repositories/pattern_repository_impl.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/pattern_result.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';
import 'package:moodbloom/features/pattern_engine/domain/pattern_failure.dart';

/// Recording fake of the Firestore datasource. Captures every call so the
/// impl's user-id + path semantics can be asserted without spinning up a
/// real `FirebaseFirestore`. Mirrors `_FakeDatasource` in
/// `cheer_up_events_repository_impl_test.dart`.
class _FakeDatasource implements PatternsFirestoreDatasource {
  final List<({String userId, PatternResult result})> calls = [];
  final List<({String userId, String dateId})> watches = [];

  /// When non-null, the next `upsertPatternResult` throws this object.
  Object? throwOnNext;

  @override
  Future<void> upsertPatternResult({
    required String userId,
    required PatternResult result,
  }) async {
    calls.add((userId: userId, result: result));
    final t = throwOnNext;
    if (t != null) {
      throwOnNext = null;
      throw t;
    }
  }

  @override
  Stream<PatternResult?> watchPatternResult({
    required String userId,
    required String dateId,
  }) {
    watches.add((userId: userId, dateId: dateId));
    return const Stream<PatternResult?>.empty();
  }
}

/// Reference [PatternResult] used across the happy-path tests.
const _result = PatternResult(
  dateId: '2026-05-09',
  mannKendallZ: -2.3,
  slidingNegCount: 5,
  consecutiveHighIntensity: 1,
  zScoreToday: null,
  cusumC: 0.5,
  triggeredTier: Tier.two,
);

void main() {
  group('PatternRepositoryImpl.save', () {
    late _FakeDatasource ds;
    late PatternRepositoryImpl repo;

    setUp(() {
      ds = _FakeDatasource();
      repo = PatternRepositoryImpl(datasource: ds);
    });

    test(
      'happy path → Ok, datasource called once with same userId/result',
      () async {
        final outcome = await repo.save(userId: 'uid-1', result: _result);
        expect(outcome, isA<Ok<void, PatternFailure>>());
        expect(ds.calls, hasLength(1));
        expect(ds.calls.single.userId, 'uid-1');
        expect(ds.calls.single.result, _result);
      },
    );

    test('empty userId → Err(network), no datasource call', () async {
      final outcome = await repo.save(userId: '', result: _result);
      expect(outcome, isA<Err<void, PatternFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f, isA<PatternFailure>()),
      );
      expect(ds.calls, isEmpty);
    });

    test('Firestore permission-denied → Err(permissionDenied)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'PERMISSION_DENIED',
      );
      final outcome = await repo.save(userId: 'uid-1', result: _result);
      expect(outcome, isA<Err<void, PatternFailure>>());
      // The runtimeType is the post-save logger's signal — confirm we get
      // the `_PermissionDenied` private subtype, distinct from network /
      // unknown for downstream debug visibility.
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) {
          expect(f.runtimeType.toString(), contains('Permission'));
        },
      );
    });

    test('Firestore unavailable → Err(network)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'transient',
      );
      final outcome = await repo.save(userId: 'uid-1', result: _result);
      expect(outcome, isA<Err<void, PatternFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
    });

    test('Firestore deadline-exceeded / cancelled → Err(network)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
        message: 'slow',
      );
      final outcome = await repo.save(userId: 'uid-1', result: _result);
      expect(outcome, isA<Err<void, PatternFailure>>());
    });

    test('arbitrary FirebaseException code → Err(unknown)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'something-totally-new',
        message: 'huh',
      );
      final outcome = await repo.save(userId: 'uid-1', result: _result);
      expect(outcome, isA<Err<void, PatternFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Unknown')),
      );
    });

    test('non-FirebaseException catch-all → Err(unknown)', () async {
      ds.throwOnNext = StateError('arbitrary failure');
      final outcome = await repo.save(userId: 'uid-1', result: _result);
      expect(outcome, isA<Err<void, PatternFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Unknown')),
      );
    });
  });

  group('PatternRepositoryImpl.watch', () {
    test('forwards (userId, dateId) to the datasource', () {
      final ds = _FakeDatasource();
      final repo = PatternRepositoryImpl(datasource: ds);
      final stream = repo.watch(userId: 'uid-1', dateId: '2026-05-09');
      // Consume the stream so the datasource's call is registered.
      // (The fake returns `Stream.empty()` so it terminates immediately.)
      expect(stream, isA<Stream<PatternResult?>>());
      expect(ds.watches, hasLength(1));
      expect(ds.watches.single.userId, 'uid-1');
      expect(ds.watches.single.dateId, '2026-05-09');
    });
  });
}
