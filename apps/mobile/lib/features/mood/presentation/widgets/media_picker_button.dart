import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/repositories/mood_media_repository.dart';

/// Two-icon row that lets the user attach media from the gallery or camera.
/// Stateless — the parent controller holds the picked list. Tapping invokes
/// [onPick] with the chosen [MoodMediaSource]; the parent then runs the
/// `PickMoodMedia` use case.
class MediaPickerButton extends StatelessWidget {
  const MediaPickerButton({super.key, required this.onPick});

  final ValueChanged<MoodMediaSource> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PickerTile(
            icon: Icons.photo_library_outlined,
            label: 'From gallery',
            onTap: () => onPick(MoodMediaSource.gallery),
          ),
        ),
        const SizedBox(width: MoodBloomSpacing.sm),
        Expanded(
          child: _PickerTile(
            icon: Icons.photo_camera_outlined,
            label: 'From camera',
            onTap: () => onPick(MoodMediaSource.camera),
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add photo or video — $label',
      child: SizedBox(
        height: MoodBloomSpacing.tapTargetMin,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
