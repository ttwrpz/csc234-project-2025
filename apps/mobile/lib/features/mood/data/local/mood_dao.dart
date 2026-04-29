import 'package:drift/drift.dart';

import 'mood_database.dart';
import 'mood_entry_table.dart';

part 'mood_dao.g.dart';

/// Sync-state vocabulary used in the `sync_state` column. Kept as plain
/// constants (not an enum) because the column is `TEXT` and Drift
/// `TypeConverter` would obscure the values during ad-hoc SQL inspection.
class MoodSyncState {
  static const String pending = 'pending';
  static const String syncing = 'syncing';
  static const String synced = 'synced';
  static const String error = 'error';
}

/// DAO for `mood_entries`. PR-1 ships the schema, the watch query, and the LWW
/// rule for `upsertFromRemote`. The remaining mutators are wired now so PR-2
/// (sync manager) and PR-3 (repo cutover) can call them without further schema
/// churn.
@DriftAccessor(tables: [MoodEntries])
class MoodDao extends DatabaseAccessor<MoodDatabase> with _$MoodDaoMixin {
  MoodDao(super.db);

  /// All non-deleted entries for [userId], newest first. Drives the future
  /// PR-3 `MoodRepositoryImpl.watchAll` refactor.
  Stream<List<MoodEntryRow>> watchAllForUser(String userId) {
    return (select(moodEntries)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<MoodEntryRow?> getById(String id) {
    return (select(
      moodEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// True when the user has zero entries (live or tombstoned). Used by PR-3 to
  /// decide whether to bootstrap-fetch from Firestore on first launch.
  Future<bool> isEmpty(String userId) async {
    final row =
        await (selectOnly(moodEntries)
              ..addColumns([moodEntries.id])
              ..where(moodEntries.userId.equals(userId))
              ..limit(1))
            .getSingleOrNull();
    return row == null;
  }

  /// Local mutation path: inserts or replaces and marks the row pending so the
  /// sync worker (PR-2) picks it up.
  Future<void> upsertFromLocal(MoodEntriesCompanion row) {
    return into(moodEntries).insert(
      row.copyWith(syncState: const Value(MoodSyncState.pending)),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Remote echo path: applies a server-originated row using Last-Write-Wins
  /// per ADR-0005:
  ///   - newer `updated_at` wins;
  ///   - on equal `updated_at`, lexicographically smaller `device_id` wins;
  ///   - if the local row is `pending` and not strictly older, the remote
  ///     payload is dropped (the user's in-flight mutation must not be
  ///     clobbered by a stale snapshot).
  Future<void> upsertFromRemote(MoodEntriesCompanion row) async {
    if (!row.id.present) {
      throw ArgumentError('upsertFromRemote requires `id` to be present');
    }
    if (!row.updatedAt.present) {
      throw ArgumentError(
        'upsertFromRemote requires `updated_at` to be present',
      );
    }
    if (!row.deviceId.present) {
      throw ArgumentError(
        'upsertFromRemote requires `device_id` to be present',
      );
    }

    final id = row.id.value;
    final remoteUpdatedAt = row.updatedAt.value;
    final remoteDeviceId = row.deviceId.value;

    await transaction(() async {
      final existing = await (select(
        moodEntries,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (existing == null) {
        await into(moodEntries).insert(
          row.copyWith(syncState: const Value(MoodSyncState.synced)),
          mode: InsertMode.insertOrReplace,
        );
        return;
      }

      // Defend the user's in-flight mutation: a pending local row that is at
      // least as fresh as the incoming remote echo is preserved.
      final localUpdatedAt = existing.updatedAt;
      if (existing.syncState == MoodSyncState.pending &&
          localUpdatedAt != null &&
          remoteUpdatedAt != null &&
          localUpdatedAt >= remoteUpdatedAt) {
        return;
      }

      // LWW comparison: a NULL `updated_at` is treated as -infinity so any
      // remote with a real timestamp wins.
      final local = localUpdatedAt ?? -1 << 62;
      final remote = remoteUpdatedAt ?? -1 << 62;
      if (remote < local) return;
      if (remote == local && remoteDeviceId.compareTo(existing.deviceId) >= 0) {
        // Tie or larger device_id loses — local stays.
        return;
      }

      await (update(moodEntries)..where((t) => t.id.equals(id))).write(
        row.copyWith(syncState: const Value(MoodSyncState.synced)),
      );
    });
  }

  /// Marks a row as successfully uploaded and stamps the server-assigned
  /// `updated_at`. Used by PR-2's sync worker.
  Future<void> markSynced(String id, {required int updatedAt}) {
    return (update(moodEntries)..where((t) => t.id.equals(id))).write(
      MoodEntriesCompanion(
        syncState: const Value(MoodSyncState.synced),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> markSyncing(String id) {
    return (update(moodEntries)..where((t) => t.id.equals(id))).write(
      const MoodEntriesCompanion(syncState: Value(MoodSyncState.syncing)),
    );
  }

  Future<void> markError(String id) {
    return (update(moodEntries)..where((t) => t.id.equals(id))).write(
      const MoodEntriesCompanion(syncState: Value(MoodSyncState.error)),
    );
  }

  /// Tombstones a row locally. PR-3 wires this to the delete path with the
  /// 24h-lock guard. PR-1 just defines the operation.
  Future<void> softDelete(String id, {required int now}) {
    return (update(moodEntries)..where((t) => t.id.equals(id))).write(
      MoodEntriesCompanion(
        deletedAt: Value(now),
        syncState: const Value(MoodSyncState.pending),
        updatedAt: Value(now),
      ),
    );
  }

  /// Removes the row entirely. Used by PR-2 when a remote-delete event arrives
  /// (Firestore is the system of record post-upload).
  Future<void> hardDelete(String id) {
    return (delete(moodEntries)..where((t) => t.id.equals(id))).go();
  }
}
