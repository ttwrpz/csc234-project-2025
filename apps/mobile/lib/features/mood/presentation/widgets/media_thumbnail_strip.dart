import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../domain/entities/mood_media.dart';

/// Horizontal scrollable preview of media the user has picked but not yet
/// uploaded. Each tile shows a small "remove" affordance.
///
/// On Web, `Image.file` does not work (no `dart:io` File on the platform), so
/// we fall back to a generic icon — full Web image previews land in S4 if we
/// ship Web GA.
class MediaThumbnailStrip extends StatelessWidget {
  const MediaThumbnailStrip({
    super.key,
    required this.media,
    required this.onRemove,
  });

  final List<MoodMedia> media;
  final void Function(int index) onRemove;

  static const double _tileSize = 72;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: _tileSize + MoodBloomSpacing.sm,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: MoodBloomSpacing.sm),
        itemBuilder: (context, index) =>
            _Thumbnail(media: media[index], onRemove: () => onRemove(index)),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.media, required this.onRemove});

  final MoodMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
          child: Container(
            width: MediaThumbnailStrip._tileSize,
            height: MediaThumbnailStrip._tileSize,
            color: theme.colorScheme.surfaceContainerHighest,
            child: _previewFor(media, theme),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Semantics(
            button: true,
            label: 'Remove attachment',
            child: Material(
              color: theme.colorScheme.surface,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewFor(MoodMedia m, ThemeData theme) {
    if (m.kind == MoodMediaKind.video) {
      return Icon(
        Icons.play_circle_outline,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    if (kIsWeb) {
      return Icon(
        Icons.image_outlined,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return Image.file(
      File(m.localPath),
      fit: BoxFit.cover,
      width: MediaThumbnailStrip._tileSize,
      height: MediaThumbnailStrip._tileSize,
      errorBuilder: (_, _, _) => Icon(
        Icons.broken_image_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
