import '../models/mood_entry.dart';
import 'local_db_service.dart';

class LocalDbServiceImpl implements LocalDbService {
  final Map<String, MoodEntry> _entries = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> insertMoodEntry(MoodEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> updateMoodEntry(MoodEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> deleteMoodEntry(String id) async {
    _entries.remove(id);
  }

  @override
  Future<List<MoodEntry>> getMoodEntries(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final userEntries = _entries.values
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final end = (offset + limit).clamp(0, userEntries.length);
    return userEntries.sublist(offset.clamp(0, userEntries.length), end);
  }

  @override
  Future<List<MoodEntry>> getUnsyncedEntries(String userId) async {
    return _entries.values
        .where((e) => e.userId == userId && !e.isSynced)
        .toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    final entry = _entries[id];
    if (entry != null) {
      _entries[id] = entry.copyWith(isSynced: true);
    }
  }

  @override
  Future<void> clearUserEntries(String userId) async {
    _entries.removeWhere((_, e) => e.userId == userId);
  }

  @override
  Future<void> upsertMoodEntry(MoodEntry entry) async {
    _entries[entry.id] = entry;
  }
}
