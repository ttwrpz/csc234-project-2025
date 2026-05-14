import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/data/datasources/skin_firestore_datasource.dart';
import 'package:moodbloom/features/tokens/data/repositories/skin_repository_impl.dart';
import 'package:moodbloom/features/tokens/domain/entities/flower_skin.dart';
import 'package:moodbloom/features/tokens/domain/entities/skin_state.dart';
import 'package:moodbloom/features/tokens/domain/skin_failure.dart';

class _FakeDatasource implements SkinFirestoreDatasource {
  Object? throwOnUnlock;
  SkinState? returnFromUnlock;
  Object? throwOnSelect;
  SkinState? returnFromSelect;

  final List<({String userId, FlowerSkin skin})> unlockCalls = [];
  final List<
    ({String userId, FlowerSpecies species, String skinId})
  > selectCalls = [];

  @override
  Future<SkinState> unlockAndSelect({
    required String userId,
    required FlowerSkin skin,
  }) async {
    unlockCalls.add((userId: userId, skin: skin));
    final t = throwOnUnlock;
    if (t != null) {
      throwOnUnlock = null;
      throw t;
    }
    return returnFromUnlock ?? SkinState.empty();
  }

  @override
  Future<SkinState> select({
    required String userId,
    required FlowerSpecies species,
    required String skinId,
  }) async {
    selectCalls.add((userId: userId, species: species, skinId: skinId));
    final t = throwOnSelect;
    if (t != null) {
      throwOnSelect = null;
      throw t;
    }
    return returnFromSelect ?? SkinState.empty();
  }

  @override
  Stream<SkinState> watchSkinState({required String userId}) =>
      const Stream<SkinState>.empty();
}

const _catalogSkin = FlowerSkin(
  skinId: 'sunflower_sunset',
  species: FlowerSpecies.sunflower,
  displayName: 'Sunset Sunflower',
  cost: 50,
  isDefault: false,
  paletteSeed: 12,
);

void main() {
  group('SkinRepositoryImpl.unlockAndSelect', () {
    late _FakeDatasource ds;
    late SkinRepositoryImpl repo;

    setUp(() {
      ds = _FakeDatasource();
      repo = SkinRepositoryImpl(datasource: ds);
    });

    test('happy path → Ok carrying datasource result', () async {
      final newState = SkinState(
        unlockedBySpecies: {
          FlowerSpecies.sunflower: {'sunflower_sunset'},
        },
        selectedBySpecies: const {FlowerSpecies.sunflower: 'sunflower_sunset'},
      );
      ds.returnFromUnlock = newState;
      final outcome = await repo.unlockAndSelect(
        userId: 'uid-1',
        skin: _catalogSkin,
      );
      expect(outcome, isA<Ok<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (s) => expect(s, newState),
        err: (_) => fail('expected Ok'),
      );
      expect(ds.unlockCalls.single.userId, 'uid-1');
    });

    test('empty userId → Err(network), no datasource call', () async {
      final outcome = await repo.unlockAndSelect(
        userId: '',
        skin: _catalogSkin,
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
      expect(ds.unlockCalls, isEmpty);
    });

    test('SkinTransactionFailure(insufficient) → Err(insufficientTokens)',
        () async {
      ds.throwOnUnlock = const SkinTransactionFailure(
        kind: SkinTransactionFailureKind.insufficientTokens,
      );
      final outcome = await repo.unlockAndSelect(
        userId: 'uid-1',
        skin: _catalogSkin,
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) =>
            expect(f.runtimeType.toString(), contains('InsufficientTokens')),
      );
    });

    test('SkinTransactionFailure(alreadyUnlocked) → Err(alreadyUnlocked)',
        () async {
      ds.throwOnUnlock = const SkinTransactionFailure(
        kind: SkinTransactionFailureKind.alreadyUnlocked,
      );
      final outcome = await repo.unlockAndSelect(
        userId: 'uid-1',
        skin: _catalogSkin,
      );
      expect(outcome, isA<Err<SkinState, SkinFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) =>
            expect(f.runtimeType.toString(), contains('AlreadyUnlocked')),
      );
    });

    test('permission-denied → Err(permissionDenied)', () async {
      ds.throwOnUnlock = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      final outcome = await repo.unlockAndSelect(
        userId: 'uid-1',
        skin: _catalogSkin,
      );
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Permission')),
      );
    });

    test('unavailable → Err(network)', () async {
      ds.throwOnUnlock = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      final outcome = await repo.unlockAndSelect(
        userId: 'uid-1',
        skin: _catalogSkin,
      );
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
    });

    test('arbitrary FirebaseException → Err(unknown)', () async {
      ds.throwOnUnlock = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'something-totally-new',
      );
      final outcome = await repo.unlockAndSelect(
        userId: 'uid-1',
        skin: _catalogSkin,
      );
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Unknown')),
      );
    });

    test('non-FirebaseException catch-all → Err(unknown)', () async {
      ds.throwOnUnlock = StateError('arbitrary failure');
      final outcome = await repo.unlockAndSelect(
        userId: 'uid-1',
        skin: _catalogSkin,
      );
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Unknown')),
      );
    });
  });

  group('SkinRepositoryImpl.select', () {
    test('forwards args to datasource and wraps Ok', () async {
      final ds = _FakeDatasource();
      final newState = SkinState(
        unlockedBySpecies: const {},
        selectedBySpecies: const {FlowerSpecies.lavender: 'lavender_default'},
      );
      ds.returnFromSelect = newState;
      final repo = SkinRepositoryImpl(datasource: ds);
      final outcome = await repo.select(
        userId: 'uid-1',
        species: FlowerSpecies.lavender,
        skinId: 'lavender_default',
      );
      expect(outcome, isA<Ok<SkinState, SkinFailure>>());
      expect(ds.selectCalls.single.species, FlowerSpecies.lavender);
      expect(ds.selectCalls.single.skinId, 'lavender_default');
    });
  });
}
