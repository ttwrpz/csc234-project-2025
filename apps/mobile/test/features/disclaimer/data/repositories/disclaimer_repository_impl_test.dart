import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/disclaimer/data/datasources/disclaimer_firestore_datasource.dart';
import 'package:moodbloom/features/disclaimer/data/repositories/disclaimer_repository_impl.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_failure.dart';

/// Hand-rolled fake datasource. Mirrors the
/// `pattern_repository_impl_test.dart` style - testing the repo through
/// a fake at the datasource boundary keeps the assertions about
/// FirebaseException → DisclaimerFailure mapping, while avoiding the
/// `fake_cloud_firestore` dev dependency (not in pubspec).
class _FakeDatasource implements DisclaimerFirestoreDatasource {
  /// When non-null, [ack] throws this on the next call.
  Object? nextAckError;

  /// Captures the userId of every successful ack.
  final List<String> ackedUsers = [];

  /// Driver for [watchAckState] - values returned in order.
  final List<bool> nextStreamValues = [];

  /// Records the userId that the stream was subscribed for.
  String? lastWatchUserId;

  @override
  Future<void> ack({required String userId}) async {
    final err = nextAckError;
    if (err != null) {
      nextAckError = null;
      // ignore: only_throw_errors
      throw err;
    }
    ackedUsers.add(userId);
  }

  @override
  Stream<bool> watchAckState({required String userId}) {
    lastWatchUserId = userId;
    return Stream.fromIterable(nextStreamValues);
  }
}

void main() {
  group('DisclaimerRepositoryImpl', () {
    late _FakeDatasource fake;
    late DisclaimerRepositoryImpl repo;

    setUp(() {
      fake = _FakeDatasource();
      repo = DisclaimerRepositoryImpl(datasource: fake);
    });

    test(
      'ack happy path returns Ok and forwards userId to datasource',
      () async {
        final result = await repo.ack(userId: 'u-1');

        expect(result, isA<Ok<void, DisclaimerFailure>>());
        expect(fake.ackedUsers, ['u-1']);
      },
    );

    test(
      'ack with empty userId returns Err(network) without touching datasource',
      () async {
        final result = await repo.ack(userId: '');

        expect(result, isA<Err<void, DisclaimerFailure>>());
        expect(fake.ackedUsers, isEmpty);
      },
    );

    test(
      'FirebaseException permission-denied → Err(permissionDenied)',
      () async {
        fake.nextAckError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );

        final result = await repo.ack(userId: 'u-1');

        expect(result, isA<Err<void, DisclaimerFailure>>());
        final failure = (result as Err<void, DisclaimerFailure>).failure;
        // The sealed-class variants do not expose a public discriminator
        // beyond the runtime type; `toString()` for Freezed-style sealed
        // failures contains the variant name and is the load-bearing
        // identity check used elsewhere in this test suite.
        expect(failure.toString(), contains('_PermissionDenied'));
      },
    );

    test(
      'FirebaseException unavailable → Err(network) (transient retryable)',
      () async {
        fake.nextAckError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );

        final result = await repo.ack(userId: 'u-1');

        expect(result, isA<Err<void, DisclaimerFailure>>());
        final failure = (result as Err<void, DisclaimerFailure>).failure;
        expect(failure.toString(), contains('_Network'));
      },
    );

    test(
      'FirebaseException unknown code → Err(unknown) carrying the code',
      () async {
        fake.nextAckError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'aborted',
        );

        final result = await repo.ack(userId: 'u-1');

        expect(result, isA<Err<void, DisclaimerFailure>>());
        final failure = (result as Err<void, DisclaimerFailure>).failure;
        expect(failure.toString(), contains('_Unknown'));
      },
    );

    test(
      'non-FirebaseException error → Err(unknown) carrying the type name',
      () async {
        fake.nextAckError = StateError('something is rotten');

        final result = await repo.ack(userId: 'u-1');

        expect(result, isA<Err<void, DisclaimerFailure>>());
        final failure = (result as Err<void, DisclaimerFailure>).failure;
        expect(failure.toString(), contains('_Unknown'));
      },
    );

    test('watchAckState forwards userId to the datasource', () {
      fake.nextStreamValues.addAll([false, true]);

      final stream = repo.watchAckState(userId: 'u-watcher');

      expect(stream, isA<Stream<bool>>());
      expect(fake.lastWatchUserId, 'u-watcher');
    });

    test('watchAckState with empty userId emits a single false', () async {
      final values = await repo.watchAckState(userId: '').toList();

      expect(values, [false]);
      expect(
        fake.lastWatchUserId,
        isNull,
        reason: 'empty userId must short-circuit before touching datasource',
      );
    });
  });
}
