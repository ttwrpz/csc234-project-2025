import 'package:core/core.dart';

import '../entities/token_award.dart';
import '../entities/token_balance.dart';
import '../token_failure.dart';

/// Contract for any backing store that persists the user's token-economy
/// state.
///
/// Implementations live in `data/` and may use Firestore, Drift, or a
/// fake. The concrete Firestore implementation reads/writes three
/// top-level fields on `users/{uid}` (`tokenBalance`, `tokensEarnedToday`,
/// `lastTokenEarnedDate`) inside a transaction, so concurrent awards from
/// two devices never lose an increment.
///
/// `awardForLog` is best-effort from the caller's perspective: the
/// post-save controller logs the failure but never blocks the user's
/// log-success surfacing on it.
///
/// Pure-Dart contract — imports only `package:core/core.dart` and
/// sibling domain entities. Domain-purity rule per CLAUDE.md.
abstract class TokenRepository {
  /// Atomically reads the user's current token state, computes the
  /// award via [awardDailyTokens], and writes the new state back.
  /// Returns the [TokenAward] (award integer + resulting balance) on
  /// success.
  Future<Result<TokenAward, TokenFailure>> awardForLog({
    required String userId,
  });

  /// Streams the user's current token-balance snapshot. Used by the
  /// garden-screen chip; emits a fresh [TokenBalance] every time the
  /// user-doc changes (token award, skin purchase, etc).
  Stream<TokenBalance> watchBalance({required String userId});

  /// Debug-only escape hatch that increments `tokenBalance` by [amount]
  /// without touching the daily-cap fields (`tokensEarnedToday`,
  /// `lastTokenEarnedDate`). Exists so QA / reviewers can grant
  /// themselves tokens during testing without manufacturing a week of
  /// mood logs. Production callers MUST gate invocations behind
  /// `kDebugMode` — the Firestore rule only permits monotonic-up
  /// increments to `tokenBalance`, so the write succeeds in release
  /// builds too, but no production surface should expose this path.
  ///
  /// Returns the [TokenAward] (award integer + resulting balance) on
  /// success so the caller can render a snackbar with the post-grant
  /// state without a separate read.
  Future<Result<TokenAward, TokenFailure>> grantDebug({
    required String userId,
    required int amount,
  });
}
