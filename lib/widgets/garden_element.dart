import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mood_type.dart';
import '../providers/garden_provider.dart';

class GardenElementWidget extends StatefulWidget {
  final GardenElement element;

  const GardenElementWidget({super.key, required this.element});

  @override
  State<GardenElementWidget> createState() => _GardenElementWidgetState();
}

class _GardenElementWidgetState extends State<GardenElementWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _phase;

  @override
  void initState() {
    super.initState();
    // Unique phase per element so animations don't sync
    _phase = (widget.element.id.hashCode.abs() % 1000) / 1000.0;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.element.isBug
            ? 1500 + (_phase * 1000).round()
            : 2500 + (_phase * 1500).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: widget.element.opacity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = (_controller.value + _phase) % 1.0;

          if (widget.element.isBug) {
            // Bugs: bob up/down and drift side to side
            final bobY = sin(t * 2 * pi) * 5;
            final driftX = sin(t * pi + 0.5) * 3;
            return Transform.translate(
              offset: Offset(driftX, bobY),
              child: child,
            );
          } else if (widget.element.moodType.category == MoodCategory.neutral) {
            // Neutral (leaf): gentle float and rotate
            final floatY = sin(t * 2 * pi) * 3;
            final rotate = sin(t * 2 * pi) * 0.08;
            return Transform.translate(
              offset: Offset(0, floatY),
              child: Transform.rotate(angle: rotate, child: child),
            );
          } else {
            // Positive (flowers): gentle sway from base
            final sway = sin(t * 2 * pi) * 0.06;
            return Transform.rotate(
              angle: sway,
              alignment: Alignment.bottomCenter,
              child: child,
            );
          }
        },
        child: Text(
          widget.element.moodType.gardenEmoji,
          style: TextStyle(fontSize: widget.element.size),
        ),
      ),
    );
  }
}
