import 'dart:io';

import 'package:core/core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/entities/mood_media.dart';
import '../../domain/mood_failure.dart';
import '../../domain/repositories/mood_media_repository.dart';
import '../datasources/image_picker_datasource.dart';
import '../datasources/mood_storage_datasource.dart';

/// Maximum upload size in bytes (25 MB). Matches the Storage rule's
/// `request.resource.size < 25 * 1024 * 1024` clause exactly - strict less-
/// than. We pre-validate in the client to give the user a fast error instead
/// of waiting for a 403 from Storage.
const int kMaxMediaBytes = 25 * 1024 * 1024;

/// Allowed MIME prefixes. Mirrors the Storage rule's
/// `image/.*|video/.*` allowlist.
const List<String> _allowedPrefixes = ['image/', 'video/'];

/// Concrete [MoodMediaRepository] backed by `image_picker` for selection and
/// `firebase_storage` for upload.
///
/// ## Known limitation - orphan media
/// If [upload] succeeds but the caller's subsequent Firestore write fails,
/// the uploaded blob remains at `users/{uid}/media/{moodId}/...` with no
/// pointing entry. A janitor cron sweeps these orphans; until then, the
/// storage cost is bounded by the 25 MB-per-file cap.
class MoodMediaRepositoryImpl implements MoodMediaRepository {
  MoodMediaRepositoryImpl({
    required ImagePickerDatasource picker,
    required MoodStorageDatasource storage,
    Uuid uuid = const Uuid(),
    Logger logger = const Logger('mood.media.repo'),
    File Function(String path) fileFactory = _defaultFileFactory,
  }) : _picker = picker,
       _storage = storage,
       _uuid = uuid,
       _logger = logger,
       _fileFactory = fileFactory;

  final ImagePickerDatasource _picker;
  final MoodStorageDatasource _storage;
  final Uuid _uuid;
  final Logger _logger;
  final File Function(String path) _fileFactory;

  static File _defaultFileFactory(String path) => File(path);

  @override
  Future<Result<List<MoodMedia>, MoodFailure>> pick({
    required MoodMediaSource source,
    bool allowMultiple = true,
  }) async {
    try {
      final picked = switch (source) {
        MoodMediaSource.gallery => await _picker.pickFromGallery(
          allowMultiple: allowMultiple,
        ),
        MoodMediaSource.camera => await _pickFromCamera(),
      };
      final out = <MoodMedia>[];
      for (final x in picked) {
        final media = await _toMoodMedia(x);
        if (media != null) out.add(media);
      }
      return Ok(out);
    } on MediaPermissionDeniedException catch (e) {
      _logger.warn(
        'media pick denied',
        data: 'source=${e.source} permanent=${e.permanent}',
      );
      return Err(
        MoodFailure.mediaPermissionDenied(
          source: e.source,
          permanent: e.permanent,
        ),
      );
    } catch (e) {
      _logger.warn('media pick failed', data: e.runtimeType.toString());
      return Err(MoodFailure.unknown(e));
    }
  }

  Future<List<XFile>> _pickFromCamera() async {
    // Camera defaults to a still photo; users can record video via the
    // gallery flow on their device camera-roll if they prefer.
    final photo = await _picker.takePhoto();
    return photo == null ? const <XFile>[] : <XFile>[photo];
  }

  Future<MoodMedia?> _toMoodMedia(XFile x) async {
    final mime = x.mimeType ?? lookupMimeType(x.path) ?? '';
    final size = await x.length();
    final kind = mime.startsWith('video/')
        ? MoodMediaKind.video
        : MoodMediaKind.image;
    return MoodMedia(
      localPath: x.path,
      kind: kind,
      sizeBytes: size,
      mimeType: mime,
    );
  }

  @override
  Future<Result<String, MoodFailure>> upload({
    required String userId,
    required String moodId,
    required MoodMedia media,
  }) async {
    final validation = validate(media);
    if (validation != null) return Err(validation);

    final ext = _extensionFor(media);
    final objectPath =
        'users/$userId/media/$moodId/${_uuid.v4()}${ext.isEmpty ? '' : '.$ext'}';

    try {
      // Web cannot back a `dart:io File` from a blob: URL - the
      // `XFile.path` returned by image_picker on web is a blob handle,
      // not a filesystem path. Read the bytes through `XFile` (which
      // handles blob URLs on web and falls back to filesystem reads on
      // native) and call the bytes upload variant. On native we still
      // use the cheaper `putFile` path that streams off disk.
      final UploadTask task;
      if (kIsWeb) {
        final bytes = await XFile(media.localPath).readAsBytes();
        task = _storage.uploadBytes(
          objectPath,
          bytes,
          contentType: media.mimeType,
        );
      } else {
        task = _storage.upload(
          objectPath,
          _fileFactory(media.localPath),
          contentType: media.mimeType,
        );
      }
      await task;
      return Ok(_storage.gsUriFor(objectPath));
    } on FirebaseException catch (e) {
      // PII rule: never log the localPath or userId+path correlation. Only
      // the failure code and the size bucket.
      _logger.warn(
        'media upload failed',
        data: '${e.code} bytes=${media.sizeBytes}',
      );
      return Err(MoodFailure.mediaUploadFailed(e.code));
    } catch (e) {
      _logger.warn('media upload failed', data: e.runtimeType.toString());
      return Err(MoodFailure.mediaUploadFailed(e.runtimeType.toString()));
    }
  }

  /// Returns a [MoodFailure] when [media] violates a pre-upload invariant, or
  /// `null` when the media is acceptable. Static + library-public so unit
  /// tests can exercise it without instantiating the whole repository.
  static MoodFailure? validate(MoodMedia media) {
    if (media.sizeBytes >= kMaxMediaBytes) {
      return MoodFailure.mediaTooLarge(media.sizeBytes);
    }
    final mime = media.mimeType;
    final ok = _allowedPrefixes.any(mime.startsWith);
    if (!ok) {
      return MoodFailure.mediaUnsupportedType(mime);
    }
    return null;
  }

  /// Filename extension to append to the uuid. Derived from the local path -
  /// the picker always returns a path with the source extension on Android,
  /// iOS, and Web. Empty string if the path has no extension.
  String _extensionFor(MoodMedia media) {
    final fromPath = p.extension(media.localPath);
    if (fromPath.isEmpty) return '';
    return fromPath.substring(1).toLowerCase(); // strip the leading "."
  }
}
