import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/entities/per_species_skin.dart';
import 'package:moodbloom/features/tokens/domain/entities/per_species_skin_state.dart';
import 'package:moodbloom/features/tokens/domain/repositories/per_species_skin_repository.dart';
import 'package:moodbloom/features/tokens/domain/services/per_species_skin_catalog.dart';
import 'package:moodbloom/features/tokens/domain/skin_failure.dart';
import 'package:moodbloom/features/tokens/domain/usecases/unlock_per_species_skin.dart';

/// Records every call to `unlockAndEquip` / `equip` so the test can
/// assert which branch the use case took. `unlockAndEquip` always
/// succeeds in this fake unless `nextResult` is set to an `Err`.
class _RecordingRepo implements PerSpeciesSkinRepository {
  Result<PerSpeciesSkinState, SkinFailure>? nextResult;
  PerSpeciesSkin? lastUnlockedSkin;
  int unlockAndEquipCalls = 0;
  int equipCalls = 0;

  @override
  Future<Result<PerSpeciesSkinState, SkinFailure>> unlockAndEquip({
    required String userId,
    required PerSpeciesSkin skin,
  }) async {
    unlockAndEquipCalls += 1;
    lastUnlockedSkin = skin;
    return nextResult ??
        Ok(
          PerSpeciesSkinState(
            unlocked: <FlowerSpecies, Set<String>>{
              skin.species: {skin.id},
            },
            equipped: <FlowerSpecies, String>{skin.species: skin.id},
          ),
        );
  }

  @override
  Future<Result<PerSpeciesSkinState, SkinFailure>> equip({
    required String userId,
    required FlowerSpecies species,
    required String? skinId,
  }) async {
    equipCalls += 1;
    throw UnsupportedError('equip is not exercised by the unlock use case');
  }

  @override
  Stream<PerSpeciesSkinState> watchState({required String userId}) =>
      const Stream.empty();
}

void main() {
  final goldenHour = PerSpeciesSkinCatalog.byId('sunflower_goldenHour')!;
  final fresh = PerSpeciesSkinState.initial();

  group('UnlockPerSpeciesSkinUseCase - happy path', () {
    test('forwards a valid purchase to the repository', () async {
      final repo = _RecordingRepo();
      final useCase = UnlockPerSpeciesSkinUseCase(repo);

      final result = await useCase(
        userId: 'u-1',
        skin: goldenHour,
        currentState: fresh,
        currentBalance: goldenHour.cost + 5,
      );

      expect(result, isA<Ok<PerSpeciesSkinState, SkinFailure>>());
      expect(repo.unlockAndEquipCalls, 1);
      expect(repo.lastUnlockedSkin, same(goldenHour));
    });
  });

  group('UnlockPerSpeciesSkinUseCase - failure modes', () {
    test('blocks purchase when balance is below cost', () async {
      final repo = _RecordingRepo();
      final useCase = UnlockPerSpeciesSkinUseCase(repo);

      final result = await useCase(
        userId: 'u-1',
        skin: goldenHour,
        currentState: fresh,
        currentBalance: goldenHour.cost - 1,
      );

      expect(result, isA<Err<PerSpeciesSkinState, SkinFailure>>());
      result.fold(
        ok: (_) => fail('insufficient balance must short-circuit'),
        err: (failure) {
          final ins = failure as dynamic;
          expect(ins.required, equals(goldenHour.cost));
          expect(ins.available, equals(goldenHour.cost - 1));
        },
      );
      expect(
        repo.unlockAndEquipCalls,
        0,
        reason: 'guard must run BEFORE any Firestore transaction',
      );
    });

    test('blocks purchase when the skin is already owned', () async {
      final repo = _RecordingRepo();
      final useCase = UnlockPerSpeciesSkinUseCase(repo);

      final owned = PerSpeciesSkinState(
        unlocked: <FlowerSpecies, Set<String>>{
          goldenHour.species: {goldenHour.id},
        },
        equipped: const <FlowerSpecies, String>{},
      );

      final result = await useCase(
        userId: 'u-1',
        skin: goldenHour,
        currentState: owned,
        currentBalance: 999,
      );

      expect(result, isA<Err<PerSpeciesSkinState, SkinFailure>>());
      expect(repo.unlockAndEquipCalls, 0);
    });

    test('blocks purchase with empty userId', () async {
      final repo = _RecordingRepo();
      final useCase = UnlockPerSpeciesSkinUseCase(repo);

      final result = await useCase(
        userId: '',
        skin: goldenHour,
        currentState: fresh,
        currentBalance: 999,
      );

      expect(result, isA<Err<PerSpeciesSkinState, SkinFailure>>());
      expect(repo.unlockAndEquipCalls, 0);
    });
  });
}
