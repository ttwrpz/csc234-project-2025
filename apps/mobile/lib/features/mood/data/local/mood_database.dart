import 'package:drift/drift.dart';

import 'mood_dao.dart';
import 'mood_database_web.dart'
    if (dart.library.io) 'mood_database_native.dart'
    as platform;
import 'mood_entry_table.dart';
import 'sync_queue_dao.dart';
import 'sync_queue_table.dart';

part 'mood_database.g.dart';

/// Single Drift database for the mood feature. Two tables (`mood_entries`,
/// `sync_queue`) and two DAOs back the offline-first persistence per ADR-0004.
///
/// Schema version 1 is what S3 ships. v2 will use `MigrationStrategy.onUpgrade`
/// step-by-step migrations.
///
/// Connector platform split: `dart.library.io` is used as the conditional
/// import switch — native targets (Android, iOS, desktop, VM) get the
/// FFI-backed `NativeDatabase` from `mood_database_native.dart`; Web gets a
/// throwing stub from `mood_database_web.dart` (see ADR-0004 §"Risks #1"
/// — Web ships through the Firestore-only fallback path, so the stub is
/// never invoked at runtime).
@DriftDatabase(tables: [MoodEntries, SyncQueue], daos: [MoodDao, SyncQueueDao])
class MoodDatabase extends _$MoodDatabase {
  MoodDatabase() : super(platform.openConnection());

  /// Test-only constructor — allows passing `NativeDatabase.memory()` so the
  /// DAO suite can run in-process without touching the filesystem.
  MoodDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2+ migrations land in a future sprint; v1 ships clean.
    },
  );
}
