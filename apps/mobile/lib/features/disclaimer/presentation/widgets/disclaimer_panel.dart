import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/disclaimer_copy.dart';

/// Read-only panel that renders [DisclaimerCopy.full] with a small
/// medical icon. Used by the Settings → About cluster (inside an
/// `ExpansionTile`) and the onboarding "A note about MoodBloom" slide.
///
/// No interactive elements — the dedicated `DisclaimerAckDialog` owns
/// the "I understand" affordance. Keeping this widget stateless also
/// makes the goldens and Settings widget tests simpler.
class DisclaimerPanel extends StatelessWidget {
  const DisclaimerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined, color: mb.textDim, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DisclaimerCopy.full,
              style: MbFonts.nunito(fontSize: 13, height: 1.5, color: mb.text),
            ),
          ),
        ],
      ),
    );
  }
}
