import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../domain/services/pin_hasher.dart';

/// Production [PinHasher] backed by `package:crypto`'s `Hmac<Sha256>`.
///
/// PBKDF2-HMAC-SHA256 is hand-rolled here — `crypto` provides the HMAC
/// primitive but not a one-call PBKDF2 helper. The implementation
/// follows RFC 2898 §5.2: the derived key is the concatenation of T_1,
/// T_2, ... T_l where T_i = U_1 XOR U_2 XOR ... XOR U_c and each U_k
/// is HMAC-SHA256(password, U_{k-1}). For a 32-byte output and SHA-256
/// (32-byte block) the loop is l=1 — single T_1 of 32 bytes.
///
/// Choice rationale (ADR-0013 Open Follow-up #1): `pointycastle` is
/// NOT in `flutter pub deps`, only `crypto` (transitive via `uuid`,
/// promoted to a direct dep in pubspec). Hand-rolled is < 20 lines and
/// keeps the dependency surface area minimal.
class PinHasherImpl implements PinHasher {
  PinHasherImpl({Random? random})
    : _random = random ?? Random.secure();

  /// Cryptographically-secure RNG. Tests can inject a deterministic
  /// `Random(seed)` to get reproducible salts; production must use
  /// [Random.secure].
  final Random _random;

  @override
  String get algorithm => 'pbkdf2-sha256';

  @override
  List<int> derive({
    required String pinDigits,
    required List<int> salt,
    required int iterations,
  }) {
    if (iterations < PinHasher.minIterations) {
      throw ArgumentError.value(
        iterations,
        'iterations',
        'must be at least ${PinHasher.minIterations}',
      );
    }
    if (salt.length != PinHasher.saltLengthBytes) {
      throw ArgumentError.value(
        salt.length,
        'salt.length',
        'must be ${PinHasher.saltLengthBytes} bytes',
      );
    }

    // RFC 2898 §5.2 PBKDF2. dkLen = 32 bytes (SHA-256 output), so we
    // need exactly one block T_1. The "INT(i)" salt-suffix is i=1
    // encoded as a 4-byte big-endian integer.
    final passwordBytes = utf8.encode(pinDigits);
    final hmac = Hmac(sha256, passwordBytes);

    final saltWithCounter = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt);
    // INT(1) big-endian: 0x00 0x00 0x00 0x01
    saltWithCounter[salt.length + 3] = 1;

    // U_1 = HMAC(password, salt || INT(1))
    var u = Uint8List.fromList(hmac.convert(saltWithCounter).bytes);
    final t = Uint8List(PinHasher.derivedKeyLengthBytes)..setRange(0, u.length, u);

    // T_1 = U_1 XOR U_2 XOR ... XOR U_iterations.
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    return t;
  }

  @override
  List<int> newSalt() {
    final bytes = Uint8List(PinHasher.saltLengthBytes);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  @override
  bool constantTimeEquals(List<int> a, List<int> b) {
    // Comparing differing lengths in constant time is impossible — the
    // length itself is the side channel. But a length-mismatch on the
    // derived key means a programmer error upstream (the derive params
    // are fixed), so returning early here is acceptable: an attacker
    // who can manipulate stored hash length already controls the doc.
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
