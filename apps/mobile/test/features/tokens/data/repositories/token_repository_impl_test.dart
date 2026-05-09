import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/tokens/data/datasources/token_balance_firestore_datasource.dart';
import 'package:moodbloom/features/tokens/data/repositories/token_repository_impl.dart';
import 'package:moodbloom/features/tokens/domain/entities/token_award.dart';
import 'package:moodbloom/features/tokens/domain/entities/token_balance.dart';
import 'package:moodbloom/features/tokens/domain/token_failure.dart';

/// Recording fake of the Firestore datasource. Captures every call so
/// the impl's userId + clock semantics can be asserted without spinning
/// up a real `FirebaseFirestore`. Mirrors the `_FakeDatasource` in
/// `pattern_repository_impl_test.dart`.
class _FakeDatasource implements TokenBalanceFirestoreDatasource {
  final List<({String userId, DateTime now})> calls = [];
  final List<({String userId})> watches = [];

  /// When non-null, the next `awardForLog` throws this object.
  Object? throwOnNext;

  /// When non-null, the next `awardForLog` returns this award.
  TokenAward? returnNext;

  @override
  Future<TokenAward> awardForLog({
    required String userId,
    required DateTime now,
  }) async {
    calls.add((userId: userId, now: now));
    final t = throwOnNext;
    if (t != null) {
      throwOnNext = null;
      throw t;
    }
    final r = returnNext;
    if (r != null) {
      returnNext = null;
      return r;
    }
    return TokenAward(
      award: 5,
      updated: TokenBalance(
        balance: 5,
        earnedToday: 5,
        lastEarnedDate: DateTime(2026, 5, 12),
      ),
    );
  }

  @override
  Stream<TokenBalance> watchBalance({required String userId}) {
    watches.add((userId: userId));
    return const Stream<TokenBalance>.empty();
  }
}

void main() {
  group('TokenRepositoryImpl.awardForLog', () {
    late _FakeDatasource ds;
    late TokenRepositoryImpl repo;

    setUp(() {
      ds = _FakeDatasource();
      repo = TokenRepositoryImpl(
        datasource: ds,
        // Pin the clock so the fake's call list is deterministic.
        now: () => DateTime(2026, 5, 12, 10, 30),
      );
    });

    test(
      'happy path → Ok, datasource called with same userId + clock',
      () async {
        final outcome = await repo.awardForLog(userId: 'uid-1');
        expect(outcome, isA<Ok<TokenAward, TokenFailure>>());
        expect(ds.calls, hasLength(1));
        expect(ds.calls.single.userId, 'uid-1');
        expect(ds.calls.single.now, DateTime(2026, 5, 12, 10, 30));
        outcome.fold(
          ok: (a) {
            expect(a.award, 5);
            expect(a.updated.balance, 5);
          },
          err: (_) => fail('expected Ok'),
        );
      },
    );

    test('empty userId → Err(network), no datasource call', () async {
      final outcome = await repo.awardForLog(userId: '');
      expect(outcome, isA<Err<TokenAward, TokenFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
      expect(ds.calls, isEmpty);
    });

    test('Firestore permission-denied → Err(permissionDenied)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'PERMISSION_DENIED',
      );
      final outcome = await repo.awardForLog(userId: 'uid-1');
      expect(outcome, isA<Err<TokenAward, TokenFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Permission')),
      );
    });

    test('Firestore unavailable → Err(network)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'transient',
      );
      final outcome = await repo.awardForLog(userId: 'uid-1');
      expect(outcome, isA<Err<TokenAward, TokenFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
    });

    test('Firestore deadline-exceeded → Err(network)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
        message: 'slow',
      );
      final outcome = await repo.awardForLog(userId: 'uid-1');
      expect(outcome, isA<Err<TokenAward, TokenFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Network')),
      );
    });

    test('arbitrary FirebaseException code → Err(unknown)', () async {
      ds.throwOnNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'something-totally-new',
        message: 'huh',
      );
      final outcome = await repo.awardForLog(userId: 'uid-1');
      expect(outcome, isA<Err<TokenAward, TokenFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Unknown')),
      );
    });

    test('non-FirebaseException catch-all → Err(unknown)', () async {
      ds.throwOnNext = StateError('arbitrary failure');
      final outcome = await repo.awardForLog(userId: 'uid-1');
      expect(outcome, isA<Err<TokenAward, TokenFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) => expect(f.runtimeType.toString(), contains('Unknown')),
      );
    });
  });

  group('TokenRepositoryImpl.watchBalance', () {
    test('forwards userId to the datasource', () {
      final ds = _FakeDatasource();
      final repo = TokenRepositoryImpl(datasource: ds);
      final stream = repo.watchBalance(userId: 'uid-1');
      expect(stream, isA<Stream<TokenBalance>>());
      expect(ds.watches, hasLength(1));
      expect(ds.watches.single.userId, 'uid-1');
    });
  });
}
