import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'mood_dao.dart';
import 'mood_entry_table.dart';
import 'sync_queue_dao.dart';
import 'sync_queue_table.dart';

part 'mood_database.g.dart';

/// Single Drift database for the mood feature. Two tables (`mood_entries`,
/// `sync_queue`) and two DAOs back the offline-first persistence per ADR-0004.
///
/// Schema version 1 is what S3 ships. v2 will use `MigrationStrategy.onUpgrade`
/// step-by-step migrations.
@DriftDatabase(tables: [MoodEntries, SyncQueue], daos: [MoodDao, SyncQueueDao])
class MoodDatabase extends _$MoodDatabase {
  MoodDatabase() : super(_openConnection());

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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'moodbloom.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
