// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Trigger a browser download for the given URL by appending a hidden
/// `<a download>` element to the DOM. Works for any URL the browser can
/// fetch - including the Firebase Storage download URLs we hand out
/// from `getDownloadURL()`.
Future<bool> downloadAttachment(String url, {String? filename}) async {
  final anchor = html.AnchorElement(href: url)
    ..download = filename ?? _filenameFromUrl(url)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}

String _filenameFromUrl(String url) {
  // Strip query string then take the last path segment.
  final clean = url.split('?').first;
  final segments = clean.split('/');
  if (segments.isEmpty) return 'attachment';
  // Firebase Storage paths are URL-encoded - decode for a friendlier name.
  return Uri.decodeComponent(segments.last);
}
