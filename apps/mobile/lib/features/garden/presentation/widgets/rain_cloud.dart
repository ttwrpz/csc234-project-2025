import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One rain-cloud glyph in the garden canvas, used for negative moods at
/// intensity 4–5 (per ADR-0006). Self-fades over 15–25 seconds without any
/// user action — US-Som-1's "no user dismiss" criterion. Fade duration is
/// deterministic per [entryId] so goldens (with [animate] set to `false`)
/// produce stable images and the animation lifecycle never touches
/// Firestore or Drift.
///
/// Animation lifecycle is purely visual sugar. If the user navigates away
/// and back, the cloud restarts at full opacity — the underlying entry
/// stays in history; the cloud is a rolling visualisation of recency.
///
/// Decorative; the surrounding canvas exposes one aggregate Semantics
/// label, so individual clouds are excluded from the a11y tree.
class RainCloud extends StatefulWidget {
  const RainCloud({
    super.key,
    required this.entryId,
    this.size = _defaultSize,
    this.animate = true,
  });

  /// Stable identifier of the underlying [MoodEntry]. Used as the seed for
  /// the per-cloud fade duration, so the same cloud renders with the same
  /// timing on every build.
  final String entryId;
  final double size;

  /// When `false`, skips the [AnimationController] so the cloud renders at
  /// full opacity. Two callers use this:
  ///   * Golden tests, to freeze the silhouette at a deterministic frame.
  ///   * `_GardenCanvas`, beyond the visible-cloud cap, to keep the
  ///     controller budget bounded on long histories (per ADR-0006
  ///     §performance).
  final bool animate;

  static const double _defaultSize = 28;

  @override
  State<RainCloud> createState() => _RainCloudState();
}

class _RainCloudState extends State<RainCloud>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      // 15..25 seconds inclusive, deterministic per entry id. The
      // controller drives a single forward run; `onComplete` keeps the
      // widget at opacity 0 so the cloud "stays gone" for the rest of
      // the screen's lifetime.
      final ms = 15000 + (widget.entryId.hashCode.abs() % 11) * 1000;
      _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: ms),
      );
      _opacity = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOut));
      _controller!.forward();
    } else {
      // Static rendering — no controller, no listeners. Always renders
      // at the cloud's start-of-life opacity.
      _opacity = const AlwaysStoppedAnimation<double>(1.0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) => Opacity(
          opacity: _opacity.value,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Icon(
                  Icons.cloud,
                  color: MoodBloomColors.moodAnxious,
                  size: size * 0.85,
                ),
                Positioned(
                  bottom: 0,
                  left: size * 0.18,
                  child: _RainStreak(width: size * 0.08, height: size * 0.28),
                ),
                Positioned(
                  bottom: 0,
                  child: _RainStreak(width: size * 0.08, height: size * 0.34),
                ),
                Positioned(
                  bottom: 0,
                  right: size * 0.18,
                  child: _RainStreak(width: size * 0.08, height: size * 0.28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RainStreak extends StatelessWidget {
  const _RainStreak({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MoodBloomColors.moodAnxious.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}
