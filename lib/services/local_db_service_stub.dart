import '../models/mood_entry.dart';
import 'local_db_service.dart';

class LocalDbServiceImpl implements LocalDbService {
  @override
  Future<void> init() async {}

  @override
  Future<void> insertMoodEntry(MoodEntry entry) async {}

  @override
  Future<void> updateMoodEntry(MoodEntry entry) async {}

  @override
  Future<void> deleteMoodEntry(String id) async {}

  @override
  Future<List<MoodEntry>> getMoodEntries(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async => [];

  @override
  Future<List<MoodEntry>> getUnsyncedEntries(String userId) async => [];

  @override
  Future<void> markAsSynced(String id) async {}

  @override
  Future<void> clearUserEntries(String userId) async {}

  @override
  Future<void> upsertMoodEntry(MoodEntry entry) async {}
}
