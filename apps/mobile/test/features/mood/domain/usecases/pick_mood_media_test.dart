import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_media.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/repositories/mood_media_repository.dart';
import 'package:moodbloom/features/mood/domain/usecases/pick_mood_media.dart';

import '../fakes/fake_mood_media_repository.dart';

void main() {
  group('PickMoodMediaUseCase', () {
    late FakeMoodMediaRepository repo;
    late PickMoodMediaUseCase usecase;

    setUp(() {
      repo = FakeMoodMediaRepository();
      usecase = PickMoodMediaUseCase(repository: repo);
    });

    test('forwards source and allowMultiple to the repository', () async {
      repo.pickResult = const Ok(<MoodMedia>[]);
      final result = await usecase(
        source: MoodMediaSource.gallery,
        allowMultiple: true,
      );
      expect(result, isA<Ok<List<MoodMedia>, MoodFailure>>());
      expect(repo.pickCalls, hasLength(1));
      expect(repo.pickCalls.single.source, MoodMediaSource.gallery);
      expect(repo.pickCalls.single.allowMultiple, isTrue);
    });

    test('camera source passes allowMultiple = false through', () async {
      repo.pickResult = const Ok(<MoodMedia>[]);
      await usecase(source: MoodMediaSource.camera, allowMultiple: false);
      expect(repo.pickCalls.single.source, MoodMediaSource.camera);
      expect(repo.pickCalls.single.allowMultiple, isFalse);
    });

    test('passes through repository failure', () async {
      repo.pickResult = const Err(MoodFailure.unknown('denied'));
      final result = await usecase(source: MoodMediaSource.gallery);
      expect(result, isA<Err<List<MoodMedia>, MoodFailure>>());
    });

    test('returns the picked list on success', () async {
      const media = MoodMedia(
        localPath: '/tmp/a.jpg',
        kind: MoodMediaKind.image,
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
      );
      repo.pickResult = const Ok([media]);
      final result = await usecase(source: MoodMediaSource.gallery);
      expect(result.getOrNull(), hasLength(1));
      expect(result.getOrNull()!.single.localPath, '/tmp/a.jpg');
    });
  });
}
