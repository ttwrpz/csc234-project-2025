import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/mood_type.dart';

/// One tile inside the mood-picker grid. Stateless. Square (1:1 aspect ratio)
/// with a label below — no emoji or icon yet (architect default per HB-002
/// OQ-2; iconography curated in S3).
///
/// Selected state uses the per-mood color from the design system, softly
/// tinted so the label stays readable.
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
    final moodColor = _moodToColor(type);
    final fill = selected
        ? moodColor.withValues(alpha: 0.4)
        : MoodBloomColors.surfaceDim;
    final label = type.name;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, intensity selector tile',
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: MoodBloomColors.outline),
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: MoodBloomSpacing.tapTargetMin + MoodBloomSpacing.lg,
              ),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: MoodBloomColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _moodToColor(MoodType type) => switch (type) {
    MoodType.happy => MoodBloomColors.moodHappy,
    MoodType.calm => MoodBloomColors.moodCalm,
    MoodType.okay => MoodBloomColors.moodOkay,
    MoodType.sad => MoodBloomColors.moodSad,
    MoodType.angry => MoodBloomColors.moodAngry,
    MoodType.anxious => MoodBloomColors.moodAnxious,
  };
}
