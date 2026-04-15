import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAttachment({
    required String userId,
    required String entryId,
    required Uint8List data,
    required String fileName,
    required String contentType,
  }) async {
    final ref = _storage
        .ref()
        .child(AppConstants.moodAttachmentsPath)
        .child(userId)
        .child('$entryId-$fileName');

    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(data, metadata);
    return await ref.getDownloadURL();
  }

  Future<void> deleteAttachment(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }

  Future<void> deleteAllUserAttachments(String userId) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.moodAttachmentsPath)
          .child(userId);
      final result = await ref.listAll();
      for (final item in result.items) {
        await item.delete();
      }
    } catch (_) {
      // Ignore if directory doesn't exist
    }
  }
}
