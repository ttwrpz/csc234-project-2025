import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:design_system/design_system.dart' show GardenSkinId;

import '../../domain/entities/garden_skin.dart';
import '../../domain/entities/skin_state.dart';

/// Thin Firestore wrapper for the two global-skin fields on the
/// `users/{userId}` profile document.
///
/// Field shape (v1.6 global model):
///   * `unlockedSkinIds` - `List<String>`: the user's owned global skin
///     ids. Always contains "meadow" (the free default).
///   * `equippedSkinId` - `String`: currently active skin id. Defaults
///     to "meadow" if absent.
///
/// Migration from the v1.5 per-species model: the old `unlockedSkins`
/// map field is ignored on read. Users who had per-species unlocks
/// effectively get a fresh start at Meadow. They keep their token
/// balance (which lives in a separate field), so the cost of any new
/// global skin purchase is intentional and visible. This is a locked
/// user decision - the per-species ids (~$20 worth of unlocks across
/// 6 species x 3-4 variants) don't map cleanly to the 5 global skins
/// and a clean cutover beats a partial inheritance heuristic.
class SkinFirestoreDatasource {
  const SkinFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Reads `tokenBalance` + `unlockedSkinIds`, checks the invariants,
  /// debits the balance, appends the new id, and equips it - all in a
  /// single atomic transaction. Throws [SkinTransactionFailure] when
  /// the in-transaction guard fails; the repository impl maps it back
  /// to a [SkinFailure].
  Future<SkinState> unlockAndEquip({
    required String userId,
    required GardenSkin skin,
  }) async {
    if (skin.cost == 0) {
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

      final unlocked = _readUnlockedIds(data);
      if (unlocked.contains(skin.id)) {
        throw const SkinTransactionFailure.alreadyUnlocked();
      }

      final newUnlocked = <GardenSkinId>{...unlocked, skin.id};

      tx.update(ref, <String, Object?>{
        'tokenBalance': currentBalance - skin.cost,
        'unlockedSkinIds': newUnlocked.map((s) => s.name).toList(),
        'equippedSkinId': skin.id.name,
      });

      return SkinState(equippedSkinId: skin.id, unlockedSkinIds: newUnlocked);
    });
  }

  /// Sets `equippedSkinId = id` without reading or writing the balance.
  /// The caller asserts the skin is owned (or is the default Meadow).
  Future<SkinState> equip({
    required String userId,
    required GardenSkinId id,
  }) async {
    final ref = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction<SkinState>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, Object?>{};
      final unlocked = _readUnlockedIds(data);
      // Defensive: if the caller passes an id the user does NOT own,
      // treat it as no-op for the unlocked set but still write
      // equippedSkinId. The Firestore rules can also reject this.
      tx.update(ref, <String, Object?>{'equippedSkinId': id.name});
      return SkinState(equippedSkinId: id, unlockedSkinIds: unlocked);
    });
  }

  /// Streams the live skin-state snapshot. Empty / missing fields
  /// resolve to [SkinState.initial] (meadow equipped, meadow unlocked).
  Stream<SkinState> watchSkinState({required String userId}) {
    return _firestore.collection('users').doc(userId).snapshots().map((s) {
      final data = s.data() ?? <String, Object?>{};
      final unlocked = _readUnlockedIds(data);
      final equipped = _readEquippedId(data);
      return SkinState(equippedSkinId: equipped, unlockedSkinIds: unlocked);
    });
  }

  // ----- (de)serialization helpers -----

  /// Reads `unlockedSkinIds: List<String>`. Always includes Meadow as a
  /// floor (every user owns the default). Old `unlockedSkins` map docs
  /// from the v1.5 per-species model are intentionally ignored - see
  /// the class-level migration note.
  static Set<GardenSkinId> _readUnlockedIds(Map<String, Object?> data) {
    final raw = data['unlockedSkinIds'];
    final out = <GardenSkinId>{GardenSkinId.meadow};
    if (raw is! List) return out;
    for (final item in raw) {
      if (item is! String) continue;
      final id = _idByName(item);
      if (id != null) out.add(id);
    }
    return out;
  }

  /// Reads `equippedSkinId: String`. Falls back to Meadow when absent or
  /// when the value doesn't match any known id (forward-compat hedge).
  static GardenSkinId _readEquippedId(Map<String, Object?> data) {
    final raw = data['equippedSkinId'];
    if (raw is String) {
      final id = _idByName(raw);
      if (id != null) return id;
    }
    return GardenSkinId.meadow;
  }

  static GardenSkinId? _idByName(String name) {
    for (final v in GardenSkinId.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// Sentinel exception thrown inside the transaction body when the
/// pre-write invariants fail. Caught + translated by the repository
/// impl - never surfaces to callers.
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
