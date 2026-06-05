import 'package:core/core.dart';

import '../../../analytics/data/datasources/analyze_patterns_functions_datasource.dart';
import '../../../analytics/domain/entities/pattern_insight.dart';
import '../../domain/ai_analysis_failure.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/repositories/ai_analysis_repository.dart';
import '../datasources/ai_analysis_functions_datasource.dart';
import '../dtos/ai_suggestion_dto.dart';

class AiAnalysisRepositoryImpl implements AIAnalysisRepository {
  const AiAnalysisRepositoryImpl({
    required AiAnalysisFunctionsDatasource datasource,
    required AnalyzePatternsFunctionsDatasource patternsDatasource,
    required bool patternAnalysisEnabled,
    Logger logger = const Logger('mood.ai'),
  }) : _datasource = datasource,
       _patternsDatasource = patternsDatasource,
       _patternAnalysisEnabled = patternAnalysisEnabled,
       _logger = logger;

  final AiAnalysisFunctionsDatasource _datasource;
  final AnalyzePatternsFunctionsDatasource _patternsDatasource;
  final bool _patternAnalysisEnabled;
  final Logger _logger;

  @override
  bool get isEnabled => _patternAnalysisEnabled;

  @override
  Future<Result<AiSuggestion, AiAnalysisFailure>> analyzeMoodText({
    required String text,
    String? locale,
  }) async {
    try {
      final payload = await _datasource.call(text: text, locale: locale);

      // The function returns a discriminated union on `ok`. Success path goes
      // through the DTO mapper; error path is structural (no DTO).
      if (payload['ok'] == true) {
        // The cloud_functions callable can decode whole-number JSON fields
        // as `double` on some platforms; json_serializable casts the int
        // fields with `as int`, which then throws a _TypeError. Coerce the
        // numeric int fields to int before parsing so the success path is
        // robust to that num/int variance.
        final normalized = Map<String, Object?>.from(payload);
        for (final key in const ['v', 'latencyMs', 'intensity']) {
          final value = normalized[key];
          if (value is num) normalized[key] = value.toInt();
        }
        // Same platform variance one level down: Android's platform channel
        // decodes NESTED objects as Map<Object?, Object?>, and the generated
        // fromJson casts `alternative` with `as Map<String, dynamic>`, which
        // throws a _TypeError on native whenever the server includes an
        // alternative suggestion (web's JS interop yields string-keyed maps,
        // so it only bit Android). Re-key it like the top-level copy above.
        final alternative = normalized['alternative'];
        if (alternative is Map) {
          normalized['alternative'] = Map<String, Object?>.from(alternative);
        }
        final result = AiSuggestionDto.fromJson(normalized).toEntity();
        if (result is Err<AiSuggestion, AiAnalysisFailure>) {
          // Defensive: log only the failure runtimeType - never the input
          // text, never the failure.message (which could echo content).
          _logger.warn(
            'ai analyze parse failed',
            data: result.failure.runtimeType.toString(),
          );
        }
        return result;
      }

      // Error envelope: `{ok: false, code, message, retryAfterSec?}`.
      final code = payload['code'];
      final message = (payload['message'] as String?) ?? '';
      final failure = switch (code) {
        'invalid_input' => AiAnalysisFailure.invalidInput(message),
        'rate_limited' => AiAnalysisFailure.rateLimited(
          Duration(seconds: (payload['retryAfterSec'] as num?)?.toInt() ?? 60),
        ),
        'gemini_unavailable' => const AiAnalysisFailure.geminiUnavailable(),
        'parse_error' => AiAnalysisFailure.parseError(message),
        'unauthenticated' => const AiAnalysisFailure.unauthenticated(),
        _ => const AiAnalysisFailure.geminiUnavailable(),
      };
      _logger.warn(
        'ai analyze server error',
        data: failure.runtimeType.toString(),
      );
      return Err(failure);
    } on AiAnalysisDatasourceException catch (e) {
      final failure = switch (e) {
        AiUnauthenticatedException() =>
          const AiAnalysisFailure.unauthenticated(),
        AiNetworkException() => const AiAnalysisFailure.network(),
        AiParseErrorException(reason: final r) => AiAnalysisFailure.parseError(
          r,
        ),
      };
      _logger.warn(
        'ai analyze datasource exception',
        data: failure.runtimeType.toString(),
      );
      return Err(failure);
    } catch (e) {
      _logger.warn('ai analyze unknown error', data: e.runtimeType.toString());
      return Err(AiAnalysisFailure.unknown(e));
    }
  }

  @override
  Future<Result<List<PatternInsight>, AiAnalysisFailure>> analyzePatterns({
    required List<MoodEntry> history,
    int windowDays = 90,
  }) async {
    try {
      final payload = await _patternsDatasource.call(
        history: history,
        windowDays: windowDays,
      );

      if (payload['ok'] == true) {
        final raw = payload['insights'];
        if (raw is! List) {
          return const Err(
            AiAnalysisFailure.parseError(
              'insights field missing or wrong type',
            ),
          );
        }
        final insights = <PatternInsight>[];
        for (final item in raw) {
          if (item is! Map) continue;
          final json = Map<String, Object?>.from(item);
          // Hand-roll minimal coercion so a malformed wire entry does not
          // poison the whole batch.
          try {
            insights.add(PatternInsight.fromJson(json));
          } catch (e) {
            _logger.warn(
              'analyzePatterns insight parse failed',
              data: e.runtimeType.toString(),
            );
          }
        }
        return Ok(insights);
      }

      // Error envelope.
      final code = payload['code'];
      final message = (payload['message'] as String?) ?? '';
      final failure = switch (code) {
        'invalid_input' => AiAnalysisFailure.invalidInput(message),
        'rate_limited' => AiAnalysisFailure.rateLimited(
          Duration(seconds: (payload['retryAfterSec'] as num?)?.toInt() ?? 30),
        ),
        'unauthenticated' => const AiAnalysisFailure.unauthenticated(),
        _ => const AiAnalysisFailure.geminiUnavailable(),
      };
      _logger.warn(
        'analyzePatterns server error',
        data: failure.runtimeType.toString(),
      );
      return Err(failure);
    } on AiAnalysisDatasourceException catch (e) {
      final failure = switch (e) {
        AiUnauthenticatedException() =>
          const AiAnalysisFailure.unauthenticated(),
        AiNetworkException() => const AiAnalysisFailure.network(),
        AiParseErrorException(reason: final r) => AiAnalysisFailure.parseError(
          r,
        ),
      };
      _logger.warn(
        'analyzePatterns datasource exception',
        data: failure.runtimeType.toString(),
      );
      return Err(failure);
    } catch (e) {
      _logger.warn(
        'analyzePatterns unknown error',
        data: e.runtimeType.toString(),
      );
      return Err(AiAnalysisFailure.unknown(e));
    }
  }
}
