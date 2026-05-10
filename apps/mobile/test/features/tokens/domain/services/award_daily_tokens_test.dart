import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/tokens/domain/entities/token_balance.dart';
import 'package:moodbloom/features/tokens/domain/services/award_daily_tokens.dart';

/// Tests for the pure-Dart [awardDailyTokens] engine — pivot feature #10
/// (CLAUDE.md), HB-005 §"Track 6.2 — Token economy", spec §7.1–§7.5
/// (TC-1..TC-5).
///
/// TC-2 is THE load-bearing assertion: the function is mood-agnostic by
/// construction. Two layers of evidence:
///   1. The signature has no emotion-content parameter.
///   2. A file-level grep of the source asserts zero references to
///      the emotion-feature filenames or class names. Any future
///      change that adds a mood-typed import trips the test
///      immediately, surfacing a design violation at PR time.
void main() {
  group('awardDailyTokens — TC-1..TC-5', () {
    test('TC-1 first log of day → 5 tokens, balance += 5', () {
      const start = TokenBalance(
        balance: 12,
        earnedToday: 0,
        lastEarnedDate: null,
      );
      final now = DateTime(2026, 5, 12, 10, 30);

      final award = awardDailyTokens(current: start, now: now);

      expect(award.award, 5);
      expect(award.updated.balance, 17);
      expect(award.updated.earnedToday, 5);
      expect(award.updated.lastEarnedDate, DateTime(2026, 5, 12));
    });

    test('within-day: logs 2..6 each award 1 (totals 6, 7, 8, 9, 10)', () {
      const today = TokenBalance(
        balance: 5,
        earnedToday: 5,
        lastEarnedDate: null, // overridden below per call
      );
      final lastDate = DateTime(2026, 5, 12);
      final now = DateTime(2026, 5, 12, 14, 0);

      // Log 2 (earnedToday 5 → 6).
      var s = today.copyWith(lastEarnedDate: lastDate);
      var a = awardDailyTokens(current: s, now: now);
      expect(a.award, 1);
      expect(a.updated.earnedToday, 6);
      expect(a.updated.balance, 6);

      // Log 3 (6 → 7).
      s = a.updated;
      a = awardDailyTokens(current: s, now: now);
      expect(a.award, 1);
      expect(a.updated.earnedToday, 7);
      expect(a.updated.balance, 7);

      // Log 4 (7 → 8).
      s = a.updated;
      a = awardDailyTokens(current: s, now: now);
      expect(a.updated.earnedToday, 8);

      // Log 5 (8 → 9).
      s = a.updated;
      a = awardDailyTokens(current: s, now: now);
      expect(a.updated.earnedToday, 9);

      // Log 6 (9 → 10).
      s = a.updated;
      a = awardDailyTokens(current: s, now: now);
      expect(a.award, 1);
      expect(a.updated.earnedToday, 10);
      expect(a.updated.balance, 10);
    });

    test('TC-2 mood-agnostic: same balance state produces same award '
        '(no emotion input by construction)', () {
      // The function takes only the balance + clock. A fresh-day call
      // returns 5 unconditionally — there is no path through which an
      // emotion-content value could change the answer, because no
      // emotion-content value is in the signature.
      const fresh = TokenBalance(
        balance: 0,
        earnedToday: 0,
        lastEarnedDate: null,
      );
      final now = DateTime(2026, 5, 12, 10, 30);
      final first = awardDailyTokens(current: fresh, now: now);
      final second = awardDailyTokens(current: fresh, now: now);
      expect(first.award, 5);
      expect(second.award, 5);
      expect(first.updated.balance, second.updated.balance);
    });

    test('TC-2 file-level: source contains no mood-feature references', () {
      // Absolute path resolution that survives whichever cwd the
      // runner picks (project root vs. apps/mobile). Walk up until
      // the apps/mobile boundary is found.
      final source = _readTokenServiceSource();
      // Grep the canonical filenames of the emotion feature.
      // Any line importing from those would fail this assertion.
      // A comment that mentions them in passing also fails — by
      // design: even comment-level coupling signals a design
      // smell that should surface at PR time.
      for (final needle in const [
        'mood_type.dart',
        'mood_entry.dart',
        'mood_score.dart',
        'MoodType',
        'MoodEntry',
        'MoodScore',
      ]) {
        expect(
          source.contains(needle),
          isFalse,
          reason:
              'award_daily_tokens.dart contains forbidden reference '
              '"$needle" — the function MUST stay mood-agnostic by '
              'construction (Cheng et al. 2019).',
        );
      }
    });

    test('TC-3 cap reached: 7th log → award = 0, no field changes', () {
      final lastDate = DateTime(2026, 5, 12);
      final now = DateTime(2026, 5, 12, 22, 0);
      final capped = TokenBalance(
        balance: 10,
        earnedToday: 10,
        lastEarnedDate: lastDate,
      );

      final award = awardDailyTokens(current: capped, now: now);

      expect(award.award, 0);
      // Cap-reached path returns the input balance unchanged so the
      // datasource can skip the Firestore round-trip entirely.
      expect(award.updated, capped);
    });

    test(
      'TC-4 midnight reset: yesterday → today → award = 5, earnedToday = 5',
      () {
        final yesterday = DateTime(2026, 5, 11);
        final now = DateTime(2026, 5, 12, 7, 30);
        final state = TokenBalance(
          balance: 25,
          earnedToday: 10, // yesterday's cap
          lastEarnedDate: yesterday,
        );

        final award = awardDailyTokens(current: state, now: now);

        expect(award.award, 5);
        expect(award.updated.earnedToday, 5);
        expect(award.updated.balance, 30);
        expect(award.updated.lastEarnedDate, DateTime(2026, 5, 12));
      },
    );

    test('TC-5 missed days lose nothing: lastEarnedDate = today - 3 → '
        'award = 5, balance preserved', () {
      final threeDaysAgo = DateTime(2026, 5, 9);
      final now = DateTime(2026, 5, 12, 10, 0);
      final state = TokenBalance(
        balance: 47,
        earnedToday: 8,
        lastEarnedDate: threeDaysAgo,
      );

      final award = awardDailyTokens(current: state, now: now);

      expect(award.award, 5);
      // Crucially, the previous 47-token balance is preserved — the
      // user is NOT punished for missing days. Cheng et al. 2019
      // guardrail.
      expect(award.updated.balance, 52);
      expect(award.updated.earnedToday, 5);
      expect(award.updated.lastEarnedDate, DateTime(2026, 5, 12));
    });

    test('boundary: lastEarnedDate same calendar day but distant clock '
        '→ treated as same day (compares localMidnight, not raw 24h)', () {
      // Last log at 00:30 today, current call at 23:30 today. Raw
      // delta is 23h, but they are the same calendar day → same-day
      // path (1-token award), NOT a fresh-day reset.
      final lastDate = DateTime(2026, 5, 12, 0, 30);
      final now = DateTime(2026, 5, 12, 23, 30);
      final state = TokenBalance(
        balance: 5,
        earnedToday: 5,
        lastEarnedDate: lastDate,
      );

      final award = awardDailyTokens(current: state, now: now);

      expect(award.award, 1);
      expect(award.updated.earnedToday, 6);
    });

    test('boundary: lastEarnedDate 23:59 yesterday + now 00:01 today → '
        'fresh-day reset (different calendar day)', () {
      // Only 2 minutes elapsed but two distinct calendar days —
      // localMidnight comparison fires correctly.
      final yesterdayLate = DateTime(2026, 5, 11, 23, 59);
      final nowEarly = DateTime(2026, 5, 12, 0, 1);
      final state = TokenBalance(
        balance: 9,
        earnedToday: 9,
        lastEarnedDate: yesterdayLate,
      );

      final award = awardDailyTokens(current: state, now: nowEarly);

      expect(award.award, 5);
      expect(award.updated.earnedToday, 5);
      expect(award.updated.balance, 14);
    });
  });
}

/// Locates `award_daily_tokens.dart` regardless of the test runner's
/// cwd. `flutter test` runs from `apps/mobile/`; an IDE may run from
/// the project root.
String _readTokenServiceSource() {
  const relative =
      'lib/features/tokens/domain/services/award_daily_tokens.dart';
  final candidates = <String>[
    relative,
    'apps/mobile/$relative',
    '../$relative',
  ];
  for (final p in candidates) {
    final f = File(p);
    if (f.existsSync()) return f.readAsStringSync();
  }
  fail(
    'Could not locate award_daily_tokens.dart from cwd '
    '${Directory.current.path}. Searched: $candidates',
  );
}
