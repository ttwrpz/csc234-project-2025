import 'package:core/core.dart';
import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/tokens/domain/entities/garden_skin.dart';
import 'package:moodbloom/features/tokens/domain/entities/skin_state.dart';
import 'package:moodbloom/features/tokens/domain/repositories/skin_repository.dart';
import 'package:moodbloom/features/tokens/domain/services/garden_skin_catalog.dart';
import 'package:moodbloom/features/tokens/domain/skin_failure.dart';
import 'package:moodbloom/features/tokens/domain/usecases/unlock_garden_skin.dart';

/// Records every call to `unlockAndEquip` / `equip` so the test can
/// assert which branch the use case took. `unlockAndEquip` always
/// succeeds in this fake; tests that need a failure path simply set
/// `nextResult` to an `Err`.
class _RecordingSkinRepository implements SkinRepository {
  Result<SkinState, SkinFailure>? nextResult;
  GardenSkin? lastUnlockedSkin;
  int unlockAndEquipCalls = 0;
  int equipCalls = 0;

  @override
  Future<Result<SkinState, SkinFailure>> unlockAndEquip({
    required String userId,
    required GardenSkin skin,
  }) async {
    unlockAndEquipCalls += 1;
    lastUnlockedSkin = skin;
    return nextResult ??
        Ok(
          SkinState(
            equippedSkinId: skin.id,
            unlockedSkinIds: <GardenSkinId>{GardenSkinId.meadow, skin.id},
          ),
        );
  }

  @override
  Future<Result<SkinState, SkinFailure>> equip({
    required String userId,
    required GardenSkinId id,
  }) async {
    equipCalls += 1;
    throw UnsupportedError('equip is not exercised by the unlock use case');
  }

  @override
  Stream<SkinState> watchSkinState({required String userId}) =>
      const Stream.empty();
}

const _meadowOnly = SkinState(
  equippedSkinId: GardenSkinId.meadow,
  unlockedSkinIds: <GardenSkinId>{GardenSkinId.meadow},
);

void main() {
  group('UnlockGardenSkinUseCase - happy path', () {
    test('forwards a valid purchase to the repository', () async {
      final repo = _RecordingSkinRepository();
      final useCase = UnlockGardenSkinUseCase(repo);

      final result = await useCase(
        userId: 'u-1',
        id: GardenSkinId.origami,
        currentState: _meadowOnly,
        // Origami costs 12 (see GardenSkinCatalog). 20 > 12 so the
        // balance guard passes.
        currentBalance: 20,
      );

      expect(
        result,
        isA<Ok<SkinState, SkinFailure>>(),
        reason: 'sufficient balance must succeed',
      );
      expect(repo.unlockAndEquipCalls, 1);
      expect(repo.lastUnlockedSkin?.id, GardenSkinId.origami);
      // The use case forwards the catalog entry verbatim, not a
      // re-constructed `GardenSkin`, so price drift never sneaks past.
      expect(
        repo.lastUnlockedSkin,
        same(GardenSkinCatalog.byId(GardenSkinId.origami)),
      );
    });
  });

  group('UnlockGardenSkinUseCase - failure modes', () {
    test('blocks purchase when balance is below cost', () async {
      final repo = _RecordingSkinRepository();
      final useCase = UnlockGardenSkinUseCase(repo);

      final result = await useCase(
        userId: 'u-1',
        id: GardenSkinId.lantern, // costs 20
        currentState: _meadowOnly,
        currentBalance: 5,
      );

      expect(result, isA<Err<SkinState, SkinFailure>>());
      result.fold(
        ok: (_) => fail('insufficient balance must short-circuit'),
        err: (failure) {
          expect(failure, isA<SkinFailure>());
          final ins = failure as dynamic;
          // _InsufficientTokens is private but the use case constructs
          // it via the public factory, so we assert via the structural
          // `required` / `available` getters that come for free.
          expect(ins.required, equals(20));
          expect(ins.available, equals(5));
        },
      );
      expect(
        repo.unlockAndEquipCalls,
        0,
        reason:
            'guard must run BEFORE the repo - we never want a Firestore '
            'transaction to fire for a known-failed purchase',
      );
    });

    test('blocks purchase when skin is already in the user pool', () async {
      final repo = _RecordingSkinRepository();
      final useCase = UnlockGardenSkinUseCase(repo);

      const stateWithOrigami = SkinState(
        equippedSkinId: GardenSkinId.origami,
        unlockedSkinIds: <GardenSkinId>{
          GardenSkinId.meadow,
          GardenSkinId.origami,
        },
      );

      final result = await useCase(
        userId: 'u-1',
        id: GardenSkinId.origami,
        currentState: stateWithOrigami,
        currentBalance: 999,
      );

      expect(result, isA<Err<SkinState, SkinFailure>>());
      expect(repo.unlockAndEquipCalls, 0);
    });

    test('blocks purchase of the free default (Meadow)', () async {
      final repo = _RecordingSkinRepository();
      final useCase = UnlockGardenSkinUseCase(repo);

      final result = await useCase(
        userId: 'u-1',
        id: GardenSkinId.meadow,
        // Pretend the pool has been cleared somehow - the cost == 0
        // guard fires before the already-unlocked guard.
        currentState: const SkinState(
          equippedSkinId: GardenSkinId.meadow,
          unlockedSkinIds: <GardenSkinId>{},
        ),
        currentBalance: 999,
      );

      expect(result, isA<Err<SkinState, SkinFailure>>());
      expect(repo.unlockAndEquipCalls, 0);
    });

    test('blocks purchase with empty userId', () async {
      final repo = _RecordingSkinRepository();
      final useCase = UnlockGardenSkinUseCase(repo);

      final result = await useCase(
        userId: '',
        id: GardenSkinId.origami,
        currentState: _meadowOnly,
        currentBalance: 999,
      );

      expect(result, isA<Err<SkinState, SkinFailure>>());
      expect(repo.unlockAndEquipCalls, 0);
    });
  });
}
