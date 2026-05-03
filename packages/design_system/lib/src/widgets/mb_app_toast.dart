import 'mb_fonts.dart';
import 'dart:async';
import 'dart:ui';

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
    final overlay = Overlay.of(context);
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(245, 34, 48, 63),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4A78C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child:
                            leadingIcon ??
                            const Text('🌸', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: MbFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: MbFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(0xE6), // 90% white
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
      top: 54 + mediaQuery.padding.top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: FadeTransition(opacity: _controller, child: widget.child),
      ),
    );
  }
}
