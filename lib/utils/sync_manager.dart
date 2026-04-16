import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/mood_entry.dart';
import '../services/firestore_service.dart';
import '../services/local_db_service.dart';

/// Manages offline-first sync between local SQLite DB and Firestore.
///
/// Entries are always saved locally first, then pushed to Firestore when online.
/// Uses last-write-wins conflict resolution.
class SyncManager {
  final FirestoreService _firestoreService;
  final LocalDbService _localDbService;

  SyncManager({
    required FirestoreService firestoreService,
    required LocalDbService localDbService,
  })  : _firestoreService = firestoreService,
        _localDbService = localDbService;

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> syncEntries(String userId) async {
    if (!await isOnline()) return;

    // Push unsynced local entries to Firestore
    final unsyncedEntries = await _localDbService.getUnsyncedEntries(userId);
    for (final entry in unsyncedEntries) {
      try {
        await _firestoreService.addMoodEntry(entry);
        await _localDbService.markAsSynced(entry.id);
      } catch (_) {
        // Will retry on next sync
      }
    }

    // Pull latest from Firestore and merge into local DB
    try {
      final remoteEntries = await _firestoreService.getMoodEntries(
        userId,
        limit: 100,
      );
      for (final entry in remoteEntries) {
        await _localDbService.upsertMoodEntry(entry);
      }
    } catch (_) {
      // Will retry on next sync
    }
  }

  Future<void> saveMoodEntry(MoodEntry entry) async {
    // Always save locally first
    await _localDbService.insertMoodEntry(entry);

    // Try to sync to Firestore
    if (await isOnline()) {
      try {
        await _firestoreService.addMoodEntry(entry);
        await _localDbService.markAsSynced(entry.id);
      } catch (_) {
        // Stays unsynced, will sync later
      }
    }
  }

  Future<void> updateMoodEntry(MoodEntry entry) async {
    final unsyncedEntry = entry.copyWith(isSynced: false);
    await _localDbService.updateMoodEntry(unsyncedEntry);

    if (await isOnline()) {
      try {
        await _firestoreService.updateMoodEntry(entry);
        await _localDbService.markAsSynced(entry.id);
      } catch (_) {
        // Will sync later
      }
    }
  }

  Future<void> deleteMoodEntry(String id) async {
    await _localDbService.deleteMoodEntry(id);

    if (await isOnline()) {
      try {
        await _firestoreService.deleteMoodEntry(id);
      } catch (_) {
        // Best effort
      }
    }
  }
}
