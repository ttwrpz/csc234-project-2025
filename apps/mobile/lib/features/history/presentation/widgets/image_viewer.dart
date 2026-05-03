import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Conditional import: `dart:html` is web-only, so we route through a
// stub on native targets. Both files expose the same API:
//   `Future<bool> downloadAttachment(String url, {String? filename})`.
import 'image_download_stub.dart'
    if (dart.library.html) 'image_download_web.dart';

/// Full-screen viewer for an attached image. Opens via [show], which
/// pushes a translucent black-barrier `Dialog` so the route is
/// dismissible by tap-outside on top of the back-arrow / system-back
/// path. The viewer uses [InteractiveViewer] for pinch-zoom and pan.
class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, required this.url});

  /// Convenience launcher matching the calendar / day-entries-sheet
  /// pattern. Returns once the viewer is dismissed.
  static Future<void> show(BuildContext context, String url) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => ImageViewer(url: url),
    );
  }

  /// HTTPS download URL produced by `FirebaseStorage.refFromURL().getDownloadURL()`.
  final String url;

  Future<void> _onDownload(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await downloadAttachment(url);
    if (!context.mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Downloading attachment…')),
      );
      return;
    }
    // Native path: copy the URL to the clipboard so the user can paste
    // it into a browser. Avoids pulling `share_plus` for one button.
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Image link copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pinch-zoom / pan on the image itself.
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            // Top bar: close + download. Sits above the image so taps
            // route to buttons before the InteractiveViewer.
            Positioned(
              top: 4,
              left: 4,
              right: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ViewerButton(
                    icon: Icons.close,
                    label: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _ViewerButton(
                    icon: Icons.download,
                    label: 'Download',
                    onPressed: () => _onDownload(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Tooltip(
            message: label,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
