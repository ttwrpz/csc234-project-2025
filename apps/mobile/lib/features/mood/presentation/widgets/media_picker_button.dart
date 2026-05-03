import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/repositories/mood_media_repository.dart';

/// 36×36 attach button used in the LogMood note card. Card-bg surface with a
/// 1 px line border, r10. Three visual variants (`gallery`, `camera`, `mic`)
/// map to the prototype's photo/video/mic glyphs — though only `gallery` and
/// `camera` are wired to actual sources today (mic is decorative until S4
/// audio capture lands).
class MediaPickerButton extends StatelessWidget {
  const MediaPickerButton({super.key, required this.onPick});

  final ValueChanged<MoodMediaSource> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AttachIcon(
          icon: Icons.camera_alt_outlined,
          semanticLabel: 'Add a photo from camera',
          onTap: () => onPick(MoodMediaSource.camera),
        ),
        const SizedBox(width: 8),
        _AttachIcon(
          icon: Icons.photo_library_outlined,
          semanticLabel: 'Pick a photo or video from gallery',
          onTap: () => onPick(MoodMediaSource.gallery),
        ),
      ],
    );
  }
}

/// Single 36×36 r10 attach button. Card bg, 1 px line border, 18 px icon. Not
/// exported — only the two-source row above is the public surface.
class _AttachIcon extends StatelessWidget {
  const _AttachIcon({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: mb.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: mb.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(child: Icon(icon, size: 18, color: mb.textDim)),
            ),
          ),
        ),
      ),
    );
  }
}
