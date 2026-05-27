import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart' show GardenSkinId;

import '../../domain/entities/garden_skin.dart';
import '../../domain/entities/skin_state.dart';
import '../../domain/repositories/skin_repository.dart';
import '../../domain/skin_failure.dart';
import '../datasources/skin_firestore_datasource.dart';

/// Firestore-backed implementation of [SkinRepository].
///
/// Failure mapping mirrors [TokenRepositoryImpl]:
///   * In-transaction guard failure (insufficient tokens / already
///     unlocked) -> [SkinFailure.insufficientTokens] /
///     [SkinFailure.alreadyUnlocked]. Expected failures, never logged
///     as errors.
///   * `permission-denied` -> [SkinFailure.permissionDenied].
///   * `unavailable`, `deadline-exceeded`, `cancelled` ->
///     [SkinFailure.network] (transient).
///   * everything else -> [SkinFailure.unknown] with the exception's
///     `code` as the message (PII-free).
class SkinRepositoryImpl implements SkinRepository {
  const SkinRepositoryImpl({required SkinFirestoreDatasource datasource})
    : _datasource = datasource;

  final SkinFirestoreDatasource _datasource;

  @override
  Stream<SkinState> watchSkinState({required String userId}) =>
      _datasource.watchSkinState(userId: userId);

  @override
  Future<Result<SkinState, SkinFailure>> unlockAndEquip({
    required String userId,
    required GardenSkin skin,
  }) async {
    if (userId.isEmpty) {
      return const Err(SkinFailure.network());
    }
    try {
      final updated = await _datasource.unlockAndEquip(
        userId: userId,
        skin: skin,
      );
      return Ok(updated);
    } on SkinTransactionFailure catch (e) {
      switch (e.kind) {
        case SkinTransactionFailureKind.insufficientTokens:
          return Err(
            SkinFailure.insufficientTokens(
              required: e.required,
              available: e.available,
            ),
          );
        case SkinTransactionFailureKind.alreadyUnlocked:
          return const Err(SkinFailure.alreadyUnlocked());
      }
    } on FirebaseException catch (e) {
      return Err(_failureFor(e));
    } catch (e) {
      return Err(SkinFailure.unknown(e.runtimeType.toString()));
    }
  }

  @override
  Future<Result<SkinState, SkinFailure>> equip({
    required String userId,
    required GardenSkinId id,
  }) async {
    if (userId.isEmpty) {
      return const Err(SkinFailure.network());
    }
    try {
      final updated = await _datasource.equip(userId: userId, id: id);
      return Ok(updated);
    } on FirebaseException catch (e) {
      return Err(_failureFor(e));
    } catch (e) {
      return Err(SkinFailure.unknown(e.runtimeType.toString()));
    }
  }

  SkinFailure _failureFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const SkinFailure.permissionDenied();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return const SkinFailure.network();
      default:
        return SkinFailure.unknown(e.code);
    }
  }
}
