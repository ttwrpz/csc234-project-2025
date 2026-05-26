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

    test('Intervention dispatch defaults to FALSE in v1.0 (ADR-0011 §4)', () {
      // Engine on, dispatcher off — see CLAUDE.md "The pivot features"
      // and ADR-0011 §4. S5 flips this to true.
      final flags = FeatureFlags.defaults();
      expect(flags.interventionDispatchEnabled, isFalse);
    });
  });

  group('FeatureFlags equality', () {
    test('two flag sets with the same values are equal', () {
      const a = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: false,
        interventionDispatchEnabled: false,
      );
      const b = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: false,
        interventionDispatchEnabled: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('flag sets with differing values are not equal', () {
      const a = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: true,
        interventionDispatchEnabled: false,
      );
      const b = FeatureFlags(
        aiPatternAnalysisEnabled: false,
        geminiDetectionEnabled: true,
        interventionDispatchEnabled: false,
      );
      expect(a, isNot(equals(b)));
    });

    test(
      'flag sets differing on interventionDispatchEnabled are not equal',
      () {
        const a = FeatureFlags(
          aiPatternAnalysisEnabled: true,
          geminiDetectionEnabled: true,
          interventionDispatchEnabled: false,
        );
        const b = FeatureFlags(
          aiPatternAnalysisEnabled: true,
          geminiDetectionEnabled: true,
          interventionDispatchEnabled: true,
        );
        expect(a, isNot(equals(b)));
      },
    );
  });

  group('FeatureFlags.copyWith', () {
    test('copyWith flips a single flag without disturbing the rest', () {
      const original = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: true,
        interventionDispatchEnabled: false,
      );
      final updated = original.copyWith(geminiDetectionEnabled: false);
      expect(updated.aiPatternAnalysisEnabled, isTrue);
      expect(updated.geminiDetectionEnabled, isFalse);
      expect(updated.interventionDispatchEnabled, isFalse);
    });

    test('copyWith on interventionDispatchEnabled flips only that flag', () {
      const original = FeatureFlags(
        aiPatternAnalysisEnabled: true,
        geminiDetectionEnabled: true,
        interventionDispatchEnabled: false,
      );
      final updated = original.copyWith(interventionDispatchEnabled: true);
      expect(updated.aiPatternAnalysisEnabled, isTrue);
      expect(updated.geminiDetectionEnabled, isTrue);
      expect(updated.interventionDispatchEnabled, isTrue);
    });

    test('copyWith with no overrides returns an equal value', () {
      const original = FeatureFlags(
        aiPatternAnalysisEnabled: false,
        geminiDetectionEnabled: true,
        interventionDispatchEnabled: false,
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
    });
  });
}
