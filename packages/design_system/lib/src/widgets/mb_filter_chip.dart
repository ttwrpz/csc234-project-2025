import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Small horizontal-scroll filter chip used in the History list. Selected =
/// primary fill + white fg; unselected = card bg + dim fg.
class MbFilterChip extends StatelessWidget {
  const MbFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : mb.card,
            border: Border.all(
              color: selected ? theme.colorScheme.primary : mb.line,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: MbFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : mb.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
