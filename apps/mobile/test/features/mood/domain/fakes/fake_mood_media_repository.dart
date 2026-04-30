import 'package:core/core.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_media.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/repositories/mood_media_repository.dart';

/// Hand-rolled fake mirroring `FakeMoodRepository`. Lets unit tests configure
/// canned `pick` and `upload` results without bringing in mockito.
class FakeMoodMediaRepository implements MoodMediaRepository {
  FakeMoodMediaRepository({this.pickResult, this.uploadResults});

  /// Result returned from [pick]. Defaults to an empty list on null.
  Result<List<MoodMedia>, MoodFailure>? pickResult;

  /// Sequence of results returned from successive [upload] calls. Each call
  /// pops the head; running out yields `Err(unknown)`. Configure by setting
  /// before invocation.
  List<Result<String, MoodFailure>>? uploadResults;

  /// Captures every `(userId, moodId, media)` triple passed to [upload].
  final List<({String userId, String moodId, MoodMedia media})> uploadCalls =
      [];

  /// Captures every `(source, allowMultiple)` pair passed to [pick].
  final List<({MoodMediaSource source, bool allowMultiple})> pickCalls = [];

  @override
  Future<Result<List<MoodMedia>, MoodFailure>> pick({
    required MoodMediaSource source,
    bool allowMultiple = true,
  }) async {
    pickCalls.add((source: source, allowMultiple: allowMultiple));
    return pickResult ?? const Ok(<MoodMedia>[]);
  }

  @override
  Future<Result<String, MoodFailure>> upload({
    required String userId,
    required String moodId,
    required MoodMedia media,
  }) async {
    uploadCalls.add((userId: userId, moodId: moodId, media: media));
    final queue = uploadResults;
    if (queue == null || queue.isEmpty) {
      return const Err(MoodFailure.unknown(null));
    }
    return queue.removeAt(0);
  }
}
