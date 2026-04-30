import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin Firebase Storage wrapper. No domain types here — this is the boundary
/// between `firebase_storage` and the rest of the app.
///
/// Mirrors `MoodFirestoreDatasource` in spirit: a single concrete dependency
/// (`FirebaseStorage`) injected at construction so tests can swap a fake.
class MoodStorageDatasource {
  const MoodStorageDatasource(this._storage);
  final FirebaseStorage _storage;

  /// Uploads [file] to [path] under the configured Storage bucket. The
  /// returned task lets callers observe progress / await completion. We do
  /// not await here — the repository chooses when to block.
  UploadTask upload(String path, File file, {String? contentType}) {
    final ref = _storage.ref().child(path);
    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);
    return ref.putFile(file, metadata);
  }

  /// Builds the canonical `gs://<bucket>/<path>` URI for a given object path.
  /// Used after a successful upload — the SDK does not surface a dedicated
  /// `gsUri` getter on the snapshot, so we synthesize from the bucket + path.
  String gsUriFor(String path) {
    final bucket = _storage.bucket;
    return 'gs://$bucket/$path';
  }
}
