import 'package:core/core.dart';

import '../entities/token_award.dart';
import '../entities/token_balance.dart';

/// Pure-Dart token-award engine.
///
/// MOOD-AGNOSTIC by construction. The function takes only the current
/// [TokenBalance] state and `now` — there is no emotion-content
/// parameter, no behaviour that depends on what the user logged.
/// Logging a sad-5 entry earns the same as logging a joy-5 entry. This
/// is THE load-bearing property of the design (Cheng et al. 2019 —
/// gamification that rewards emotion content punishes the user on
/// negative-feeling days, the exact opposite of self-compassion).
///
/// The mood-agnostic invariant is enforced two ways:
///   1. The function signature has no emotion-content parameter — the
///      type system makes it impossible to call with one.
///   2. A file-level grep in `award_daily_tokens_test.dart` asserts
///      this source file contains zero references to the emotion-
///      feature filenames or class names. Any future change that adds
///      such an import trips the test.
///
/// Algorithm:
///   1. `today = localMidnight(now)`.
///   2. If `current.lastEarnedDate` is null OR a different calendar day
///      than `today`: this is the first log of the day. `award = 5`,
///      `earnedToday = 5`, `lastEarnedDate = today`. Missed days lose
///      nothing — `current.balance` is preserved verbatim (no reset).
///   3. Else (same calendar day):
///        * If `current.earnedToday < 10`: `award = 1`,
///          `earnedToday = current.earnedToday + 1`.
///        * Else (cap reached): `award = 0`, every field unchanged.
///   4. `updated = TokenBalance(balance: current.balance + award, ...)`.
///
/// The function NEVER decreases `balance`. Skin purchases use a
/// separate `SpendTokensUseCase`.
///
/// "Same calendar day" is decided via [localMidnight] equality, not raw
/// 24h elapsed. An entry at 23:59 yesterday + an entry at 00:01 today
/// is correctly two distinct first-logs-of-day, even though only 2
/// minutes elapsed.
TokenAward awardDailyTokens({
  required TokenBalance current,
  required DateTime now,
}) {
  final today = localMidnight(now);
  final lastDate = current.lastEarnedDate;
  final isNewDay = lastDate == null || localMidnight(lastDate) != today;

  if (isNewDay) {
    // First log of the calendar day — full 5-token award. Missed days
    // lose nothing: `current.balance` is preserved.
    return TokenAward(
      award: 5,
      updated: TokenBalance(
        balance: current.balance + 5,
        earnedToday: 5,
        lastEarnedDate: today,
      ),
    );
  }

  if (current.earnedToday < 10) {
    // Same calendar day, under the cap — 1-token award.
    return TokenAward(
      award: 1,
      updated: TokenBalance(
        balance: current.balance + 1,
        earnedToday: current.earnedToday + 1,
        lastEarnedDate: lastDate,
      ),
    );
  }

  // Cap reached — no award, no field changes. Caller may skip the
  // Firestore write entirely.
  return TokenAward(award: 0, updated: current);
}
