import 'mb_fonts.dart';
import 'package:flutter/material.dart';

/// Small lock pill shown on entries past the 24h immutability window. Uses
/// the Material `Icons.lock_outline` glyph (a control), not the 🔒 emoji -
/// emoji are reserved for brand mood-emotion glyphs.
///
/// Set [small] for the tighter list-row variant.
class MbLockBadge extends StatelessWidget {
  const MbLockBadge({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurfaceVariant;
    final padH = small ? 6.0 : 8.0;
    final padV = small ? 2.0 : 3.0;
    final fontSize = small ? 10.0 : 11.0;
    final iconSize = small ? 11.0 : 13.0;
    return Semantics(
      label: 'Locked',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(0x0F),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: iconSize, color: fg),
            if (!small) ...[
              const SizedBox(width: 4),
              Text(
                'locked',
                style: MbFonts.nunito(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
