import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../disclaimer/presentation/widgets/disclaimer_panel.dart';
import 'widgets/onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  /// Onboarding deck — 4 slides. The 3 art-driven slides keep their
  /// original copy; the new "A note about MoodBloom" disclaimer slide
  /// (S5 feature 7.4 — pulled forward) sits second-to-last so the
  /// existing "Watch patterns emerge" + "Get started" CTA remains the
  /// user's last touch.
  static const _slideKinds = <_SlideKind>[
    _SlideKind.gardenScene,
    _SlideKind.logEntry,
    _SlideKind.disclaimer,
    _SlideKind.patterns,
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    if (_index == _slideKinds.length - 1) {
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
    final isLast = _index == _slideKinds.length - 1;
    final isFirst = _index == 0;

    return Scaffold(
      backgroundColor: mb.bg,
      // Centred column with a fixed max width so the carousel doesn't
      // stretch across a desktop viewport (which previously pushed the
      // bottom button row off-screen on tall windows). 480 dp matches
      // the carousel art's natural reading width.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slideKinds.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _buildSlide(_slideKinds[i]),
                    ),
                  ),
                  _Dots(count: _slideKinds.length, activeIndex: _index),
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
                          // The Get-started CTA is the only entry-point on
                          // the final slide — make it visually unmistakable
                          // even when the user is on a small phone. Add a
                          // forward arrow so it reads as "go".
                          leading: isLast
                              ? const Icon(Icons.arrow_forward, size: 18)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Skip on slides 0/1 lets the user bail early; on the last
                  // slide the same slot becomes a "I'm ready" reinforcement
                  // — same destination, redundant CTA, but it removes any
                  // ambiguity about how to leave the carousel.
                  TextButton(
                    onPressed: _complete,
                    style: TextButton.styleFrom(
                      foregroundColor: mb.textDim,
                      textStyle: MbFonts.nunito(fontSize: 13),
                    ),
                    child: Text(isLast ? "I'm ready" : 'Skip'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the slide widget for the given kind. The 3 art-driven
  /// slides reuse the existing `OnboardingSlide` widget; the disclaimer
  /// slide composes a similar layout (Fraunces title + body content +
  /// dim Nunito caption) but swaps the inline brand art for a
  /// [DisclaimerPanel].
  Widget _buildSlide(_SlideKind kind) {
    switch (kind) {
      case _SlideKind.gardenScene:
        return OnboardingSlide(
          art: _buildArt(kind),
          title: 'Meet your garden',
          body:
              'Your feelings become a living scene. Nothing to fix — just to '
              'notice.',
        );
      case _SlideKind.logEntry:
        return OnboardingSlide(
          art: _buildArt(kind),
          title: 'Log how you feel',
          body:
              'Pick a mood, slide the intensity, and write as much or as '
              'little as you want.',
        );
      case _SlideKind.patterns:
        return OnboardingSlide(
          art: _buildArt(kind),
          title: 'Watch patterns emerge',
          body:
              'Over time, gentle insights appear. Your history is safe, '
              'private, and yours.',
        );
      case _SlideKind.disclaimer:
        return const _DisclaimerSlide();
    }
  }

  Widget _buildArt(_SlideKind kind) {
    return SizedBox(
      width: 220,
      height: 170,
      child: CustomPaint(painter: _OnboardingArtPainter(kind)),
    );
  }
}

/// Carousel slide kinds. Names match the painter cases for the
/// art-driven slides; `disclaimer` has no painter case (it renders a
/// `DisclaimerPanel` instead) — the painter switch's default branch
/// handles that.
enum _SlideKind { gardenScene, logEntry, patterns, disclaimer }

/// Custom slide for the bipolar / medical disclaimer (S5 feature 7.4 —
/// pulled forward). Mirrors `OnboardingSlide`'s typography (Fraunces 26
/// title + Nunito 13 dim caption) so the carousel feels consistent;
/// swaps the inline brand art for a [DisclaimerPanel] containing
/// [DisclaimerCopy.full] + a small medical icon.
///
/// The slide does NOT call `disclaimerRepository.ack()` automatically.
/// The ack-tracking flag (`users/{uid}.insightsDisclaimerAcked`) flips
/// only when the user taps "I understand" in the (S5) Insights ack
/// dialog. Swiping past this slide is fine — onboarding completion is
/// a separate concern.
class _DisclaimerSlide extends StatelessWidget {
  const _DisclaimerSlide();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Semantics(
      label: 'A note about MoodBloom',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A note about MoodBloom',
              style: MbFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            const DisclaimerPanel(),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                "You'll see this again any time you visit Settings → About.",
                style: MbFonts.nunito(
                  fontSize: 13,
                  height: 1.5,
                  color: mb.textDim,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

/// Inline brand art for the three art-driven onboarding slides.
/// Transcribed from the React prototype's SVGs (`screens.jsx` lines
/// 1–93). The viewBox is 200×160 so we paint into a 220×170 canvas and
/// scale uniformly. The `disclaimer` slide has no painter case — it
/// composes a `DisclaimerPanel` instead.
class _OnboardingArtPainter extends CustomPainter {
  _OnboardingArtPainter(this.kind);

  final _SlideKind kind;

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
      case _SlideKind.gardenScene:
        _paintGarden(canvas);
      case _SlideKind.logEntry:
        _paintLogEntry(canvas);
      case _SlideKind.patterns:
        _paintPatterns(canvas);
      case _SlideKind.disclaimer:
        // No painter — `_DisclaimerSlide` renders its own content and
        // never instantiates this painter. The case is here so the
        // exhaustive switch passes the analyser.
        break;
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
