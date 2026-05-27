import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/mood_type.dart';
import 'mood_type_tile.dart';

/// Responsive mood-type picker — 3-column x 2-row grid with the prototype's
/// 1.1:1 aspect ratio (84 dp tall floor). The grid uses `LayoutBuilder` so
/// it adapts to the parent column width without overflowing on narrow
/// phones (<360 dp) or stretching on a wide desktop slot.
///
/// Stateless; the parent controller owns the selection.
class MoodTypeGrid extends StatelessWidget {
  const MoodTypeGrid({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final MoodType? selected;
  final ValueChanged<MoodType> onSelect;

  /// Minimum tile height per the prototype spec (84 dp).
  static const double _minTileHeight = 84;

  /// Aspect ratio width:height per the prototype spec (1.1 : 1).
  static const double _aspect = 1.1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = MoodBloomSpacing.sm + 2; // 10 dp between cells.
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final tileWidth = (available - gap * 2) / 3;
        final tileHeight = (tileWidth / _aspect).clamp(_minTileHeight, 160.0);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final type in MoodType.values)
              SizedBox(
                width: tileWidth,
                height: tileHeight,
                child: MoodTypeTile(
                  type: type,
                  selected: selected == type,
                  onTap: () => onSelect(type),
                ),
              ),
          ],
        );
      },
    );
  }
}
