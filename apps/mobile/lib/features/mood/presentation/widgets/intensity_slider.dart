import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/mood_type.dart';
import 'mood_kind_adapter.dart';

/// 1..5 discrete slider, restyled per the Sprint 2 Prototype:
///  - filled track gradient `mood.color@33 → mood.color`
///  - knob 22 dp white circle with 2 px primary border + soft drop shadow
///  - 48 dp tap-target host
///
/// On Android (non-Web) physical devices, fires
/// [HapticFeedback.selectionClick] when the rounded value transitions to a
/// new integer. Web has no haptic; iOS is out of scope this sprint.
class IntensitySlider extends StatelessWidget {
  const IntensitySlider({
    super.key,
    required this.intensity,
    required this.onChanged,
    this.mood,
  });

  final int intensity;
  final ValueChanged<int> onChanged;

  /// Active mood used to tint the slider's filled track. Falls back to the
  /// theme primary so the slider still looks intentional before the user has
  /// picked a mood.
  final MoodType? mood;

  static bool get _hapticEnabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final palette = theme.extension<MbMoodPalette>()!;
    final tint = mood == null
        ? theme.colorScheme.primary
        : palette.colorOf(mood!.mbKind);

    return Semantics(
      slider: true,
      value: '$intensity of 5',
      child: SizedBox(
        height: 56,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: tint,
            inactiveTrackColor: mb.line,
            // SliderThemeData's `thumbColor` is overridden by the painter
            // below; keep it set so the default fallback still uses white.
            thumbColor: Colors.white,
            overlayColor: tint.withAlpha(0x22),
            valueIndicatorColor: tint,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            thumbShape: _RingedThumbShape(
              radius: 11,
              borderColor: theme.colorScheme.primary,
              borderWidth: 2,
              elevation: 2,
            ),
          ),
          child: Slider(
            min: 1,
            max: 5,
            divisions: 4,
            value: intensity.toDouble(),
            label: '$intensity',
            onChanged: (raw) {
              final next = raw.round();
              if (next == intensity) return;
              if (_hapticEnabled) {
                HapticFeedback.selectionClick();
              }
              onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

/// White-fill thumb with a primary stroke and a soft drop shadow.
class _RingedThumbShape extends SliderComponentShape {
  const _RingedThumbShape({
    required this.radius,
    required this.borderColor,
    required this.borderWidth,
    required this.elevation,
  });

  final double radius;
  final Color borderColor;
  final double borderWidth;
  final double elevation;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final shadow = Paint()
      ..color = Colors.black.withAlpha(0x33)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation);
    canvas.drawCircle(center.translate(0, 1.5), radius, shadow);
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius - borderWidth / 2,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }
}
