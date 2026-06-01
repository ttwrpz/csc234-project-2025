import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import 'image_viewer.dart';

/// Strip of attachment thumbnails for an entry-detail screen. Each item
/// in [refs] is a `gs://bucket/path` URI persisted on the mood document.
/// We resolve every gs:// to a download URL on first build and cache the
/// result inside a `FutureProvider.family` so consecutive paints don't
/// re-fetch.
///
/// Still images only. Videos render as a generic film-strip placeholder
/// with a "Video" overlay - playing them inline is not yet supported
/// (`video_player` is not in pubspec).
class EntryAttachments extends StatelessWidget {
  const EntryAttachments({super.key, required this.refs});

  final List<String> refs;

  @override
  Widget build(BuildContext context) {
    if (refs.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in refs) ...[
            _AttachmentTile(gsUri: r),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// One 96×96 thumbnail. Resolves the gs:// URI to a download URL via
/// the shared `firebaseStorageProvider` and renders the result with
/// `Image.network`. Videos get a film-icon placeholder.
class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({required this.gsUri});

  final String gsUri;

  bool get _looksLikeVideo {
    final lower = gsUri.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final urlAsync = ref.watch(_attachmentUrlProvider(gsUri));

    return GestureDetector(
      // Tap → full-screen viewer (images only - videos still hit the
      // placeholder until video_player ships, but we let the gesture
      // through so a future video viewer can hook in here too).
      onTap: () {
        final url = urlAsync.value;
        if (url == null || _looksLikeVideo) return;
        ImageViewer.show(context, url);
      },
      child: Container(
        width: 96,
        height: 96,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: mb.line,
          borderRadius: BorderRadius.circular(12),
        ),
        child: urlAsync.when(
          loading: () => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: mb.textDim,
              size: 22,
            ),
          ),
          data: (url) {
            if (_looksLikeVideo) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: mb.bg),
                  Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 32,
                      color: mb.text,
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Video',
                        style: MbFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Image.network(
              url,
              fit: BoxFit.cover,
              // Same tile-sized loading placeholder so swap-in is smooth.
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: mb.textDim,
                  size: 22,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Caches download URLs by gs:// URI so the entry screen doesn't make
/// fresh getDownloadURL() calls on every rebuild. The provider's family
/// key is the gs:// URI itself.
final _attachmentUrlProvider = FutureProvider.family<String, String>((
  ref,
  gsUri,
) async {
  final storage = ref.watch(firebaseStorageProvider);
  final reference = storage.refFromURL(gsUri);
  return reference.getDownloadURL();
});
