import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../../domain/entities/token_award.dart';
import '../../domain/entities/token_balance.dart';
import '../../domain/repositories/token_repository.dart';
import '../../domain/token_failure.dart';
import '../datasources/token_balance_firestore_datasource.dart';

/// Firestore-backed implementation of [TokenRepository] — pivot feature
/// #10 (CLAUDE.md), HB-005 §"Track 6.2 — Token economy".
///
/// Failure mapping mirrors `PatternRepositoryImpl`:
///   * `permission-denied` → [TokenFailure.permissionDenied] — the rule
///     rejected the write (e.g. monotonic-down attempt, or stale uid in
///     the path). Surface so the controller doesn't blame transient
///     cloud weather for a programmer error.
///   * `unavailable`, `deadline-exceeded`, `cancelled` →
///     [TokenFailure.network] — transient; the next mood log retries.
///   * everything else → [TokenFailure.unknown] with the exception's
///     `code` as the message (PII-free; the caller logs only the
///     `runtimeType` of the failure).
///
/// The post-save controller (`LogMoodController._awardTokens`) swallows
/// failures and keeps surfacing the user's log success.
class TokenRepositoryImpl implements TokenRepository {
  const TokenRepositoryImpl({
    required TokenBalanceFirestoreDatasource datasource,
    DateTime Function() now = _defaultNow,
  }) : _datasource = datasource,
       _now = now;

  final TokenBalanceFirestoreDatasource _datasource;
  final DateTime Function() _now;

  static DateTime _defaultNow() => DateTime.now();

  @override
  Future<Result<TokenAward, TokenFailure>> awardForLog({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      // Defense-in-depth — caller is `LogMoodController` which already
      // gates on a signed-in user, but a stale ref shouldn't round-trip
      // a malformed write. Network is the closest "transient, retry on
      // next save" semantic.
      return const Err(TokenFailure.network());
    }
    try {
      final award = await _datasource.awardForLog(userId: userId, now: _now());
      return Ok(award);
    } on FirebaseException catch (e) {
      return Err(_failureFor(e));
    } catch (e) {
      return Err(TokenFailure.unknown(e.runtimeType.toString()));
    }
  }

  @override
  Stream<TokenBalance> watchBalance({required String userId}) =>
      _datasource.watchBalance(userId: userId);

  TokenFailure _failureFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const TokenFailure.permissionDenied();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return const TokenFailure.network();
      default:
        return TokenFailure.unknown(e.code);
    }
  }
}
