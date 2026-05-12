import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/notifications/data/notifications_dto.dart';
import 'package:moodbloom/features/notifications/domain/notifications_settings.dart';

/// Tests the legacy-to-tiered migration helpers on
/// [NotificationsSettingsDto].
///
/// The actual `set(merge: true)` write happens inside
/// `NotificationsFirestoreDatasource`, which depends on
/// `FirebaseFirestore`. The project does not carry
/// `fake_cloud_firestore` in pubspec (see harvest / disclaimer
/// repository tests for the precedent), so the write side is asserted
/// here by inspecting the merge payload that the datasource
/// constructs. The schema-correctness invariants the rule engine
/// enforces (four bool flags + tokens + updatedAt) are validated
/// against the same payload.
///
/// A separate Firestore-emulator test for the migration write path
/// would also be valuable; flagged for the security-reviewer to add
/// before Day 4 since no emulator-test infrastructure exists in the
/// repo today.
void main() {
  group('NotificationsSettingsDto migration helpers', () {
    test('needsTierMigration — legacy doc (cheerUpEnabled only) → true', () {
      final data = <String, dynamic>{
        'cheerUpEnabled': true,
        'tokens': <Object?>[],
      };
      expect(NotificationsSettingsDto.needsTierMigration(data), isTrue);
    });

    test('needsTierMigration — legacy opted-out doc → true', () {
      final data = <String, dynamic>{
        'cheerUpEnabled': false,
        'tokens': <Object?>[],
      };
      expect(NotificationsSettingsDto.needsTierMigration(data), isTrue);
    });

    test('needsTierMigration — already-migrated doc → false', () {
      final data = <String, dynamic>{
        'cheerUpEnabled': true,
        'tier1Enabled': false,
        'tier2Enabled': true,
        'tier3Enabled': true,
        'tokens': <Object?>[],
      };
      expect(NotificationsSettingsDto.needsTierMigration(data), isFalse);
    });

    test(
      'needsTierMigration — partially-migrated doc (missing tier2) → true',
      () {
        // Defense-in-depth: a crashed-mid-write doc still triggers a
        // repair on the next read.
        final data = <String, dynamic>{
          'cheerUpEnabled': true,
          'tier1Enabled': true,
          // tier2Enabled missing
          'tier3Enabled': true,
          'tokens': <Object?>[],
        };
        expect(NotificationsSettingsDto.needsTierMigration(data), isTrue);
      },
    );

    test('needsTierMigration — null data (brand-new user, no doc) → false', () {
      expect(NotificationsSettingsDto.needsTierMigration(null), isFalse);
    });

    test(
      'needsTierMigration — doc without cheerUpEnabled → false (not legacy)',
      () {
        // A doc that lacks even `cheerUpEnabled` is treated as
        // brand-new — the caller's normal "no doc" path will write a
        // fresh initial() instead.
        final data = <String, dynamic>{'tokens': <Object?>[]};
        expect(NotificationsSettingsDto.needsTierMigration(data), isFalse);
      },
    );

    test(
      'migratedFromLegacy — opted-in user gets all three tier flags true',
      () {
        final data = <String, dynamic>{
          'cheerUpEnabled': true,
          'tokens': <Object?>[],
        };
        final s = NotificationsSettingsDto.migratedFromLegacy(data);
        expect(s.cheerUpEnabled, isTrue);
        expect(s.tier1Enabled, isTrue);
        expect(s.tier2Enabled, isTrue);
        expect(s.tier3Enabled, isTrue);
        expect(s.tokens, isEmpty);
      },
    );

    test(
      'migratedFromLegacy — opted-out user gets all three tier flags false',
      () {
        final data = <String, dynamic>{
          'cheerUpEnabled': false,
          'tokens': <Object?>[],
        };
        final s = NotificationsSettingsDto.migratedFromLegacy(data);
        expect(s.cheerUpEnabled, isFalse);
        expect(s.tier1Enabled, isFalse);
        expect(s.tier2Enabled, isFalse);
        expect(s.tier3Enabled, isFalse);
      },
    );

    test('migratedFromLegacy — preserves existing tokens verbatim', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 5, 1, 12));
      final data = <String, dynamic>{
        'cheerUpEnabled': true,
        'tokens': <Map<String, dynamic>>[
          {'token': 'tok-A', 'platform': 'android', 'lastSeenAt': ts},
        ],
      };
      final s = NotificationsSettingsDto.migratedFromLegacy(data);
      expect(s.tokens, hasLength(1));
      expect(s.tokens.single.token, 'tok-A');
      expect(s.tokens.single.platform, NotificationPlatform.android);
    });

    test(
      'fromMap — already-migrated doc preserves per-tier values exactly',
      () {
        final data = <String, dynamic>{
          'cheerUpEnabled': true,
          'tier1Enabled': false,
          'tier2Enabled': true,
          'tier3Enabled': false,
          'tokens': <Object?>[],
        };
        final s = NotificationsSettingsDto.fromMap(data);
        expect(s.tier1Enabled, isFalse);
        expect(s.tier2Enabled, isTrue);
        expect(s.tier3Enabled, isFalse);
        expect(s.cheerUpEnabled, isTrue);
      },
    );

    test('fromMap — missing tier flags default to true (forward-compat)', () {
      // If the datasource somehow returns a partially-shaped doc
      // without triggering migration, the read still surfaces a
      // sane default.
      final data = <String, dynamic>{
        'cheerUpEnabled': true,
        'tokens': <Object?>[],
      };
      final s = NotificationsSettingsDto.fromMap(data);
      expect(s.tier1Enabled, isTrue);
      expect(s.tier2Enabled, isTrue);
      expect(s.tier3Enabled, isTrue);
    });

    test(
      'toFirestoreMerge — writes all four bool flags + tokens + serverTime',
      () {
        final settings = const NotificationsSettings(
          cheerUpEnabled: true,
          tier1Enabled: false,
          tier2Enabled: true,
          tier3Enabled: true,
        );
        final payload = NotificationsSettingsDto.toFirestoreMerge(
          settings: settings,
        );
        expect(payload['cheerUpEnabled'], isTrue);
        expect(payload['tier1Enabled'], isFalse);
        expect(payload['tier2Enabled'], isTrue);
        expect(payload['tier3Enabled'], isTrue);
        expect(payload['tokens'], isA<List<Object?>>());
        // FieldValue.serverTimestamp() — value identity not asserted
        // (it's an opaque sentinel) but the key must be present so the
        // Firestore rule's `updatedAt == request.time` guard passes.
        expect(payload.containsKey('updatedAt'), isTrue);
      },
    );
  });
}
