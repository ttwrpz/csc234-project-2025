import 'package:core/core.dart';

import '../entities/mood_media.dart';
import '../mood_failure.dart';
import '../repositories/mood_media_repository.dart';

/// Uploads a single [MoodMedia] under
/// `users/{userId}/media/{moodId}/{uuid}.{ext}` and returns the resulting
/// `gs://...` URI on success.
///
/// Pure-Dart use case. Validation (size, MIME) lives inside the repository
/// implementation - the use case is a thin contract so callers can swap in a
/// fake during testing.
class UploadMoodMediaUseCase {
  const UploadMoodMediaUseCase({required MoodMediaRepository repository})
    : _repository = repository;

  final MoodMediaRepository _repository;

  Future<Result<String, MoodFailure>> call({
    required String userId,
    required String moodId,
    required MoodMedia media,
  }) {
    return _repository.upload(userId: userId, moodId: moodId, media: media);
  }
}
