// Tests for: F35 SQLite Local Cache, F36 Offline-First Save
// Features covered: SQLite CRUD operations, isSynced flag management,
//   query ordering, user data isolation
//
// Uses the web in-memory implementation (LocalDbServiceImpl from
// local_db_service_web.dart) which mirrors the SQLite behavior
// without requiring a real database.
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_entry.dart';
import 'package:user_centric_mobile_app/services/local_db_service_web.dart';

void main() {
  group('LocalDbService', () {
    late LocalDbServiceImpl db;

    setUp(() async {
      db = LocalDbServiceImpl();
      await db.init();
    });

    MoodEntry createEntry({
      String id = 'entry-1',
      String userId = 'user-1',
      String mood = 'happy',
      String moodCategory = 'positive',
      String text = 'Test entry',
      bool isSynced = false,
      DateTime? createdAt,
    }) {
      return MoodEntry(
        id: id,
        userId: userId,
        mood: mood,
        moodCategory: moodCategory,
        text: text,
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: isSynced,
      );
    }

    group('insertMoodEntry', () {
      test('inserts an entry with isSynced = false', () async {
        final entry = createEntry(isSynced: false);
        await db.insertMoodEntry(entry);

        final entries = await db.getMoodEntries('user-1');
        expect(entries.length, 1);
        expect(entries.first.id, 'entry-1');
        expect(entries.first.isSynced, false);
      });

      test('inserts multiple entries', () async {
        await db.insertMoodEntry(createEntry(id: 'e1'));
        await db.insertMoodEntry(createEntry(id: 'e2'));
        await db.insertMoodEntry(createEntry(id: 'e3'));

        final entries = await db.getMoodEntries('user-1');
        expect(entries.length, 3);
      });

      test('insert with same id replaces existing entry', () async {
        await db.insertMoodEntry(createEntry(id: 'e1', text: 'original'));
        await db.insertMoodEntry(createEntry(id: 'e1', text: 'replaced'));

        final entries = await db.getMoodEntries('user-1');
        expect(entries.length, 1);
        expect(entries.first.text, 'replaced');
      });
    });

    group('getUnsyncedEntries', () {
      test('returns only unsynced entries', () async {
        await db.insertMoodEntry(createEntry(id: 'e1', isSynced: false));
        await db.insertMoodEntry(createEntry(id: 'e2', isSynced: true));
        await db.insertMoodEntry(createEntry(id: 'e3', isSynced: false));

        final unsynced = await db.getUnsyncedEntries('user-1');
        expect(unsynced.length, 2);
        expect(unsynced.map((e) => e.id).toSet(), {'e1', 'e3'});
      });

      test('returns empty list when all entries are synced', () async {
        await db.insertMoodEntry(createEntry(id: 'e1', isSynced: true));
        await db.insertMoodEntry(createEntry(id: 'e2', isSynced: true));

        final unsynced = await db.getUnsyncedEntries('user-1');
        expect(unsynced, isEmpty);
      });

      test('filters by userId', () async {
        await db.insertMoodEntry(
            createEntry(id: 'e1', userId: 'user-1', isSynced: false));
        await db.insertMoodEntry(
            createEntry(id: 'e2', userId: 'user-2', isSynced: false));

        final unsynced = await db.getUnsyncedEntries('user-1');
        expect(unsynced.length, 1);
        expect(unsynced.first.id, 'e1');
      });
    });

    group('markAsSynced', () {
      test('updates isSynced flag from false to true', () async {
        await db.insertMoodEntry(createEntry(id: 'e1', isSynced: false));

        await db.markAsSynced('e1');

        final unsynced = await db.getUnsyncedEntries('user-1');
        expect(unsynced, isEmpty);

        final all = await db.getMoodEntries('user-1');
        expect(all.first.isSynced, true);
      });

      test('does not error when entry does not exist', () async {
        // Should not throw
        await db.markAsSynced('nonexistent');
      });
    });

    group('getMoodEntries', () {
      test('returns entries in descending createdAt order', () async {
        final now = DateTime.now();
        await db.insertMoodEntry(createEntry(
          id: 'e1',
          createdAt: now.subtract(const Duration(hours: 3)),
        ));
        await db.insertMoodEntry(createEntry(
          id: 'e2',
          createdAt: now.subtract(const Duration(hours: 1)),
        ));
        await db.insertMoodEntry(createEntry(
          id: 'e3',
          createdAt: now,
        ));

        final entries = await db.getMoodEntries('user-1');
        expect(entries[0].id, 'e3');
        expect(entries[1].id, 'e2');
        expect(entries[2].id, 'e1');
      });

      test('respects limit parameter', () async {
        for (int i = 0; i < 10; i++) {
          await db.insertMoodEntry(createEntry(id: 'e$i'));
        }

        final entries = await db.getMoodEntries('user-1', limit: 5);
        expect(entries.length, 5);
      });

      test('respects offset parameter', () async {
        final now = DateTime.now();
        for (int i = 0; i < 5; i++) {
          await db.insertMoodEntry(createEntry(
            id: 'e$i',
            createdAt: now.subtract(Duration(hours: i)),
          ));
        }

        final entries = await db.getMoodEntries('user-1', limit: 2, offset: 2);
        expect(entries.length, 2);
        expect(entries[0].id, 'e2');
        expect(entries[1].id, 'e3');
      });

      test('only returns entries for specified userId', () async {
        await db.insertMoodEntry(createEntry(id: 'e1', userId: 'user-1'));
        await db.insertMoodEntry(createEntry(id: 'e2', userId: 'user-2'));
        await db.insertMoodEntry(createEntry(id: 'e3', userId: 'user-1'));

        final entries = await db.getMoodEntries('user-1');
        expect(entries.length, 2);
        expect(entries.every((e) => e.userId == 'user-1'), true);
      });
    });

    group('updateMoodEntry', () {
      test('updates entry fields', () async {
        await db.insertMoodEntry(createEntry(id: 'e1', text: 'original'));

        final updated = createEntry(id: 'e1', text: 'updated text');
        await db.updateMoodEntry(updated);

        final entries = await db.getMoodEntries('user-1');
        expect(entries.first.text, 'updated text');
      });
    });

    group('deleteMoodEntry', () {
      test('removes entry from local DB', () async {
        await db.insertMoodEntry(createEntry(id: 'e1'));
        await db.insertMoodEntry(createEntry(id: 'e2'));

        await db.deleteMoodEntry('e1');

        final entries = await db.getMoodEntries('user-1');
        expect(entries.length, 1);
        expect(entries.first.id, 'e2');
      });

      test('does not error when deleting nonexistent entry', () async {
        // Should not throw
        await db.deleteMoodEntry('nonexistent');
      });
    });

    group('clearUserEntries', () {
      test('removes all entries for a specific user', () async {
        await db.insertMoodEntry(createEntry(id: 'e1', userId: 'user-1'));
        await db.insertMoodEntry(createEntry(id: 'e2', userId: 'user-1'));
        await db.insertMoodEntry(createEntry(id: 'e3', userId: 'user-2'));

        await db.clearUserEntries('user-1');

        final user1Entries = await db.getMoodEntries('user-1');
        final user2Entries = await db.getMoodEntries('user-2');
        expect(user1Entries, isEmpty);
        expect(user2Entries.length, 1);
      });
    });

    group('upsertMoodEntry', () {
      test('inserts new entry if not exists', () async {
        await db.upsertMoodEntry(createEntry(id: 'e1'));
        final entries = await db.getMoodEntries('user-1');
        expect(entries.length, 1);
      });

      test('updates existing entry if id matches', () async {
        await db.upsertMoodEntry(createEntry(id: 'e1', text: 'v1'));
        await db.upsertMoodEntry(createEntry(id: 'e1', text: 'v2'));

        final entries = await db.getMoodEntries('user-1');
        expect(entries.length, 1);
        expect(entries.first.text, 'v2');
      });
    });
  });
}
