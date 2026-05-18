import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Self-initiated entry point to the 2-minute breathing screen. Standalone
/// pill so the home page can place it where it fits — between the
/// SkyHeader and the DailyScoreStrip on phone, and at the foot of the
/// right column on tablet / desktop.
class TakeABreathButton extends StatelessWidget {
  const TakeABreathButton({super.key, this.expand = false});

  /// Stretches the pill to fill its parent's width — used inline on
  /// phone where the parent is a column-stretched stack.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFFFE7BD) : const Color(0xFF8A5A1F);
    final bg = isDark
        ? const Color(0xFFFFE7BD).withValues(alpha: 0.18)
        : const Color(0xFFFFE7BD).withValues(alpha: 0.55);
    final border = isDark
        ? const Color(0xFFFFE7BD).withValues(alpha: 0.45)
        : const Color(0xFF8A5A1F).withValues(alpha: 0.25);

    final button = Semantics(
      button: true,
      label: 'Take a 2-minute breath',
      child: TextButton.icon(
        onPressed: () => context.pushNamed('intervention.breathing'),
        style: TextButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
            side: BorderSide(color: border),
          ),
        ),
        icon: Icon(Icons.air_outlined, size: 18, color: fg),
        label: Text(
          'Take a breath',
          style: MbFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
