// Native (VM / Android / iOS / Windows / macOS / Linux) connector for the
// MoodDatabase. Selected via the conditional import in mood_database.dart
// when `dart.library.io` is available.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'moodbloom.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
