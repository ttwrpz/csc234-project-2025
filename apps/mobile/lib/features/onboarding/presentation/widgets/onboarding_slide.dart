import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One page of the onboarding carousel. Shows a small inline brand
/// illustration (220×170) above a Fraunces 600 26 sp title and a Nunito
/// 15 sp dim body capped at 300 dp width.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.art,
    required this.title,
    required this.body,
  });

  /// Inline illustration (220×170) drawn with [CustomPaint] — matches the
  /// SVG art used in the React prototype (`screens.jsx` lines 1–93).
  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Semantics(
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            art,
            const SizedBox(height: 24),
            Text(
              title,
              style: MbFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                body,
                style: MbFonts.nunito(
                  fontSize: 15,
                  height: 1.55,
                  color: mb.textDim,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
