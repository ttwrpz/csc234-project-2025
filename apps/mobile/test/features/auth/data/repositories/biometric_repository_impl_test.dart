import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moodbloom/features/auth/data/datasources/biometric_datasource.dart';
import 'package:moodbloom/features/auth/data/datasources/biometric_preference_datasource.dart';
import 'package:moodbloom/features/auth/data/repositories/biometric_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBiometricDatasource implements BiometricDatasource {
  bool deviceSupported = true;
  bool canCheck = true;
  List<BiometricType> enrolled = const [BiometricType.fingerprint];
  bool authenticateReturns = true;
  Object? authenticateThrows;

  int authenticateCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => enrolled;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCalls += 1;
    if (authenticateThrows != null) {
      throw authenticateThrows!;
    }
    return authenticateReturns;
  }
}

void main() {
  group('BiometricRepositoryImpl', () {
    late _FakeBiometricDatasource ds;
    late BiometricPreferenceDatasource prefDs;
    late BiometricRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ds = _FakeBiometricDatasource();
      prefDs = BiometricPreferenceDatasource(prefs);
      repo = BiometricRepositoryImpl(datasource: ds, preference: prefDs);
    });

    test('capability — device unsupported reports isAvailable=false', () async {
      ds.deviceSupported = false;
      ds.canCheck = false;
      final cap = await repo.capability();
      expect(cap.isAvailable, isFalse);
      expect(cap.hasEnrolledBiometrics, isFalse);
      expect(cap.userOptedIn, isFalse);
    });

    test('capability — enrolled biometrics flagged true', () async {
      final cap = await repo.capability();
      expect(cap.isAvailable, isTrue);
      expect(cap.hasEnrolledBiometrics, isTrue);
    });

    test('capability — empty enrolled list flagged false', () async {
      ds.enrolled = const [];
      final cap = await repo.capability();
      expect(cap.hasEnrolledBiometrics, isFalse);
    });

    test('setOptIn(true) is reflected in next capability read', () async {
      var cap = await repo.capability();
      expect(cap.userOptedIn, isFalse);

      await repo.setOptIn(true);
      cap = await repo.capability();
      expect(cap.userOptedIn, isTrue);
    });

    test('authenticate — true on datasource success', () async {
      ds.authenticateReturns = true;
      expect(await repo.authenticate(reason: 'r'), isTrue);
    });

    test('authenticate — false on BiometricCancelledException', () async {
      ds.authenticateThrows = const BiometricCancelledException();
      expect(await repo.authenticate(reason: 'r'), isFalse);
    });

    test('authenticate — rethrows BiometricFailedException on '
        'BiometricUnavailableException', () async {
      ds.authenticateThrows = const BiometricUnavailableException();
      expect(
        () => repo.authenticate(reason: 'r'),
        throwsA(isA<BiometricFailedException>()),
      );
    });
  });
}
