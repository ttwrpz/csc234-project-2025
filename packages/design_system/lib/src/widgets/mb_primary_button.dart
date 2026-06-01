import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// Primary CTA. Filled, white text, r14, 600 weight. Defaults to full width
/// because the prototype uses a sticky-bottom primary in most flows.
class MbPrimaryButton extends StatelessWidget {
  const MbPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.fullWidth = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: theme.colorScheme.primary.withAlpha(0x99),
        disabledForegroundColor: Colors.white,
        // Material accessibility minimum tap target is 48 dp; set both
        // minimumSize.height and tapTargetSize so a 14 sp label inside a
        // tight container doesn't shrink the hit area below the threshold.
        // Size(0, h) - Size.fromHeight forces minWidth = infinity, which
        // asserts when the button sits in a Row's non-flex slot.
        minimumSize: const Size(0, MoodBloomSpacing.tapTargetMin),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusButton),
        ),
        textStyle: MbFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                // Flexible so the label can shrink-to-fit at 200% dynamic
                // type on narrow surfaces - prevents a RenderFlex overflow
                // when the scaled text is wider than the button's inner
                // constraint (caught by the disclaimer dialog a11y test).
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
