import 'package:core/core.dart';

import '../entities/mood_media.dart';
import '../mood_failure.dart';
import '../repositories/mood_media_repository.dart';

/// Asks the [MoodMediaRepository] for one or more media items.
///
/// Pure-Dart use case (no Flutter / Firebase imports). The Riverpod provider
/// for this class lives in `mood/data/providers.dart` - see CLAUDE.md "Use
/// cases" section.
class PickMoodMediaUseCase {
  const PickMoodMediaUseCase({required MoodMediaRepository repository})
    : _repository = repository;

  final MoodMediaRepository _repository;

  Future<Result<List<MoodMedia>, MoodFailure>> call({
    required MoodMediaSource source,
    bool allowMultiple = true,
  }) {
    return _repository.pick(source: source, allowMultiple: allowMultiple);
  }
}
