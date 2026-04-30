import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_draft.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/usecases/save_mood_entry.dart';

import '../fakes/fake_mood_repository.dart';

void main() {
  group('SaveMoodEntryUseCase', () {
    late FakeMoodRepository repo;
    late SaveMoodEntryUseCase usecase;
    final fixedNow = DateTime.utc(2026, 4, 28, 12);

    setUp(() {
      repo = FakeMoodRepository();
      usecase = SaveMoodEntryUseCase(repository: repo, now: () => fixedNow);
    });

    test('returns malformed without calling repo when mood is null', () async {
      const draft = MoodDraft();
      final result = await usecase(userId: 'u-1', draft: draft);

      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_Malformed',
      );
      expect(repo.saveCalls, isEmpty);
    });

    test('propagates invalidIntensity when intensity = 0', () async {
      const draft = MoodDraft(mood: MoodType.happy, intensity: 0);
      final result = await usecase(userId: 'u-1', draft: draft);

      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_InvalidIntensity',
      );
      expect(repo.saveCalls, isEmpty);
    });

    test('propagates invalidIntensity when intensity = 6', () async {
      const draft = MoodDraft(mood: MoodType.happy, intensity: 6);
      final result = await usecase(userId: 'u-1', draft: draft);

      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_InvalidIntensity',
      );
      expect(repo.saveCalls, isEmpty);
    });

    test('propagates textTooLong when text length = 501', () async {
      final draft = MoodDraft(
        mood: MoodType.happy,
        intensity: 3,
        text: 'a' * 501,
      );
      final result = await usecase(userId: 'u-1', draft: draft);

      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_TextTooLong',
      );
      expect(repo.saveCalls, isEmpty);
    });

    test(
      'forwards to repo on valid input and returns the repo-allocated id',
      () async {
        const allocatedId = 'firestore-id-123';
        repo.saveResult = Ok(
          MoodEntry(
            id: allocatedId,
            userId: 'u-1',
            mood: MoodType.happy,
            intensity: 3,
            text: 'hello',
            createdAt: fixedNow,
          ),
        );
        const draft = MoodDraft(
          mood: MoodType.happy,
          intensity: 3,
          text: 'hello',
        );

        final result = await usecase(userId: 'u-1', draft: draft);

        expect(result, isA<Ok<MoodEntry, MoodFailure>>());
        expect(result.getOrNull()?.id, allocatedId);
        expect(repo.saveCalls, hasLength(1));
        // The entry handed to the repo carries a non-empty sentinel id; the
        // data layer is what allocates the real Firestore id.
        expect(repo.saveCalls.single.userId, 'u-1');
        expect(repo.saveCalls.single.mood, MoodType.happy);
        expect(repo.saveCalls.single.intensity, 3);
        expect(repo.saveCalls.single.text, 'hello');
        expect(repo.saveCalls.single.createdAt, fixedNow);
        expect(repo.saveCalls.single.id, isNotEmpty);
      },
    );

    test('passes through repo failure on network error', () async {
      repo.saveResult = const Err(MoodFailure.network());
      const draft = MoodDraft(mood: MoodType.happy, intensity: 3, text: '');

      final result = await usecase(userId: 'u-1', draft: draft);

      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (result.errOrNull()! as Object).runtimeType.toString(),
        '_Network',
      );
      expect(repo.saveCalls, hasLength(1));
    });
  });
}
