import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/mood_type.dart';
import 'mood_type_tile.dart';

/// Responsive mood-type picker. On phones (< ~480 dp) we render a 3-column
/// grid; tiles fill the row. On tablet / desktop we cap each tile to a sane
/// width (`_maxTileWidth`) and centre them in a `Wrap`, otherwise a 1200 dp
/// content column blew the tiles up to ~380 dp squares.
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

  /// Per-tile cap. Mirrors the prototype's tile dimensions inside the iOS
  /// frame so tiles stay readable on a 24" monitor.
  static const double _maxTileWidth = 132;
  static const double _tileHeight = 84;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Aim for 3 across on narrow widths, but let `Wrap` reflow when the
        // content column gets wide enough that 3 tiles would each exceed
        // `_maxTileWidth`. Subtract two gaps' worth of horizontal space when
        // computing the per-tile width target.
        const gap = MoodBloomSpacing.md;
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final threeColWidth = (available - gap * 2) / 3;
        final tileWidth = threeColWidth.clamp(72.0, _maxTileWidth);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.start,
          children: [
            for (final type in MoodType.values)
              SizedBox(
                width: tileWidth,
                height: _tileHeight,
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
