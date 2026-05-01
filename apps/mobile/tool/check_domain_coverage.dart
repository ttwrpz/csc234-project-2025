// Per-feature domain-coverage report from coverage/lcov.info.

import 'dart:io';

void main() {
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln('coverage/lcov.info not found.');
    exit(2);
  }

  final byFeature = <String, _Tally>{};
  final lines = lcov.readAsLinesSync();
  bool isDomain = false;
  String? feature;
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).replaceAll(r'\', '/');
      final m = RegExp(
        r'lib/features/([^/]+)/domain/.+\.dart$',
      ).firstMatch(path);
      isDomain =
          m != null &&
          !path.endsWith('.freezed.dart') &&
          !path.endsWith('.g.dart');
      feature = m?.group(1);
      continue;
    }
    if (line == 'end_of_record') {
      isDomain = false;
      feature = null;
      continue;
    }
    if (!isDomain || feature == null) continue;
    if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length != 2) continue;
      final hits = int.tryParse(parts[1]) ?? 0;
      final tally = byFeature.putIfAbsent(feature, _Tally.new);
      tally.lines++;
      if (hits > 0) tally.hit++;
    }
  }

  final features = byFeature.keys.toList()..sort();
  print('| feature | lines covered | total lines | coverage |');
  print('|---|---:|---:|---:|');
  var allCovered = 0;
  var allTotal = 0;
  var anyBelow = false;
  for (final feat in features) {
    final t = byFeature[feat]!;
    allCovered += t.hit;
    allTotal += t.lines;
    final pct = t.lines == 0 ? 100.0 : (t.hit * 100.0) / t.lines;
    final marker = pct >= 80 ? '✓' : '✗';
    if (pct < 80) anyBelow = true;
    print(
      '| $feat | ${t.hit} | ${t.lines} | ${pct.toStringAsFixed(1)}% $marker |',
    );
  }
  final overall = allTotal == 0 ? 100.0 : (allCovered * 100.0) / allTotal;
  print(
    '| **all** | **$allCovered** | **$allTotal** | **${overall.toStringAsFixed(1)}%** |',
  );
  if (anyBelow) {
    stderr.writeln('\nAt least one feature is below 80%.');
    exit(1);
  }
}

class _Tally {
  int lines = 0;
  int hit = 0;
}
