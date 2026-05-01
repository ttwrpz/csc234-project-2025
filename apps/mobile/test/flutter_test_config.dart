import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

/// Global test bootstrap. Loads project fonts before any golden test
/// runs so font rendering is deterministic across CI (Linux) and local
/// dev. Flutter calls `testExecutable` once per test process — there is
/// no need to register this elsewhere.
///
/// `golden_toolkit`'s `loadAppFonts()` registers Material Icons + the
/// project's custom font family from pubspec assets. Without this call,
/// goldens drift on sub-pixel font hinting between OS / Skia versions.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  await testMain();
}
