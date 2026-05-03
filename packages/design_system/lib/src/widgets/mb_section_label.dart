import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Small uppercase section caption (e.g. "PREFERENCES", "ABOUT").
class MbSectionLabel extends StatelessWidget {
  const MbSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      text.toUpperCase(),
      style: MbFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: mb.textDim,
      ),
    );
  }
}
