import 'package:cloud_functions/cloud_functions.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/analytics/data/datasources/analyze_patterns_functions_datasource.dart';
import 'package:moodbloom/features/mood/data/datasources/ai_analysis_functions_datasource.dart';
import 'package:moodbloom/features/mood/data/repositories/ai_analysis_repository_impl.dart';
import 'package:moodbloom/features/mood/domain/ai_analysis_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/ai_suggestion.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

class _FakeDatasource implements AiAnalysisFunctionsDatasource {
  Map<String, dynamic>? nextResponse;
  Object? throwOnCall;
  final List<({String text, String? locale})> calls = [];

  @override
  Future<Map<String, dynamic>> call({
    required String text,
    String? locale,
  }) async {
    calls.add((text: text, locale: locale));
    if (throwOnCall != null) {
      throw throwOnCall!;
    }
    return nextResponse ?? const {};
  }

  @override
  // ignore: unused_element
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePatternsDatasource implements AnalyzePatternsFunctionsDatasource {
  Map<String, dynamic>? nextResponse;
  Object? throwOnCall;
  final List<({List<MoodEntry> history, int windowDays})> calls = [];

  @override
  Future<Map<String, dynamic>> call({
    required List<MoodEntry> history,
    int windowDays = 90,
  }) async {
    calls.add((history: history, windowDays: windowDays));
    if (throwOnCall != null) {
      throw throwOnCall!;
    }
    return nextResponse ?? const {};
  }

  @override
  // ignore: unused_element
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> successPayload({
  String mood = 'happy',
  double confidence = 0.8,
}) {
  return {
    'ok': true,
    'v': 1,
    'requestId': '00000000-0000-0000-0000-000000000000',
    'mood': mood,
    'confidence': confidence,
    'alternative': null,
    'rationale': '',
    'flag': null,
    'latencyMs': 100,
    'modelVersion': 'gemini-2.5-flash',
  };
}

Map<String, Object?> errorPayload(String code, {Object? extra}) {
  return {
    'ok': false,
    'v': 1,
    'requestId': '00000000-0000-0000-0000-000000000000',
    'code': code,
    'message': 'something happened',
    if (extra is Map<String, Object?>) ...extra,
  };
}

void main() {
  late _FakeDatasource ds;
  late _FakePatternsDatasource patternsDs;
  late AiAnalysisRepositoryImpl repo;

  setUp(() {
    ds = _FakeDatasource();
    patternsDs = _FakePatternsDatasource();
    repo = AiAnalysisRepositoryImpl(
      datasource: ds,
      patternsDatasource: patternsDs,
      patternAnalysisEnabled: true,
    );
  });

  group('AiAnalysisRepositoryImpl - success path', () {
    test('valid success payload → Ok(AiSuggestion)', () async {
      ds.nextResponse = Map<String, dynamic>.from(successPayload());
      final result = await repo.analyzeMoodText(text: 'happy day');
      expect(result, isA<Ok<AiSuggestion, AiAnalysisFailure>>());
      final entity = (result as Ok<AiSuggestion, AiAnalysisFailure>).value;
      expect(entity.mood, MoodType.happy);
    });

    test('server-returned bogus mood → parseError', () async {
      ds.nextResponse = Map<String, dynamic>.from(
        successPayload(mood: 'melancholy'),
      );
      final result = await repo.analyzeMoodText(text: 'mixed feelings');
      expect(result, isA<Err<AiSuggestion, AiAnalysisFailure>>());
      final failure = (result as Err<AiSuggestion, AiAnalysisFailure>).failure;
      expect(failure.runtimeType.toString(), contains('ParseError'));
    });

    test(
      'Android-shaped payload (nested alternative as Map<Object?, Object?>) '
      '→ Ok, not _TypeError',
      () async {
        // Regression for the mobile-only "Couldn't analyze" bug (2026-06-05):
        // Android's platform channel decodes nested JSON objects as
        // Map<Object?, Object?>; the generated fromJson casts `alternative`
        // with `as Map<String, dynamic>` and threw _TypeError before the
        // repository re-keyed the nested map.
        final payload = Map<String, dynamic>.from(successPayload(mood: 'sad'));
        payload['alternative'] = <Object?, Object?>{
          'mood': 'anxious',
          'confidence': 0.4,
        };
        ds.nextResponse = payload;
        final result = await repo.analyzeMoodText(text: 'long enough text');
        expect(result, isA<Ok<AiSuggestion, AiAnalysisFailure>>());
        final entity = (result as Ok<AiSuggestion, AiAnalysisFailure>).value;
        expect(entity.mood, MoodType.sad);
        expect(entity.alternative?.mood, MoodType.anxious);
      },
    );
  });

  group('AiAnalysisRepositoryImpl - server error envelopes', () {
    test('rate_limited carries retryAfterSec into Duration', () async {
      ds.nextResponse = Map<String, dynamic>.from(
        errorPayload('rate_limited', extra: {'retryAfterSec': 30}),
      );
      final result = await repo.analyzeMoodText(text: 'x');
      expect(result, isA<Err<AiSuggestion, AiAnalysisFailure>>());
      final failure = (result as Err<AiSuggestion, AiAnalysisFailure>).failure;
      expect(failure.runtimeType.toString(), contains('RateLimited'));
      // The Duration is on the variant; we cast via switch to verify.
      final retryAfter = switch (failure) {
        // ignore: pattern_never_matches_value_type
        var f when f.runtimeType.toString().contains('RateLimited') =>
          (f as dynamic).retryAfter as Duration,
        _ => Duration.zero,
      };
      expect(retryAfter.inSeconds, 30);
    });

    test('gemini_unavailable → geminiUnavailable failure', () async {
      ds.nextResponse = Map<String, dynamic>.from(
        errorPayload('gemini_unavailable'),
      );
      final result = await repo.analyzeMoodText(text: 'x');
      final failure = (result as Err<AiSuggestion, AiAnalysisFailure>).failure;
      expect(failure.runtimeType.toString(), contains('GeminiUnavailable'));
    });

    test('parse_error envelope → parseError failure', () async {
      ds.nextResponse = Map<String, dynamic>.from(errorPayload('parse_error'));
      final result = await repo.analyzeMoodText(text: 'x');
      final failure = (result as Err<AiSuggestion, AiAnalysisFailure>).failure;
      expect(failure.runtimeType.toString(), contains('ParseError'));
    });

    test('unauthenticated envelope → unauthenticated failure', () async {
      ds.nextResponse = Map<String, dynamic>.from(
        errorPayload('unauthenticated'),
      );
      final result = await repo.analyzeMoodText(text: 'x');
      final failure = (result as Err<AiSuggestion, AiAnalysisFailure>).failure;
      expect(failure.runtimeType.toString(), contains('Unauthenticated'));
    });

    test('unknown server code falls through to geminiUnavailable', () async {
      ds.nextResponse = Map<String, dynamic>.from(errorPayload('teapot'));
      final result = await repo.analyzeMoodText(text: 'x');
      final failure = (result as Err<AiSuggestion, AiAnalysisFailure>).failure;
      expect(failure.runtimeType.toString(), contains('GeminiUnavailable'));
    });
  });

  group('AiAnalysisRepositoryImpl - datasource exceptions', () {
    test('AiUnauthenticatedException → unauthenticated', () async {
      ds.throwOnCall = const AiAnalysisDatasourceException.unauthenticated();
      final result = await repo.analyzeMoodText(text: 'x');
      expect(
        (result as Err<AiSuggestion, AiAnalysisFailure>).failure.runtimeType
            .toString(),
        contains('Unauthenticated'),
      );
    });

    test('AiNetworkException → network', () async {
      ds.throwOnCall = const AiAnalysisDatasourceException.network();
      final result = await repo.analyzeMoodText(text: 'x');
      expect(
        (result as Err<AiSuggestion, AiAnalysisFailure>).failure.runtimeType
            .toString(),
        contains('Network'),
      );
    });

    test('AiParseErrorException → parseError', () async {
      ds.throwOnCall = const AiAnalysisDatasourceException.parseError(
        'bad shape',
      );
      final result = await repo.analyzeMoodText(text: 'x');
      expect(
        (result as Err<AiSuggestion, AiAnalysisFailure>).failure.runtimeType
            .toString(),
        contains('ParseError'),
      );
    });

    test('arbitrary FirebaseFunctionsException bubbles to unknown', () async {
      ds.throwOnCall = FirebaseFunctionsException(
        message: 'permission-denied',
        code: 'permission-denied',
      );
      final result = await repo.analyzeMoodText(text: 'x');
      expect(
        (result as Err<AiSuggestion, AiAnalysisFailure>).failure.runtimeType
            .toString(),
        contains('Unknown'),
      );
    });
  });
}
