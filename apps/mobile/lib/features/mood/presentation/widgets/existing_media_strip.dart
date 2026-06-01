import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';

/// Horizontal strip of attachments already persisted on the entry being
/// edited. Each tile shows the resolved download-URL preview with a
/// circular ✕ to drop the gs:// URI from the draft's `mediaRefs`.
///
/// Lives in the mood feature (not history) because removal mutates the
/// log-mood draft state - keeping it here means the screen owns its
/// own attachment lifecycle.
class ExistingMediaStrip extends ConsumerWidget {
  const ExistingMediaStrip({
    super.key,
    required this.gsUris,
    required this.onRemove,
  });

  final List<String> gsUris;
  final void Function(int index) onRemove;

  static const double _tileSize = 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gsUris.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: _tileSize + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gsUris.length,
        separatorBuilder: (_, _) => const SizedBox(width: MoodBloomSpacing.sm),
        itemBuilder: (context, i) =>
            _Tile(gsUri: gsUris[i], onRemove: () => onRemove(i)),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.gsUri, required this.onRemove});

  final String gsUri;
  final VoidCallback onRemove;

  bool get _isVideo {
    final l = gsUri.toLowerCase();
    return l.endsWith('.mp4') ||
        l.endsWith('.mov') ||
        l.endsWith('.webm') ||
        l.endsWith('.m4v');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final urlAsync = ref.watch(_urlProvider(gsUri));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: ExistingMediaStrip._tileSize,
            height: ExistingMediaStrip._tileSize,
            color: mb.line,
            child: urlAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => Icon(
                Icons.broken_image_outlined,
                color: mb.textDim,
                size: 22,
              ),
              data: (url) {
                if (_isVideo) {
                  return Icon(
                    Icons.play_circle_outline,
                    size: 28,
                    color: mb.text,
                  );
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.broken_image_outlined,
                    color: mb.textDim,
                    size: 22,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Semantics(
            button: true,
            label: 'Remove attachment',
            child: Material(
              color: mb.card,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: mb.text),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cache of gs:// → download URL. Same shape as the entry-detail
/// version; kept private here so each feature owns its own provider
/// (different lifecycles - the edit-mode strip can be torn down at any
/// moment without affecting cached entries on the detail screen).
final _urlProvider = FutureProvider.family<String, String>((ref, gsUri) async {
  final storage = ref.watch(firebaseStorageProvider);
  return storage.refFromURL(gsUri).getDownloadURL();
});
