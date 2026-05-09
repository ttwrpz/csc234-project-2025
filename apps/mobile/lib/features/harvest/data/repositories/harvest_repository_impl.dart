import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../../domain/entities/weekly_garden.dart';
import '../../domain/harvest_failure.dart';
import '../../domain/repositories/harvest_repository.dart';
import '../datasources/weekly_gardens_firestore_datasource.dart';

/// Firestore-backed implementation of [HarvestRepository] (HB-005
/// Track 6.1).
///
/// Failure mapping mirrors `PatternRepositoryImpl`:
///   * `'already-exists'` → [HarvestFailure.alreadyArchived] — the doc
///     already exists for this weekId. Surfaces TC-11's
///     write-once-on-archive guarantee at the controller layer.
///   * `'permission-denied'` → [HarvestFailure.permissionDenied].
///   * `'unavailable'` / `'deadline-exceeded'` / `'cancelled'` →
///     [HarvestFailure.network] (transient; the next harvest attempt
///     will retry).
///   * everything else → [HarvestFailure.unknown] with the exception's
///     `code` for the post-save logger (PII-free).
class HarvestRepositoryImpl implements HarvestRepository {
  const HarvestRepositoryImpl({
    required WeeklyGardensFirestoreDatasource datasource,
  }) : _datasource = datasource;

  final WeeklyGardensFirestoreDatasource _datasource;

  @override
  Future<Result<WeeklyGarden, HarvestFailure>> archive({
    required String userId,
    required WeeklyGarden garden,
  }) async {
    if (userId.isEmpty) {
      return const Err(HarvestFailure.network());
    }
    try {
      await _datasource.createWeeklyGarden(userId: userId, garden: garden);
      return Ok(garden);
    } on FirebaseException catch (e) {
      return Err(_failureFor(e, weekId: garden.weekId));
    } catch (e) {
      return Err(HarvestFailure.unknown(e.runtimeType.toString()));
    }
  }

  @override
  Stream<List<WeeklyGarden>> watchHistory({required String userId}) {
    if (userId.isEmpty) return const Stream<List<WeeklyGarden>>.empty();
    return _datasource.watchHistory(userId: userId);
  }

  @override
  Future<Result<WeeklyGarden, HarvestFailure>> getByWeekId({
    required String userId,
    required String weekId,
  }) async {
    if (userId.isEmpty) {
      return const Err(HarvestFailure.network());
    }
    try {
      final garden = await _datasource.getByWeekId(
        userId: userId,
        weekId: weekId,
      );
      if (garden == null) {
        return Err(HarvestFailure.unknown('not-found:$weekId'));
      }
      return Ok(garden);
    } on FirebaseException catch (e) {
      return Err(_failureFor(e, weekId: weekId));
    } catch (e) {
      return Err(HarvestFailure.unknown(e.runtimeType.toString()));
    }
  }

  HarvestFailure _failureFor(FirebaseException e, {required String weekId}) {
    switch (e.code) {
      case 'already-exists':
        return HarvestFailure.alreadyArchived(weekId);
      case 'permission-denied':
        return const HarvestFailure.permissionDenied();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return const HarvestFailure.network();
      default:
        return HarvestFailure.unknown(e.code);
    }
  }
}
