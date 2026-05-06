import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/notifications_settings.dart';

/// Wire-format mirror of `users/{uid}/settings/notifications`. Lives in
/// `data/` only — the domain layer never touches Firestore types.
///
/// Doc shape (HB-003 §"Settings doc shape"):
/// ```json
/// {
///   "cheerUpEnabled": true,
///   "tokens": [
///     { "token": "abc...", "platform": "android", "lastSeenAt": <ts> }
///   ],
///   "updatedAt": <ts>
/// }
/// ```
class NotificationsSettingsDto {
  const NotificationsSettingsDto({
    required this.cheerUpEnabled,
    required this.tokens,
    required this.updatedAt,
  });

  final bool cheerUpEnabled;
  final List<Map<String, Object?>> tokens;
  final Timestamp? updatedAt;

  static NotificationsSettings fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return NotificationsSettings.initial();
    final rawTokens = (data['tokens'] as List?) ?? const [];
    return NotificationsSettings(
      cheerUpEnabled: data['cheerUpEnabled'] as bool? ?? true,
      tokens: rawTokens
          .map((e) {
            final map = e as Map<String, dynamic>;
            final ts = map['lastSeenAt'] as Timestamp?;
            return FcmTokenRecord(
              token: map['token'] as String? ?? '',
              platform: _platformFromString(map['platform'] as String?),
              lastSeenAt:
                  ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
            );
          })
          .where((r) => r.token.isNotEmpty)
          .toList(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Payload for the merge-write that bumps a single token's freshness
  /// without touching unrelated keys. Intentionally returns the full
  /// settings payload (including `cheerUpEnabled`) — callers that just
  /// want to refresh a token use [tokensArrayPayload].
  static Map<String, Object?> toFirestoreMerge({
    required NotificationsSettings settings,
  }) {
    return {
      'cheerUpEnabled': settings.cheerUpEnabled,
      'tokens': settings.tokens.map(_tokenToMap).toList(),
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
