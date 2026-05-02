import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import '../../../mood/data/datasources/ai_analysis_functions_datasource.dart';
import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';

/// Thin wrapper over `FirebaseFunctions.httpsCallable('analyzePatterns')`.
/// Owns transport (request id, projection, exception mapping); the
/// repository converts the raw payload to domain types.
///
/// **PII fence (ADR-0007 §"PII fence")**: the projection MUST drop
/// `text` and `mediaRefs` from each `MoodEntry` before serialising. The
/// Zod `.strict()` schema on the server will reject payloads containing
/// `text` at any nesting level, so a regression in the projection
/// produces an `invalid_input` envelope at runtime — but the unit test
/// on this datasource catches it at build time first.
class AnalyzePatternsFunctionsDatasource {
  AnalyzePatternsFunctionsDatasource(this._functions, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final FirebaseFunctions _functions;
  final Uuid _uuid;

  /// Calls the Cloud Function with a numeric-only projection of [history]
  /// and returns the raw payload map.
  Future<Map<String, dynamic>> call({
    required List<MoodEntry> history,
    int windowDays = 90,
  }) async {
    final callable = _functions.httpsCallable('analyzePatterns');
    final request = <String, Object?>{
      'requestId': _uuid.v4(),
      'v': 1,
      'windowDays': windowDays,
      // PII fence: numeric-only projection. Asserted by unit test.
      'history': history.map(projectEntry).toList(growable: false),
    };

    try {
      final result = await callable.call<Object?>(request);
      final data = result.data;
      if (data is! Map) {
        throw const AiAnalysisDatasourceException.parseError(
          'response data was not a map',
        );
      }
      return Map<String, dynamic>.from(data);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw const AiAnalysisDatasourceException.unauthenticated();
        case 'unavailable':
        case 'deadline-exceeded':
          throw const AiAnalysisDatasourceException.network();
        default:
          rethrow;
      }
    }
  }

  /// Public so unit tests can assert the projection drops `text` and
  /// `mediaRefs`. **Hard contract**: the returned map must contain
  /// exactly `{ date, moodCode, intensity }` keys — no `text`, no
  /// `mediaRefs`, no anything else.
  static Map<String, Object?> projectEntry(MoodEntry e) {
    return <String, Object?>{
      'date': _localDayIso(e.createdAt),
      'moodCode': _moodCodeWire(e.mood),
      'intensity': e.intensity,
    };
  }

  static String _localDayIso(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _moodCodeWire(MoodType m) => switch (m) {
    MoodType.happy => 'happy',
    MoodType.calm => 'calm',
    MoodType.okay => 'okay',
    MoodType.sad => 'sad',
    MoodType.angry => 'angry',
    MoodType.anxious => 'anxious',
  };
}
