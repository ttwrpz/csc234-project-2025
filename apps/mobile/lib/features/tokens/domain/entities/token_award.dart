import 'package:freezed_annotation/freezed_annotation.dart';

import 'token_balance.dart';

part 'token_award.freezed.dart';

/// Result of a single call to [awardDailyTokens] - the integer awarded to
/// the user (0..5) plus the resulting [TokenBalance] post-write.
///
/// `award == 0` means the daily cap (10) has been reached and the user
/// got nothing for this log. The resulting [updated] is then identical
/// to the input balance - no field changes, no Firestore write needed.
///
/// Not [JsonSerializable] - this value never round-trips through
/// Firestore. Only [updated] is persisted (as the three user-doc fields).
@freezed
abstract class TokenAward with _$TokenAward {
  const factory TokenAward({
    required int award,
    required TokenBalance updated,
  }) = _TokenAward;
}
