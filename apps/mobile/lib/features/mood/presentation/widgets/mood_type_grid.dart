import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/mood_type.dart';
import 'mood_type_tile.dart';

/// Responsive mood-type picker. Always 3 across; tiles fill the row.
/// The previous 132dp cap left the LogMood Add page looking sparse on
/// desktop wide layouts (user feedback v1.0 polish: "emotion button in
/// Choose feeling in the desktop must width 100%"). We now derive the
/// tile width from the available column width and only clamp at
/// extremes (72dp lower bound for cramped narrow phones, 240dp upper
/// bound so a 1440dp window doesn't get cartoon-sized tiles).
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

  /// Lower bound — protects the 5-letter labels (`happy`, `angry`)
  /// from clipping on a < 360dp phone width.
  static const double _minTileWidth = 72;

  /// Upper bound — keeps tiles readable on a 24" monitor without
  /// turning the row into a billboard. 240dp is the sweet spot for a
  /// 600dp left-column width (the LogMood wide-layout 55% slice of a
  /// 1080dp form: 600dp - 2×md gap = ~580 / 3 ≈ 193dp per tile).
  static const double _maxTileWidth = 240;

  static const double _tileHeight = 84;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = MoodBloomSpacing.md;
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        // Always 3 across; tile fills its share of the row.
        final threeColWidth = (available - gap * 2) / 3;
        final tileWidth = threeColWidth.clamp(_minTileWidth, _maxTileWidth);
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
