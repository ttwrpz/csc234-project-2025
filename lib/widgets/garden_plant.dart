import 'package:flutter/material.dart';
import '../models/mood_type.dart';
import '../providers/garden_provider.dart';

class GardenPlantWidget extends StatefulWidget {
  final GardenElement element;

  const GardenPlantWidget({super.key, required this.element});

  @override
  State<GardenPlantWidget> createState() => _GardenPlantWidgetState();
}

class _GardenPlantWidgetState extends State<GardenPlantWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final double _phase;

  @override
  void initState() {
    super.initState();
    _phase = (widget.element.id.hashCode.abs() % 1000) / 1000.0;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    // Delay growth animation based on element position for staggered effect
    Future.delayed(Duration(milliseconds: (_phase * 600).round()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.element.moodType;
    final size = widget.element.size;
    final colors = _getPlantColors(mood);

    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: size * 1.2,
        height: size * 1.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flower head
            _FlowerHead(
              mood: mood,
              size: size,
              petalColor: colors.petal,
              centerColor: colors.center,
            ),
            // Stem
            Container(
              width: 3,
              height: size * 0.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6B9F7A),
                    const Color(0xFF4A7C59),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _PlantColors _getPlantColors(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return _PlantColors(
          petal: const Color(0xFFFFD93D),
          center: const Color(0xFF8B6914),
        );
      case MoodType.calm:
        return _PlantColors(
          petal: const Color(0xFFB8A9E0),
          center: const Color(0xFF7B68AE),
        );
      case MoodType.grateful:
        return _PlantColors(
          petal: const Color(0xFFF4A0B0),
          center: const Color(0xFFC27A8A),
        );
      case MoodType.excited:
        return _PlantColors(
          petal: const Color(0xFFFF6B6B),
          center: const Color(0xFFCC4444),
        );
      case MoodType.loved:
        return _PlantColors(
          petal: const Color(0xFFFFB7C5),
          center: const Color(0xFFFF85A2),
        );
      default:
        return _PlantColors(
          petal: const Color(0xFF6B9F7A),
          center: const Color(0xFF4A7C59),
        );
    }
  }
}

class _PlantColors {
  final Color petal;
  final Color center;
  _PlantColors({required this.petal, required this.center});
}

class _FlowerHead extends StatelessWidget {
  final MoodType mood;
  final double size;
  final Color petalColor;
  final Color centerColor;

  const _FlowerHead({
    required this.mood,
    required this.size,
    required this.petalColor,
    required this.centerColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.2,
      height: size * 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Petal container with gradient
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: _getShape(),
              gradient: RadialGradient(
                colors: [
                  petalColor,
                  petalColor.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: petalColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Center with emoji
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: centerColor,
            ),
            child: Center(
              child: Text(
                mood.emoji,
                style: TextStyle(fontSize: size * 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxShape _getShape() {
    // All use circle for simplicity; differentiation comes from colors/gradients
    return BoxShape.circle;
  }
}
