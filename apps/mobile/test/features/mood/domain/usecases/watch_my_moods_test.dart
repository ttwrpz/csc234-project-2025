import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/usecases/watch_my_moods.dart';

import '../fakes/fake_mood_repository.dart';

void main() {
  group('WatchMyMoodsUseCase', () {
    test('forwards userId to the repository', () async {
      final repo = FakeMoodRepository();
      final entry = MoodEntry(
        id: 'm-1',
        userId: 'u-1',
        mood: MoodType.calm,
        intensity: 3,
        text: '',
        createdAt: DateTime(2026, 4, 28, 10, 0, 0),
      );
      repo.streamedEntries = [
        [entry],
      ];
      final usecase = WatchMyMoodsUseCase(repository: repo);

      final emissions = <List<MoodEntry>>[];
      await usecase(userId: 'u-1').forEach(emissions.add);

      expect(emissions, hasLength(1));
      expect(emissions.single.single.id, 'm-1');
      expect(repo.watchAllCalls.single, 'u-1');
    });

    test('emits an empty list when the repo emits one', () async {
      final repo = FakeMoodRepository();
      repo.streamedEntries = [[]];
      final usecase = WatchMyMoodsUseCase(repository: repo);

      final emissions = <List<MoodEntry>>[];
      await usecase(userId: 'u-2').forEach(emissions.add);

      expect(emissions.single, isEmpty);
    });
  });
}
