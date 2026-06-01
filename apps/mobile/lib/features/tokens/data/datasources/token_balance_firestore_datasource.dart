import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/token_award.dart';
import '../../domain/entities/token_balance.dart';
import '../../domain/services/award_daily_tokens.dart';

/// Thin Firestore wrapper for the three token-economy fields on the
/// `users/{userId}` profile document - pivot feature #10 (CLAUDE.md
/// "Firestore data model").
///
/// NOT a sub-collection. The fields live alongside `displayName`,
/// `photoUrl`, etc., so a single `users/{uid}` read returns the entire
/// profile + token state in one round-trip.
///
/// The award path runs inside a Firestore transaction so two devices
/// logging concurrently never lose an increment - the transaction
/// re-runs `awardDailyTokens` on each retry against the latest snapshot
/// of the doc, and the final write commits atomically.
///
/// Field names match the rules in `firebase/firestore.rules` (architect
/// commit lands the field-level validation):
///   * `tokenBalance` - int, monotonic-up via this datasource.
///   * `tokensEarnedToday` - int, 0..10.
///   * `lastTokenEarnedDate` - Firestore [Timestamp]; null when the
///     user has never earned (first lifetime log path).
class TokenBalanceFirestoreDatasource {
  const TokenBalanceFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Runs the read-compute-write transaction. Throws on Firestore
  /// errors; the repository impl translates them to `TokenFailure`.
  ///
  /// [now] is injected so unit tests can pin a deterministic clock.
  /// Production passes `DateTime.now()`.
  Future<TokenAward> awardForLog({
    required String userId,
    required DateTime now,
  }) async {
    final ref = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<TokenAward>((tx) async {
      final snap = await tx.get(ref);
      final current = _balanceFromSnapshot(snap);

      final award = awardDailyTokens(current: current, now: now);

      // Skip the write entirely when nothing changed (cap reached).
      // Saves a round-trip + keeps `tokenBalance` strictly monotonic
      // even when the rule would have permitted equality.
      if (award.award == 0) {
        return award;
      }

      final lastDate = award.updated.lastEarnedDate;
      tx.update(ref, <String, Object?>{
        'tokenBalance': award.updated.balance,
        'tokensEarnedToday': award.updated.earnedToday,
        'lastTokenEarnedDate': lastDate == null
            ? null
            : Timestamp.fromDate(lastDate),
      });

      return award;
    });
  }

  /// Debug-only grant that bumps `tokenBalance` by [amount] inside a
  /// transaction without mutating `tokensEarnedToday` /
  /// `lastTokenEarnedDate`. Mirrors [awardForLog] for the read-compute-
  /// write idiom so concurrent grants from two devices never lose an
  /// increment. The Firestore rule permits monotonic-up writes to
  /// `tokenBalance` from any owner, so no rule changes are needed.
  ///
  /// Returns a [TokenAward] with `award = amount` and the resulting
  /// balance so the caller can render an immediate snackbar without a
  /// follow-up read.
  Future<TokenAward> grantDebug({
    required String userId,
    required int amount,
  }) async {
    final ref = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<TokenAward>((tx) async {
      final snap = await tx.get(ref);
      final current = _balanceFromSnapshot(snap);
      final next = TokenBalance(
        balance: current.balance + amount,
        earnedToday: current.earnedToday,
        lastEarnedDate: current.lastEarnedDate,
      );

      tx.update(ref, <String, Object?>{'tokenBalance': next.balance});

      return TokenAward(award: amount, updated: next);
    });
  }

  /// Streams the live token-balance snapshot. Empty / missing fields
  /// resolve to a fresh-user default ({balance: 0, earnedToday: 0,
  /// lastEarnedDate: null}) so the chip renders sensibly during the
  /// short window between sign-up and the first user-doc write.
  Stream<TokenBalance> watchBalance({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map(_balanceFromSnapshot);
  }

  /// Decodes the three token fields from a `users/{uid}` snapshot.
  /// Tolerant of partial docs (any field can be missing during the
  /// account-creation window).
  TokenBalance _balanceFromSnapshot(DocumentSnapshot<Map<String, Object?>> s) {
    final data = s.data();
    if (data == null) {
      return const TokenBalance(
        balance: 0,
        earnedToday: 0,
        lastEarnedDate: null,
      );
    }
    final balance = (data['tokenBalance'] as int?) ?? 0;
    final earnedToday = (data['tokensEarnedToday'] as int?) ?? 0;
    final lastTs = data['lastTokenEarnedDate'];
    final lastDate = lastTs is Timestamp ? lastTs.toDate() : null;
    return TokenBalance(
      balance: balance,
      earnedToday: earnedToday,
      lastEarnedDate: lastDate,
    );
  }
}
