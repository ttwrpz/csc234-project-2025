import 'dart:math';
import 'package:flutter/material.dart';

class SuccessAnimation extends StatefulWidget {
  final VoidCallback onComplete;

  const SuccessAnimation({super.key, required this.onComplete});

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _particleController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Main bloom animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Generate particles
    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        angle: (i / 12) * 2 * pi + rng.nextDouble() * 0.3,
        distance: 60 + rng.nextDouble() * 40,
        size: 6 + rng.nextDouble() * 8,
        color: _particleColors[i % _particleColors.length],
      ));
    }

    _scaleController.forward();
    _particleController.forward();

    // Complete after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) widget.onComplete();
    });
  }

  static const _particleColors = [
    Color(0xFFFFD93D),
    Color(0xFF6B9F7A),
    Color(0xFFC27A8A),
    Color(0xFFE8B954),
    Color(0xFFFF85A2),
    Color(0xFF9DB4C0),
  ];

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _particleController]),
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Particles
                ..._particles.map((p) {
                  final progress = _particleController.value;
                  final dx = cos(p.angle) * p.distance * progress;
                  final dy = sin(p.angle) * p.distance * progress;
                  final opacity = (1.0 - progress).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.color,
                        ),
                      ),
                    ),
                  );
                }),

                // Checkmark circle
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),

                // Bloom emoji
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value * 0.8,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Text(
                        'Mood saved!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}

Future<void> showSuccessAnimation(BuildContext context) async {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => SuccessAnimation(
      onComplete: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}
