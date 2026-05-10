import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_balance.freezed.dart';
part 'token_balance.g.dart';

/// User's token-economy state (S4 — pivot feature #10). Persisted as three
/// top-level fields on the `users/{uid}` profile document: `tokenBalance`,
/// `tokensEarnedToday`, `lastTokenEarnedDate`.
///
/// Anti-pattern guardrails (ADR-0010 §7, Cheng et al. 2019):
///   * `balance` is monotonic-up — only [awardDailyTokens] increases it,
///     and only ever by 0..5. Skin purchases land in S5 via a separate
///     `SpendTokensUseCase`.
///   * `earnedToday` is capped at 10 (the daily ceiling); the rules also
///     pin `0..10`.
///   * `lastEarnedDate` is the local-midnight of the day the user last
///     earned at least one token. `null` means "never earned" (first
///     log of the user's lifetime).
///
/// MOOD-AGNOSTIC by construction — the entity has zero references to
/// any emotion-feature filename or class name. Verifiable by file-
/// level grep (see `award_daily_tokens_test.dart`'s TC-2 file-level
/// test).
@freezed
abstract class TokenBalance with _$TokenBalance {
  const factory TokenBalance({
    required int balance,
    required int earnedToday,
    required DateTime? lastEarnedDate,
  }) = _TokenBalance;

  factory TokenBalance.fromJson(Map<String, Object?> json) =>
      _$TokenBalanceFromJson(json);
}
