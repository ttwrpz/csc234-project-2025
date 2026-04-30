import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/auth/domain/repositories/biometric_repository.dart';

/// Hand-rolled fake mirroring the FakeAuthRepository pattern. Lets tests
/// configure the next [capability] read, the [authenticate] outcome, and
/// inspect calls to [setOptIn].
class FakeBiometricRepository implements BiometricRepository {
  FakeBiometricRepository({
    BiometricCapability? nextCapability,
    bool? nextAuthenticateResult,
    Object? authenticateThrows,
  }) : _capability =
           nextCapability ??
           const BiometricCapability(
             isAvailable: true,
             hasEnrolledBiometrics: true,
             userOptedIn: false,
           ),
       _authenticateResult = nextAuthenticateResult,
       _authenticateThrows = authenticateThrows;

  BiometricCapability _capability;
  bool? _authenticateResult;
  Object? _authenticateThrows;

  final List<bool> setOptInCalls = [];
  int authenticateCalls = 0;
  String? lastAuthenticateReason;

  /// Update the value [capability] will return.
  set nextCapability(BiometricCapability c) => _capability = c;
  set nextAuthenticateResult(bool? value) => _authenticateResult = value;
  set authenticateThrows(Object? error) => _authenticateThrows = error;

  @override
  Future<BiometricCapability> capability() async => _capability;

  @override
  Future<void> setOptIn(bool enabled) async {
    setOptInCalls.add(enabled);
    _capability = BiometricCapability(
      isAvailable: _capability.isAvailable,
      hasEnrolledBiometrics: _capability.hasEnrolledBiometrics,
      userOptedIn: enabled,
    );
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCalls += 1;
    lastAuthenticateReason = reason;
    if (_authenticateThrows != null) {
      throw _authenticateThrows!;
    }
    return _authenticateResult ?? true;
  }
}
