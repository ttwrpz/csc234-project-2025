import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/entities/flower_skin.dart';
import 'package:moodbloom/features/tokens/domain/entities/skin_state.dart';
import 'package:moodbloom/features/tokens/domain/repositories/skin_repository.dart';
import 'package:moodbloom/features/tokens/domain/services/skin_catalog.dart';
import 'package:moodbloom/features/tokens/domain/skin_failure.dart';
import 'package:moodbloom/features/tokens/domain/usecases/unlock_flower_skin.dart';

/// Hand-rolled fake mirroring the existing `FakeMoodRepository` pattern.
/// Captures every call + lets each test pin a deterministic outcome.
class _FakeSkinRepo implements SkinRepository {
  final List<({String userId, FlowerSkin skin})> unlockCalls = [];
  final List<
    ({String userId, FlowerSpecies species, String skinId})
  > selectCalls = [];

  /// When non-null, the next `unlockAndSelect` returns this result.
  Result<SkinState, SkinFailure>? unlockResult;

  @override
  Future<Result<SkinState, SkinFailure>> unlockAndSelect({
    required String userId,
    required FlowerSkin skin,
  }) async {
    unlockCalls.add((userId: userId, skin: skin));
    return unlockResult ??
        Ok(
          SkinState(
            unlockedBySpecies: {
              skin.species: {skin.skinId},
            },
            selectedBySpecies: {skin.species: skin.skinId},
          ),
        );
  }

  @override
  Future<Result<SkinState, SkinFailure>> select({
    required String userId,
    required FlowerSpecies species,
    required String skinId,
  }) async {
    selectCalls.add((userId: userId, species: species, skinId: skinId));
    return Ok(
      SkinState(
        unlockedBySpecies: const {},
        selectedBySpecies: {species: skinId},
      ),
    );
  }

  @override
  Stream<SkinState> watchSkinState({required String userId}) =>
      Stream<SkinState>.value(SkinState.empty());
}

void main() {
  group('UnlockFlowerSkinUseCase', () {
    late _FakeSkinRepo repo;
    late UnlockFlowerSkinUseCase useCase;

    setUp(() {
      repo = _FakeSkinRepo();
      useCase = UnlockFlowerSkinUseCase(repo);
    });

    test('happy path → repo called with userId + canonical catalog skin', () async {
      final catalogSkin = SkinCatalog.byId('sunflower_sunset')!;
      final outcome = await useCase(
        userId: 'uid-1',
        skin: catalogSkin,
        currentState: SkinState.empty(),
      );

      expect(outcome, isA<Ok<SkinState, SkinFailure>>());
      expect(repo.unlockCalls, hasLength(1));
      expect(repo.unlockCalls.single.userId, 'uid-1');
      expect(repo.unlockCalls.single.skin.skinId, 'sunflower_sunset');
    });

    test('empty userId → Err(network), no repo call', () async {
      final catalogSkin = SkinCatalog.byId('sunflower_sunset')!;
      final outcome = await useCase(
        userId: '',
        skin: catalogSkin,
        currentState: SkinState.empty(),
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
      expect(repo.unlockCalls, isEmpty);
    });

    test('default skin → Err(alreadyUnlocked), no repo call', () async {
      final defaultSkin = SkinCatalog.defaultFor(FlowerSpecies.sunflower);
      final outcome = await useCase(
        userId: 'uid-1',
        skin: defaultSkin,
        currentState: SkinState.empty(),
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) =>
            expect(f.runtimeType.toString(), contains('AlreadyUnlocked')),
      );
      expect(repo.unlockCalls, isEmpty);
    });

    test('unknown skinId → Err(unknownSkin), no repo call', () async {
      const bogus = FlowerSkin(
        skinId: 'not_in_catalog',
        species: FlowerSpecies.sunflower,
        displayName: 'Forged',
        cost: 1,
        isDefault: false,
        paletteSeed: 99,
      );
      final outcome = await useCase(
        userId: 'uid-1',
        skin: bogus,
        currentState: SkinState.empty(),
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('UnknownSkin')),
      );
      expect(repo.unlockCalls, isEmpty);
    });

    test('already-unlocked skin → Err(alreadyUnlocked), no repo call', () async {
      final catalogSkin = SkinCatalog.byId('sunflower_sunset')!;
      final state = SkinState(
        unlockedBySpecies: {
          FlowerSpecies.sunflower: {'sunflower_sunset'},
        },
        selectedBySpecies: const {},
      );
      final outcome = await useCase(
        userId: 'uid-1',
        skin: catalogSkin,
        currentState: state,
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) =>
            expect(f.runtimeType.toString(), contains('AlreadyUnlocked')),
      );
      expect(repo.unlockCalls, isEmpty);
    });

    test('repo failure is surfaced verbatim to caller', () async {
      final catalogSkin = SkinCatalog.byId('sunflower_sunset')!;
      repo.unlockResult = const Err(
        SkinFailure.insufficientTokens(required: 50, available: 12),
      );
      final outcome = await useCase(
        userId: 'uid-1',
        skin: catalogSkin,
        currentState: SkinState.empty(),
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) =>
            expect(f.runtimeType.toString(), contains('InsufficientTokens')),
      );
      expect(repo.unlockCalls, hasLength(1));
    });

    test('uses catalog price even when caller passes a stale lower price',
        () async {
      // Defense-in-depth: a malicious or stale client could pass a
      // FlowerSkin with cost: 1 even though the catalog has 50. The
      // use case must forward the CANONICAL skin (from SkinCatalog) to
      // the repository, never the stale caller-supplied entity.
      const stale = FlowerSkin(
        skinId: 'sunflower_sunset',
        species: FlowerSpecies.sunflower,
        displayName: 'Sunset Sunflower',
        cost: 1, // wrong price
        isDefault: false,
        paletteSeed: 12,
      );
      final outcome = await useCase(
        userId: 'uid-1',
        skin: stale,
        currentState: SkinState.empty(),
      );
      expect(outcome, isA<Ok<SkinState, SkinFailure>>());
      // Repo was called with the canonical catalog cost (50), not the
      // stale caller-supplied 1.
      expect(repo.unlockCalls, hasLength(1));
      expect(repo.unlockCalls.single.skin.cost, 50);
    });
  });
}
