import '../models/mood_entry.dart';
import 'local_db_service_stub.dart'
    if (dart.library.io) 'local_db_service_mobile.dart'
    if (dart.library.html) 'local_db_service_web.dart'
    as impl;

/// Abstract interface for local database operations.
///
/// Uses SQLite on Android ([local_db_service_mobile.dart]) and an
/// in-memory store on Web ([local_db_service_web.dart]).
abstract class LocalDbService {
  Future<void> init();
  Future<void> insertMoodEntry(MoodEntry entry);
  Future<void> updateMoodEntry(MoodEntry entry);
  Future<void> deleteMoodEntry(String id);
  Future<List<MoodEntry>> getMoodEntries(String userId, {int limit, int offset});
  Future<List<MoodEntry>> getUnsyncedEntries(String userId);
  Future<void> markAsSynced(String id);
  Future<void> clearUserEntries(String userId);
  Future<void> upsertMoodEntry(MoodEntry entry);

  factory LocalDbService() = impl.LocalDbServiceImpl;
}
