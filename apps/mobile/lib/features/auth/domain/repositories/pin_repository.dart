import 'package:core/core.dart';

import '../entities/pin.dart';
import '../entities/pin_hash.dart';
import '../entities/pin_setup_failure.dart';
import '../entities/pin_verify_failure.dart';

/// Contract for the storage + verification of the PIN fallback factor.
///
/// Implementations live in `data/`; they own the Firestore wire to
/// `users/{uid}/security/pin` and the rate-limit doc mutations.
/// Domain consumers (use cases, controllers) speak only in terms of
/// the abstract result types.
///
/// **Threat model boundary:** verification happens **client-side**.
/// The repository reads the stored hash, re-derives PBKDF2 with the
/// user-entered PIN + stored salt, and compares the two with
/// constant-time bytes. The PIN string never leaves the device.
abstract class PinRepository {
  /// Reads the current PIN hash record for [userId], or `null` when no
  /// PIN is set. Firestore rule denials due to the rate-limit gate
  /// surface as a [PinVerifyFailure.locked] when called via [verify];
  /// direct reads via this method return `null` so callers can render
  /// the "no PIN set" Settings state without leaking the limit state.
  Future<PinHash?> read({required String userId});

  /// Idempotent - overwrites any existing hash. Used by both first-time
  /// setup and Change PIN. The data layer is responsible for:
  ///  - Generating a fresh 16-byte salt.
  ///  - Setting `iterations` and `algorithm` to the canonical values.
  ///  - Stamping `createdAt` to server-time.
  ///  - Resetting `failedAttempts` to 0 and `lockedUntil` to null.
  Future<Result<void, PinSetupFailure>> setup({
    required String userId,
    required Pin pin,
  });

  /// Verifies [pin] against the stored hash for [userId]. On success
  /// resets `failedAttempts` to 0 and clears `lockedUntil`. On wrong
  /// input increments `failedAttempts` and, at the threshold, sets
  /// `lockedUntil` per the rate-limit ladder (5 → 60 s, 10/hour →
  /// 30 min).
  ///
  /// Reads that hit the rule-level rate-limit (`lockedUntil > now`)
  /// surface as [PinVerifyFailure.locked]; the data layer translates
  /// the Firestore `permission-denied` into that failure.
  Future<Result<void, PinVerifyFailure>> verify({
    required String userId,
    required Pin pin,
  });

  /// Marks the PIN as removed by overwriting it with an unrecoverable
  /// random hash. Per ADR-0013 Decision E §3, the Firestore rule
  /// denies client-side deletes of `users/{uid}/security/pin` so we
  /// cannot literally delete; the data layer accomplishes a
  /// semantically-equivalent "removed" state by writing a random salt
  /// and random derived-key bytes that no real user PIN can ever match.
  ///
  /// Used by the toggle-OFF path in Settings (gate turns off and the
  /// PIN is invalidated for good measure) and by [ChangePinUseCase]
  /// when the user wants to wipe before setting a fresh one.
  Future<Result<void, PinSetupFailure>> remove({required String userId});
}
