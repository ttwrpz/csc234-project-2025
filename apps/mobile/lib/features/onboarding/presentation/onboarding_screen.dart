import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_SlideData>[
    _SlideData(
      art: _OnboardingArt.gardenScene,
      title: 'Meet your garden',
      body:
          'Your feelings become a living scene. Nothing to fix — just to '
          'notice.',
    ),
    _SlideData(
      art: _OnboardingArt.logEntry,
      title: 'Log how you feel',
      body:
          'Pick a mood, slide the intensity, and write as much or as little '
          'as you want.',
    ),
    _SlideData(
      art: _OnboardingArt.patterns,
      title: 'Watch patterns emerge',
      body:
          'Over time, gentle insights appear. Your history is safe, '
          'private, and yours.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _complete();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isLast = _index == _slides.length - 1;
    final isFirst = _index == 0;

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final s = _slides[i];
                    return OnboardingSlide(
                      art: _buildArt(s.art),
                      title: s.title,
                      body: s.body,
                    );
                  },
                ),
              ),
              _Dots(count: _slides.length, activeIndex: _index),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!isFirst) ...[
                    MbGhostButton(
                      label: 'Back',
                      onPressed: _back,
                      fullWidth: false,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: MbPrimaryButton(
                      label: isLast ? 'Get started' : 'Next',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _complete,
                  style: TextButton.styleFrom(
                    foregroundColor: mb.textDim,
                    textStyle: MbFonts.nunito(fontSize: 13),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArt(_OnboardingArt art) {
    return SizedBox(
      width: 220,
      height: 170,
      child: CustomPaint(painter: _OnboardingArtPainter(art)),
    );
  }
}

enum _OnboardingArt { gardenScene, logEntry, patterns }

class _SlideData {
  const _SlideData({
    required this.art,
    required this.title,
    required this.body,
  });
  final _OnboardingArt art;
  final String title;
  final String body;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});
  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 22 : 6,
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary
                : Colors.black.withAlpha(0x1F), // ~12%
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

/// Inline brand art for the three onboarding slides. Transcribed from the
/// React prototype's SVGs (`screens.jsx` lines 1–93). The viewBox is 200×160
/// so we paint into a 220×170 canvas and scale uniformly.
class _OnboardingArtPainter extends CustomPainter {
  _OnboardingArtPainter(this.kind);

  final _OnboardingArt kind;

  // Palette mirrors `data.jsx` PALETTE constants used in the prototype.
  static const _skyTop = Color(0xFFFFE4D1);
  static const _skyBot = Color(0xFFE8F3ED);
  static const _ground = Color(0xFF8FBFA3);
  static const _stem = Color(0xFF4C8B6A);
  static const _amber = Color(0xFFE8A23B);
  static const _coral = Color(0xFFE77A8C);
  static const _yellow = Color(0xFFF6C45A);
  static const _peach = Color(0xFFF6A86B);
  static const _primary = Color(0xFF2E7D5B);
  static const _line = Color(0xFFD6DDE4);

  @override
  void paint(Canvas canvas, Size size) {
    // Map the prototype's 200×160 viewBox onto the canvas.
    canvas.save();
    canvas.scale(size.width / 200, size.height / 160);

    switch (kind) {
      case _OnboardingArt.gardenScene:
        _paintGarden(canvas);
      case _OnboardingArt.logEntry:
        _paintLogEntry(canvas);
      case _OnboardingArt.patterns:
        _paintPatterns(canvas);
    }
    canvas.restore();
  }

  void _paintGarden(Canvas canvas) {
    // Backdrop with rounded corners + sky gradient.
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 200, 160),
      const Radius.circular(18),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyBot],
      ).createShader(const Rect.fromLTWH(0, 0, 200, 160));
    canvas.drawRRect(bgRect, bgPaint);

    // Sun.
    canvas.drawCircle(
      const Offset(160, 36),
      18,
      Paint()..color = _yellow.withAlpha(0xCC), // 0.8 opacity
    );

    // Ground (filled curve from x=0 to x=200).
    final ground = Path()
      ..moveTo(0, 130)
      ..cubicTo(60, 110, 140, 140, 200, 120)
      ..lineTo(200, 160)
      ..lineTo(0, 160)
      ..close();
    canvas.drawPath(ground, Paint()..color = _ground);

    // Coral flower (50, 120).
    final stemPaint = Paint()
      ..color = _stem
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(50, 120), const Offset(50, 150), stemPaint);
    canvas.drawCircle(const Offset(50, 120), 10, Paint()..color = _coral);
    canvas.drawCircle(const Offset(50, 120), 4, Paint()..color = _yellow);

    // Yellow sunflower (110, 110).
    canvas.drawLine(const Offset(110, 110), const Offset(110, 150), stemPaint);
    canvas.drawCircle(const Offset(110, 110), 12, Paint()..color = _yellow);
    canvas.drawCircle(const Offset(110, 110), 5, Paint()..color = _amber);

    // Peach bud (150, 125).
    canvas.drawLine(const Offset(150, 125), const Offset(150, 150), stemPaint);
    canvas.drawCircle(const Offset(150, 125), 8, Paint()..color = _peach);
  }

  void _paintLogEntry(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 200, 160),
        const Radius.circular(18),
      ),
      Paint()..color = _skyBot,
    );

    // Top "mood" card (white).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 30, 160, 40),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(40, 50), 10, Paint()..color = _yellow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 44, 80, 6),
        const Radius.circular(3),
      ),
      Paint()..color = _line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 54, 50, 6),
        const Radius.circular(3),
      ),
      Paint()..color = _line,
    );

    // Slider track + filled portion + knob.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 84, 160, 8),
        const Radius.circular(4),
      ),
      Paint()..color = _line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 84, 110, 8),
        const Radius.circular(4),
      ),
      Paint()..color = _primary,
    );
    canvas.drawCircle(const Offset(130, 88), 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(130, 88),
      9,
      Paint()
        ..color = _primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Note card.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 108, 160, 34),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 118, 100, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = _line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 128, 60, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = _line,
    );
  }

  void _paintPatterns(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 200, 160),
        const Radius.circular(18),
      ),
      Paint()..color = _skyTop,
    );

    // Trend polyline.
    final points = const <Offset>[
      Offset(20, 110),
      Offset(50, 80),
      Offset(75, 95),
      Offset(105, 55),
      Offset(135, 70),
      Offset(170, 40),
    ];
    final linePaint = Paint()
      ..color = _primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);
    final dotPaint = Paint()..color = _primary;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }

    // Pill summary.
    final pill = Paint()..color = Colors.white.withAlpha(0xCC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 125, 160, 20),
        const Radius.circular(8),
      ),
      pill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 132, 80, 6),
        const Radius.circular(3),
      ),
      Paint()..color = _primary,
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingArtPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
