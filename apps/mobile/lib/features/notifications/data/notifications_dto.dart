import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/notifications_settings.dart';

/// Wire-format mirror of `users/{uid}/settings/notifications`. Lives in
/// `data/` only - the domain layer never touches Firestore types.
///
/// Doc shape:
/// ```json
/// {
///   "cheerUpEnabled": true,
///   "tier1Enabled": true,
///   "tier2Enabled": true,
///   "tier3Enabled": true,
///   "tokens": [
///     { "token": "abc...", "platform": "android", "lastSeenAt": <ts> }
///   ],
///   "updatedAt": <ts>
/// }
/// ```
///
/// Migration: docs created before the per-tier opt-outs landed only
/// carry `cheerUpEnabled` + `tokens` + `updatedAt`. The datasource
/// detects "legacy shape" via [needsTierMigration] and mirrors the
/// legacy value to all three new tier flags in a single merge-write so
/// the dispatcher's read path always sees the four-flag schema.
class NotificationsSettingsDto {
  const NotificationsSettingsDto({
    required this.cheerUpEnabled,
    required this.tier1Enabled,
    required this.tier2Enabled,
    required this.tier3Enabled,
    required this.tokens,
    required this.updatedAt,
  });

  final bool cheerUpEnabled;
  final bool tier1Enabled;
  final bool tier2Enabled;
  final bool tier3Enabled;
  final List<Map<String, Object?>> tokens;
  final Timestamp? updatedAt;

  static NotificationsSettings fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return NotificationsSettings.initial();
    return _fromMap(data);
  }

  /// Reads the four-flag schema directly out of a raw Firestore map.
  /// Extracted so the migration helper in the datasource can compute
  /// the post-migration entity without re-decoding the snapshot twice.
  static NotificationsSettings fromMap(Map<String, dynamic> data) =>
      _fromMap(data);

  /// `true` when the doc has the legacy `cheerUpEnabled` flag but is
  /// missing AT LEAST ONE of the three new tier flags. Brand-new docs
  /// (no `cheerUpEnabled` key) are NOT considered pre-migration - they
  /// take the default path via [NotificationsSettings.initial].
  ///
  /// The check is deliberately "missing any tier flag" rather than
  /// "missing all three" so a half-written doc (e.g. a partial write
  /// crashed before the migration completed) still gets repaired on
  /// the next read.
  static bool needsTierMigration(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['cheerUpEnabled'] is! bool) return false;
    return data['tier1Enabled'] is! bool ||
        data['tier2Enabled'] is! bool ||
        data['tier3Enabled'] is! bool;
  }

  /// Computes the migrated settings entity for a legacy doc. Mirrors the
  /// `cheerUpEnabled` value to all three tier flags so a user who had
  /// previously opted out of cheer-up reminders stays opted out of every
  /// tier; a user who was opted in stays opted in to every tier.
  ///
  /// Tokens + updatedAt are preserved verbatim from the input map.
  static NotificationsSettings migratedFromLegacy(Map<String, dynamic> data) {
    final legacy = data['cheerUpEnabled'] as bool? ?? true;
    final tokens = _parseTokens(data['tokens']);
    return NotificationsSettings(
      cheerUpEnabled: legacy,
      tier1Enabled: legacy,
      tier2Enabled: legacy,
      tier3Enabled: legacy,
      tokens: tokens,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static NotificationsSettings _fromMap(Map<String, dynamic> data) {
    return NotificationsSettings(
      cheerUpEnabled: data['cheerUpEnabled'] as bool? ?? true,
      tier1Enabled: data['tier1Enabled'] as bool? ?? true,
      tier2Enabled: data['tier2Enabled'] as bool? ?? true,
      tier3Enabled: data['tier3Enabled'] as bool? ?? true,
      tokens: _parseTokens(data['tokens']),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static List<FcmTokenRecord> _parseTokens(Object? raw) {
    final rawTokens = (raw as List?) ?? const [];
    return rawTokens
        .map((e) {
          final map = e as Map<String, dynamic>;
          final ts = map['lastSeenAt'] as Timestamp?;
          return FcmTokenRecord(
            token: map['token'] as String? ?? '',
            platform: _platformFromString(map['platform'] as String?),
            lastSeenAt: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .where((r) => r.token.isNotEmpty)
        .toList();
  }

  /// Payload for the merge-write that bumps a single token's freshness
  /// without touching unrelated keys. Intentionally returns the full
  /// settings payload (including `cheerUpEnabled` and all three tier
  /// flags) so callers that just want to refresh a token still write a
  /// schema-complete doc.
  ///
  /// Empty token strings are dropped at this boundary (defense-in-depth):
  /// rules cap list size at 25 but cannot validate elements, so the
  /// write side must reject malformed tokens before they round-trip and
  /// surface as ghost records on read.
  static Map<String, Object?> toFirestoreMerge({
    required NotificationsSettings settings,
  }) {
    return {
      'cheerUpEnabled': settings.cheerUpEnabled,
      'tier1Enabled': settings.tier1Enabled,
      'tier2Enabled': settings.tier2Enabled,
      'tier3Enabled': settings.tier3Enabled,
      'tokens': settings.tokens
          .where((r) => r.token.isNotEmpty)
          .map(_tokenToMap)
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object?> _tokenToMap(FcmTokenRecord r) => {
    'token': r.token,
    'platform': _platformToString(r.platform),
    'lastSeenAt': Timestamp.fromDate(r.lastSeenAt),
  };

  static NotificationPlatform _platformFromString(String? s) {
    switch (s) {
      case 'android':
        return NotificationPlatform.android;
      case 'web':
        return NotificationPlatform.web;
      case 'ios':
        return NotificationPlatform.iOS;
      default:
        return NotificationPlatform.android;
    }
  }

  static String _platformToString(NotificationPlatform p) {
    switch (p) {
      case NotificationPlatform.android:
        return 'android';
      case NotificationPlatform.web:
        return 'web';
      case NotificationPlatform.iOS:
        return 'ios';
    }
  }
}
