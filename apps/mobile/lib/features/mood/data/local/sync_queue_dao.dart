import 'package:drift/drift.dart';

import 'mood_database.dart';
import 'sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

/// Operation vocabulary for the `operation` column. Plain constants for the
/// same reason as [MoodSyncState] in mood_dao.dart.
class SyncOperation {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
}

/// DAO for `sync_queue`. The PR-1 contract: enqueue with idempotent coalescing
/// per ADR-0004, plus the FIFO peek/dequeue plumbing PR-2 will drain.
@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<MoodDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Coalescing-aware enqueue. Per ADR-0004:
  ///   - a new `update` for a pending entry replaces the pending payload
  ///     (idempotent — N saves from one user gesture become 1 mutation);
  ///   - a new `delete` drops every pending mutation for the same `entry_id`
  ///     and inserts a single `delete` row (creates that never made it to the
  ///     server become no-ops);
  ///   - all transitions happen inside a single `transaction(...)`.
  ///
  /// Returns the queue row id of the resulting (possibly coalesced) row.
  Future<int> enqueue(SyncQueueCompanion row) {
    final operation = row.operation.present
        ? row.operation.value
        : (throw ArgumentError(
            'enqueue requires `operation` to be present',
          ));
    final entryId = row.entryId.present
        ? row.entryId.value
        : (throw ArgumentError('enqueue requires `entry_id` to be present'));

    return transaction(() async {
      final existing = await (select(syncQueue)
            ..where((t) => t.entryId.equals(entryId))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.id, mode: OrderingMode.asc),
            ]))
          .get();

      if (operation == SyncOperation.delete) {
        // Drop everything pending for this entry, then insert a single delete.
        if (existing.isNotEmpty) {
          await (delete(syncQueue)..where((t) => t.entryId.equals(entryId)))
              .go();
        }
        return into(syncQueue).insert(row);
      }

      // create / update path: if a pending row already exists for this entry,
      // overwrite its payload so we never queue duplicate writes.
      if (existing.isNotEmpty) {
        // Coalesce onto the *oldest* row so FIFO order across distinct entries
        // is preserved.
        final head = existing.first;
        await (update(syncQueue)..where((t) => t.id.equals(head.id))).write(
          SyncQueueCompanion(
            operation: row.operation,
            payload: row.payload,
            // `attempt_count` and `retry_after` reset so the coalesced payload
            // is treated as a fresh attempt by PR-2's worker.
            attemptCount: const Value(0),
            retryAfter: const Value(0),
            lastError: const Value(null),
            lastErrorCode: const Value(null),
          ),
        );
        // If older duplicates somehow snuck in, prune them.
        if (existing.length > 1) {
          final extras = existing.skip(1).map((r) => r.id).toList();
          await (delete(syncQueue)..where((t) => t.id.isIn(extras))).go();
        }
        return head.id;
      }

      return into(syncQueue).insert(row);
    });
  }

  /// Lowest-id row whose `retry_after` is in the past. Drives the worker's
  /// "next due mutation" loop in PR-2.
  Future<SyncQueueRow?> peekNextDue({required int now}) {
    return (select(syncQueue)
          ..where((t) => t.retryAfter.isSmallerOrEqualValue(now))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Batched variant for PR-2's drain. [limit] caps the per-tick batch.
  Future<List<SyncQueueRow>> peekAllDue({
    required int now,
    int limit = 32,
  }) {
    return (select(syncQueue)
          ..where((t) => t.retryAfter.isSmallerOrEqualValue(now))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();
  }

  /// Bumps `attempt_count` and pushes the row out of the worker's window.
  /// Error metadata is truncated to the 200-char cap mandated by ADR-0004.
  Future<void> markFailed(
    int queueId, {
    required int retryAfter,
    String? code,
    String? message,
  }) async {
    final existing =
        await (select(syncQueue)..where((t) => t.id.equals(queueId)))
            .getSingleOrNull();
    final nextAttempt = (existing?.attemptCount ?? 0) + 1;
    final truncated = message == null
        ? null
        : (message.length > 200 ? message.substring(0, 200) : message);

    await (update(syncQueue)..where((t) => t.id.equals(queueId))).write(
      SyncQueueCompanion(
        attemptCount: Value(nextAttempt),
        retryAfter: Value(retryAfter),
        lastError: Value(truncated),
        lastErrorCode: Value(code),
      ),
    );
  }

  Future<void> dequeue(int queueId) {
    return (delete(syncQueue)..where((t) => t.id.equals(queueId))).go();
  }

  Future<int> length() async {
    final count = countAll();
    final row = await (selectOnly(syncQueue)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  /// Live count for the future "N pending uploads" UI badge.
  Stream<int> watchPendingCount() {
    final count = countAll();
    final query = selectOnly(syncQueue)..addColumns([count]);
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }
}
