import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/intervention/data/ai_quote_repository_impl.dart';
import 'package:moodbloom/features/intervention/data/datasources/suggest_quote_functions_datasource.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_context.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

class _FakeDatasource implements SuggestQuoteFunctionsDatasource {
  Map<String, dynamic>? nextResponse;
  Object? throwOnCall;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<Map<String, dynamic>> call({
    required int tier,
    required String weekId,
    required double dailyAvgS,
    required String dominantEmotion,
  }) async {
    calls.add(<String, Object?>{
      'tier': tier,
      'weekId': weekId,
      'dailyAvgS': dailyAvgS,
      'dominantEmotion': dominantEmotion,
    });
    if (throwOnCall != null) {
      throw throwOnCall!;
    }
    return nextResponse ?? const {};
  }

  @override
  // ignore: unused_element
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeDatasource ds;
  late AIQuoteRepositoryImpl repo;

  setUp(() {
    ds = _FakeDatasource();
    repo = AIQuoteRepositoryImpl(datasource: ds);
  });

  const ctx = QuoteContext(
    weekId: '2026-W19',
    dailyAvgS: -0.4,
    dominantEmotion: MoodType.sad,
  );

  group('AIQuoteRepositoryImpl — success path', () {
    test('200 OK with suggestedText → Ok(rawText)', () async {
      ds.nextResponse = <String, dynamic>{
        'suggestedText': 'Maybe a quiet breath helps.',
      };
      final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
      expect(result, isA<Ok<String, QuoteFailure>>());
      final value = (result as Ok<String, QuoteFailure>).value;
      expect(value, 'Maybe a quiet breath helps.');
    });

    test('Tier 2 maps to wire `tier: 2`', () async {
      ds.nextResponse = <String, dynamic>{'suggestedText': 'Write a little.'};
      await repo.requestSuggestion(AiAllowedTier.two, ctx);
      expect(ds.calls.first['tier'], 2);
    });

    test('Tier 1 maps to wire `tier: 1`', () async {
      ds.nextResponse = <String, dynamic>{'suggestedText': 'Breathe softly.'};
      await repo.requestSuggestion(AiAllowedTier.one, ctx);
      expect(ds.calls.first['tier'], 1);
    });
  });

  group('AIQuoteRepositoryImpl — datasource exceptions', () {
    test('rate-limit exception → QuoteFailure.network', () async {
      ds.throwOnCall = const SuggestQuoteDatasourceException.rateLimited();
      final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
      expect(result, isA<Err<String, QuoteFailure>>());
      final failure = (result as Err<String, QuoteFailure>).failure;
      expect(failure.toString(), contains('Network'));
    });

    test('network exception → QuoteFailure.network', () async {
      ds.throwOnCall = const SuggestQuoteDatasourceException.network();
      final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
      expect((result as Err).failure.toString(), contains('Network'));
    });

    test(
      'unauthenticated → QuoteFailure.network (treated as transient)',
      () async {
        ds.throwOnCall =
            const SuggestQuoteDatasourceException.unauthenticated();
        final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
        expect((result as Err).failure.toString(), contains('Network'));
      },
    );

    test('malformed (invalid-argument from CF) → malformedResponse', () async {
      ds.throwOnCall = const SuggestQuoteDatasourceException.malformed(
        'tier:3 rejected',
      );
      final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
      final failure = (result as Err<String, QuoteFailure>).failure;
      expect(failure.toString(), contains('Malformed'));
    });

    test('missing suggestedText → malformedResponse', () async {
      ds.nextResponse = <String, dynamic>{};
      final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
      final failure = (result as Err<String, QuoteFailure>).failure;
      expect(failure.toString(), contains('Malformed'));
    });

    test('empty suggestedText → malformedResponse', () async {
      ds.nextResponse = <String, dynamic>{'suggestedText': ''};
      final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
      final failure = (result as Err<String, QuoteFailure>).failure;
      expect(failure.toString(), contains('Malformed'));
    });

    test('arbitrary exception → QuoteFailure.unknown', () async {
      ds.throwOnCall = Exception('boom');
      final result = await repo.requestSuggestion(AiAllowedTier.one, ctx);
      final failure = (result as Err<String, QuoteFailure>).failure;
      expect(failure.toString(), contains('Unknown'));
    });
  });

  group('AIQuoteRepositoryImpl — outbound PII canary', () {
    test(
      'payload contains ONLY tier, weekId, dailyAvgS, dominantEmotion',
      () async {
        ds.nextResponse = <String, dynamic>{'suggestedText': 'x'};
        await repo.requestSuggestion(AiAllowedTier.two, ctx);

        expect(ds.calls, hasLength(1));
        final call = ds.calls.first;

        // Allow-list of keys that may appear in the outbound payload.
        const allowedKeys = {'tier', 'weekId', 'dailyAvgS', 'dominantEmotion'};
        for (final key in call.keys) {
          expect(
            allowedKeys,
            contains(key),
            reason: 'Outbound payload contains forbidden key: $key',
          );
        }

        // Explicit deny-list — assert these PII fields are absent.
        expect(call.containsKey('userId'), isFalse);
        expect(call.containsKey('email'), isFalse);
        expect(call.containsKey('moodText'), isFalse);
        expect(call.containsKey('text'), isFalse);
        expect(call.containsKey('fcmToken'), isFalse);
        expect(call.containsKey('tokens'), isFalse);
        expect(call.containsKey('uid'), isFalse);
      },
    );

    test(
      'null dominantEmotion collapses to canonical "okay" (CF accepts only enum strings)',
      () async {
        ds.nextResponse = <String, dynamic>{'suggestedText': 'x'};
        const noEmotion = QuoteContext(weekId: '2026-W19', dailyAvgS: 0);
        await repo.requestSuggestion(AiAllowedTier.one, noEmotion);
        expect(ds.calls.first['dominantEmotion'], 'okay');
      },
    );

    test(
      'dominantEmotion maps each MoodType to canonical wire string',
      () async {
        const cases = [
          (MoodType.happy, 'happy'),
          (MoodType.calm, 'calm'),
          (MoodType.okay, 'okay'),
          (MoodType.sad, 'sad'),
          (MoodType.angry, 'angry'),
          (MoodType.anxious, 'anxious'),
        ];
        for (final (mood, wire) in cases) {
          ds.calls.clear();
          ds.nextResponse = <String, dynamic>{'suggestedText': 'x'};
          await repo.requestSuggestion(
            AiAllowedTier.one,
            QuoteContext(
              weekId: '2026-W19',
              dailyAvgS: 0,
              dominantEmotion: mood,
            ),
          );
          expect(ds.calls.first['dominantEmotion'], wire);
        }
      },
    );
  });
}
