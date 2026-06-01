import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/analytics/data/datasources/analyze_patterns_functions_datasource.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('AnalyzePatternsFunctionsDatasource.projectEntry', () {
    final entry = MoodEntry(
      id: 'e-1',
      userId: 'u-1',
      mood: MoodType.sad,
      intensity: 4,
      text: 'I had a really hard day at work today and feel exhausted.',
      createdAt: DateTime(2026, 4, 28, 23, 5),
      mediaRefs: const ['gs://bucket/path-1.jpg', 'gs://bucket/path-2.jpg'],
    );

    test('projection drops `text` (PII fence - ADR-0007)', () {
      final out = AnalyzePatternsFunctionsDatasource.projectEntry(entry);
      expect(out.containsKey('text'), isFalse);
    });

    test('projection drops `mediaRefs` (PII fence - ADR-0007)', () {
      final out = AnalyzePatternsFunctionsDatasource.projectEntry(entry);
      expect(out.containsKey('mediaRefs'), isFalse);
    });

    test('projection contains exactly { date, moodCode, intensity }', () {
      final out = AnalyzePatternsFunctionsDatasource.projectEntry(entry);
      expect(out.keys.toSet(), {'date', 'moodCode', 'intensity'});
    });

    test('projection serialises mood enum to lowercase wire string', () {
      expect(
        AnalyzePatternsFunctionsDatasource.projectEntry(
          entry.copyWith(mood: MoodType.happy),
        )['moodCode'],
        'happy',
      );
      expect(
        AnalyzePatternsFunctionsDatasource.projectEntry(
          entry.copyWith(mood: MoodType.anxious),
        )['moodCode'],
        'anxious',
      );
    });

    test('projection serialises intensity as a plain int', () {
      final out = AnalyzePatternsFunctionsDatasource.projectEntry(entry);
      expect(out['intensity'], isA<int>());
      expect(out['intensity'], 4);
    });

    test('projection date is local-day ISO (YYYY-MM-DD)', () {
      final out = AnalyzePatternsFunctionsDatasource.projectEntry(entry);
      // The createdAt was 2026-04-28 23:05 in local time → date is
      // 2026-04-28 regardless of TZ (we explicitly local-truncate before
      // serialisation).
      expect(out['date'], '2026-04-28');
    });

    test(
      'PII canary: full projected payload contains no MoodEntry text content',
      () {
        final out = AnalyzePatternsFunctionsDatasource.projectEntry(entry);
        final serialised = out.toString();
        // Specific substrings from `entry.text` and `entry.mediaRefs` must
        // not appear anywhere in the projection.
        expect(serialised, isNot(contains('hard day')));
        expect(serialised, isNot(contains('exhausted')));
        expect(serialised, isNot(contains('gs://')));
        expect(serialised, isNot(contains('bucket')));
      },
    );
  });
}
