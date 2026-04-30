import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/mood_type.dart';
import 'mood_type_tile.dart';

/// 3×2 grid of mood-type tiles. Stateless; the parent controller owns the
/// selection.
class MoodTypeGrid extends StatelessWidget {
  const MoodTypeGrid({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final MoodType? selected;
  final ValueChanged<MoodType> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: MoodBloomSpacing.md,
      crossAxisSpacing: MoodBloomSpacing.md,
      children: [
        for (final type in MoodType.values)
          MoodTypeTile(
            type: type,
            selected: selected == type,
            onTap: () => onSelect(type),
          ),
      ],
    );
  }
}
