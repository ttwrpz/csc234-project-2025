import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Secondary CTA. Card background, line border, onSurface text, r14.
class MbGhostButton extends StatelessWidget {
  const MbGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: mb.card,
        foregroundColor: mb.text,
        side: BorderSide(color: mb.line),
        minimumSize: const Size.fromHeight(MoodBloomSpacing.tapTargetMin),
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
          Text(label),
        ],
      ),
    );

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
