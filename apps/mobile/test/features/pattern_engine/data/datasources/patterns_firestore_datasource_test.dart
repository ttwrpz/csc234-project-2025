import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/pattern_result.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// `PatternsFirestoreDatasource` is a thin wrapper over `FirebaseFirestore`.
/// The project does not depend on `fake_cloud_firestore` (see
/// `intervention_state_firestore_datasource.dart` for the same convention),
/// so we cannot exercise the live Firestore round-trip here. Instead we
/// pin the JSON shape that the datasource hands the cloud — that's what
/// the firestore.rules `affectedKeys()` allowlist actually validates, and
/// it's what fails first if the entity drifts away from the rule schema.
///
/// Behavioural coverage of upsert + watch lives in
/// `pattern_repository_impl_test.dart` via a fake datasource (the same
/// pattern as `cheer_up_events_repository_impl_test.dart`).
void main() {
  group('PatternResult JSON shape (cloud round-trip contract)', () {
    test('toJson contains exactly the rule-allowed keys', () {
      const result = PatternResult(
        dateId: '2026-05-09',
        mannKendallZ: -2.21,
        slidingNegCount: 5,
        consecutiveHighIntensity: 3,
        zScoreToday: -2.6,
        cusumC: 4.5,
        triggeredTier: Tier.three,
      );
      final json = result.toJson();
      // The keyset is what the firestore.rules `affectedKeys().hasOnly(...)`
      // pin will accept. If this set ever drifts, the rule will deny the
      // write and the post-save controller will see PatternFailure on every
      // save. Defense-in-depth assertion.
      expect(json.keys.toSet(), {
        'dateId',
        'mannKendallZ',
        'slidingNegCount',
        'consecutiveHighIntensity',
        'zScoreToday',
        'cusumC',
        'triggeredTier',
        'schemaV',
      });
      expect(json['dateId'], '2026-05-09');
      expect(json['triggeredTier'], 'three');
      expect(json['schemaV'], 1);
    });

    test('null mannKendallZ + zScoreToday round-trip cleanly', () {
      const result = PatternResult(
        dateId: '2026-05-09',
        mannKendallZ: null,
        slidingNegCount: 0,
        consecutiveHighIntensity: 0,
        zScoreToday: null,
        cusumC: 0.0,
        triggeredTier: null,
      );
      final json = result.toJson();
      expect(json['mannKendallZ'], isNull);
      expect(json['zScoreToday'], isNull);
      expect(json['triggeredTier'], isNull);

      final revived = PatternResult.fromJson(json);
      expect(revived, result);
    });

    test('triggeredTier serialises as the lowercase enum name', () {
      // Mirrors the firestore.rules tier allowlist `['one','two','three']`.
      for (final t in Tier.values) {
        final json = PatternResult(
          dateId: '2026-05-09',
          mannKendallZ: null,
          slidingNegCount: 0,
          consecutiveHighIntensity: 0,
          zScoreToday: null,
          cusumC: 0.0,
          triggeredTier: t,
        ).toJson();
        expect(json['triggeredTier'], t.name);
      }
    });

    test('dateId follows yyyy-MM-dd (rule regex contract)', () {
      const result = PatternResult(
        dateId: '2026-05-09',
        mannKendallZ: null,
        slidingNegCount: 0,
        consecutiveHighIntensity: 0,
        zScoreToday: null,
        cusumC: 0.0,
        triggeredTier: null,
      );
      // SAME regex as `firebase/firestore.rules` — if this fails the rule
      // will deny the write.
      final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(pattern.hasMatch(result.dateId), isTrue);
    });

    test('idempotency: same dateId means same doc (overwrite semantics)', () {
      // Two `PatternResult`s with the same `dateId` produce different JSON
      // (different metric values) but the SAME Firestore path. The
      // datasource writes via `set(merge: false)` so the second wins.
      const a = PatternResult(
        dateId: '2026-05-09',
        mannKendallZ: -1.0,
        slidingNegCount: 1,
        consecutiveHighIntensity: 0,
        zScoreToday: null,
        cusumC: 0.0,
        triggeredTier: null,
      );
      const b = PatternResult(
        dateId: '2026-05-09',
        mannKendallZ: -2.5,
        slidingNegCount: 5,
        consecutiveHighIntensity: 2,
        zScoreToday: -2.6,
        cusumC: 4.0,
        triggeredTier: Tier.three,
      );
      // Same dateId → same doc id at `users/{uid}/patterns/{dateId}`.
      expect(a.dateId, b.dateId);
      // Different content → second `set` overwrites the first.
      expect(a.toJson(), isNot(b.toJson()));
    });
  });
}
