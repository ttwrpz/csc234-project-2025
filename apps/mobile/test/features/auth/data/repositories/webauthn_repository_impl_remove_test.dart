import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/datasources/webauthn_browser_datasource.dart';
import 'package:moodbloom/features/auth/data/datasources/webauthn_credential_firestore_datasource.dart';
import 'package:moodbloom/features/auth/data/datasources/webauthn_functions_datasource.dart';
import 'package:moodbloom/features/auth/data/webauthn_repository_impl.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_credential.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_remove_failure.dart';

/// Functions-datasource fake. Only `removeCredential` is exercised by the
/// remove path; every other call routes through `noSuchMethod` and throws,
/// so a stray call surfaces loudly rather than silently passing.
class _FakeFunctions implements WebauthnFunctionsDatasource {
  _FakeFunctions(this.onRemove);

  final Future<Map<String, Object?>> Function() onRemove;
  int removeCount = 0;

  @override
  Future<Map<String, Object?>> removeCredential() {
    removeCount += 1;
    return onRemove();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBrowser implements WebauthnBrowserDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeFirestore implements WebauthnCredentialFirestoreDatasource {
  @override
  Stream<WebauthnCredential?> watch({required String userId}) =>
      const Stream<WebauthnCredential?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

WebauthnRepositoryImpl _repo(_FakeFunctions functions) =>
    WebauthnRepositoryImpl(
      functions: functions,
      browser: _FakeBrowser(),
      firestore: _FakeFirestore(),
    );

void main() {
  group('WebauthnRepositoryImpl.removeCredential', () {
    test('ok:true response maps to Ok and calls the CF once', () async {
      final functions = _FakeFunctions(() async => {'ok': true, 'removed': 1});
      final repo = _repo(functions);

      final result = await repo.removeCredential(uid: 'u-1');

      expect(result, isA<Ok<void, WebauthnRemoveFailure>>());
      expect(functions.removeCount, 1);
    });

    test('ok:false response maps to a network failure', () async {
      final functions = _FakeFunctions(
        () async => {'ok': false, 'code': 'internal'},
      );
      final repo = _repo(functions);

      final result = await repo.removeCredential(uid: 'u-1');

      expect(result, isA<Err<void, WebauthnRemoveFailure>>());
      final failure = (result as Err<void, WebauthnRemoveFailure>).failure;
      expect(failure, isA<WebauthnRemoveFailure>());
    });

    test('an unexpected throw maps to an unknown failure', () async {
      final functions = _FakeFunctions(() async => throw Exception('boom'));
      final repo = _repo(functions);

      final result = await repo.removeCredential(uid: 'u-1');

      expect(result, isA<Err<void, WebauthnRemoveFailure>>());
    });
  });
}
