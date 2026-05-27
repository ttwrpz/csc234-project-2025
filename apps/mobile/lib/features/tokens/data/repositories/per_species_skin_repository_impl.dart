import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../../../garden/domain/entities/flower_species.dart';
import '../../domain/entities/per_species_skin.dart';
import '../../domain/entities/per_species_skin_state.dart';
import '../../domain/repositories/per_species_skin_repository.dart';
import '../../domain/skin_failure.dart';
import '../datasources/per_species_skin_firestore_datasource.dart';
import '../datasources/skin_firestore_datasource.dart'
    show SkinTransactionFailure, SkinTransactionFailureKind;

/// Firestore-backed implementation of [PerSpeciesSkinRepository].
///
/// Failure mapping mirrors `SkinRepositoryImpl` (the global model):
///   * In-transaction guard failure (insufficient tokens / already
///     unlocked) -> the matching [SkinFailure]. Expected, never logged.
///   * `permission-denied` -> [SkinFailure.permissionDenied].
///   * `unavailable` / `deadline-exceeded` / `cancelled` ->
///     [SkinFailure.network] (transient).
///   * everything else -> [SkinFailure.unknown] with the exception's
///     `code` (PII-free).
class PerSpeciesSkinRepositoryImpl implements PerSpeciesSkinRepository {
  const PerSpeciesSkinRepositoryImpl({
    required PerSpeciesSkinFirestoreDatasource datasource,
  }) : _datasource = datasource;

  final PerSpeciesSkinFirestoreDatasource _datasource;

  @override
  Stream<PerSpeciesSkinState> watchState({required String userId}) =>
      _datasource.watchState(userId: userId);

  @override
  Future<Result<PerSpeciesSkinState, SkinFailure>> unlockAndEquip({
    required String userId,
    required PerSpeciesSkin skin,
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
  Future<Result<PerSpeciesSkinState, SkinFailure>> equip({
    required String userId,
    required FlowerSpecies species,
    required String? skinId,
  }) async {
    if (userId.isEmpty) {
      return const Err(SkinFailure.network());
    }
    try {
      final updated = await _datasource.equip(
        userId: userId,
        species: species,
        skinId: skinId,
      );
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
