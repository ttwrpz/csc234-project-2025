import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../intervention/presentation/screens/breathing_screen.dart';

/// Self-initiated entry point to the 2-minute breathing modal. Standalone
/// pill so the home page can place it where it fits — between the
/// SkyHeader and the ThisWeeksTierCard on phone, and inside the left
/// column on tablet / desktop.
class TakeABreathButton extends StatelessWidget {
  const TakeABreathButton({super.key, this.expand = false});

  /// Stretches the pill to fill its parent's width — used inline on
  /// phone where the parent is a column-stretched stack.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;

    // Prototype `PillBtn`: card background, 1px line border, text-colour
    // foreground, fully-rounded pill, air icon + "Take a breath".
    final button = Semantics(
      button: true,
      label: 'Take a 2-minute breath',
      child: TextButton.icon(
        onPressed: () => BreathingSheet.show(context),
        style: TextButton.styleFrom(
          foregroundColor: mb.text,
          backgroundColor: mb.card,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
            side: BorderSide(color: mb.line),
          ),
        ),
        icon: Icon(Icons.air, size: 16, color: mb.text),
        label: Text(
          'Take a breath',
          style: MbFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
      ),
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
