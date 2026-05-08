import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_settings.freezed.dart';

/// Platform a registered FCM token came from. Stored as a string in
/// Firestore so the rule check stays a simple `in [...]` comparison.
enum NotificationPlatform { android, web, iOS }

/// One device registration. Multiple devices per user is supported per
/// O11: a token is stored once per (token) — re-registering the same
/// token simply refreshes [lastSeenAt].
class FcmTokenRecord {
  const FcmTokenRecord({
    required this.token,
    required this.platform,
    required this.lastSeenAt,
  });

  final String token;
  final NotificationPlatform platform;
  final DateTime lastSeenAt;

  FcmTokenRecord copyWith({
    String? token,
    NotificationPlatform? platform,
    DateTime? lastSeenAt,
  }) => FcmTokenRecord(
    token: token ?? this.token,
    platform: platform ?? this.platform,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FcmTokenRecord &&
          token == other.token &&
          platform == other.platform &&
          lastSeenAt == other.lastSeenAt;

  @override
  int get hashCode => Object.hash(token, platform, lastSeenAt);
}

/// Per-user notification preferences. Maps 1:1 to the Firestore document
/// at `users/{uid}/settings/notifications` (HB-003 §"Settings doc shape").
///
/// Rules:
/// - [cheerUpEnabled] gates the cheer-up push channel only; other product
///   notifications (none today) would gain their own flag here.
/// - [tokens] is the device fan-out list. The setter [withToken] dedups
///   on `token`: same-token re-registration replaces the existing entry
///   so `lastSeenAt` advances without duplicating rows.
@freezed
abstract class NotificationsSettings with _$NotificationsSettings {
  const factory NotificationsSettings({
    @Default(true) bool cheerUpEnabled,
    @Default(<FcmTokenRecord>[]) List<FcmTokenRecord> tokens,
    DateTime? updatedAt,
  }) = _NotificationsSettings;

  const NotificationsSettings._();

  /// Default factory for first-write: `cheerUpEnabled = true` per O13,
  /// no tokens yet.
  factory NotificationsSettings.initial() => const NotificationsSettings();

  /// Returns a new settings object with [record] merged into [tokens].
  /// If a record with the same `token` already exists, it is replaced
  /// (so `lastSeenAt` and `platform` reflect the freshest registration);
  /// otherwise the record is appended.
  NotificationsSettings withToken(FcmTokenRecord record) {
    final existing = tokens.where((t) => t.token != record.token).toList();
    return copyWith(tokens: [...existing, record]);
  }

  /// Removes a token by value. No-op if absent. Used when FCM signals a
  /// token has been invalidated (e.g. app uninstalled on another device).
  NotificationsSettings withoutToken(String token) {
    if (!tokens.any((t) => t.token == token)) return this;
    return copyWith(tokens: tokens.where((t) => t.token != token).toList());
  }
}
