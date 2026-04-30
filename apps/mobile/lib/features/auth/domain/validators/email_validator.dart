/// Pure-Dart email validation. Intentionally permissive — we do not try to
/// reproduce RFC 5322 here; Firebase and the email server will reject anything
/// genuinely malformed. We only catch obviously empty / unparseable inputs so
/// the UI can surface a friendly message before a network round-trip.
///
/// Rules (HB-001 invariant 1):
///  - non-empty after trim
///  - contains a single `@`
///  - has at least one character on each side of `@`
///  - total length ≤ 254 (RFC 3696 practical limit)
bool emailIsValid(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.length > 254) return false;
  final atIndex = trimmed.indexOf('@');
  if (atIndex <= 0) return false;
  if (atIndex != trimmed.lastIndexOf('@')) return false;
  if (atIndex == trimmed.length - 1) return false;
  return true;
}
