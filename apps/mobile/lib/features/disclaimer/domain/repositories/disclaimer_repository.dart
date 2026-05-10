import 'package:core/core.dart';

import '../disclaimer_failure.dart';

/// Contract for any backing store that persists the user's bipolar /
/// medical disclaimer ack flag (S5 feature 7.4, pulled forward into
/// S4).
///
/// The Day-4 concrete implementation reads/writes the
/// `users/{userId}.insightsDisclaimerAcked` boolean field via
/// `set(merge: true)`. The firestore.rule for that field is one-way
/// (false → true is allowed, true → false is denied), so [ack] is
/// idempotent and never reverts.
///
/// Pure-Dart contract — imports only `package:core/core.dart` and a
/// sibling failure type. Domain-purity rule per CLAUDE.md.
abstract class DisclaimerRepository {
  /// Streams the user's current ack state. Default `false` for new
  /// users (the field defaults to absent on the user doc, and the
  /// data layer maps absent → false).
  Stream<bool> watchAckState({required String userId});

  /// Marks the disclaimer as acknowledged. One-way: once true, the
  /// firestore rule denies false reverts, so a second call is a no-op
  /// at the rule level. Returns `Ok(null)` on success.
  Future<Result<void, DisclaimerFailure>> ack({required String userId});
}
