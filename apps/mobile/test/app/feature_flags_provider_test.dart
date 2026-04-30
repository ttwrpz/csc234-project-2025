import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/feature_flags.dart';
import 'package:moodbloom/app/providers.dart';

/// Hand-rolled fake mirroring the `FakeMoodRepository` pattern. We swap a
/// closure-driven stub in for the real RC adapter so the provider's logic
/// is exercised without touching Firebase platform channels.
class _FakeFlagSource implements FeatureFlagSource {
  _FakeFlagSource(this._handler);

  final bool Function(String key) _handler;

  final List<String> calls = [];

  @override
  bool getBool(String key) {
    calls.add(key);
    return _handler(key);
  }
}

void main() {
  group('featureFlagsProvider', () {
    test('when RC returns false for ai_pattern_analysis_enabled, '
        'provider exposes aiPatternAnalysisEnabled: false', () {
      final source = _FakeFlagSource(
        (key) => key == 'ai_pattern_analysis_enabled' ? false : true,
      );
      final container = ProviderContainer(
        overrides: [featureFlagSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      final flags = container.read(featureFlagsProvider);

      expect(flags.aiPatternAnalysisEnabled, isFalse);
      expect(flags.geminiDetectionEnabled, isTrue);
      expect(
        source.calls,
        containsAll(<String>[
          'ai_pattern_analysis_enabled',
          'gemini_detection_enabled',
        ]),
      );
    });

    test('when RC throws (e.g. uninitialised), '
        'provider returns FeatureFlags.defaults()', () {
      final source = _FakeFlagSource(
        (_) => throw StateError('RC not initialised'),
      );
      final container = ProviderContainer(
        overrides: [featureFlagSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      final flags = container.read(featureFlagsProvider);

      expect(flags, equals(FeatureFlags.defaults()));
      expect(flags.aiPatternAnalysisEnabled, isTrue);
      expect(flags.geminiDetectionEnabled, isTrue);
    });

    test('when RC returns false for gemini_detection_enabled, '
        'provider exposes geminiDetectionEnabled: false', () {
      final source = _FakeFlagSource(
        (key) => key == 'gemini_detection_enabled' ? false : true,
      );
      final container = ProviderContainer(
        overrides: [featureFlagSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      final flags = container.read(featureFlagsProvider);

      expect(flags.aiPatternAnalysisEnabled, isTrue);
      expect(flags.geminiDetectionEnabled, isFalse);
    });
  });
}
