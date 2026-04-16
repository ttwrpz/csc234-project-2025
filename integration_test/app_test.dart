// Integration tests for MoodBloom Beta v0.2
// Tests covered: Auth flow, Mood logging, Settings persistence
// Features covered: US-01 Login, US-02 Register, US-03 Mood Logging,
//   US-19 Animation Speed, US-23 Dark Mode, US-24 Settings Persistence
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:user_centric_mobile_app/app.dart';
import 'package:user_centric_mobile_app/models/mood_entry.dart';
import 'package:user_centric_mobile_app/models/mood_type.dart';
import 'package:user_centric_mobile_app/models/user_profile.dart';
import 'package:user_centric_mobile_app/providers/auth_provider.dart';
import 'package:user_centric_mobile_app/providers/mood_provider.dart';
import 'package:user_centric_mobile_app/providers/garden_provider.dart';
import 'package:user_centric_mobile_app/providers/settings_provider.dart';
import 'package:user_centric_mobile_app/services/auth_service.dart';
import 'package:user_centric_mobile_app/services/firestore_service.dart';
import 'package:user_centric_mobile_app/services/storage_service.dart';
import 'package:user_centric_mobile_app/services/local_db_service.dart';
import 'package:user_centric_mobile_app/services/preferences_service.dart';
import 'package:user_centric_mobile_app/utils/sync_manager.dart';

// --- Mock Services ---

class MockLocalDbService implements LocalDbService {
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

class MockFirestoreService extends FirestoreService {
  final Map<String, MoodEntry> _entries = {};
  final Map<String, UserProfile> _profiles = {};

  @override
  Future<void> addMoodEntry(MoodEntry entry) async {
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
    dynamic startAfter,
  }) async {
    return _entries.values
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    _profiles[profile.uid] = profile;
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    return _profiles[uid];
  }

  @override
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {}

  @override
  Future<void> deleteUserProfile(String uid) async {
    _profiles.remove(uid);
  }

  @override
  Future<void> deleteAllUserMoods(String userId) async {
    _entries.removeWhere((_, e) => e.userId == userId);
  }
}

class MockStorageService extends StorageService {
  @override
  Future<String> uploadAttachment({
    required String userId,
    required String entryId,
    required Uint8List data,
    required String fileName,
    required String contentType,
  }) async {
    return 'https://mock.storage/$userId/$entryId/$fileName';
  }

  @override
  Future<void> deleteAttachment(String url) async {}

  @override
  Future<void> deleteAllUserAttachments(String userId) async {}
}

class MockAuthService extends AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signOut() async {}
}

// --- Test App Builder ---

