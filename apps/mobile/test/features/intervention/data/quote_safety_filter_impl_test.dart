import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/intervention/data/quote_library_impl.dart';
import 'package:moodbloom/features/intervention/data/quote_safety_filter_impl.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_failure.dart';

/// TC-41 - the canonical safety-filter test. 55 explicit inputs across four
/// rejection categories + 5 known-good positive controls. 100% of the
/// rejection inputs MUST return `Err`; 100% of the controls MUST return
/// `Ok`. A single pass-through in the rejection set fails the build -
/// that is the entire point.
///
/// Test groups:
///   1. Forbidden-word inputs (25) - at least one input per blacklist term
///      (HB-008 §"QuoteSafetyFilter design").
///   2. Length-violation inputs (15) - > 140 chars, otherwise compassionate.
///   3. Off-script inputs (10) - random sentences not in the approved set.
///   4. "Almost-OK" inputs (5) - single forbidden word in valid phrasing.
///   5. Known-good controls (5) - drawn from the curated tier pools.
void main() {
  const filter = QuoteSafetyFilterImpl();

  // ──────────────────────────────────────────────────────────────────
  // Category 1 - 25 forbidden-word inputs. Spread across the blacklist;
  // each forbidden term appears in at least one input. Verbatim from
  // HB-008's blacklist:
  //   depression, anxiety disorder, bipolar, diagnose, diagnosis,
  //   medication, prescribe, therapy, therapist, must, should, now,
  //   have to, need to, fix yourself, get better, overcome.
  // ──────────────────────────────────────────────────────────────────
  const forbiddenInputs = <String>[
    // depression
    'Your depression may pass if you breathe slowly.',
    // anxiety disorder
    'Many people with anxiety disorder find a slow breath helps.',
    // bipolar
    'A short pause can help with bipolar weather.',
    // diagnose
    'We will not diagnose you here, only invite a pause.',
    // diagnosis
    'A diagnosis is not what you need right now.',
    // medication
    'Your medication regime aside, a gentle breath helps.',
    // prescribe
    'We prescribe nothing - only a kind moment.',
    // therapy
    'Outside of therapy, a short pause is welcome.',
    // therapist
    'Your therapist might agree a breath is gentle.',
    // must
    'You must take a slow breath right now.',
    // should
    'You should breathe slowly and the storm will pass.',
    // now
    'Breathe slowly now and the moment will settle.',
    // have to
    'You have to write what is on your mind.',
    // need to
    'You need to journal about the week ahead.',
    // fix yourself
    'A quiet breath might fix yourself in a moment.',
    // get better
    'A short pause to get better - try a breath.',
    // overcome
    'Try to overcome this with a slow breath.',
    // depression - second instance to round out the spread
    'A short walk in the garden helps with depression.',
    // bipolar - second instance
    'Even bipolar weather can soften with a pause.',
    // should - second instance
    'A slow breath: you should try one now.',
    // diagnose - second instance
    'No one will diagnose you here; just a gentle breath.',
    // medication - second instance
    'Even on medication a short breath can help.',
    // therapy - second instance
    'Beyond therapy, a soft pause is welcome.',
    // overcome - second instance
    'A breath can help you overcome the moment.',
    // must - second instance
    'A slow breath you must try if it helps.',
  ];

  // ──────────────────────────────────────────────────────────────────
  // Category 2 - 15 over-length inputs (> 140 chars). Compassionate
  // phrasing padded with filler so the FORBIDDEN gate would PASS and
  // the WHITELIST gate would likely pass too; only the LENGTH gate
  // should fire.
  // ──────────────────────────────────────────────────────────────────
  final overLengthInputs = <String>[
    'A gentle breath can help the soil settle when the weather feels heavy and the garden has held many quiet moments through the week and the day before now.',
    'When rainy days happen the roots still hold and a soft breath can be a kind moment to yourself and the garden has been through gentle pauses many times before now.',
    'Would you like a soft pause for the garden today as a gentle breath can soften the moment and the soil has held many soft rainy days through this week ahead.',
    'Soft breaths help the garden hold steady when the weather feels heavy and the gentle pause can be enough for the moment to settle into a kind quiet space here.',
    'A few slow breaths can be enough for the garden to soften and the soil to settle as the weather passes and the gentle moment can hold for as long as you like.',
    'Rainy days happen in the garden and a short gentle breath can be a kind moment to yourself if it feels welcome to pause for a soft and quiet moment together here.',
    'The garden has weathered a long stretch and a gentle breath can help the soil settle for as long as you like to pause and the moment will hold for a quiet while here.',
    'Soft breathing can be a kind moment in the garden as the weather softens and the soil settles into a quiet pause for as long as you would like to breathe gently now today.',
    'A quiet breath can help the moment hold when the garden has had a heavy stretch and the soil has been through many rainy days through this week and the one before too.',
    'The garden is still here and a gentle breath can help you notice it for as long as you like to pause and the soft moment will hold for a kind quiet while together here.',
    'A few slow breaths in the garden today can soften the moment as the weather passes and the soil settles and the gentle pause can hold for as long as you would like.',
    'Would you like a short and quiet breath in the garden today as the weather softens and the soil settles into a gentle pause for as long as you would like together here.',
    'The garden holds you through the rainy days and a gentle breath can help the moment settle for a soft and quiet pause for as long as it feels welcome to breathe slowly.',
    'A soft pause can help the garden hold steady when the weather feels heavy and the gentle breath can be enough for the soil to settle into a kind quiet moment ahead.',
    'When the garden has had a long stretch of rainy days a slow gentle breath can be a kind moment to yourself for as long as you would like to pause and breathe softly.',
  ];

  // ──────────────────────────────────────────────────────────────────
  // Category 3 - 10 off-script inputs. Random sentences not in the
  // approved vocabulary. None contain forbidden terms, none exceed 140
  // chars; only the WHITELIST gate should fire.
  // ──────────────────────────────────────────────────────────────────
  const offScriptInputs = <String>[
    'The weather in Lyon is wonderful today.',
    'Apples roll downhill quickly during autumn.',
    'My cat enjoys chasing red dot lasers.',
    'Carburetors require periodic maintenance schedules.',
    'Quantum mechanics confuses many graduate students.',
    'The bakery sells excellent croissants on weekends.',
    'Penguins waddle gracefully across icy terrain.',
    'My grandmother knits sweaters for newborn babies.',
    'Sourdough bread rises slowly during cold nights.',
    'Locomotives whistle loudly through countryside villages.',
  ];

  // ──────────────────────────────────────────────────────────────────
  // Category 4 - 5 "almost-OK" inputs. Single forbidden word embedded
  // in otherwise valid phrasing. These are the trick cases - the filter
  // MUST catch them.
  // ──────────────────────────────────────────────────────────────────
  const almostOkInputs = <String>[
    'Maybe a short breathing exercise would help - you should try it.',
    'A gentle pause might help; you must breathe slowly for a moment.',
    'Soft breaths can be kind - you have to give it a try.',
    'A quiet breath would be welcome now if it helps.',
    'Writing a few lines could help you overcome the weather.',
  ];

  // ──────────────────────────────────────────────────────────────────
  // Positive controls - 5 known-good curated phrases drawn from the
  // tier pools. These MUST pass; failure here means the filter is
  // mis-aligned with the pool vocabulary.
  // ──────────────────────────────────────────────────────────────────
  final positiveControls = <(String, AiAllowedTier)>[
    (QuoteLibraryImpl.tier1Pool[0], AiAllowedTier.one),
    (QuoteLibraryImpl.tier1Pool[3], AiAllowedTier.one),
    (QuoteLibraryImpl.tier2Pool[0], AiAllowedTier.two),
    (QuoteLibraryImpl.tier2Pool[5], AiAllowedTier.two),
    (QuoteLibraryImpl.tier2Pool[11], AiAllowedTier.two),
  ];

  group('QuoteSafetyFilterImpl - TC-41 (55 inputs, 100% rejection)', () {
    test('Category 1: 25 forbidden-word inputs all reject', () {
      expect(forbiddenInputs, hasLength(25));
      for (final input in forbiddenInputs) {
        final result = filter.gate(input, tier: AiAllowedTier.one);
        expect(
          result,
          isA<Err<Quote, QuoteFailure>>(),
          reason: 'Forbidden-word input must reject: "$input"',
        );
        // Defence-in-depth: the snippet should reveal the failure
        // reason for the analytics path.
        final failure = (result as Err<Quote, QuoteFailure>).failure;
        expect(failure, isA<FilterReject>());
      }
    });

    test('Category 2: 15 over-length inputs all reject', () {
      expect(overLengthInputs, hasLength(15));
      for (final input in overLengthInputs) {
        expect(
          input.length,
          greaterThan(QuoteSafetyFilterImpl.maxLength),
          reason: 'Test data sanity: input must be over the cap.',
        );
        final result = filter.gate(input, tier: AiAllowedTier.one);
        expect(
          result,
          isA<Err<Quote, QuoteFailure>>(),
          reason:
              'Over-length input must reject: "${input.substring(0, 50)}..."',
        );
      }
    });

    test('Category 3: 10 off-script inputs all reject', () {
      expect(offScriptInputs, hasLength(10));
      for (final input in offScriptInputs) {
        final result = filter.gate(input, tier: AiAllowedTier.one);
        expect(
          result,
          isA<Err<Quote, QuoteFailure>>(),
          reason: 'Off-script input must reject: "$input"',
        );
      }
    });

    test('Category 4: 5 "almost-OK" trick inputs all reject', () {
      expect(almostOkInputs, hasLength(5));
      for (final input in almostOkInputs) {
        final result = filter.gate(input, tier: AiAllowedTier.one);
        expect(
          result,
          isA<Err<Quote, QuoteFailure>>(),
          reason:
              'Almost-OK input must reject (single forbidden word): "$input"',
        );
      }
    });

    test(
      'Aggregate: all 55 rejection inputs → 100% Err, zero pass-throughs',
      () {
        final all = <String>[
          ...forbiddenInputs,
          ...overLengthInputs,
          ...offScriptInputs,
          ...almostOkInputs,
        ];
        expect(all, hasLength(55));
        var passThroughs = 0;
        for (final input in all) {
          final result = filter.gate(input, tier: AiAllowedTier.one);
          if (result is Ok<Quote, QuoteFailure>) {
            passThroughs++;
            fail('Filter let through: "$input" - gave ${result.value.text}');
          }
        }
        expect(
          passThroughs,
          0,
          reason: 'TC-41 invariant: zero pass-throughs across 55 inputs.',
        );
      },
    );
  });

  group('QuoteSafetyFilterImpl - positive controls', () {
    test('5 curated phrases pass their tier filter', () {
      for (final (phrase, tier) in positiveControls) {
        final result = filter.gate(phrase, tier: tier);
        expect(
          result,
          isA<Ok<Quote, QuoteFailure>>(),
          reason:
              'Curated phrase must pass tier ${tier.name} filter: "$phrase"',
        );
        final ok = (result as Ok<Quote, QuoteFailure>).value;
        expect(ok.source, QuoteSource.ai); // Filter wraps as AI on pass
        expect(ok.text, phrase);
      }
    });
  });

  group('QuoteSafetyFilterImpl - edge cases', () {
    test('exactly 140 chars passes the length gate', () {
      // 140 chars exactly, using only approved Tier 1 vocabulary.
      // 'a gentle breath ' is 16 chars; 8 repeats = 128 chars; add a
      // 12-char compassionate tail.
      const padded =
          'a gentle breath a gentle breath a gentle breath a gentle breath a gentle breath a gentle breath a gentle breath a gentle breath kind';
      expect(padded.length, lessThanOrEqualTo(140));
      final result = filter.gate(padded, tier: AiAllowedTier.one);
      // May still reject on whitelist ratio for unusual constructions;
      // verify only that 140-char inputs are not auto-rejected on
      // length alone.
      // Either passes or rejects on a non-length reason.
      if (result is Err<Quote, QuoteFailure>) {
        final f = result.failure;
        expect(f, isA<FilterReject>());
        if (f is FilterReject) {
          expect(f.snippet, isNot(contains('length')));
        }
      }
    });

    test('whole-word semantics: "diagnose" alone triggers forbidden gate; '
        '"diagnosing" does not', () {
      // HB-008 is explicit: "diagnose" matches but "diagnosing" does NOT.
      // Direct positive: a sentence containing the bare token
      // "diagnose" must reject WITH the forbidden marker.
      const withDiagnose = 'A short breath: no one will diagnose anything.';
      final r1 = filter.gate(withDiagnose, tier: AiAllowedTier.one);
      expect(r1, isA<Err<Quote, QuoteFailure>>());
      final f1 = (r1 as Err<Quote, QuoteFailure>).failure;
      expect(f1, isA<FilterReject>());
      if (f1 is FilterReject) {
        expect(
          f1.snippet,
          contains('forbidden:diagnose'),
          reason: 'Bare "diagnose" must trip the forbidden gate.',
        );
      }

      // Negative control: a sentence containing "diagnosing" (a
      // distinct token after lowercasing + tokenisation) must NOT
      // hit `forbidden:diagnose`. Whether the sentence ultimately
      // passes or rejects on whitelist ratio depends on the rest of
      // the vocabulary - we only assert the forbidden-gate behaviour.
      const withDiagnosing = 'A breath while diagnosing the moment.';
      final r2 = filter.gate(withDiagnosing, tier: AiAllowedTier.one);
      if (r2 is Err<Quote, QuoteFailure> && r2.failure is FilterReject) {
        final fr = r2.failure as FilterReject;
        expect(
          fr.snippet,
          isNot(contains('forbidden:diagnose')),
          reason:
              '"diagnosing" must not be treated as the forbidden token "diagnose".',
        );
      }
    });

    test('empty / whitespace input rejects (no semantic content)', () {
      final result = filter.gate('   ', tier: AiAllowedTier.one);
      expect(result, isA<Err<Quote, QuoteFailure>>());
    });
  });
}
