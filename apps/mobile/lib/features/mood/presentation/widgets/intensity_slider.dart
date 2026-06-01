import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/mood_type.dart';
import 'mood_kind_adapter.dart';

/// 1..5 discrete slider matching the v1.6 prototype's `IntensitySlider`:
///  - rail 6 dp `mb.line`; filled portion = selected mood color (or seed
///    when nothing is picked yet)
///  - 5 small (4 dp) tick circles at the 1..5 stop positions
///  - thumb is a 24 dp white circle with a 3 dp colored border
///  - 48 dp tap-target host (Material accessibility minimum)
///
/// On Android (non-Web) physical devices, fires
/// [HapticFeedback.selectionClick] when the rounded value transitions to a
/// new integer. Web has no haptic; iOS is out of scope.
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
  /// theme primary (`MoodBloomColors.seed`) so the slider still looks
  /// intentional before the user has picked a mood.
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
        height: 48,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: tint,
            inactiveTrackColor: mb.line,
            // SliderThemeData's `thumbColor` is overridden by the painter
            // below; keep it set so the default fallback still uses white.
            thumbColor: Colors.white,
            overlayColor: tint.withAlpha(0x22),
            valueIndicatorColor: tint,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            thumbShape: _RingedThumbShape(
              radius: 12,
              borderColor: tint,
              borderWidth: 3,
              elevation: 2,
            ),
            // Hide the default divider ticks - we paint our own 4 dp dots
            // on top in `_TickOverlay`.
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Slider(
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
              // Tick overlay sits on top of the slider so the white dots
              // float on the rail. IgnorePointer so the slider still
              // receives every drag.
              IgnorePointer(child: _TickOverlay(intensity: intensity)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Five 4-dp tick dots painted over the slider rail at the 1..5 stop
/// positions. Filled ticks (≤ current intensity) are white at 85% opacity;
/// unfilled ticks are `mb.textDim` at 45% opacity, matching the prototype.
class _TickOverlay extends StatelessWidget {
  const _TickOverlay({required this.intensity});

  final int intensity;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Mirror the Material Slider's default horizontal padding so our
        // tick positions line up with the thumb track's 1..5 stops.
        const inset = 24.0;
        final railWidth = width - inset * 2;
        if (railWidth <= 0) return const SizedBox.shrink();
        return Stack(
          children: [
            for (var i = 1; i <= 5; i++)
              Positioned(
                left: inset + railWidth * (i - 1) / 4 - 2,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= intensity
                          ? Colors.white.withAlpha(0xD9)
                          : mb.textDim.withAlpha(0x73),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// White-fill thumb with a colored stroke and a soft drop shadow.
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
