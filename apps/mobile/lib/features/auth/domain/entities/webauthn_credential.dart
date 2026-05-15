import 'package:freezed_annotation/freezed_annotation.dart';

part 'webauthn_credential.freezed.dart';
part 'webauthn_credential.g.dart';

/// Client-visible projection of a registered WebAuthn credential
/// (ADR-0014 Decision C).
///
/// Stored under `users/{uid}/webauthn/{credentialId}` and surfaced to the
/// Privacy UI for the "Security key registered — last used …" status
/// tile. The full credential doc on Firestore carries additional
/// server-managed fields (`publicKeyBase64`, `counter`, `aaguid`,
/// `transports`) that the client never needs; this projection includes
/// only the fields the UI consumes.
///
/// **Never** carries the public key, the AAGUID, or the signature
/// counter. Those are written by the Cloud Functions via admin SDK and
/// read by the verify path on the server, never by the Dart client.
///
/// The [failedAttempts] / [lockedUntil] pair is the rate-limit anchor
/// per ADR-0014 §"Rate-limit": 5 failed assertions → 60s lock; 10
/// failures/hour → 30 min lock. The Firestore read rule also blocks
/// reads when `lockedUntil > request.time`, so a tampered client cannot
/// bypass the limit by skipping the failure-write.
@freezed
abstract class WebauthnCredential with _$WebauthnCredential {
  const factory WebauthnCredential({
    /// Base64URL-encoded credential id (also the Firestore doc id).
    /// Used as `allowCredentials.id` on subsequent assertion ceremonies.
    required String credentialId,

    /// Server-time timestamp when registration finished. Surfaced as
    /// "Registered May 15" in the Privacy UI status tile.
    required DateTime createdAt,

    /// Server-time timestamp of the most recent successful assertion.
    /// Null until the first verify. Surfaced as "Last used May 17" in
    /// the Privacy UI status tile.
    DateTime? lastUsedAt,

    /// Count of consecutive failed assertion attempts since the last
    /// success. Reset to 0 on success.
    @Default(0) int failedAttempts,

    /// If non-null, assertion is rate-limited until this UTC time.
    DateTime? lockedUntil,
  }) = _WebauthnCredential;

  factory WebauthnCredential.fromJson(Map<String, Object?> json) =>
      _$WebauthnCredentialFromJson(json);
}
