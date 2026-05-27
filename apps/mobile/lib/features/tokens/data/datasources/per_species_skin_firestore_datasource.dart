import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../garden/domain/entities/flower_species.dart';
import '../../domain/entities/per_species_skin.dart';
import '../../domain/entities/per_species_skin_state.dart';
import 'skin_firestore_datasource.dart' show SkinTransactionFailure;

/// Thin Firestore wrapper for the PER-SPECIES skin field on the
/// `users/{userId}` profile document. Strictly additive to
/// [SkinFirestoreDatasource] - it only ever reads / writes the
/// `perSpeciesSkins` field and `tokenBalance`, never the global
/// `unlockedSkinIds` / `equippedSkinId` fields.
///
/// Field shape: `perSpeciesSkins` is a `map` keyed by species name, each
/// value an object with an `unlocked` id list (owned skin ids for that
/// species) and an optional `equipped` id (the currently-equipped id, or
/// absent).
///
/// Species are keyed by [FlowerSpecies.name] (e.g. "sunflower"). Unknown
/// species keys on read are skipped (forward-compat hedge).
class PerSpeciesSkinFirestoreDatasource {
  const PerSpeciesSkinFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _field = 'perSpeciesSkins';

  /// Reads `tokenBalance` + `perSpeciesSkins`, checks the invariants,
  /// debits the balance, appends the new id to that species' unlocked
  /// list, and equips it - all in a single atomic transaction. Throws
  /// [SkinTransactionFailure] when the in-transaction guard fails; the
  /// repository impl maps it back to a `SkinFailure`.
  Future<PerSpeciesSkinState> unlockAndEquip({
    required String userId,
    required PerSpeciesSkin skin,
  }) async {
    if (skin.cost <= 0) {
      // Per-species defaults are the built-in colour, never purchased.
      throw const SkinTransactionFailure.alreadyUnlocked();
    }

    final ref = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction<PerSpeciesSkinState>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, Object?>{};
      final currentBalance = (data['tokenBalance'] as int?) ?? 0;

      if (currentBalance < skin.cost) {
        throw SkinTransactionFailure.insufficientTokens(
          required: skin.cost,
          available: currentBalance,
        );
      }

      final state = _readState(data);
      if (state.isUnlocked(skin.species, skin.id)) {
        throw const SkinTransactionFailure.alreadyUnlocked();
      }

      final next = _withUnlockedAndEquipped(state, skin);

      tx.update(ref, <String, Object?>{
        'tokenBalance': currentBalance - skin.cost,
        _field: _toFirestore(next),
      });

      return next;
    });
  }

  /// Sets the equipped per-species skin for [species] (or clears it when
  /// [skinId] is `null`) without reading or writing the balance.
  Future<PerSpeciesSkinState> equip({
    required String userId,
    required FlowerSpecies species,
    required String? skinId,
  }) async {
    final ref = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction<PerSpeciesSkinState>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, Object?>{};
      final state = _readState(data);
      final next = _withEquipped(state, species, skinId);
      tx.update(ref, <String, Object?>{_field: _toFirestore(next)});
      return next;
    });
  }

  /// Streams the live per-species snapshot. Empty / missing field
  /// resolves to [PerSpeciesSkinState.initial].
  Stream<PerSpeciesSkinState> watchState({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((s) => _readState(s.data() ?? <String, Object?>{}));
  }

  // ----- (de)serialization helpers -----

  static PerSpeciesSkinState _readState(Map<String, Object?> data) {
    final raw = data[_field];
    if (raw is! Map) return PerSpeciesSkinState.initial();

    final unlocked = <FlowerSpecies, Set<String>>{};
    final equipped = <FlowerSpecies, String>{};
    raw.forEach((key, value) {
      if (key is! String || value is! Map) return;
      final species = _speciesByName(key);
      if (species == null) return;

      final unlockedRaw = value['unlocked'];
      if (unlockedRaw is List) {
        final ids = <String>{
          for (final id in unlockedRaw)
            if (id is String) id,
        };
        if (ids.isNotEmpty) unlocked[species] = ids;
      }

      final equippedRaw = value['equipped'];
      if (equippedRaw is String && equippedRaw.isNotEmpty) {
        equipped[species] = equippedRaw;
      }
    });

    return PerSpeciesSkinState(unlocked: unlocked, equipped: equipped);
  }

  static Map<String, Object?> _toFirestore(PerSpeciesSkinState state) {
    final out = <String, Object?>{};
    final species = <FlowerSpecies>{
      ...state.unlocked.keys,
      ...state.equipped.keys,
    };
    for (final s in species) {
      final ids = state.unlocked[s] ?? const <String>{};
      final equipped = state.equipped[s];
      out[s.name] = <String, Object?>{
        'unlocked': ids.toList(),
        // Null-aware element: omits the `equipped` key entirely when no
        // per-species skin is equipped for this species.
        'equipped': ?equipped,
      };
    }
    return out;
  }

  static PerSpeciesSkinState _withUnlockedAndEquipped(
    PerSpeciesSkinState state,
    PerSpeciesSkin skin,
  ) {
    final unlocked = <FlowerSpecies, Set<String>>{
      for (final entry in state.unlocked.entries) entry.key: {...entry.value},
    };
    unlocked.update(
      skin.species,
      (existing) => {...existing, skin.id},
      ifAbsent: () => {skin.id},
    );
    final equipped = <FlowerSpecies, String>{...state.equipped}
      ..[skin.species] = skin.id;
    return PerSpeciesSkinState(unlocked: unlocked, equipped: equipped);
  }

  static PerSpeciesSkinState _withEquipped(
    PerSpeciesSkinState state,
    FlowerSpecies species,
    String? skinId,
  ) {
    final equipped = <FlowerSpecies, String>{...state.equipped};
    if (skinId == null) {
      equipped.remove(species);
    } else {
      equipped[species] = skinId;
    }
    return PerSpeciesSkinState(unlocked: state.unlocked, equipped: equipped);
  }

  static FlowerSpecies? _speciesByName(String name) {
    for (final v in FlowerSpecies.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
