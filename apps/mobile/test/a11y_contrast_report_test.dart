// ignore_for_file: avoid_print

// Prints the resolved-theme contrast ratios used by the
// docs/test-reports/sprint-5-a11y-report.md table. Skipped by default
// (`skip: false` to regenerate). Keeps the WCAG-math + colour
// resolution in lockstep — the test framework's `tester.element`
// resolves `Theme.of(context).colorScheme` and `MbColors` via the same
// path the runtime uses, so the report's numbers are not a separate
// computation.
//
// Why a test rather than a `dart run` script: the design_system /
// flutter Material packages require the Flutter SDK's compiled-frontend
// shims, which only exist inside `flutter test`'s isolate.

import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _toLinear(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relLum(Color c) =>
    0.2126 * _toLinear(c.r) + 0.7152 * _toLinear(c.g) + 0.0722 * _toLinear(c.b);

double contrast(Color fg, Color bg) {
  final l1 = _relLum(fg);
  final l2 = _relLum(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

String row(String pair, double ratio, {double aa = 4.5}) {
  final pass = ratio >= aa ? 'PASS' : 'FAIL';
  return '| $pair | ${ratio.toStringAsFixed(2)}:1 | $pass |';
}

void main() {
  testWidgets(
    'a11y contrast report — prints values to stdout (skipped by default)',
    (tester) async {
      // Pump both themes side-by-side under a single MaterialApp via
      // a Theme widget swap so the resolved ColorSchemes are distinct
      // (a sequential pumpWidget with two MaterialApps would re-use
      // the first frame's resolved-scheme reference in some Flutter
      // versions).
      ColorScheme? lightScheme;
      ColorScheme? darkScheme;
      MbColors? lightMb;
      MbColors? darkMb;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Theme(
                data: buildLightTheme(),
                child: Builder(
                  builder: (ctx) {
                    lightScheme = Theme.of(ctx).colorScheme;
                    lightMb = Theme.of(ctx).extension<MbColors>()!;
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Theme(
                data: buildDarkTheme(),
                child: Builder(
                  builder: (ctx) {
                    darkScheme = Theme.of(ctx).colorScheme;
                    darkMb = Theme.of(ctx).extension<MbColors>()!;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final l = lightScheme!;
      final d = darkScheme!;
      final lmb = lightMb!;
      final dmb = darkMb!;

      // Print a copy-pasteable markdown table. The test always passes
      // — the output is the artifact.
      print('\n=== Sprint 5 a11y contrast report ===');
      print('');
      print('| Pair | Ratio | AA (4.5:1) |');
      print('|------|-------|------------|');
      print(
        row(
          'Hotline tile light (onPrimaryContainer / primaryContainer)',
          contrast(l.onPrimaryContainer, l.primaryContainer),
        ),
      );
      print(
        row(
          'Hotline tile dark (onPrimaryContainer / primaryContainer)',
          contrast(d.onPrimaryContainer, d.primaryContainer),
        ),
      );
      print(
        row(
          'Tier 3 banner light (onErrorContainer / errorContainer)',
          contrast(l.onErrorContainer, l.errorContainer),
        ),
      );
      print(
        row(
          'Tier 3 banner dark (onErrorContainer / errorContainer)',
          contrast(d.onErrorContainer, d.errorContainer),
        ),
      );
      print(
        row(
          'Tier 1/2 banner light (onSurface / surfaceContainerHighest)',
          contrast(l.onSurface, l.surfaceContainerHighest),
        ),
      );
      print(
        row(
          'Tier 1/2 banner dark (onSurface / surfaceContainerHighest)',
          contrast(d.onSurface, d.surfaceContainerHighest),
        ),
      );
      print(
        row('Body text light (mb.text / mb.bg)', contrast(lmb.text, lmb.bg)),
      );
      print(
        row('Body text dark (mb.text / mb.bg)', contrast(dmb.text, dmb.bg)),
      );
      print(
        row(
          'Dim text light (mb.textDim / mb.bg)',
          contrast(lmb.textDim, lmb.bg),
        ),
      );
      print(
        row(
          'Dim text dark (mb.textDim / mb.bg)',
          contrast(dmb.textDim, dmb.bg),
        ),
      );
      print(
        row(
          'Body on card light (mb.text / mb.card)',
          contrast(lmb.text, lmb.card),
        ),
      );
      print(
        row(
          'Body on card dark (mb.text / mb.card)',
          contrast(dmb.text, dmb.card),
        ),
      );
      print(
        row(
          'Banner over storm sky light (mb.text / mb.skyBot)',
          contrast(lmb.text, lmb.skyBot),
        ),
      );
      print(
        row(
          'Banner over storm sky dark (mb.text / mb.skyBot)',
          contrast(dmb.text, dmb.skyBot),
        ),
      );
      print(
        row(
          'Affordance hint light (mb.textDim / mb.softCoral)',
          contrast(lmb.textDim, lmb.softCoral),
        ),
      );
      print(
        row(
          'Affordance hint dark (mb.textDim / mb.softCoral)',
          contrast(dmb.textDim, dmb.softCoral),
        ),
      );
      print('=== end ===\n');
      // No assertions — this test exists to print the artifact. Keep it
      // green so the runner doesn't fail on a CI rerun.
      expect(true, isTrue);
    },
    skip: false,
  );
}
