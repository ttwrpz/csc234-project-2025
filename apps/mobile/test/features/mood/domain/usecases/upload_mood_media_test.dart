import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_media.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/usecases/upload_mood_media.dart';

import '../fakes/fake_mood_media_repository.dart';

void main() {
  group('UploadMoodMediaUseCase', () {
    late FakeMoodMediaRepository repo;
    late UploadMoodMediaUseCase usecase;

    const media = MoodMedia(
      localPath: '/tmp/a.jpg',
      kind: MoodMediaKind.image,
      sizeBytes: 1024,
      mimeType: 'image/jpeg',
    );

    setUp(() {
      repo = FakeMoodMediaRepository();
      usecase = UploadMoodMediaUseCase(repository: repo);
    });

    test('forwards args and returns gs:// uri on success', () async {
      repo.uploadResults = [const Ok('gs://bucket/users/u-1/media/m-1/x.jpg')];
      final result = await usecase(
        userId: 'u-1',
        moodId: 'm-1',
        media: media,
      );
      expect(result, isA<Ok<String, MoodFailure>>());
      expect(result.getOrNull(), 'gs://bucket/users/u-1/media/m-1/x.jpg');
      expect(repo.uploadCalls.single.userId, 'u-1');
      expect(repo.uploadCalls.single.moodId, 'm-1');
      expect(repo.uploadCalls.single.media, media);
    });

    test('passes through mediaTooLarge failure', () async {
      repo.uploadResults = [const Err(MoodFailure.mediaTooLarge(30000000))];
      final result = await usecase(
        userId: 'u-1',
        moodId: 'm-1',
        media: media,
      );
      expect(result, isA<Err<String, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_MediaTooLarge',
      );
    });

    test('passes through mediaUploadFailed failure', () async {
      repo.uploadResults = [const Err(MoodFailure.mediaUploadFailed('quota'))];
      final result = await usecase(
        userId: 'u-1',
        moodId: 'm-1',
        media: media,
      );
      expect(result, isA<Err<String, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_MediaUploadFailed',
      );
    });
  });
}
