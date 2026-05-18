import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../pattern_engine/domain/entities/tier.dart';

part 'intervention_dispatch.freezed.dart';

/// The emitted payload of a successful dispatch. The controller layer turns
/// this into a banner / FCM push, but the dispatcher itself is pure-Dart.
///
/// `body` is the full user-visible string AFTER the disclaimer footer has
/// been appended. Callers MUST NOT append the footer a second time. The
/// exact contract is: `body == "${quote.text}\n\n${notificationFooter}"`.
///
/// `ctas` is intentionally `List<String>` (semantic keys, not widgets) so the
/// domain layer stays pure. The presentation layer maps each key
/// (`'open_breathing'`, `'open_journal'`, `'open_crisis'`, `'opt_out'`) to a
/// concrete `ElevatedButton`. The dispatcher decides WHICH keys appear per
/// tier; the renderer decides HOW they look.
@freezed
abstract class InterventionDispatch with _$InterventionDispatch {
  const factory InterventionDispatch({
    required Tier tier,

    /// Quote text + `'\n\n'` + `DisclaimerCopy.notificationFooter`.
    /// Always contains the footer as a suffix.
    required String body,

    /// Semantic CTA keys for the renderer. Order matches reading order.
    /// Tier 1: `['open_breathing', 'opt_out']`.
    /// Tier 2: `['open_journal', 'opt_out']`.
    /// Tier 3: `['open_crisis', 'opt_out']` — crisis screen carries the
    /// Hotline 1323 link.
    required List<String> ctas,

    /// UUID-ish id for the audit record at
    /// `users/{uid}/interventions/{dispatchId}`. Deterministic on
    /// `(tier, dispatchedAt.millisecondsSinceEpoch)` so a retry never
    /// emits a second row.
    required String dispatchId,

    /// Stable id of the [Quote] that produced `body`. Persisted in the
    /// audit record; never surfaced to the user.
    required String quoteId,

    required DateTime dispatchedAt,
  }) = _InterventionDispatch;
}
