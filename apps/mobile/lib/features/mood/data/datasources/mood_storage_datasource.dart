import 'dart:io' show File;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin Firebase Storage wrapper. No domain types here — this is the boundary
/// between `firebase_storage` and the rest of the app.
class MoodStorageDatasource {
  const MoodStorageDatasource(this._storage);
  final FirebaseStorage _storage;

  /// Native (mobile/desktop) upload. Streams the local file off-disk via
  /// `putFile`, which is the most efficient path on Android / iOS but
  /// **crashes on Web** because `dart:io File` cannot back a blob URL.
  /// Web callers must go through [uploadBytes] instead.
  UploadTask upload(String path, File file, {String? contentType}) {
    final ref = _storage.ref().child(path);
    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);
    return ref.putFile(file, metadata);
  }

  /// In-memory upload. Used on Web (where `XFile.path` is a blob URL we
  /// cannot pass to `dart:io File`) and in tests where the bytes are
  /// already loaded.
  UploadTask uploadBytes(String path, Uint8List bytes, {String? contentType}) {
    final ref = _storage.ref().child(path);
    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);
    return ref.putData(bytes, metadata);
  }

  /// Builds the canonical `gs://<bucket>/<path>` URI for a given object path.
  String gsUriFor(String path) {
    final bucket = _storage.bucket;
    return 'gs://$bucket/$path';
  }
}
