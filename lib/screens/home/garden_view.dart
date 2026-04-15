import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/garden_element.dart';

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

    // Sort by Y position for depth (items lower = rendered later = in front)
    final sortedElements = List.of(garden.elements)
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Sky-to-ground gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.3, 0.5, 0.75, 1.0],
                    colors: [
                      Color(0xFFD6E8F8), // Soft sky blue
                      Color(0xFFE0EFE0), // Sky-ground transition
                      Color(0xFFD4E8C4), // Light meadow
                      Color(0xFFB8D9A0), // Mid green
                      Color(0xFF94C47A), // Rich ground
                    ],
                  ),
                ),
              ),

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
                        alpha: 0.7,
                      ),
                      _buildCloud(
                        constraints,
                        t,
                        baseX: 0.42,
                        baseY: 0.12,
                        size: 28,
                        speed: 0.2,
                        alpha: 0.5,
                      ),
                      _buildCloud(
                        constraints,
                        t,
                        baseX: 0.75,
                        baseY: 0.04,
                        size: 20,
                        speed: 0.25,
                        alpha: 0.6,
                      ),
                    ],
                  );
                },
              ),

              // Sun with warm glow
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
                        color: const Color(0xFFFFE082).withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '\u{2600}\u{FE0F}',
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),

              // Ground grass detail
              ..._buildGrassDetails(constraints),

              // Garden elements (depth-sorted)
              ...sortedElements.map((element) {
                return Positioned(
                  key: ValueKey(element.id),
                  left:
                      element.position.dx * constraints.maxWidth -
                      element.size / 2,
                  top:
                      element.position.dy * constraints.maxHeight -
                      element.size / 2,
                  child: GardenElementWidget(element: element),
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
        left:
            (i / 8) * constraints.maxWidth +
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
