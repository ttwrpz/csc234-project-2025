import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/local/mood_database.dart';
import 'package:moodbloom/features/mood/data/local/sync_queue_dao.dart';

void main() {
  late MoodDatabase db;
  late SyncQueueDao queue;

  SyncQueueCompanion row({
    required String entryId,
    required String operation,
    String payload = '{}',
    int retryAfter = 0,
    int? createdAt,
  }) {
    return SyncQueueCompanion.insert(
      entryId: entryId,
      operation: operation,
      payload: payload,
      retryAfter: Value(retryAfter),
      createdAt: createdAt ?? 1000,
    );
  }

  setUp(() {
    db = MoodDatabase.forTesting(NativeDatabase.memory());
    queue = db.syncQueueDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('Coalescing rules (ADR-0004)', () {
    test('create then update for same entry_id → ONE row, latest payload',
        () async {
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.create, payload: 'first'),
      );
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.update, payload: 'second'),
      );
      expect(await queue.length(), 1);
      final pending = await queue.peekNextDue(now: 9999);
      expect(pending!.entryId, 'm1');
      expect(pending.payload, 'second');
      expect(pending.operation, SyncOperation.update);
    });

    test('update then update for same entry_id → ONE row, latest payload',
        () async {
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.update, payload: 'v1'),
      );
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.update, payload: 'v2'),
      );
      expect(await queue.length(), 1);
      final pending = await queue.peekNextDue(now: 9999);
      expect(pending!.payload, 'v2');
    });

    test('create then delete for same entry_id → ONE row, op=delete',
        () async {
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.create),
      );
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.delete),
      );
      expect(await queue.length(), 1);
      final pending = await queue.peekNextDue(now: 9999);
      expect(pending!.operation, SyncOperation.delete);
    });

    test('update then delete for same entry_id → ONE row, op=delete',
        () async {
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.update),
      );
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.delete),
      );
      expect(await queue.length(), 1);
      final pending = await queue.peekNextDue(now: 9999);
      expect(pending!.operation, SyncOperation.delete);
    });

    test('different entry_ids do NOT coalesce', () async {
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.create),
      );
      await queue.enqueue(
        row(entryId: 'm2', operation: SyncOperation.create),
      );
      expect(await queue.length(), 2);
    });
  });

  group('peekNextDue ordering and retry filtering', () {
    test('skips rows with retry_after > now', () async {
      await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.create, retryAfter: 5000),
      );
      // No row is due at now=1000.
      expect(await queue.peekNextDue(now: 1000), isNull);
      // After 6000, the row is due.
      final due = await queue.peekNextDue(now: 6000);
      expect(due, isNotNull);
      expect(due!.entryId, 'm1');
    });

    test('returns lowest-id row when multiple are due (FIFO)', () async {
      // Pre-condition: distinct entry_ids so coalescing doesn't merge them.
      await queue.enqueue(
        row(entryId: 'a', operation: SyncOperation.create),
      );
      await queue.enqueue(
        row(entryId: 'b', operation: SyncOperation.create),
      );
      final due = await queue.peekNextDue(now: 9999);
      expect(due!.entryId, 'a'); // first inserted = smallest id
    });
  });

  group('markFailed and dequeue', () {
    test('markFailed bumps attempt_count and sets retry_after', () async {
      final id = await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.create),
      );
      await queue.markFailed(
        id,
        retryAfter: 12345,
        code: 'unavailable',
        message: 'network',
      );
      final row1 = await queue.peekNextDue(now: 99999);
      expect(row1!.attemptCount, 1);
      expect(row1.retryAfter, 12345);
      expect(row1.lastErrorCode, 'unavailable');
      expect(row1.lastError, 'network');

      // Subsequent failure increments.
      await queue.markFailed(id, retryAfter: 67890);
      final row2 = await queue.peekNextDue(now: 99999);
      expect(row2!.attemptCount, 2);
      expect(row2.retryAfter, 67890);
    });

    test('dequeue removes the row; length reflects', () async {
      final id = await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.create),
      );
      expect(await queue.length(), 1);
      await queue.dequeue(id);
      expect(await queue.length(), 0);
    });
  });

  group('watchPendingCount stream', () {
    test('emits 0 for empty queue, increments on enqueue, decrements on dequeue',
        () async {
      final stream = queue.watchPendingCount();
      final emissions = <int>[];
      final sub = stream.listen(emissions.add);

      // Wait for the initial emission.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final id = await queue.enqueue(
        row(entryId: 'm1', operation: SyncOperation.create),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await queue.dequeue(id);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      // Initial 0, then 1 after enqueue, then 0 after dequeue.
      expect(emissions, contains(0));
      expect(emissions, contains(1));
      expect(emissions.last, 0);
    });
  });
}
