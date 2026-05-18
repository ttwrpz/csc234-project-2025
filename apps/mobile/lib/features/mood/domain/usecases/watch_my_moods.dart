import '../entities/mood_entry.dart';
import '../mood_repository.dart';

/// Streams the current user's mood entries ordered newest-first. Consumed by
/// the History list and analytics that need a reactive history feed.
class WatchMyMoodsUseCase {
  const WatchMyMoodsUseCase({required MoodRepository repository})
    : _repository = repository;

  final MoodRepository _repository;

  Stream<List<MoodEntry>> call({required String userId}) {
    return _repository.watchAll(userId: userId);
  }
}
