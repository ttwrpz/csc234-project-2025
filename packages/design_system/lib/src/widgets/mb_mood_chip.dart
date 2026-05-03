import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Three sizes for the mood chip pill.
enum MbChipSize { sm, md, lg }

/// Pill-shaped chip showing a mood emoji and label, tinted with the mood's
/// own color at 13% bg + 33% border. Used wherever the prototype shows a
/// "currently happy" or "selected calm" badge.
class MbMoodChip extends StatelessWidget {
  const MbMoodChip({
    super.key,
    required this.mood,
    this.size = MbChipSize.md,
    this.label,
  });

  final MbMoodKind mood;
  final MbChipSize size;

  /// Override the human-readable label. Defaults to the enum name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final color = palette.colorOf(mood);
    final emoji = palette.emojiOf(mood);

    final (
      double fontSize,
      double emojiSize,
      double padH,
      double padV,
    ) = switch (size) {
      MbChipSize.sm => (11.0, 12.0, 8.0, 4.0),
      MbChipSize.md => (12.0, 14.0, 10.0, 5.0),
      MbChipSize.lg => (14.0, 16.0, 12.0, 6.0),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: color.withAlpha(0x21),
        border: Border.all(color: color.withAlpha(0x55)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: emojiSize)),
          const SizedBox(width: 4),
          Text(
            label ?? mood.name,
            style: MbFonts.nunito(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).extension<MbColors>()!.text,
            ),
          ),
        ],
      ),
    );
  }
}
