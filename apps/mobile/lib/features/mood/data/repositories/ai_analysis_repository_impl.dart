import 'package:core/core.dart';

import '../../domain/ai_analysis_failure.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/repositories/ai_analysis_repository.dart';
import '../datasources/ai_analysis_functions_datasource.dart';
import '../dtos/ai_suggestion_dto.dart';

class AiAnalysisRepositoryImpl implements AIAnalysisRepository {
  const AiAnalysisRepositoryImpl({
    required AiAnalysisFunctionsDatasource datasource,
    Logger logger = const Logger('mood.ai'),
  }) : _datasource = datasource,
       _logger = logger;

  final AiAnalysisFunctionsDatasource _datasource;
  final Logger _logger;

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
        final result = AiSuggestionDto.fromJson(payload).toEntity();
        if (result is Err<AiSuggestion, AiAnalysisFailure>) {
          // Defensive: log only the failure runtimeType — never the input
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
}