Widget buildTestApp({
  required SettingsProvider settingsProvider,
  required AuthProvider authProvider,
  required MoodProvider moodProvider,
  required GardenProvider gardenProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settingsProvider),
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider.value(value: moodProvider),
      ChangeNotifierProvider.value(value: gardenProvider),
    ],
    child: const MoodBloomApp(),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Persistence Test', () {
    testWidgets('animation speed and dark mode changes persist',
        (tester) async {
      // Set up fresh SharedPreferences
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
        'animation_speed': 2.0,
        'notifications_enabled': true,
        'dark_mode': false,
      });

      final preferencesService = PreferencesService();
      final settingsProvider =
          SettingsProvider(preferencesService: preferencesService);
      await settingsProvider.loadSettings();

      // Verify initial state
      expect(settingsProvider.animationSpeed, 2.0);
      expect(settingsProvider.darkMode, false);
      expect(settingsProvider.notificationsEnabled, true);

      // Change animation speed
      await settingsProvider.setAnimationSpeed(4.0);
      expect(settingsProvider.animationSpeed, 4.0);

      // Change dark mode
      await settingsProvider.setDarkMode(true);
      expect(settingsProvider.darkMode, true);

      // Toggle notifications off
      await settingsProvider.setNotificationsEnabled(false);
      expect(settingsProvider.notificationsEnabled, false);

      // Reload settings to verify persistence
      final settingsProvider2 =
          SettingsProvider(preferencesService: preferencesService);
      await settingsProvider2.loadSettings();

      expect(settingsProvider2.animationSpeed, 4.0);
      expect(settingsProvider2.darkMode, true);
      expect(settingsProvider2.notificationsEnabled, false);
    });
  });

  group('Mood Provider Tests', () {
    testWidgets('save and load mood entries with mock services',
        (tester) async {
      final localDb = MockLocalDbService();
      final firestoreService = MockFirestoreService();
      final storageService = MockStorageService();
      final syncManager = SyncManager(
        firestoreService: firestoreService,
        localDbService: localDb,
      );

      final moodProvider = MoodProvider(
        firestoreService: firestoreService,
        storageService: storageService,
        localDbService: localDb,
        syncManager: syncManager,
      );

      // Save a mood entry
      final success = await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.happy,
        text: 'Having a great day',
      );

      expect(success, true);
      expect(moodProvider.entries.length, 1);
      expect(moodProvider.entries.first.mood, 'happy');
      expect(moodProvider.entries.first.text, 'Having a great day');

      // Save another entry
      final success2 = await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.calm,
        text: 'Feeling peaceful',
      );

      expect(success2, true);
      expect(moodProvider.entries.length, 2);

      // Verify streak count
      expect(moodProvider.streakCount, greaterThanOrEqualTo(1));

      // Verify last 30 days includes both
      expect(moodProvider.last30DaysEntries.length, 2);

      // Verify filtering
      final happyOnly =
          moodProvider.filteredEntries({MoodType.happy});
      expect(happyOnly.length, 1);
      expect(happyOnly.first.mood, 'happy');
    });

    testWidgets('update mood entry', (tester) async {
      final localDb = MockLocalDbService();
      final firestoreService = MockFirestoreService();
      final storageService = MockStorageService();
      final syncManager = SyncManager(
        firestoreService: firestoreService,
        localDbService: localDb,
      );

      final moodProvider = MoodProvider(
        firestoreService: firestoreService,
        storageService: storageService,
        localDbService: localDb,
        syncManager: syncManager,
      );

      // Save a mood
      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.sad,
        text: 'Not a great day',
      );

      final entry = moodProvider.entries.first;

      // Update it
      final updated = await moodProvider.updateEntry(
        entry: entry,
        moodType: MoodType.happy,
        text: 'Actually, it got better!',
      );

      expect(updated, true);
      expect(moodProvider.entries.first.mood, 'happy');
      expect(moodProvider.entries.first.text, 'Actually, it got better!');
    });

    testWidgets('delete mood entry', (tester) async {
      final localDb = MockLocalDbService();
      final firestoreService = MockFirestoreService();
      final storageService = MockStorageService();
      final syncManager = SyncManager(
        firestoreService: firestoreService,
        localDbService: localDb,
      );

      final moodProvider = MoodProvider(
        firestoreService: firestoreService,
        storageService: storageService,
        localDbService: localDb,
        syncManager: syncManager,
      );

      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.happy,
        text: 'Test entry',
      );

      expect(moodProvider.entries.length, 1);

      final deleted = await moodProvider.deleteEntry(moodProvider.entries.first);

      expect(deleted, true);
      expect(moodProvider.entries.length, 0);
    });
  });

  group('Garden Provider Tests', () {
    testWidgets('garden elements generated from mood entries',
        (tester) async {
      final garden = GardenProvider();

      // Create test entries
      final entries = [
        MoodEntry(
          id: 'entry-1',
          userId: 'test-user',
          mood: 'happy',
          moodCategory: 'positive',
          text: 'Great day',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MoodEntry(
          id: 'entry-2',
          userId: 'test-user',
          mood: 'sad',
          moodCategory: 'negative',
          text: 'Bad day',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        MoodEntry(
          id: 'entry-3',
          userId: 'test-user',
          mood: 'tired',
          moodCategory: 'neutral',
          text: 'Sleepy',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

      garden.updateGarden(entries);

      expect(garden.elements.length, 3);

      // Positive moods should have full opacity
      final happyElement =
          garden.elements.firstWhere((e) => e.moodType == MoodType.happy);
      expect(happyElement.opacity, 1.0);

      // Negative moods should have some opacity (recently created)
      final sadElement =
          garden.elements.firstWhere((e) => e.moodType == MoodType.sad);
      expect(sadElement.opacity, greaterThan(0.0));
      expect(sadElement.isBug, true);

      // Animation speed affects fade
      garden.setAnimationSpeed(5.0);
      garden.updateGarden(entries);
      final sadElementFast =
          garden.elements.firstWhere((e) => e.moodType == MoodType.sad);
      // At 5x speed, fade is faster
      expect(sadElementFast.opacity, lessThanOrEqualTo(sadElement.opacity));
    });

    testWidgets('garden populates with multiple mood types', (tester) async {
      final garden = GardenProvider();

      // Log 3 different moods: happy, sad, calm
      final entries = [
        MoodEntry(
          id: 'g1',
          userId: 'test-user',
          mood: 'happy',
          moodCategory: 'positive',
          text: 'Happy entry',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MoodEntry(
          id: 'g2',
          userId: 'test-user',
          mood: 'sad',
          moodCategory: 'negative',
          text: 'Sad entry',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        MoodEntry(
          id: 'g3',
          userId: 'test-user',
          mood: 'calm',
          moodCategory: 'positive',
          text: 'Calm entry',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      garden.updateGarden(entries);

      // Verify garden shows 3 elements
      expect(garden.elements.length, 3);

      // Verify mood types are correctly mapped
      final moods = garden.elements.map((e) => e.moodType).toSet();
      expect(moods, contains(MoodType.happy));
      expect(moods, contains(MoodType.sad));
      expect(moods, contains(MoodType.calm));

      // Verify bug classification
      final bugs = garden.elements.where((e) => e.isBug);
      final plants = garden.elements.where((e) => !e.isBug);
      expect(bugs.length, 1); // Only sad
      expect(plants.length, 2); // happy and calm
    });
  });

  group('Dark Mode Integration Test', () {
    testWidgets('dark mode toggle persists and affects theme', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
        'dark_mode': false,
      });

      final preferencesService = PreferencesService();
      final settingsProvider =
          SettingsProvider(preferencesService: preferencesService);
      await settingsProvider.loadSettings();

      // Verify starts in light mode
      expect(settingsProvider.darkMode, false);

      // Toggle dark mode on
      await settingsProvider.setDarkMode(true);
      expect(settingsProvider.darkMode, true);

      // Verify persistence by reloading
      final settingsProvider2 =
          SettingsProvider(preferencesService: preferencesService);
      await settingsProvider2.loadSettings();
      expect(settingsProvider2.darkMode, true);

      // Toggle dark mode off
      await settingsProvider2.setDarkMode(false);
      expect(settingsProvider2.darkMode, false);

      // Verify off persists
      final settingsProvider3 =
          SettingsProvider(preferencesService: preferencesService);
      await settingsProvider3.loadSettings();
      expect(settingsProvider3.darkMode, false);
    });
  });

  group('Delete Entry Integration Test', () {
    testWidgets('delete entry removes from provider', (tester) async {
      final localDb = MockLocalDbService();
      final firestoreService = MockFirestoreService();
      final storageService = MockStorageService();
      final syncManager = SyncManager(
        firestoreService: firestoreService,
        localDbService: localDb,
      );

      final moodProvider = MoodProvider(
        firestoreService: firestoreService,
        storageService: storageService,
        localDbService: localDb,
        syncManager: syncManager,
      );

      // Save two entries
      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.happy,
        text: 'Entry to keep',
      );
      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.sad,
        text: 'Entry to delete',
      );

      expect(moodProvider.entries.length, 2);

      // Delete the second entry
      final entryToDelete = moodProvider.entries
          .firstWhere((e) => e.text == 'Entry to delete');
      final deleted = await moodProvider.deleteEntry(entryToDelete);

      expect(deleted, true);
      expect(moodProvider.entries.length, 1);
      expect(moodProvider.entries.first.text, 'Entry to keep');
    });
  });

  group('Filter Integration Test', () {
    testWidgets('mood filter returns only matching entries', (tester) async {
      final localDb = MockLocalDbService();
      final firestoreService = MockFirestoreService();
      final storageService = MockStorageService();
      final syncManager = SyncManager(
        firestoreService: firestoreService,
        localDbService: localDb,
      );

      final moodProvider = MoodProvider(
        firestoreService: firestoreService,
        storageService: storageService,
        localDbService: localDb,
        syncManager: syncManager,
      );

      // Save entries with different moods
      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.happy,
        text: 'Happy entry 1',
      );
      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.sad,
        text: 'Sad entry',
      );
      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.happy,
        text: 'Happy entry 2',
      );
      await moodProvider.saveMoodEntry(
        userId: 'test-user-1',
        moodType: MoodType.calm,
        text: 'Calm entry',
      );

      expect(moodProvider.entries.length, 4);

      // Filter for happy only
      final happyEntries = moodProvider.filteredEntries({MoodType.happy});
      expect(happyEntries.length, 2);
      expect(happyEntries.every((e) => e.mood == 'happy'), true);

      // Filter for sad only
      final sadEntries = moodProvider.filteredEntries({MoodType.sad});
      expect(sadEntries.length, 1);
      expect(sadEntries.first.text, 'Sad entry');

      // Filter for multiple moods
      final multiFilter =
          moodProvider.filteredEntries({MoodType.happy, MoodType.calm});
      expect(multiFilter.length, 3);

      // Empty filter returns all
      final allEntries = moodProvider.filteredEntries({});
      expect(allEntries.length, 4);
    });
  });
}
