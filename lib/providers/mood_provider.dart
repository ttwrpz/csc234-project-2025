import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_entry.dart';
import '../models/mood_type.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/local_db_service.dart';
import '../utils/sync_manager.dart';
import '../utils/date_helpers.dart';

/// Manages mood entries: loading, saving, updating, deleting, and sync status.
///
/// Uses offline-first strategy: entries save to local DB first, then sync to
/// Firestore when online. Exposes streak count, filtered views, and sync state.
class MoodProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final LocalDbService _localDbService;
  final SyncManager _syncManager;

  List<MoodEntry> _entries = [];
  bool _isLoading = false;
  final bool _hasMore = true;
  String? _error;
  int _pendingSyncCount = 0;
  DateTime? _lastSyncTime;

  MoodProvider({
    required FirestoreService firestoreService,
    required StorageService storageService,
    required LocalDbService localDbService,
    required SyncManager syncManager,
  })  : _firestoreService = firestoreService,
        _storageService = storageService,
        _localDbService = localDbService,
        _syncManager = syncManager;

  List<MoodEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get pendingSyncCount => _pendingSyncCount;
  DateTime? get lastSyncTime => _lastSyncTime;

  int get streakCount {
    final dates = _entries.map((e) => e.createdAt).toList();
    return DateHelpers.calculateStreak(dates);
  }

  List<MoodEntry> get thisWeekEntries {
    final weekDays = DateHelpers.getWeekDays();
    final start = weekDays.first;
    final end = weekDays.last.add(const Duration(days: 1));
    return _entries
        .where((e) => e.createdAt.isAfter(start) && e.createdAt.isBefore(end))
        .toList();
  }

  List<MoodEntry> get last30DaysEntries {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _entries.where((e) => e.createdAt.isAfter(cutoff)).toList();
  }

  List<MoodEntry> entriesForDate(DateTime date) {
    return _entries
        .where((e) => DateHelpers.isSameDay(e.createdAt, date))
        .toList();
  }

  List<MoodEntry> filteredEntries(Set<MoodType> filters) {
    if (filters.isEmpty) return _entries;
    return _entries
        .where((e) => filters.any((f) => f.name == e.mood))
        .toList();
  }

  Future<void> loadEntries(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try loading from Firestore first
      if (await _syncManager.isOnline()) {
        _entries = await _firestoreService.getMoodEntries(userId, limit: 100);
        // Cache locally
        for (final entry in _entries) {
          await _localDbService.upsertMoodEntry(entry);
        }
      } else {
        // Load from local DB
        _entries = await _localDbService.getMoodEntries(userId, limit: 100);
      }
    } catch (e) {
      // Fallback to local DB
      try {
        _entries = await _localDbService.getMoodEntries(userId, limit: 100);
      } catch (_) {
        _error = 'Failed to load mood entries.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      _updatePendingSyncCount(userId);
    }
  }

  Future<void> refreshEntries(String userId) async {
    await _syncManager.syncEntries(userId);
    _lastSyncTime = DateTime.now();
    await loadEntries(userId);
    await _updatePendingSyncCount(userId);
  }

  Future<void> _updatePendingSyncCount(String userId) async {
    try {
      final unsynced = await _localDbService.getUnsyncedEntries(userId);
      _pendingSyncCount = unsynced.length;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> saveMoodEntry({
    required String userId,
    required MoodType moodType,
    required String text,
    Uint8List? attachmentData,
    String? attachmentFileName,
    String? attachmentContentType,
    String? attachmentType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = const Uuid().v4();
      String? attachmentUrl;

      // Upload attachment if provided
      if (attachmentData != null &&
          attachmentFileName != null &&
          attachmentContentType != null) {
        attachmentUrl = await _storageService.uploadAttachment(
          userId: userId,
          entryId: id,
          data: attachmentData,
          fileName: attachmentFileName,
          contentType: attachmentContentType,
        );
      }

      final entry = MoodEntry(
        id: id,
        userId: userId,
        mood: moodType.name,
        moodCategory: moodType.category.name,
        text: text,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _syncManager.saveMoodEntry(entry);
      _entries.insert(0, entry.copyWith(isSynced: true));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save mood entry.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEntry({
    required MoodEntry entry,
    required MoodType moodType,
    required String text,
    Uint8List? newAttachmentData,
    String? newAttachmentFileName,
    String? newAttachmentContentType,
    String? newAttachmentType,
    bool removeAttachment = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? attachmentUrl = entry.attachmentUrl;
      String? attType = entry.attachmentType;

      // Handle attachment changes
      if (removeAttachment && attachmentUrl != null) {
        await _storageService.deleteAttachment(attachmentUrl);
        attachmentUrl = null;
        attType = null;
      } else if (newAttachmentData != null) {
        if (attachmentUrl != null) {
          await _storageService.deleteAttachment(attachmentUrl);
        }
        attachmentUrl = await _storageService.uploadAttachment(
          userId: entry.userId,
          entryId: entry.id,
          data: newAttachmentData,
          fileName: newAttachmentFileName!,
          contentType: newAttachmentContentType!,
        );
        attType = newAttachmentType;
      }

      final updated = entry.copyWith(
        mood: moodType.name,
        moodCategory: moodType.category.name,
        text: text,
        attachmentUrl: attachmentUrl,
        attachmentType: attType,
        updatedAt: DateTime.now(),
      );

      await _syncManager.updateMoodEntry(updated);

      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update mood entry.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEntry(MoodEntry entry) async {
    try {
      if (entry.attachmentUrl != null) {
        await _storageService.deleteAttachment(entry.attachmentUrl!);
      }
      await _syncManager.deleteMoodEntry(entry.id);
      _entries.removeWhere((e) => e.id == entry.id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete mood entry.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
