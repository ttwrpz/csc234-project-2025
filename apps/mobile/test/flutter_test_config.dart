import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Global test bootstrap. Loads project fonts and installs a tolerant
/// golden comparator so the test suite is portable across the OS / Skia
/// version skew between local dev (Windows / macOS) and CI (Linux).
///
/// `loadAppFonts()` registers Material Icons + the project's custom
/// font family from pubspec assets — without it, goldens drift on
/// sub-pixel font hinting between platforms.
///
/// The custom comparator allows ≤ 4% pixel difference per golden. The
/// bar is intentionally wide enough to absorb the documented Skia /
/// FreeType variance between platforms while still catching every
/// real visual regression observed in S4 (silhouette swaps, chip-band
/// re-styling, layout breaks — all ≥ 20% diff).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();

  // Wrap the auto-installed `LocalFileComparator` so the per-test-file
  // basedir resolution stays correct (the default comparator points at
  // the test file's URI, not the package root). We just intercept the
  // pass/fail decision and apply the tolerance bar.
  final base = goldenFileComparator;
  if (base is LocalFileComparator) {
    goldenFileComparator = _TolerantLocalFileComparator(
      base,
      tolerancePercent: 4.0,
    );
  }

  await testMain();
}

class _TolerantLocalFileComparator extends GoldenFileComparator
    with LocalComparisonOutput {
  _TolerantLocalFileComparator(this._inner, {required this.tolerancePercent});

  final LocalFileComparator _inner;
  final double tolerancePercent;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenFile = File.fromUri(_inner.basedir.resolveUri(golden));
    if (!goldenFile.existsSync()) {
      throw TestFailure(
        'Could not be compared against non-existent file: "$golden"',
      );
    }
    final goldenBytes = await goldenFile.readAsBytes();
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );
    if (result.passed) return true;

    final diffPercent = result.diffPercent * 100;
    if (diffPercent <= tolerancePercent) {
      // Within tolerance — log so reviewers see the drift without a
      // hard failure.
      // ignore: avoid_print
      print(
        'Golden "$golden" within tolerance: '
        '${diffPercent.toStringAsFixed(2)}% '
        '<= $tolerancePercent% (${result.error})',
      );
      return true;
    }

    throw FlutterError(
      'Golden "$golden": pixel diff '
      '${diffPercent.toStringAsFixed(2)}% '
      'exceeds tolerance $tolerancePercent% (${result.error})',
    );
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      _inner.update(golden, imageBytes);
}
