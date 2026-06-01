import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import '../../domain/repositories/mood_media_repository.dart';

/// Surface that lets the user attach photos/videos to a mood entry. Adapts
/// to the host platform AND the surrounding layout zone:
///
/// |                     | narrow (<720dp)              | wide (>=720dp)        |
/// | mobile (Android)    | 2 icon buttons (cam + gal)   | 2 icon buttons        |
/// | desktop / web       | 1 icon button (gallery only) | full-width "Attach…"  |
///
/// Why: the `image_picker` plugin maps both `ImageSource.camera` and
/// `ImageSource.gallery` to the OS file dialog on web/Windows/macOS, so
/// surfacing a separate camera button on those platforms is misleading. On
/// wide desktop windows, two 36×36 icon-only buttons are also hard to spot
/// in a mouse-driven UI - we promote to a discoverable outlined button.
class MediaPickerButton extends StatelessWidget {
  const MediaPickerButton({
    super.key,
    required this.onPick,
    this.wideLayout = false,
  });

  final ValueChanged<MoodMediaSource> onPick;

  /// Set by the parent screen when laying the form out as a two-column
  /// desktop view. Promotes the picker to a single full-width labeled
  /// button instead of the compact icon row.
  final bool wideLayout;

  /// True when the host platform is web or a desktop OS (Windows / macOS /
  /// Linux). On those platforms there's no real "camera" path through
  /// `image_picker`, so the camera affordance is hidden. Android is the
  /// only mobile target, so it is the sole platform that gets the camera
  /// button.
  static bool get _isDesktopLike {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktopLike && wideLayout) {
      return _AttachOutlinedButton(
        onTap: () => onPick(MoodMediaSource.gallery),
      );
    }

    if (_isDesktopLike) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AttachIcon(
            icon: Icons.image_outlined,
            semanticLabel: 'Choose a photo',
            onTap: () => onPick(MoodMediaSource.gallery),
          ),
        ],
      );
    }

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
/// exported - only the two-source row above is the public surface.
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

/// Full-width outlined "Attach a photo" button used on desktop wide layouts.
/// Uses [OutlinedButton.icon] so it picks up the design system theme's
/// outlined-button styling automatically.
class _AttachOutlinedButton extends StatelessWidget {
  const _AttachOutlinedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.image_outlined, size: 18, color: mb.text),
        label: Text(
          'Attach a photo',
          style: MbFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(color: mb.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: mb.bg,
        ),
      ),
    );
  }
}
