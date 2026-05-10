import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TC-15 — every `.dart` file under `lib/features/harvest/` is checked
/// for forbidden vocabulary that frames a harvest as destructive.
///
/// CLAUDE.md "Copy rules":
/// > NEVER use these words for the garden: "delete," "clear," "reset,"
/// > "lost," "destroyed," "wilted," "wilting," "dead," "dying"
///
/// HB-005 expands the list with: `gone`, `erased`.
///
/// Match strategy:
///  * The audit ONLY looks inside string literals (single- or
///    double-quoted, with or without raw `r` / interpolation `$`
///    prefixes). Identifier names, package paths, Firestore error
///    codes (e.g. `'deadline-exceeded'` ← legitimately contains
///    `dead`), and internal doc comments are out of scope: the rule
///    is about USER-FACING COPY, not source-code names.
///  * Within a string, we case-insensitively whole-word match the
///    forbidden vocabulary. A word like `clear` won't trip on
///    `clearly` or `cleared`; `dead` won't trip on `deadline`.
///  * On any hit, the test fails with file + matching word + the
///    offending string content so the next editor sees exactly
///    what to fix.
///
/// String extraction uses a deliberately simple regex that catches
/// `'…'` / `"…"` pairs on a single line. We accept that a multi-line
/// triple-quoted string inside the harvest feature would be ignored,
/// but no current file uses one — and adding multi-line awareness
/// is well beyond the test's blast radius.
void main() {
  const forbidden = <String>[
    'delete',
    'clear',
    'reset',
    'lost',
    'destroyed',
    'gone',
    'erased',
    'wilted',
    'wilting',
    'dead',
    'dying',
  ];

  final stringLiteral = RegExp(
    "(?:r?'(?:\\\\'|[^'])*')|(?:r?\"(?:\\\\\"|[^\"])*\")",
  );

  test('TC-15: harvest user-facing copy contains no forbidden vocabulary', () {
    // The Flutter test runner CWD is `apps/mobile/`.
    const harvestRoot = 'lib/features/harvest';
    final dir = Directory(harvestRoot);
    expect(
      dir.existsSync(),
      isTrue,
      reason: 'expected $harvestRoot to exist; tests run from apps/mobile/',
    );

    final dartFiles =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => !f.path.endsWith('.freezed.dart'))
            .where((f) => !f.path.endsWith('.g.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(
      dartFiles,
      isNotEmpty,
      reason: 'no .dart files found under $harvestRoot',
    );

    final hits = <String>[];

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      final lines = source.split('\n');
      for (var i = 0; i < lines.length; i += 1) {
        final line = lines[i];
        for (final match in stringLiteral.allMatches(line)) {
          // Strip the surrounding quote characters (and optional `r`
          // raw-string prefix) so we audit just the string body.
          var body = match.group(0)!;
          if (body.startsWith('r')) body = body.substring(1);
          // Drop the leading + trailing quote.
          body = body.substring(1, body.length - 1);

          for (final word in forbidden) {
            // Case-insensitive whole-word check. `\b` works on
            // `[a-zA-Z0-9_]` boundaries, which is what we want here:
            // "deadline" → no match on "dead"; "Dead Sea" → match.
            final regex = RegExp('\\b$word\\b', caseSensitive: false);
            if (regex.hasMatch(body)) {
              hits.add(
                '${file.path}:${i + 1} → '
                'string literal contains forbidden word "$word": '
                "'${body.trim()}'",
              );
            }
          }
        }
      }
    }

    expect(
      hits,
      isEmpty,
      reason:
          'TC-15 failed — forbidden vocabulary found in user-facing copy '
          'under $harvestRoot.\n${hits.join('\n')}',
    );
  });
}
