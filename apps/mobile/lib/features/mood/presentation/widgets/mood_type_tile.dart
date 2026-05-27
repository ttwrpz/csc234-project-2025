import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/mood_type.dart';
import 'mood_kind_adapter.dart';

/// One tile inside the mood-picker grid. Card surface with the prototype's
/// `MbMoodSvg` glyph and a label below.
///
/// Visual treatment per `LogMoodScreen` in `prototype/screens-extra.jsx`:
/// - aspect 1.1 : 1, min 84 dp tall
/// - radius `radiusCardLg` (20 dp)
/// - selected: tinted bg (mood color @ ~13%) + colored border (mood color @ ~33%)
/// - unselected: `mb.card` bg + `mb.line` border
/// - icon 28 dp tinted by mood color; label Nunito 12 / w600
class MoodTypeTile extends StatelessWidget {
  const MoodTypeTile({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final MoodType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final mbKind = type.mbKind;
    final color = palette.colorOf(mbKind);
    final label = type.name;

    final bg = selected ? color.withAlpha(0x21) : mb.card;
    final border = selected ? color.withAlpha(0x55) : mb.line;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, mood selector tile',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MbMoodSvg(mood: mbKind, size: 28, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: MbFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: mb.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
