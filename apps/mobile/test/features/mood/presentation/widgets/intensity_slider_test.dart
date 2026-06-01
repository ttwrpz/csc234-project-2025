import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/presentation/widgets/intensity_slider.dart';

/// Wraps [IntensitySlider] in just enough scaffolding to render. The widget
/// has no Riverpod dependencies so we don't need a [ProviderScope].
Future<void> _pumpSlider(
  WidgetTester tester, {
  required int intensity,
  required ValueChanged<int> onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: IntensitySlider(intensity: intensity, onChanged: onChanged),
        ),
      ),
    ),
  );
}

void main() {
  group('IntensitySlider', () {
    testWidgets('renders the supplied intensity on the underlying Slider', (
      tester,
    ) async {
      await _pumpSlider(tester, intensity: 3, onChanged: (_) {});

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(
        slider.value,
        equals(3.0),
        reason: 'Slider.value must reflect the intensity input',
      );
      expect(slider.min, equals(1.0));
      expect(slider.max, equals(5.0));
      expect(slider.divisions, equals(4));
    });

    testWidgets('host widget is at least 48dp tall (Lin US-Lin-3)', (
      tester,
    ) async {
      await _pumpSlider(tester, intensity: 3, onChanged: (_) {});

      final size = tester.getSize(find.byType(IntensitySlider));
      expect(
        size.height,
        greaterThanOrEqualTo(48),
        reason:
            'IntensitySlider host must meet Material 48dp tap-target minimum',
      );
    });

    testWidgets('drag emits an integer value greater than the start value', (
      tester,
    ) async {
      int? lastEmitted;
      await _pumpSlider(
        tester,
        intensity: 1,
        onChanged: (v) => lastEmitted = v,
      );

      // Drag toward the right end of the track.
      await tester.drag(find.byType(Slider), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(
        lastEmitted,
        isNotNull,
        reason: 'a horizontal drag must produce at least one emission',
      );
      // Slider geometry varies with surface size; assert "moved up" rather
      // than equality so we stay robust to layout changes.
      expect(lastEmitted!, greaterThanOrEqualTo(2));
      expect(lastEmitted!, lessThanOrEqualTo(5));
    });

    testWidgets('Semantics value reads "<n> of 5"', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _pumpSlider(tester, intensity: 4, onChanged: (_) {});

        // The Semantics(slider: true, value: '4 of 5') node lives one level
        // above the underlying Material Slider. Reading via the
        // IntensitySlider root walks down the merged semantics tree, which
        // already includes the slider's own announcement - assert the
        // substring is present.
        final node = tester.getSemantics(find.byType(IntensitySlider));
        expect(
          node.value,
          contains('4 of 5'),
          reason:
              'Semantics value must announce the discrete intensity for '
              'screen readers',
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
