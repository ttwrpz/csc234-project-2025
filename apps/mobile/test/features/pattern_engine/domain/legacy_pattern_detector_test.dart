// ignore_for_file: deprecated_member_use_from_same_package
//
// detectPattern is intentionally retained as a regression baseline for the
// legacy 2-rule trigger path. ADR-0011 supersedes it with
// RunPatternEngineUseCase; the deprecation annotation is correct, and these
// tests are the canary that protects the legacy code path until S5 flips the
// dispatcher to the new engine.
@Tags(['legacy'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/legacy_pattern_detector.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

MoodEntry _entry({
  required MoodType mood,
  required DateTime createdAt,
  int intensity = 3,
  String id = 'e',
}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: intensity,
    text: '',
    createdAt: createdAt,
  );
}

void main() {
  // Pin "today" to a concrete local date for determinism.
  final now = DateTime(2026, 4, 29, 10, 30);

  DateTime daysAgo(int n) =>
      DateTime(now.year, now.month, now.day).subtract(Duration(days: n));

  group('detectPattern', () {
    test('1. empty entries → not triggered, reason "none"', () {
      final state = detectPattern(const [], now: now);
      expect(state.triggered, isFalse);
      expect(state.escalated, isFalse);
      expect(state.reason, 'none');
    });

    test('2. 4 distinct negative days in last 7 → no trigger', () {
      final entries = [
        for (var i = 0; i < 4; i += 1)
          _entry(mood: MoodType.sad, createdAt: daysAgo(i), id: 'd$i'),
      ];
      final state = detectPattern(entries, now: now);
      expect(state.triggered, isFalse);
      expect(state.reason, 'none');
    });

    test(
      '3. 5 distinct negative days in last 7 → triggers 5_of_7_negative',
      () {
        final entries = [
          for (var i = 0; i < 5; i += 1)
            _entry(mood: MoodType.sad, createdAt: daysAgo(i), id: 'd$i'),
        ];
        final state = detectPattern(entries, now: now);
        expect(state.triggered, isTrue);
        expect(state.reason, '5_of_7_negative');
        expect(state.escalated, isFalse);
      },
    );

    test('4. multiple negative entries on same day count once for 5-of-7', () {
      // 4 distinct days, but yesterday has THREE entries — should NOT
      // count as 5 days. Triggers should NOT fire.
      final yesterday = daysAgo(1);
      final entries = [
        _entry(mood: MoodType.sad, createdAt: daysAgo(0), id: 'a'),
        _entry(mood: MoodType.angry, createdAt: yesterday, id: 'b'),
        _entry(
          mood: MoodType.anxious,
          createdAt: yesterday.add(const Duration(hours: 3)),
          id: 'c',
        ),
        _entry(
          mood: MoodType.okay,
          createdAt: yesterday.add(const Duration(hours: 6)),
          id: 'd',
        ),
        _entry(mood: MoodType.sad, createdAt: daysAgo(2), id: 'e'),
        _entry(mood: MoodType.sad, createdAt: daysAgo(3), id: 'f'),
      ];
      final state = detectPattern(entries, now: now);
      expect(state.triggered, isFalse);
    });

    test('5. 3 consecutive ≥4 negative (mixed types) → triggers '
        '3_consecutive_high_intensity', () {
      final entries = [
        _entry(
          mood: MoodType.sad,
          createdAt: daysAgo(0),
          intensity: 4,
          id: 'd0',
        ),
        _entry(
          mood: MoodType.angry,
          createdAt: daysAgo(1),
          intensity: 5,
          id: 'd1',
        ),
        _entry(
          mood: MoodType.anxious,
          createdAt: daysAgo(2),
          intensity: 4,
          id: 'd2',
        ),
      ];
      final state = detectPattern(entries, now: now);
      expect(state.triggered, isTrue);
      expect(state.reason, '3_consecutive_high_intensity');
    });

    test('6. 3 consecutive but day-2 intensity 3 → no trigger', () {
      final entries = [
        _entry(
          mood: MoodType.sad,
          createdAt: daysAgo(0),
          intensity: 4,
          id: 'd0',
        ),
        _entry(
          mood: MoodType.sad,
          createdAt: daysAgo(1),
          intensity: 3, // not heavy
          id: 'd1',
        ),
        _entry(
          mood: MoodType.angry,
          createdAt: daysAgo(2),
          intensity: 5,
          id: 'd2',
        ),
      ];
      final state = detectPattern(entries, now: now);
      expect(state.triggered, isFalse);
    });

    test('7. cooldown 12h ago suppresses even with qualifying pattern', () {
      final entries = [
        for (var i = 0; i < 5; i += 1)
          _entry(mood: MoodType.sad, createdAt: daysAgo(i), id: 'd$i'),
      ];
      final state = detectPattern(
        entries,
        now: now,
        lastTriggeredAt: now.subtract(const Duration(hours: 12)),
      );
      expect(state.triggered, isFalse);
      expect(state.reason, 'cooldown');
    });

    test('8. cooldown 49h ago (expired) → trigger fires normally', () {
      final entries = [
        for (var i = 0; i < 5; i += 1)
          _entry(mood: MoodType.sad, createdAt: daysAgo(i), id: 'd$i'),
      ];
      final state = detectPattern(
        entries,
        now: now,
        lastTriggeredAt: now.subtract(const Duration(hours: 49)),
      );
      expect(state.triggered, isTrue);
      expect(state.reason, '5_of_7_negative');
    });

    test('9. 11 days ago + currently triggering → escalated: true', () {
      final entries = [
        for (var i = 0; i < 5; i += 1)
          _entry(mood: MoodType.sad, createdAt: daysAgo(i), id: 'd$i'),
      ];
      final state = detectPattern(
        entries,
        now: now,
        firstTriggeredAt: now.subtract(const Duration(days: 11)),
      );
      expect(state.triggered, isTrue);
      expect(state.escalated, isTrue);
    });

    test('10. 11 days ago but NOT currently triggering → escalated: false', () {
      // Below the 5-of-7 threshold AND below the 3-consec heavy threshold.
      final entries = [
        _entry(mood: MoodType.sad, createdAt: daysAgo(0), id: 'a'),
        _entry(mood: MoodType.sad, createdAt: daysAgo(2), id: 'b'),
      ];
      final state = detectPattern(
        entries,
        now: now,
        firstTriggeredAt: now.subtract(const Duration(days: 11)),
      );
      expect(state.triggered, isFalse);
      expect(state.escalated, isFalse);
      expect(state.reason, 'none');
    });
  });
}
