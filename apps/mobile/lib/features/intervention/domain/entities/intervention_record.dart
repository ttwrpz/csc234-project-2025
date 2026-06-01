import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../pattern_engine/domain/entities/tier.dart';

part 'intervention_record.freezed.dart';
part 'intervention_record.g.dart';

/// Persisted audit row for a single dispatch. One doc per dispatch at
/// `users/{uid}/interventions/{dispatchId}`. Create-once + opt-out toggle -
/// every other field is immutable post-create (see `firestore.rules`).
///
/// The repository's `writeRecord` projects this to / from JSON via Freezed's
/// `fromJson`. The data-layer impl owns `Timestamp` ↔ ISO-string conversion
/// at the Firestore boundary - this entity holds `DateTime`.
@freezed
abstract class InterventionRecord with _$InterventionRecord {
  const factory InterventionRecord({
    required String dispatchId,
    required Tier tier,
    required DateTime dispatchedAt,
    required String quoteId,

    /// 48h gate the dispatcher enforces. Persisted so the Cloud Function
    /// (or admin tooling) can audit the cooldown without re-deriving from
    /// the anchor doc.
    required DateTime cooldownUntil,

    /// True when the user tapped "I'm okay". One-way false → true; the
    /// rules enforce this at the wire level.
    @Default(false) bool optedOut,

    @Default(1) int schemaV,
  }) = _InterventionRecord;

  factory InterventionRecord.fromJson(Map<String, Object?> json) =>
      _$InterventionRecordFromJson(json);
}
