import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/feature_flags.dart';

void main() {
  group('FeatureFlags.defaults', () {
    test(
      'AI pattern analysis defaults to true (per CLAUDE.md rollback plan)',
      () {
        final flags = FeatureFlags.defaults();
        expect(flags.aiPatternAnalysisEnabled, isTrue);
      },
    );

    test('Gemini detection defaults to true (sprint-3 master kill-switch)', () {
      final flags = FeatureFlags.defaults();
      expect(flags.geminiDetectionEnabled, isTrue);
    });
  });

  group('FeatureFlags equality', () {
    test('two flag sets with the same values are equal', () {
      const a = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: false,
      );
      const b = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('flag sets with differing values are not equal', () {
      const a = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: true,
      );
      const b = FeatureFlags(
        aiPatternAnalysisEnabled: false,
        geminiDetectionEnabled: true,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('FeatureFlags.copyWith', () {
    test('copyWith flips a single flag without disturbing the rest', () {
      const original = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: true,
      );
      final updated = original.copyWith(geminiDetectionEnabled: false);
      expect(updated.aiPatternAnalysisEnabled, isTrue);
      expect(updated.geminiDetectionEnabled, isFalse);
    });

    test('copyWith with no overrides returns an equal value', () {
      const original = FeatureFlags(
        aiPatternAnalysisEnabled: false,
        geminiDetectionEnabled: true,
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
    });
  });
}
