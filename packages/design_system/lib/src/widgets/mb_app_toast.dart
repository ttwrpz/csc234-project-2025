import 'mb_fonts.dart';
import 'mb_svg.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Top-anchored dark-glass toast with the MoodBloom brand chip in the
/// header row. Slides in from above, auto-dismisses after 5 seconds, and
/// can be invoked imperatively via [MbAppToast.show].
class MbAppToast extends StatelessWidget {
  const MbAppToast({
    super.key,
    required this.title,
    required this.body,
    this.leadingIcon,
    this.onDismiss,
  });

  final String title;
  final String body;
  final Widget? leadingIcon;
  final VoidCallback? onDismiss;

  /// Inserts a toast as an `OverlayEntry` and removes it after 5 seconds (or
  /// when the user taps it). Safe to call from any widget that can resolve
  /// an `Overlay`.
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    Widget? leadingIcon,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Root overlay so the toast survives a route change - e.g. saving a
    // mood shows the toast then navigates to /home; the toast should
    // float over the destination, not vanish with the source route.
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    var dismissed = false;
    void dismiss() {
      if (dismissed) return;
      dismissed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (ctx) => _AnimatedToast(
        onDismiss: dismiss,
        duration: duration,
        child: MbAppToast(
          title: title,
          body: body,
          leadingIcon: leadingIcon,
          onDismiss: dismiss,
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onDismiss,
        child: DecoratedBox(
          // Soft drop shadow per the prototype (0 12px 30px rgba black .3).
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            // On web, CanvasKit leaks an offscreen WebGL surface per
            // BackdropFilter across hot restarts ("Too many active WebGL
            // contexts"). The glass fill is already 92% opaque, so drop the
            // blur on web and keep it only on native.
            child: _MaybeBlur(
              blur: !kIsWeb,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Near-black glass (rgba 20,24,30,0.92) per prototype.
                  color: const Color.fromARGB(235, 20, 24, 30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 26,
                      width: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4A78C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child:
                          leadingIcon ??
                          const MbBrandSvg(size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: MbFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: MbFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(0xD9), // 85%
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] in a [BackdropFilter] blur only when [blur] is true.
/// Lets the toast keep its frosted glass on native while skipping the
/// extra offscreen WebGL surface on web.
class _MaybeBlur extends StatelessWidget {
  const _MaybeBlur({required this.blur, required this.child});

  final bool blur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!blur) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: child,
    );
  }
}

class _AnimatedToast extends StatefulWidget {
  const _AnimatedToast({
    required this.child,
    required this.onDismiss,
    required this.duration,
  });

  final Widget child;
  final VoidCallback onDismiss;
  final Duration duration;

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoDismiss = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Positioned(
      top: 16 + mediaQuery.padding.top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: _controller,
          // Centered, capped at 360 dp per the prototype's ToastFrame.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
