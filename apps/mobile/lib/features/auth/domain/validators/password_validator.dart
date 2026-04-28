/// Pure-Dart password validation.
///
/// Firebase Auth's minimum is 6 characters; we tighten to 8 (HB-001 invariant
/// 2) so that `RegisterWithEmailUseCase` can reject obviously weak passwords
/// before a network round-trip. The data layer also handles `weak-password`
/// errors that may come back from Firebase (e.g. on its own server-side
/// policies), so this is defence-in-depth, not the only line of defence.
bool passwordIsValid(String input) {
  return input.length >= 8;
}
