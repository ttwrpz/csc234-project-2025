/// Pure-Dart abstraction over the PBKDF2-SHA-256 key derivation function.
///
/// The concrete implementation in `data/` is the only place that touches
/// `package:crypto`; domain consumers (use cases, repository) speak only
/// in terms of [DerivedKey].
///
/// Parameters: 100 000 iterations, 16-byte salt, 32-byte output. The
/// hasher does NOT generate the salt - that is the repository's
/// responsibility so the same hasher can be re-used with the stored
/// salt during verification.
abstract class PinHasher {
  /// Algorithm tag stored in the [PinHash.algorithm] field. Used at
  /// verify time to confirm the stored doc was hashed with the same
  /// algorithm as the current code path.
  String get algorithm;

  /// Minimum iteration count. The implementation MUST refuse to derive
  /// with fewer iterations than this.
  static const int minIterations = 100000;

  /// Salt length in bytes. 16 bytes (128 bits) - the OWASP minimum.
  static const int saltLengthBytes = 16;

  /// Derived-key length in bytes. 32 bytes (SHA-256 output size).
  static const int derivedKeyLengthBytes = 32;

  /// Derives a key from [pinDigits] + [salt] using the algorithm
  /// identified by [algorithm].
  ///
  /// - [pinDigits] is the raw 6-character user input (already validated
  ///   upstream).
  /// - [salt] is the 16-byte per-user salt.
  /// - [iterations] must be ≥ [minIterations].
  ///
  /// Returns a [derivedKeyLengthBytes]-byte derived key. Throws
  /// [ArgumentError] on contract violations - these are programmer
  /// errors and must never reach a user.
  List<int> derive({
    required String pinDigits,
    required List<int> salt,
    required int iterations,
  });

  /// Async variant of [derive] that production callers MUST prefer -
  /// PBKDF2 at 100 000 iterations takes ~1–3 seconds on mid-range
  /// Android and blocks the main isolate.
  ///
  /// The production [PinHasherImpl] override runs the work in a worker
  /// isolate via `package:flutter/foundation.dart#compute`, which is
  /// what keeps the PIN-verify UI responsive. Tests that need a fake
  /// hasher can provide a trivial implementation that just returns
  /// `Future.value(derive(...))` - there are no test fakes today, but
  /// the abstract signature keeps the contract intuitive when one
  /// arrives.
  Future<List<int>> deriveAsync({
    required String pinDigits,
    required List<int> salt,
    required int iterations,
  });

  /// Generates a cryptographically-secure random salt of length
  /// [saltLengthBytes]. Exposed on the hasher so the implementation
  /// (which already imports `dart:math` / `crypto`) is the only place
  /// that touches PRNG primitives.
  List<int> newSalt();

  /// Constant-time byte comparison. **Never** use `==` on base64
  /// strings or list equality on the derived key - both leak timing
  /// information that an attacker running an offline brute-force can
  /// exploit.
  ///
  /// Returns `true` iff the inputs have the same length and the same
  /// bytes in every position.
  bool constantTimeEquals(List<int> a, List<int> b);
}
