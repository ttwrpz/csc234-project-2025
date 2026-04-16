// Tests for: F37 Automatic Background Sync
// Features covered: sync logic, push unsynced entries, pull remote entries,
//   error handling during sync, save/update/delete with sync
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_entry.dart';
import 'package:user_centric_mobile_app/services/local_db_service_web.dart'
    as web;
import 'package:user_centric_mobile_app/utils/sync_manager.dart';
import 'package:user_centric_mobile_app/services/firestore_service.dart';

// --- Mock Firestore Service ---

class MockFirestoreService extends FirestoreService {
  final Map<String, MoodEntry> _entries = {};
  bool shouldFail = false;

  @override
  Future<void> addMoodEntry(MoodEntry entry) async {
    if (shouldFail) throw Exception('Firestore write failed');
    _entries[entry.id] = entry;
  }

  @override
  Future<void> updateMoodEntry(MoodEntry entry) async {
    if (shouldFail) throw Exception('Firestore update failed');
    _entries[entry.id] = entry;
  }

  @override
  Future<void> deleteMoodEntry(String id) async {
    if (shouldFail) throw Exception('Firestore delete failed');
    _entries.remove(id);
  }

  @override
  Future<List<MoodEntry>> getMoodEntries(
    String userId, {
    int limit = 20,
    dynamic startAfter,
  }) async {
    if (shouldFail) throw Exception('Firestore read failed');
    // Simulate fromFirestore behavior: entries from Firestore are always synced
    return _entries.values
        .where((e) => e.userId == userId)
        .map((e) => e.copyWith(isSynced: true))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Map<String, MoodEntry> get entries => _entries;
}

// --- Testable SyncManager that allows overriding online check ---

class TestableSyncManager extends SyncManager {
  bool _online;

  TestableSyncManager({
    required super.firestoreService,
    required super.localDbService,
    bool online = true,
  }) : _online = online;

  set online(bool value) => _online = value;

  @override
  Future<bool> isOnline() async => _online;
}

void main() {
  group('SyncManager', () {
    late web.LocalDbServiceImpl localDb;
    late MockFirestoreService firestoreService;
    late TestableSyncManager syncManager;

    setUp(() async {
      localDb = web.LocalDbServiceImpl();
      await localDb.init();
      firestoreService = MockFirestoreService();
      syncManager = TestableSyncManager(
        firestoreService: firestoreService,
        localDbService: localDb,
        online: true,
      );
    });

    MoodEntry createEntry({
      String id = 'entry-1',
      String userId = 'user-1',
      String mood = 'happy',
      bool isSynced = false,
      DateTime? createdAt,
    }) {
      return MoodEntry(
        id: id,
        userId: userId,
        mood: mood,
        moodCategory: 'positive',
        text: 'Test',
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: isSynced,
      );
    }

    group('saveMoodEntry', () {
      test('saves locally and syncs to Firestore when online', () async {
        final entry = createEntry();
        await syncManager.saveMoodEntry(entry);

        // Should be in local DB
        final localEntries = await localDb.getMoodEntries('user-1');
        expect(localEntries.length, 1);

        // Should be in Firestore
        expect(firestoreService.entries.containsKey('entry-1'), true);

        // Should be marked as synced locally
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced, isEmpty);
      });

      test('saves locally but stays unsynced when offline', () async {
        syncManager.online = false;
        final entry = createEntry();
        await syncManager.saveMoodEntry(entry);

        // Should be in local DB
        final localEntries = await localDb.getMoodEntries('user-1');
        expect(localEntries.length, 1);

        // Should NOT be in Firestore
        expect(firestoreService.entries, isEmpty);

        // Should be unsynced
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced.length, 1);
      });

      test('saves locally even when Firestore fails', () async {
        firestoreService.shouldFail = true;
        final entry = createEntry();
        await syncManager.saveMoodEntry(entry);

        // Should still be in local DB
        final localEntries = await localDb.getMoodEntries('user-1');
        expect(localEntries.length, 1);

        // Should remain unsynced
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced.length, 1);
      });
    });

