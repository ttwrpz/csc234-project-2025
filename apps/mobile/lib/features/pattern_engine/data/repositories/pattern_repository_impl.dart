import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../../domain/entities/pattern_result.dart';
import '../../domain/pattern_failure.dart';
import '../../domain/repositories/pattern_repository.dart';
import '../datasources/patterns_firestore_datasource.dart';

/// Firestore-backed implementation of [PatternRepository].
///
/// Failure mapping mirrors `CheerUpEventsRepositoryImpl`:
///   * `permission-denied` → [PatternFailure.permissionDenied] — the
///     rule rejected the write (e.g. another uid in the path), surface
///     so the controller doesn't blame transient cloud weather.
///   * `unavailable`, `deadline-exceeded`, `cancelled` → [PatternFailure.network]
///     — transient, the next mood log will retry.
///   * everything else → [PatternFailure.unknown] with the exception
///     `runtimeType` for the post-save logger (PII-free).
///
/// The post-save controller swallows failures and keeps surfacing the
/// user's mood-save success — see `LogMoodController._onSaveOk`.
class PatternRepositoryImpl implements PatternRepository {
  const PatternRepositoryImpl({required PatternsFirestoreDatasource datasource})
    : _datasource = datasource;

  final PatternsFirestoreDatasource _datasource;

  @override
  Future<Result<void, PatternFailure>> save({
    required String userId,
    required PatternResult result,
  }) async {
    if (userId.isEmpty) {
      // Defense-in-depth — caller is `LogMoodController` which already
      // gates on a signed-in user, but a stale ref shouldn't round-trip
      // a malformed write. Network is the closest "transient, retry on
      // next save" semantic.
      return const Err(PatternFailure.network());
    }
    try {
      await _datasource.upsertPatternResult(userId: userId, result: result);
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(_failureFor(e));
    } catch (e) {
      return Err(PatternFailure.unknown(e.runtimeType.toString()));
    }
  }

  @override
  Stream<PatternResult?> watch({
    required String userId,
    required String dateId,
  }) => _datasource.watchPatternResult(userId: userId, dateId: dateId);

  @override
  Stream<List<PatternResult>> watchRange({
    required String userId,
    required String startDateId,
    required String endDateId,
  }) {
    if (userId.isEmpty) return Stream.value(const <PatternResult>[]);
    return _datasource.watchPatternResults(
      userId: userId,
      startDateId: startDateId,
      endDateId: endDateId,
    );
  }

  PatternFailure _failureFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PatternFailure.permissionDenied();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return const PatternFailure.network();
      default:
        return PatternFailure.unknown(e.code);
    }
  }
}
