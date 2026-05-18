import 'package:flutter/material.dart';

/// Brand hero mark used on Sign In / Sign Up / Biometric gate screens.
///
/// Renders the app icon at `assets/icon/app_icon.png` inside a rounded
/// clip so the splash, launcher, sidebar, and auth surfaces all show
/// the same flower-bloom mark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.glyphSize = 36});

  /// Outer side length (also the visible footprint).
  final double size;

  /// Retained for API parity with the prior hand-drawn variant. No
  /// longer renders an inner glyph because the asset already includes
  /// the disc backdrop + petals + leaf at the correct proportions.
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'MoodBloom logo',
      ),
    );
  }
}
