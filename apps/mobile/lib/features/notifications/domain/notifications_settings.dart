import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_settings.freezed.dart';

/// Platform a registered FCM token came from. Stored as a string in
/// Firestore so the rule check stays a simple `in [...]` comparison.
enum NotificationPlatform { android, web }

/// One device registration. Multiple devices per user supported: a
/// token is stored once per (token) - re-registering the same token
/// simply refreshes [lastSeenAt].
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
/// at `users/{uid}/settings/notifications`.
///
/// Rules:
/// - [cheerUpEnabled] is the legacy single-channel gate consumed by the
///   `sendCheerUpPush` Cloud Function. Kept as a backward-compat shim:
///   when ALL three tier flags go off, the shim flips false so the
///   CF stops firing - matching the previous user-visible behaviour.
///   When any tier remains enabled, the shim stays true.
/// - [tier1Enabled] / [tier2Enabled] / [tier3Enabled] are the new
///   per-tier opt-outs the intervention dispatcher reads. Defaults are
///   all `true` so a fresh install grants all three channels until the
///   user opts out in Settings.
/// - [tokens] is the device fan-out list. The setter [withToken] dedups
///   on `token`: same-token re-registration replaces the existing entry
///   so `lastSeenAt` advances without duplicating rows.
@freezed
abstract class NotificationsSettings with _$NotificationsSettings {
  const factory NotificationsSettings({
    @Default(true) bool cheerUpEnabled,
    @Default(true) bool tier1Enabled,
    @Default(true) bool tier2Enabled,
    @Default(true) bool tier3Enabled,
    @Default(<FcmTokenRecord>[]) List<FcmTokenRecord> tokens,
    DateTime? updatedAt,
  }) = _NotificationsSettings;

  const NotificationsSettings._();

  /// Default factory for first-write: all four flags `true`, no tokens
  /// yet. New users start fully opted-in to every intervention tier and
  /// to the legacy cheer-up channel; the cheer-up shim is recomputed on
  /// every per-tier toggle (see [withTier1Enabled] etc.) so it never
  /// drifts out of sync.
  factory NotificationsSettings.initial() => const NotificationsSettings();

  /// `true` if at least one tier opt-out is still enabled. The legacy
  /// `cheerUpEnabled` shim is kept in lock-step with this getter: when
  /// the last tier flips off, the shim flips false so the cheer-up CF
  /// stops firing too.
  bool get anyTierEnabled => tier1Enabled || tier2Enabled || tier3Enabled;

  /// Returns a copy with [tier1Enabled] set to [value]. Also re-derives
  /// [cheerUpEnabled] so it stays `true` while any tier is enabled and
  /// flips `false` only when all three tier flags are off. The
  /// `sendCheerUpPush` CF still reads `cheerUpEnabled` (see
  /// `functions/src/sendCheerUpPush.ts`) - keeping the field in
  /// lock-step preserves its behaviour while the dispatcher feature
  /// flag rolls out.
  NotificationsSettings withTier1Enabled(bool value) {
    final next = copyWith(tier1Enabled: value);
    return next.copyWith(cheerUpEnabled: next.anyTierEnabled);
  }

  /// Returns a copy with [tier2Enabled] set to [value]. See
  /// [withTier1Enabled] for the cheer-up shim derivation.
  NotificationsSettings withTier2Enabled(bool value) {
    final next = copyWith(tier2Enabled: value);
    return next.copyWith(cheerUpEnabled: next.anyTierEnabled);
  }

  /// Returns a copy with [tier3Enabled] set to [value]. See
  /// [withTier1Enabled] for the cheer-up shim derivation.
  NotificationsSettings withTier3Enabled(bool value) {
    final next = copyWith(tier3Enabled: value);
    return next.copyWith(cheerUpEnabled: next.anyTierEnabled);
  }

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
