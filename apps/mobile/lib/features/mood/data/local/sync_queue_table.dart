import 'package:drift/drift.dart';

/// FIFO queue of mood mutations awaiting upload. The sync manager drains
/// this; coalescing rules live in [SyncQueueDao.enqueue].
@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryId => text().named('entry_id')();

  /// `create` / `update` / `delete`.
  TextColumn get operation => text()();

  /// JSON snapshot of the entry at mutation time. Used by the sync worker so
  /// the row payload survives in-flight retries even if the local row mutates
  /// further before the network call lands.
  TextColumn get payload => text()();

  IntColumn get attemptCount =>
      integer().named('attempt_count').withDefault(const Constant(0))();

  /// Truncated to 200 chars at write time - see [SyncQueueDao.markFailed].
  /// Never include PII (entry text, email).
  TextColumn get lastError => text().named('last_error').nullable()();
  TextColumn get lastErrorCode => text().named('last_error_code').nullable()();

  IntColumn get retryAfter =>
      integer().named('retry_after').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')();
}
