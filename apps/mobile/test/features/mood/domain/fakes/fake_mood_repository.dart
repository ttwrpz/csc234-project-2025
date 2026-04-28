import 'package:core/core.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/mood_repository.dart';

/// Hand-rolled fake mirroring the auth feature's `FakeAuthRepository` pattern.
/// We don't use mockito in S2 — keeps generated code count low and tests
/// readable.
class FakeMoodRepository implements MoodRepository {
  FakeMoodRepository({this.saveResult});

  /// Result returned from [save]. If null, defaults to `Err(unknown)`.
  Result<MoodEntry, MoodFailure>? saveResult;

  /// Captures every entry passed to [save] for assertion.
  final List<MoodEntry> saveCalls = [];

  @override
  Stream<List<MoodEntry>> watchAll({required String userId}) async* {
    yield const [];
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> findById({
    required String userId,
    required String id,
  }) async {
    return Err(MoodFailure.notFound(id));
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry) async {
    saveCalls.add(entry);
    return saveResult ?? const Err(MoodFailure.unknown(null));
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry) async {
    return const Err(MoodFailure.unknown(null));
  }

  @override
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  }) async {
    return const Ok(null);
  }
}
