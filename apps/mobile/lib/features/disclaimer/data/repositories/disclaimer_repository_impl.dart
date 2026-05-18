import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../../domain/disclaimer_failure.dart';
import '../../domain/repositories/disclaimer_repository.dart';
import '../datasources/disclaimer_firestore_datasource.dart';

/// Firestore-backed implementation of [DisclaimerRepository].
///
/// Failure mapping mirrors `PatternRepositoryImpl` and
/// `HarvestRepositoryImpl`:
///   * `'permission-denied'` → [DisclaimerFailure.permissionDenied] —
///     the firestore.rule rejected the write (e.g. another uid in the
///     path, or the rule guard blocked a `true → false` revert).
///   * `'unavailable'` / `'deadline-exceeded'` / `'cancelled'` →
///     [DisclaimerFailure.network] (transient; the next ack tap
///     retries).
///   * everything else → [DisclaimerFailure.unknown] with the
///     exception's `code` (PII-free, safe to log).
class DisclaimerRepositoryImpl implements DisclaimerRepository {
  const DisclaimerRepositoryImpl({
    required DisclaimerFirestoreDatasource datasource,
  }) : _datasource = datasource;

  final DisclaimerFirestoreDatasource _datasource;

  @override
  Stream<bool> watchAckState({required String userId}) {
    if (userId.isEmpty) return Stream.value(false);
    return _datasource.watchAckState(userId: userId);
  }

  @override
  Future<Result<void, DisclaimerFailure>> ack({required String userId}) async {
    if (userId.isEmpty) {
      // Defense-in-depth — caller is the ack dialog which gates on a
      // signed-in user, but a stale ref shouldn't round-trip a
      // malformed write. Network is the closest "transient, retry"
      // semantic.
      return const Err(DisclaimerFailure.network());
    }
    try {
      await _datasource.ack(userId: userId);
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(_failureFor(e));
    } catch (e) {
      return Err(DisclaimerFailure.unknown(e.runtimeType.toString()));
    }
  }

  DisclaimerFailure _failureFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const DisclaimerFailure.permissionDenied();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return const DisclaimerFailure.network();
      default:
        return DisclaimerFailure.unknown(e.code);
    }
  }
}
