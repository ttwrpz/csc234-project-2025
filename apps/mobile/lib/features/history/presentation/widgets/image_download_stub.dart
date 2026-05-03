/// Stub used on non-web platforms. Mobile/desktop builds get a
/// platform-aware path via the conditional import in `image_viewer.dart`
/// — but there is no working "save to disk" implementation in scope for
/// Sprint 2 without pulling in `share_plus` / `path_provider` writes,
/// so the stub returns false and the caller surfaces a snackbar.
Future<bool> downloadAttachment(String url, {String? filename}) async {
  return false;
}
