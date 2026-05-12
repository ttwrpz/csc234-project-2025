import 'package:core/core.dart';

import '../../mood/domain/entities/mood_type.dart';
import '../domain/entities/ai_allowed_tier.dart';
import '../domain/entities/quote_context.dart';
import '../domain/entities/quote_failure.dart';
import '../domain/repositories/ai_quote_repository.dart';
import 'datasources/suggest_quote_functions_datasource.dart';

/// Concrete [AIQuoteRepository] backed by the `suggestQuote` Cloud Function.
///
/// Per HB-008: the repo's job is "ask Gemini, return the raw string". It
/// does NOT run the [QuoteSafetyFilterImpl] — the dispatcher composes
/// filter + repo so a future refactor can swap one without touching the
/// other.
///
/// **Tier 3 fence (ADR-0012 §"Decision" point 2):** the method signature
/// accepts [AiAllowedTier], which by construction excludes [Tier.three].
/// A Tier 3 dispatch literally cannot reach this code path. The CF
/// rejects `tier: 3` at the server boundary too — belt-and-suspenders.
///
/// **PII fence:** [requestSuggestion] sends only `tier`, `weekId`,
/// `dailyAvgS`, and `dominantEmotion`. Never `userId`, `email`, raw
/// `moodText`, or FCM tokens. The Dart-side unit test asserts the
/// outbound shape; the CF-side test asserts the Gemini prompt body.
class AIQuoteRepositoryImpl implements AIQuoteRepository {
  AIQuoteRepositoryImpl({
    required SuggestQuoteFunctionsDatasource datasource,
    Logger logger = const Logger('intervention.aiQuote'),
  }) : _datasource = datasource,
       _logger = logger;

  final SuggestQuoteFunctionsDatasource _datasource;
  final Logger _logger;

  @override
  Future<Result<String, QuoteFailure>> requestSuggestion(
    AiAllowedTier tier,
    QuoteContext ctx,
  ) async {
    final start = DateTime.now();
    try {
      final payload = await _datasource.call(
        tier: _tierWire(tier),
        weekId: ctx.weekId,
        dailyAvgS: ctx.dailyAvgS,
        dominantEmotion: _emotionWire(ctx.dominantEmotion),
      );

      final suggested = payload['suggestedText'];
      if (suggested is! String || suggested.isEmpty) {
        _logCall(tier: tier, durationMs: _durationMsSince(start), ok: false);
        return const Err(QuoteFailure.malformedResponse());
      }

      _logCall(tier: tier, durationMs: _durationMsSince(start), ok: true);
      // NEVER log `suggested` — the dispatcher will pass it through the
      // Safety Filter, but the raw text could contain off-script content
      // we should not persist in observability.
      return Ok(suggested);
    } on SuggestQuoteDatasourceException catch (e) {
      _logCall(tier: tier, durationMs: _durationMsSince(start), ok: false);
      final failure = switch (e) {
        SuggestQuoteUnauthenticatedException() => const QuoteFailure.network(),
        SuggestQuoteNetworkException() => const QuoteFailure.network(),
        SuggestQuoteRateLimitedException() => const QuoteFailure.network(),
        SuggestQuoteMalformedException() =>
          const QuoteFailure.malformedResponse(),
      };
      return Err(failure);
    } catch (e) {
      _logCall(tier: tier, durationMs: _durationMsSince(start), ok: false);
      return Err(QuoteFailure.unknown(e));
    }
  }

  /// Wire-level tier code: `AiAllowedTier.one` → 1, `AiAllowedTier.two` →
  /// 2. The CF rejects `tier: 3` at the input-schema boundary.
  int _tierWire(AiAllowedTier tier) => switch (tier) {
    AiAllowedTier.one => 1,
    AiAllowedTier.two => 2,
  };

  /// Wire-level emotion string matching the Cloud Function's allow-list.
  /// `null` collapses to `'okay'` so the CF always sees one of the six
  /// canonical strings — the CF rejects unknown values.
  String _emotionWire(MoodType? mood) => switch (mood) {
    null => 'okay',
    MoodType.happy => 'happy',
    MoodType.calm => 'calm',
    MoodType.okay => 'okay',
    MoodType.sad => 'sad',
    MoodType.angry => 'angry',
    MoodType.anxious => 'anxious',
  };

  int _durationMsSince(DateTime start) =>
      DateTime.now().difference(start).inMilliseconds;

  /// Structured log: tier index, durationMs, success flag. No PII, no
  /// suggested text, no userId. The repo logs only what's safe.
  void _logCall({
    required AiAllowedTier tier,
    required int durationMs,
    required bool ok,
  }) {
    _logger.info(
      'suggestQuote',
      data: <String, Object?>{
        'tier': _tierWire(tier),
        'source': 'ai',
        'durationMs': durationMs,
        'succeeded': ok,
      },
    );
  }
}
