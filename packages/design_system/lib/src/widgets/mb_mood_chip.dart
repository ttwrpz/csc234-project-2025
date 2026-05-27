import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'mb_intensity_dots.dart';
import 'mb_svg.dart';

/// Three sizes for the mood chip pill.
enum MbChipSize { sm, md, lg }

/// Pill-shaped chip showing a mood glyph and label, tinted with the mood's
/// own color at 13% bg + 33% border. Used wherever the prototype shows a
/// "currently happy" or "selected calm" badge.
///
/// The glyph is the canonical [MbMoodSvg] painter (the same shape used by
/// the Log Mood selector, calendar cells, and analytics) so every surface
/// renders an identical, brand-aligned mood icon - never a Unicode emoji.
///
/// When [intensity] (1..5) is supplied, the chip appends inline intensity
/// dots tinted with the same mood swatch - matches the prototype's
/// `MoodChip kind={...} intensity={...}` composition used by the History
/// list and the calendar side panel.
class MbMoodChip extends StatelessWidget {
  const MbMoodChip({
    super.key,
    required this.mood,
    this.size = MbChipSize.md,
    this.label,
    this.intensity,
  });

  final MbMoodKind mood;
  final MbChipSize size;

  /// Override the human-readable label. Defaults to the enum name.
  final String? label;

  /// Optional intensity 1..5. When supplied, the chip renders the
  /// matching `MbIntensityDots` row inline after the label. `null`
  /// keeps the bare chip used for filter / category badges.
  final int? intensity;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final color = palette.colorOf(mood);

    final (
      double fontSize,
      double glyphSize,
      double padH,
      double padV,
      double dotSize,
    ) = switch (size) {
      MbChipSize.sm => (11.0, 13.0, 8.0, 4.0, 4.0),
      MbChipSize.md => (12.0, 15.0, 10.0, 5.0, 5.0),
      MbChipSize.lg => (14.0, 18.0, 12.0, 6.0, 6.0),
    };

    final i = intensity;

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
          MbMoodSvg(mood: mood, size: glyphSize, color: color),
          const SizedBox(width: 6),
          Text(
            label ?? mood.name,
            style: MbFonts.nunito(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).extension<MbColors>()!.text,
            ),
          ),
          if (i != null) ...<Widget>[
            const SizedBox(width: 6),
            MbIntensityDots(
              value: i,
              color: color,
              dotSize: dotSize,
              gap: 2,
            ),
          ],
        ],
      ),
    );
  }
}
