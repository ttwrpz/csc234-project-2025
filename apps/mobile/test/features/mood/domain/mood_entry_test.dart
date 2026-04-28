import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';

void main() {
  final createdAt = DateTime.utc(2026, 4, 28, 12);

  group('MoodEntry.create intensity validation', () {
    test('intensity 0 returns Err invalidIntensity', () {
      final result = MoodEntry.create(
        id: 'm1',
        userId: 'u1',
        mood: MoodType.happy,
        intensity: 0,
        text: '',
        createdAt: createdAt,
      );
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(result.errOrNull(), isA<MoodFailure>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_InvalidIntensity',
      );
    });

    test('intensity 1 returns Ok', () {
      final result = MoodEntry.create(
        id: 'm1',
        userId: 'u1',
        mood: MoodType.happy,
        intensity: 1,
        text: '',
        createdAt: createdAt,
      );
      expect(result, isA<Ok<MoodEntry, MoodFailure>>());
      expect(result.getOrNull()?.intensity, 1);
    });

    test('intensity 5 returns Ok', () {
      final result = MoodEntry.create(
        id: 'm1',
        userId: 'u1',
        mood: MoodType.happy,
        intensity: 5,
        text: '',
        createdAt: createdAt,
      );
      expect(result, isA<Ok<MoodEntry, MoodFailure>>());
      expect(result.getOrNull()?.intensity, 5);
    });

    test('intensity 6 returns Err invalidIntensity', () {
      final result = MoodEntry.create(
        id: 'm1',
        userId: 'u1',
        mood: MoodType.happy,
        intensity: 6,
        text: '',
        createdAt: createdAt,
      );
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_InvalidIntensity',
      );
    });
  });

  group('MoodEntry.create text validation', () {
    test('text length 500 returns Ok', () {
      final result = MoodEntry.create(
        id: 'm1',
        userId: 'u1',
        mood: MoodType.happy,
        intensity: 3,
        text: 'a' * 500,
        createdAt: createdAt,
      );
      expect(result, isA<Ok<MoodEntry, MoodFailure>>());
    });

    test('text length 501 returns Err textTooLong', () {
      final result = MoodEntry.create(
        id: 'm1',
        userId: 'u1',
        mood: MoodType.happy,
        intensity: 3,
        text: 'a' * 501,
        createdAt: createdAt,
      );
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_TextTooLong',
      );
    });
  });

  group('MoodEntry.create id/userId validation', () {
    test('empty id returns Err malformed', () {
      final result = MoodEntry.create(
        id: '',
        userId: 'u1',
        mood: MoodType.happy,
        intensity: 3,
        text: '',
        createdAt: createdAt,
      );
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_Malformed',
      );
    });

    test('empty userId returns Err malformed', () {
      final result = MoodEntry.create(
        id: 'm1',
        userId: '',
        mood: MoodType.happy,
        intensity: 3,
        text: '',
        createdAt: createdAt,
      );
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_Malformed',
      );
    });
  });

  group('MoodEntry.isLocked 24h guard', () {
    final entry = MoodEntry(
      id: 'm1',
      userId: 'u1',
      mood: MoodType.happy,
      intensity: 3,
      text: '',
      createdAt: createdAt,
    );

    test('isLocked false at createdAt + 23h', () {
      expect(
        entry.isLocked(now: createdAt.add(const Duration(hours: 23))),
        isFalse,
      );
    });

    test('isLocked true at createdAt + 24h', () {
      expect(
        entry.isLocked(now: createdAt.add(const Duration(hours: 24))),
        isTrue,
      );
    });

    test('isLocked true at createdAt + 25h', () {
      expect(
        entry.isLocked(now: createdAt.add(const Duration(hours: 25))),
        isTrue,
      );
    });
  });
}
