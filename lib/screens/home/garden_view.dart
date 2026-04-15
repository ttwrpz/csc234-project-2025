import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mood_type.dart';
import '../../providers/garden_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/garden_plant.dart';
import '../../widgets/garden_bug.dart';
import '../../widgets/garden_ground.dart';

class GardenView extends StatefulWidget {
  const GardenView({super.key});

  @override
  State<GardenView> createState() => _GardenViewState();
}

class _GardenViewState extends State<GardenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.darkMode;

    // Sort by Y position for depth (items lower = rendered later = in front)
    final sortedElements = List.of(garden.elements)
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Sky-to-ground gradient background
              GardenBackground(isDarkMode: isDark),

              // Drifting clouds
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  final t = _ambientController.value;
                  return Stack(
                    children: [
                      _buildCloud(
                        constraints,
                        t,
                        baseX: 0.08,
                        baseY: 0.05,
                        size: 22,
                        speed: 0.3,
                        alpha: isDark ? 0.3 : 0.7,
                      ),
                      _buildCloud(
                        constraints,
                        t,
                        baseX: 0.42,
                        baseY: 0.12,
                        size: 28,
                        speed: 0.2,
                        alpha: isDark ? 0.2 : 0.5,
                      ),
                      _buildCloud(
                        constraints,
                        t,
                        baseX: 0.75,
                        baseY: 0.04,
                        size: 20,
                        speed: 0.25,
                        alpha: isDark ? 0.25 : 0.6,
                      ),
                    ],
                  );
                },
              ),

              // Sun/moon with glow
              Positioned(
                top: 10,
                right: 14,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFFB0C4DE).withValues(alpha: 0.3)
                            : const Color(0xFFFFE082).withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isDark ? '\u{1F319}' : '\u{2600}\u{FE0F}',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),

              // Soil strip at bottom
              GardenSoil(isDarkMode: isDark),

              // Ground grass detail
              ..._buildGrassDetails(constraints),

              // Garden elements (depth-sorted)
              ...sortedElements.map((element) {
                final isNegative =
                    element.moodType.category == MoodCategory.negative;
                final isNeutral =
                    element.moodType.category == MoodCategory.neutral;

                Widget child;
                if (isNegative) {
                  child = GardenBugWidget(
                    element: element,
                    animationSpeed: settings.animationSpeed,
                  );
                } else if (isNeutral) {
                  child = _NeutralLeafWidget(element: element);
                } else {
                  child = GardenPlantWidget(element: element);
                }

                return Positioned(
                  key: ValueKey(element.id),
                  left: element.position.dx * constraints.maxWidth -
                      element.size / 2,
                  top: element.position.dy * constraints.maxHeight -
                      element.size / 2,
                  child: child,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCloud(
    BoxConstraints constraints,
    double t, {
    required double baseX,
    required double baseY,
    required double size,
    required double speed,
    required double alpha,
  }) {
    final dx = sin(t * 2 * pi * speed) * constraints.maxWidth * 0.03;
    return Positioned(
      left: baseX * constraints.maxWidth + dx,
      top: baseY * constraints.maxHeight,
      child: Opacity(
        opacity: alpha,
        child: Text('\u{2601}\u{FE0F}', style: TextStyle(fontSize: size)),
      ),
    );
  }

  List<Widget> _buildGrassDetails(BoxConstraints constraints) {
    const grassEmojis = ['\u{1F33F}', '\u{1F331}', '\u{2618}\u{FE0F}'];
    return List.generate(8, (i) {
      final r = Random(i * 7 + 3);
      return Positioned(
        bottom: r.nextDouble() * constraints.maxHeight * 0.06,
        left: (i / 8) * constraints.maxWidth +
            r.nextDouble() * (constraints.maxWidth / 8),
        child: Opacity(
          opacity: 0.35 + r.nextDouble() * 0.25,
          child: Text(
            grassEmojis[i % 3],
            style: TextStyle(fontSize: 12 + r.nextDouble() * 6),
          ),
        ),
      );
    });
  }
}

class _NeutralLeafWidget extends StatefulWidget {
  final GardenElement element;

  const _NeutralLeafWidget({required this.element});

  @override
  State<_NeutralLeafWidget> createState() => _NeutralLeafWidgetState();
}

class _NeutralLeafWidgetState extends State<_NeutralLeafWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _phase;

  @override
  void initState() {
    super.initState();
    _phase = (widget.element.id.hashCode.abs() % 1000) / 1000.0;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500 + (_phase * 1500).round()),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value + _phase) % 1.0;
        final floatY = sin(t * 2 * pi) * 3;
        final rotate = sin(t * 2 * pi) * 0.08;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.rotate(angle: rotate, child: child),
        );
      },
      child: Container(
        width: size * 0.8,
        height: size * 0.8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF8E8E93).withValues(alpha: 0.25),
        ),
        child: Center(
          child: Text(
            widget.element.moodType.gardenEmoji,
            style: TextStyle(fontSize: size * 0.45),
          ),
        ),
      ),
    );
  }
}