    group('syncEntries', () {
      test('pushes all unsynced entries to Firestore', () async {
        // Insert unsynced entries directly into local DB
        await localDb.insertMoodEntry(createEntry(id: 'e1', isSynced: false));
        await localDb.insertMoodEntry(createEntry(id: 'e2', isSynced: false));
        await localDb.insertMoodEntry(createEntry(id: 'e3', isSynced: true));

        await syncManager.syncEntries('user-1');

        // Two entries should have been pushed to Firestore
        expect(firestoreService.entries.length, 2);
        expect(firestoreService.entries.containsKey('e1'), true);
        expect(firestoreService.entries.containsKey('e2'), true);

        // All should now be marked as synced
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced, isEmpty);
      });

      test('skips sync when offline', () async {
        syncManager.online = false;
        await localDb.insertMoodEntry(createEntry(id: 'e1', isSynced: false));

        await syncManager.syncEntries('user-1');

        // Nothing should have been pushed
        expect(firestoreService.entries, isEmpty);

        // Should still be unsynced
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced.length, 1);
      });

      test('skips sync when no unsynced entries exist', () async {
        await localDb.insertMoodEntry(createEntry(id: 'e1', isSynced: true));

        await syncManager.syncEntries('user-1');

        // Firestore should have the pulled entries, but no new pushes
        // (the pull will add e1 to firestore via getMoodEntries mock)
        // The key check: no errors and sync completes successfully
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced, isEmpty);
      });

      test('handles Firestore push errors gracefully', () async {
        await localDb.insertMoodEntry(createEntry(id: 'e1', isSynced: false));
        firestoreService.shouldFail = true;

        // Should not throw
        await syncManager.syncEntries('user-1');

        // Entry should remain unsynced for retry
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced.length, 1);
      });

      test('pulls remote entries into local DB', () async {
        // Add entry to Firestore directly
        firestoreService.entries['remote-1'] = createEntry(
          id: 'remote-1',
          isSynced: true,
        );

        await syncManager.syncEntries('user-1');

        // Should now be in local DB
        final localEntries = await localDb.getMoodEntries('user-1');
        expect(localEntries.any((e) => e.id == 'remote-1'), true);
      });
    });

    group('updateMoodEntry', () {
      test('updates locally and syncs when online', () async {
        await localDb.insertMoodEntry(createEntry(id: 'e1', isSynced: true));

        final updated = createEntry(id: 'e1', mood: 'calm');
        await syncManager.updateMoodEntry(updated);

        // Firestore should have updated entry
        expect(firestoreService.entries['e1']?.mood, 'calm');

        // Should be marked as synced
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced, isEmpty);
      });

      test('updates locally but stays unsynced when offline', () async {
        syncManager.online = false;
        await localDb.insertMoodEntry(createEntry(id: 'e1', isSynced: true));

        final updated = createEntry(id: 'e1', mood: 'calm');
        await syncManager.updateMoodEntry(updated);

        // Firestore should NOT have the entry
        expect(firestoreService.entries, isEmpty);

        // Should be unsynced locally
        final unsynced = await localDb.getUnsyncedEntries('user-1');
        expect(unsynced.length, 1);
      });
    });

    group('deleteMoodEntry', () {
      test('deletes locally and from Firestore when online', () async {
        await localDb.insertMoodEntry(createEntry(id: 'e1'));
        firestoreService.entries['e1'] = createEntry(id: 'e1');

        await syncManager.deleteMoodEntry('e1');

        // Should be removed from local DB
        final localEntries = await localDb.getMoodEntries('user-1');
        expect(localEntries, isEmpty);

        // Should be removed from Firestore
        expect(firestoreService.entries, isEmpty);
      });

      test('deletes locally even when Firestore fails', () async {
        await localDb.insertMoodEntry(createEntry(id: 'e1'));
        firestoreService.shouldFail = true;

        await syncManager.deleteMoodEntry('e1');

        // Should still be removed from local DB
        final localEntries = await localDb.getMoodEntries('user-1');
        expect(localEntries, isEmpty);
      });

      test('deletes locally when offline', () async {
        syncManager.online = false;
        await localDb.insertMoodEntry(createEntry(id: 'e1'));

        await syncManager.deleteMoodEntry('e1');

        // Should be removed from local DB
        final localEntries = await localDb.getMoodEntries('user-1');
        expect(localEntries, isEmpty);
      });
    });
  });
}
