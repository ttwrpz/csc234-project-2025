import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Secondary CTA. Card background, line border, onSurface text, r14.
///
/// When [danger] is true the button switches to the destructive-action
/// palette: theme `error` foreground + coral-tinted border. Used by
/// the entry-detail Delete affordance and any other "destructive but
/// reversible" CTAs.
class MbGhostButton extends StatelessWidget {
  const MbGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.fullWidth = true,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool fullWidth;

  /// When true, the foreground + border switch to the destructive
  /// palette so the button reads as "Delete / Discard" rather than a
  /// neutral secondary action.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final fg = danger ? mb.destructiveText : mb.text;
    final borderColor = danger
        ? theme.colorScheme.error.withValues(alpha: 0.55)
        : mb.line;
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: mb.card,
        foregroundColor: fg,
        side: BorderSide(color: borderColor),
        // Size.fromHeight builds Size(double.infinity, h) — that makes
        // the button's minWidth = infinity, which throws when the
        // parent (e.g. a Row's non-flex slot) passes unbounded width.
        // Size(0, h) keeps the height floor without forcing an infinite
        // width; the optional `fullWidth: true` wrapper handles full-
        // width sizing explicitly via SizedBox(width: double.infinity).
        minimumSize: const Size(0, MoodBloomSpacing.tapTargetMin),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusButton),
        ),
        textStyle: MbFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          // Flexible so the label can shrink-to-fit at 200% dynamic
          // type on narrow surfaces - same fix as MbPrimaryButton.
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
