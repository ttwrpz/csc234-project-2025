import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thrown when the user denies — or has permanently denied — a runtime
/// permission required for the requested media source. The repository
/// catches this and surfaces a `MediaFailure.permissionDenied` (with a
/// flag for the "Open Settings" recovery path when permanently denied).
class MediaPermissionDeniedException implements Exception {
  const MediaPermissionDeniedException({
    required this.source,
    required this.permanent,
  });

  /// Either 'camera' or 'gallery'. Used by the UI to format the
  /// snackbar message ("Camera permission was denied", etc.).
  final String source;

  /// True when the user picked "Don't ask again" on Android or
  /// "Don't allow" on iOS. The caller should offer an "Open Settings"
  /// action because future `request()` calls will resolve instantly
  /// without re-prompting.
  final bool permanent;
}

/// Thin `ImagePicker` wrapper. The repository decides when to call which
/// method based on [MoodMediaSource]; this datasource only exposes the four
/// concrete picker operations we need.
///
/// Runtime permissions are requested here, BEFORE handing off to
/// `image_picker`. `image_picker` does not request CAMERA on Android — the
/// camera intent fails silently if it isn't pre-granted — and the
/// pre-Photo-Picker gallery flow on Android ≤12 needs storage permission
/// declared + granted at runtime.
class ImagePickerDatasource {
  ImagePickerDatasource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<List<XFile>> pickFromGallery({required bool allowMultiple}) async {
    await _ensureGalleryPermission();
    if (allowMultiple) {
      return _picker.pickMultiImage();
    }
    final single = await _picker.pickImage(source: ImageSource.gallery);
    return single == null ? const <XFile>[] : <XFile>[single];
  }

  Future<XFile?> takePhoto() async {
    await _ensureCameraPermission();
    return _picker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> recordVideo() async {
    await _ensureCameraPermission();
    return _picker.pickVideo(source: ImageSource.camera);
  }

  /// Camera intent needs `CAMERA` granted on every Android 6+. iOS
  /// resolves through `Permission.camera` too. Web has no equivalent.
  Future<void> _ensureCameraPermission() async {
    if (kIsWeb) return;
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return;
    throw MediaPermissionDeniedException(
      source: 'camera',
      permanent: status.isPermanentlyDenied || status.isRestricted,
    );
  }

  /// Gallery permission split by platform:
  ///   - Android 13+ uses the OS Photo Picker — `image_picker` routes
  ///     through it automatically and no runtime permission is needed.
  ///     The `Permission.photos` request resolves instantly to
  ///     `granted`/`limited` on those versions, so we still call it
  ///     for consistency.
  ///   - Android ≤12 reads through `READ_EXTERNAL_STORAGE` —
  ///     `Permission.storage` maps to that and must be granted before
  ///     the picker intent fires.
  ///   - iOS uses `Permission.photos`.
  Future<void> _ensureGalleryPermission() async {
    if (kIsWeb) return;
    final permission = Platform.isAndroid && _isAndroid12OrOlder()
        ? Permission.storage
        : Permission.photos;
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return;
    throw MediaPermissionDeniedException(
      source: 'gallery',
      permanent: status.isPermanentlyDenied || status.isRestricted,
    );
  }

  /// Best-effort Android-12-or-older check via `Platform.operatingSystemVersion`.
  /// The string is vendor-formatted and not guaranteed parseable, so we fall
  /// back to "assume newer Android" (which uses `Permission.photos`, the safer
  /// default — over-requesting the Photo Picker permission gracefully degrades
  /// on older OS, whereas under-requesting storage causes a silent gallery
  /// failure). For deterministic version detection we'd need device_info_plus
  /// — out of scope for this datasource, which is intentionally dependency-light.
  bool _isAndroid12OrOlder() {
    final raw = Platform.operatingSystemVersion;
    // Android version strings look like "Android 13" or "Android 14 (...)".
    final match = RegExp(r'Android\s+(\d+)').firstMatch(raw);
    if (match == null) return false;
    final major = int.tryParse(match.group(1)!);
    return major != null && major <= 12;
  }
}
