import 'package:freezed_annotation/freezed_annotation.dart';

part 'pin_hash.freezed.dart';
part 'pin_hash.g.dart';

/// Cryptographic record of a user's PIN — derived once at setup time
/// and verified locally on every unlock attempt (ADR-0013 Decision E §4).
///
/// Stored under `users/{uid}/security/pin` (sub-document, NOT the root
/// user doc — the security-sensitive fields keep a narrower rule
/// allow-list than the broadly-read profile doc).
///
/// **Never** carries the user's raw PIN. The hash is the output of
/// PBKDF2-SHA-256(pin, salt, iterations, dkLen=32). The salt is
/// 16 random bytes per user, generated once at setup time.
///
/// The [failedAttempts] / [lockedUntil] pair is the rate-limit anchor
/// per ADR-0013 Decision E §3: 5 failed attempts → 60s lock; 10 failures
/// in an hour → 30min lock. Both bounds are enforced ALSO at the
/// Firestore rule level so a tampered client cannot bypass them by
/// skipping the write.
@freezed
abstract class PinHash with _$PinHash {
  const factory PinHash({
    /// PBKDF2 variant identifier. Fixed at `'pbkdf2-sha256'` for v1.5.
    /// Stored explicitly so a future rotation (e.g. Argon2id in v2.0)
    /// can be distinguished at read time without a schema migration.
    required String algorithm,

    /// PBKDF2 iteration count. ADR-0013: ≥ 100 000.
    required int iterations,

    /// Base64-encoded 16-byte random salt. Per-user; generated once at
    /// setup and never rotated unless the PIN itself is replaced.
    required String saltBase64,

    /// Base64-encoded 32-byte PBKDF2 derived key.
    required String hashBase64,

    /// Server-time timestamp when this PIN was set up. Used only for
    /// audit (e.g. "PIN set N days ago"); never for security decisions.
    required DateTime createdAt,

    /// Count of consecutive failed verification attempts since the last
    /// success. Reset to 0 on success.
    @Default(0) int failedAttempts,

    /// If non-null, verification is rate-limited until this UTC time.
    /// Reads of the hash doc may also be blocked by the Firestore rule
    /// `lockedUntil > request.time`.
    DateTime? lockedUntil,
  }) = _PinHash;

  factory PinHash.fromJson(Map<String, Object?> json) =>
      _$PinHashFromJson(json);
}
