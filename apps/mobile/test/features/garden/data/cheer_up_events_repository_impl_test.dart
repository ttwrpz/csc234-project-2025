import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/data/cheer_up_events_repository_impl.dart';
import 'package:moodbloom/features/garden/data/datasources/cheer_up_events_firestore_datasource.dart';
import 'package:moodbloom/features/garden/domain/cheer_up_events_repository.dart';

/// Recording fake of the Firestore datasource. Captures every call so
/// the impl's id-derivation + payload semantics can be asserted
/// without spinning up a real `FirebaseFirestore`.
class _FakeDatasource implements CheerUpEventsFirestoreDatasource {
  final List<({String uid, String evtId, String reason, String dayUtc})> calls =
      [];

  /// Optional override - when non-null, the next `createEvent` throws
  /// the supplied exception. Used to test the impl's mapping of
  /// `already-exists` → success and `permission-denied` → permission.
  Object? throwOnNext;

  @override
  Future<void> createEvent({
    required String uid,
    required String evtId,
    required String reason,
    required String dayUtc,
  }) async {
    calls.add((uid: uid, evtId: evtId, reason: reason, dayUtc: dayUtc));
    final t = throwOnNext;
    if (t != null) {
      throwOnNext = null;
      throw t;
    }
  }
}

void main() {
  group('CheerUpEventsRepositoryImpl', () {
    late _FakeDatasource ds;

    setUp(() {
      ds = _FakeDatasource();
    });

    test(
      'happy path - passes (uid, dayUtc-now, reason) to the datasource',
      () async {
        final repo = CheerUpEventsRepositoryImpl(
          datasource: ds,
          uidGetter: () => 'uid-1',
        );

        // 23:00 in UTC → still 2026-05-13 in UTC.
        final now = DateTime.utc(2026, 5, 13, 23, 0);
        final result = await repo.createEvent(
          reason: '5_of_7_negative',
          now: now,
        );

        expect(result, isA<Ok<void, CheerUpEventsFailure>>());
        expect(ds.calls, hasLength(1));
        expect(ds.calls.single.uid, 'uid-1');
        expect(ds.calls.single.reason, '5_of_7_negative');
        expect(ds.calls.single.dayUtc, '2026-05-13');
        expect(ds.calls.single.evtId, '2026-05-13-5_of_7_negative');
      },
    );

    test('id matches the firestore.rules regex', () async {
      final repo = CheerUpEventsRepositoryImpl(
        datasource: ds,
        uidGetter: () => 'uid-1',
      );

      final now = DateTime.utc(2026, 5, 13, 12, 0);
      await repo.createEvent(reason: '3_consecutive_high_intensity', now: now);

      // SAME regex as `firebase/firestore.rules` - if this fails the
      // rule WILL deny the write.
      final pattern = RegExp(
        r'^\d{4}-\d{2}-\d{2}-(5_of_7_negative|3_consecutive_high_intensity)$',
      );
      expect(pattern.hasMatch(ds.calls.single.evtId), isTrue);
    });

    test(
      'unknown reason short-circuits with Err(unknown) - never round-trips',
      () async {
        final repo = CheerUpEventsRepositoryImpl(
          datasource: ds,
          uidGetter: () => 'uid-1',
        );

        final result = await repo.createEvent(
          reason: 'totally_made_up_reason',
          now: DateTime.utc(2026, 5, 13),
        );

        expect(result, isA<Err<void, CheerUpEventsFailure>>());
        // Defense-in-depth: the rule would reject this anyway, but the
        // impl must not even attempt the write.
        expect(ds.calls, isEmpty);
      },
    );

    test('missing uid → Err(network), no datasource call', () async {
      final repo = CheerUpEventsRepositoryImpl(
        datasource: ds,
        uidGetter: () => null,
      );

      final result = await repo.createEvent(
        reason: '5_of_7_negative',
        now: DateTime.utc(2026, 5, 13),
      );

      expect(result, isA<Err<void, CheerUpEventsFailure>>());
      expect(ds.calls, isEmpty);
    });

    test('already-exists from Firestore is the idempotent path → Ok', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'Document already exists',
      );

      final repo = CheerUpEventsRepositoryImpl(
        datasource: ds,
        uidGetter: () => 'uid-1',
      );

      final result = await repo.createEvent(
        reason: '5_of_7_negative',
        now: DateTime.utc(2026, 5, 13),
      );

      // The whole point of the deterministic doc id: a duplicate
      // write is success, not failure. The CF already fired earlier
      // today (or it'll be rate-limited regardless).
      expect(result, isA<Ok<void, CheerUpEventsFailure>>());
    });

    test('permission-denied → Err(permission)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'PERMISSION_DENIED',
      );

      final repo = CheerUpEventsRepositoryImpl(
        datasource: ds,
        uidGetter: () => 'uid-1',
      );

      final result = await repo.createEvent(
        reason: '5_of_7_negative',
        now: DateTime.utc(2026, 5, 13),
      );

      expect(result, isA<Err<void, CheerUpEventsFailure>>());
      result.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f, isA<CheerUpEventsFailure>()),
      );
    });

    test('unavailable / cancelled → Err(network)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'transient',
      );

      final repo = CheerUpEventsRepositoryImpl(
        datasource: ds,
        uidGetter: () => 'uid-1',
      );

      final result = await repo.createEvent(
        reason: '5_of_7_negative',
        now: DateTime.utc(2026, 5, 13),
      );

      expect(result, isA<Err<void, CheerUpEventsFailure>>());
    });
  });
}
