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

  group('MoodEntry.isLocked midnight guard', () {
    // Use local-time anchors so the test passes regardless of host TZ.
    // The guard compares local calendar days, so we build a `createdAt`
    // anchored on a fixed local-noon and probe around that day's
    // midnight rollover.
    final createdLocal = DateTime(2026, 4, 28, 12);
    final entry = MoodEntry(
      id: 'm1',
      userId: 'u1',
      mood: MoodType.happy,
      intensity: 3,
      text: '',
      createdAt: createdLocal,
    );

    test('isLocked false earlier on the same local day', () {
      expect(
        entry.isLocked(now: DateTime(2026, 4, 28, 7)),
        isFalse,
        reason: 'editing the morning entry from later that morning is fine',
      );
    });

    test('isLocked false later on the same local day (11:59pm)', () {
      expect(
        entry.isLocked(now: DateTime(2026, 4, 28, 23, 59)),
        isFalse,
        reason: 'still the same calendar day - editable',
      );
    });

    test('isLocked true at midnight of the next day', () {
      expect(
        entry.isLocked(now: DateTime(2026, 4, 29, 0, 0)),
        isTrue,
        reason: 'lock kicks in the moment the calendar day rolls over',
      );
    });

    test('isLocked true on a later day (next-day morning)', () {
      expect(entry.isLocked(now: DateTime(2026, 4, 29, 9)), isTrue);
    });
  });
}
