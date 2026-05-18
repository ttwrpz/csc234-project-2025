import 'package:core/core.dart';

import '../entities/mood_media.dart';
import '../mood_failure.dart';

/// Where the user is picking media from.
enum MoodMediaSource { gallery, camera }

/// Contract for picking media from the device and uploading it to remote
/// storage. Implementations live in `data/`; this interface keeps the domain
/// layer free of `image_picker` and `firebase_storage` imports.
///
/// Sibling to [MoodRepository] — kept separate so the entry repository can
/// evolve without touching media plumbing.
abstract class MoodMediaRepository {
  /// Pick one or more images/videos from the device gallery or camera.
  /// `allowMultiple` is honored only for [MoodMediaSource.gallery]; camera
  /// captures one item at a time on every platform we ship.
  Future<Result<List<MoodMedia>, MoodFailure>> pick({
    required MoodMediaSource source,
    bool allowMultiple = true,
  });

  /// Upload a single [MoodMedia] to
  /// `users/{userId}/media/{moodId}/{uuid}.{ext}` and return the resulting
  /// `gs://...` URI on success.
  Future<Result<String, MoodFailure>> upload({
    required String userId,
    required String moodId,
    required MoodMedia media,
  });
}
