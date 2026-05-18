import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../garden/domain/entities/flower_species.dart';
import '../../domain/entities/flower_skin.dart';
import '../../domain/entities/skin_state.dart';

/// Thin Firestore wrapper for the two skin-economy fields on the
/// `users/{userId}` profile document.
///
/// NOT a sub-collection. The fields live alongside `tokenBalance`,
/// `displayName`, `photoUrl`, etc., so a single `users/{uid}` read
/// returns the entire profile + skin state in one round-trip.
///
/// Field shape:
///   * `unlockedSkins` — `map<speciesName, [skinId]>`: per-species list
///     of owned non-default skinIds. NEVER includes the default
///     (defaults are always available without purchase, so storing them
///     would just bloat the doc).
///   * `selectedSkins` — `map<speciesName, skinId>`: per-species active
///     selection. Absent species fall back to the built-in default at
///     render time.
///
/// The unlock path runs inside a Firestore transaction so a concurrent
/// token award from another device never races the spend: we read the
/// live `tokenBalance` + `unlockedSkins[species]` snapshot, check the
/// invariants, and commit the debit + pool append + selection write in
/// a single atomic update. Partial-write is impossible by construction.
///
/// Throws an [SkinTransactionFailure] (a private sentinel) when the
/// invariants fail inside the transaction — the impl translates it
/// back to a [SkinFailure] without leaking Firestore types to callers.
class SkinFirestoreDatasource {
  const SkinFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Runs the read-check-write transaction. Throws
  /// [SkinTransactionFailure] when the in-transaction guard fails
  /// (insufficient tokens / already unlocked); throws [FirebaseException]
  /// on network / permission errors. The repository impl maps both to
  /// [SkinFailure].
  Future<SkinState> unlockAndSelect({
    required String userId,
    required FlowerSkin skin,
  }) async {
    if (skin.isDefault) {
      // Defensive: the use case rejects this path, but a second-line
      // guard ensures a buggy controller can't quietly call us with a
      // free skin and still rack up a Firestore write.
      throw const SkinTransactionFailure.alreadyUnlocked();
    }

    final ref = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction<SkinState>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, Object?>{};
      final currentBalance = (data['tokenBalance'] as int?) ?? 0;

      if (currentBalance < skin.cost) {
        throw SkinTransactionFailure.insufficientTokens(
          required: skin.cost,
          available: currentBalance,
        );
      }

      final unlocked = _readUnlockedMap(data);
      final existingForSpecies = unlocked[skin.species] ?? <String>{};
      if (existingForSpecies.contains(skin.skinId)) {
        throw const SkinTransactionFailure.alreadyUnlocked();
      }

      final newUnlocked = <FlowerSpecies, Set<String>>{
        ...unlocked,
        skin.species: {...existingForSpecies, skin.skinId},
      };
      final newSelected = <FlowerSpecies, String>{
        ..._readSelectedMap(data),
        skin.species: skin.skinId,
      };

      tx.update(ref, <String, Object?>{
        'tokenBalance': currentBalance - skin.cost,
        'unlockedSkins': _writeUnlockedMap(newUnlocked),
        'selectedSkins': _writeSelectedMap(newSelected),
      });

      return SkinState(
        unlockedBySpecies: newUnlocked,
        selectedBySpecies: newSelected,
      );
    });
  }

  /// Sets `selectedSkins[species] = skinId` without reading or writing
  /// the token balance. The caller (a UseCase) asserts the skin is
  /// owned (or is the species default) before invoking. We still run
  /// the write inside `update` rather than `set(merge)` so a stale uid
  /// can never accidentally create a new doc.
  Future<SkinState> select({
    required String userId,
    required FlowerSpecies species,
    required String skinId,
  }) async {
    final ref = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction<SkinState>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, Object?>{};
      final unlocked = _readUnlockedMap(data);
      final newSelected = <FlowerSpecies, String>{
        ..._readSelectedMap(data),
        species: skinId,
      };
      tx.update(ref, <String, Object?>{
        'selectedSkins': _writeSelectedMap(newSelected),
      });
      return SkinState(
        unlockedBySpecies: unlocked,
        selectedBySpecies: newSelected,
      );
    });
  }

  /// Streams the live skin-state snapshot. Empty / missing fields
  /// resolve to [SkinState.empty] so the modal renders sensibly during
  /// the short window between sign-up and the first user-doc write.
  Stream<SkinState> watchSkinState({required String userId}) {
    return _firestore.collection('users').doc(userId).snapshots().map((s) {
      final data = s.data() ?? <String, Object?>{};
      return SkinState(
        unlockedBySpecies: _readUnlockedMap(data),
        selectedBySpecies: _readSelectedMap(data),
      );
    });
  }

  // ───── (de)serialization helpers ─────

  static Map<FlowerSpecies, Set<String>> _readUnlockedMap(
    Map<String, Object?> data,
  ) {
    final raw = data['unlockedSkins'];
    if (raw is! Map) return <FlowerSpecies, Set<String>>{};
    final out = <FlowerSpecies, Set<String>>{};
    for (final entry in raw.entries) {
      final speciesName = entry.key;
      if (speciesName is! String) continue;
      final species = _speciesByName(speciesName);
      if (species == null) continue;
      final list = entry.value;
      if (list is! List) continue;
      final ids = <String>{};
      for (final item in list) {
        if (item is String && item.isNotEmpty) ids.add(item);
      }
      out[species] = ids;
    }
    return out;
  }

  static Map<FlowerSpecies, String> _readSelectedMap(
    Map<String, Object?> data,
  ) {
    final raw = data['selectedSkins'];
    if (raw is! Map) return <FlowerSpecies, String>{};
    final out = <FlowerSpecies, String>{};
    for (final entry in raw.entries) {
      final speciesName = entry.key;
      if (speciesName is! String) continue;
      final species = _speciesByName(speciesName);
      if (species == null) continue;
      final id = entry.value;
      if (id is String && id.isNotEmpty) out[species] = id;
    }
    return out;
  }

  static Map<String, List<String>> _writeUnlockedMap(
    Map<FlowerSpecies, Set<String>> in_,
  ) {
    final out = <String, List<String>>{};
    for (final entry in in_.entries) {
      if (entry.value.isEmpty) continue;
      out[entry.key.name] = entry.value.toList(growable: false);
    }
    return out;
  }

  static Map<String, String> _writeSelectedMap(Map<FlowerSpecies, String> in_) {
    final out = <String, String>{};
    for (final entry in in_.entries) {
      out[entry.key.name] = entry.value;
    }
    return out;
  }

  static FlowerSpecies? _speciesByName(String name) {
    for (final s in FlowerSpecies.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// Sentinel exception thrown inside the transaction body when the
/// pre-write invariants fail. Caught + translated by the repository
/// impl — never surfaces to callers.
///
/// The public unnamed constructor is intentional so tests can spin
/// the sentinel up directly without reaching into private API. The
/// production paths inside this file use the two named factories below
/// for clarity.
class SkinTransactionFailure implements Exception {
  const SkinTransactionFailure({
    required this.kind,
    this.required = 0,
    this.available = 0,
  });

  factory SkinTransactionFailure.insufficientTokens({
    required int required,
    required int available,
  }) => SkinTransactionFailure(
    kind: SkinTransactionFailureKind.insufficientTokens,
    required: required,
    available: available,
  );

  const factory SkinTransactionFailure.alreadyUnlocked() =
      _AlreadyUnlockedTxFailure;

  final SkinTransactionFailureKind kind;
  final int required;
  final int available;
}

class _AlreadyUnlockedTxFailure extends SkinTransactionFailure {
  const _AlreadyUnlockedTxFailure()
    : super(kind: SkinTransactionFailureKind.alreadyUnlocked);
}

enum SkinTransactionFailureKind { insufficientTokens, alreadyUnlocked }
