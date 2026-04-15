import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_entry.dart';
import 'package:user_centric_mobile_app/models/mood_type.dart';

void main() {
  group('MoodEntry', () {
    final now = DateTime(2026, 4, 15, 14, 30);
    final entry = MoodEntry(
      id: 'test-id',
      userId: 'user-123',
      mood: 'happy',
      moodCategory: 'positive',
      text: 'Feeling great today!',
      attachmentUrl: 'https://example.com/photo.jpg',
      attachmentType: 'image',
      createdAt: now,
      updatedAt: now,
      isSynced: true,
    );

    test('moodType returns correct MoodType', () {
      expect(entry.moodType, MoodType.happy);
    });

    test('moodType returns null for invalid mood', () {
      final invalid = entry.copyWith(mood: 'nonexistent');
      expect(invalid.moodType, isNull);
    });

    test('copyWith creates modified copy', () {
      final copy = entry.copyWith(text: 'Updated text', mood: 'sad');
      expect(copy.text, 'Updated text');
      expect(copy.mood, 'sad');
      expect(copy.id, entry.id);
      expect(copy.userId, entry.userId);
    });

    test('toSqlite produces correct map', () {
      final map = entry.toSqlite();
      expect(map['id'], 'test-id');
      expect(map['userId'], 'user-123');
      expect(map['mood'], 'happy');
      expect(map['moodCategory'], 'positive');
      expect(map['text'], 'Feeling great today!');
      expect(map['attachmentUrl'], 'https://example.com/photo.jpg');
      expect(map['attachmentType'], 'image');
      expect(map['isSynced'], 1);
      expect(map['createdAt'], now.toIso8601String());
    });

    test('fromSqlite restores entry', () {
      final map = entry.toSqlite();
      final restored = MoodEntry.fromSqlite(map);
      expect(restored.id, entry.id);
      expect(restored.userId, entry.userId);
      expect(restored.mood, entry.mood);
      expect(restored.moodCategory, entry.moodCategory);
      expect(restored.text, entry.text);
      expect(restored.attachmentUrl, entry.attachmentUrl);
      expect(restored.attachmentType, entry.attachmentType);
      expect(restored.isSynced, entry.isSynced);
    });

    test('toFirestore produces correct map', () {
      final map = entry.toFirestore();
      expect(map['id'], 'test-id');
      expect(map['userId'], 'user-123');
      expect(map['mood'], 'happy');
      expect(map['moodCategory'], 'positive');
      expect(map['text'], 'Feeling great today!');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map.containsKey('isSynced'), isFalse);
    });

    test('fromFirestore restores entry', () {
      final data = {
        'id': 'test-id',
        'userId': 'user-123',
        'mood': 'happy',
        'moodCategory': 'positive',
        'text': 'Feeling great today!',
        'attachmentUrl': null,
        'attachmentType': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final restored = MoodEntry.fromFirestore(data);
      expect(restored.id, 'test-id');
      expect(restored.mood, 'happy');
      expect(restored.isSynced, isTrue);
      expect(restored.attachmentUrl, isNull);
    });

    test('default text is empty string', () {
      final minimal = MoodEntry(
        id: 'id',
        userId: 'uid',
        mood: 'calm',
        moodCategory: 'positive',
        createdAt: now,
        updatedAt: now,
      );
      expect(minimal.text, '');
    });
  });
}
