/// Stub used on non-web platforms. Mobile/desktop builds get a
/// platform-aware path via the conditional import in `image_viewer.dart`
/// — but no "save to disk" implementation is in scope without pulling in
/// `share_plus` / `path_provider` writes, so the stub returns false and
/// the caller surfaces a snackbar.
Future<bool> downloadAttachment(String url, {String? filename}) async {
  return false;
}
