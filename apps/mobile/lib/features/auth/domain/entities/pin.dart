/// Value object for a user-entered PIN.
///
/// PIN is the fallback authentication factor for the History privacy
/// gate. 6 numeric digits — the modern minimum; 4 was rejected because
/// 10^6 vs 10^4 gives 100x the brute-force time at the same PBKDF2
/// iteration count.
///
/// Construction is the only enforcement point — once a [Pin] exists,
/// callers can rely on `digits.length == 6` and every char being `0-9`.
/// Use [tryFrom] from any caller that takes raw user input.
class Pin {
  /// PIN length — 6 digits.
  static const int length = 6;

  /// Private — construct via [tryFrom] (or [Pin.unchecked] in tests).
  const Pin._(this.digits);

  /// The raw 6 numeric characters. Never log this — it is the secret
  /// the PIN protects.
  final String digits;

  /// Parses [raw] into a [Pin] or returns `null` if it is not exactly
  /// [length] digits of `0-9`. Whitespace is NOT trimmed here — the
  /// caller (UI) owns input shaping so we don't silently accept
  /// `" 123456"`.
  static Pin? tryFrom(String raw) {
    if (raw.length != length) return null;
    // Manual scan is cheaper than `RegExp` and keeps the entity
    // dependency-free for the test suite.
    for (var i = 0; i < raw.length; i++) {
      final code = raw.codeUnitAt(i);
      // ASCII '0' = 48, '9' = 57.
      if (code < 48 || code > 57) return null;
    }
    return Pin._(raw);
  }

  /// Test-only escape hatch. Skips validation. Prefer [tryFrom] in
  /// production code paths so the invariant is preserved.
  ///
  /// Not marked `@visibleForTesting` because `meta` is not a domain
  /// layer dependency; the named constructor + docstring is signal
  /// enough for reviewers.
  const Pin.unchecked(this.digits);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Pin && other.digits == digits);

  @override
  int get hashCode => digits.hashCode;

  // Deliberately overrides `toString` so a misplaced `print(pin)` (which
  // we shouldn't be doing anyway) doesn't leak the digits into a log.
  @override
  String toString() => 'Pin(***)';
}
