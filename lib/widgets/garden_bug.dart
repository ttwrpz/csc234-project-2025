import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/garden_provider.dart';

class GardenBugWidget extends StatefulWidget {
  final GardenElement element;
  final double animationSpeed;

  const GardenBugWidget({
    super.key,
    required this.element,
    this.animationSpeed = 2.0,
  });

  @override
  State<GardenBugWidget> createState() => _GardenBugWidgetState();
}

class _GardenBugWidgetState extends State<GardenBugWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _phase;

  @override
  void initState() {
    super.initState();
    _phase = (widget.element.id.hashCode.abs() % 1000) / 1000.0;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 1500 + (_phase * 1000).round(),
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
    final size = widget.element.size;
    final opacity = widget.element.opacity;

    return AnimatedOpacity(
      duration: const Duration(seconds: 2),
      opacity: opacity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = (_controller.value + _phase) % 1.0;
          final bobY = sin(t * 2 * pi) * 4;
          final driftX = sin(t * pi + 0.5) * 3;

          return Transform.translate(
            offset: Offset(driftX, bobY),
            child: child,
          );
        },
        child: Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3D2B2B).withValues(alpha: 0.85),
            border: Border.all(
              color: const Color(0xFF6B3333).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.element.moodType.gardenEmoji,
              style: TextStyle(fontSize: size * 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
