import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../garden/domain/entities/flower_species.dart';
import '../../../garden/presentation/widgets/flower_sprite.dart';
import '../../domain/entities/mood_type.dart';
import 'mood_kind_adapter.dart';

/// One tile inside the mood-picker grid. Card surface with an emoji + label
/// matching the prototype (`screens.jsx` LogScreen). Selected state tints the
/// background with the mood's own color at 20% and outlines it at 1.5 px.
///
/// Public API (`type`, `selected`, `onTap`) is preserved so that the existing
/// widget tests in `mood_type_grid_test.dart` and `log_mood_screen_test.dart`
/// keep matching by `MoodTypeTile && w.selected && w.type == ...`.
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
    final species = FlowerSpecies.forMood(type);
    final label = type.name;

    final bg = selected ? color.withAlpha(0x33) : mb.card;
    final border = selected ? color : mb.line;
    final borderWidth = selected ? 1.5 : 1.0;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, mood selector tile',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: borderWidth),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlowerSprite(species: species, size: 28, tint: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: MbFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
