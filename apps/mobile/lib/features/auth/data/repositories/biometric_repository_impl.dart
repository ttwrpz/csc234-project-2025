import 'package:core/core.dart';

import '../../domain/entities/biometric_capability.dart';
import '../../domain/repositories/biometric_repository.dart';
import '../datasources/biometric_datasource.dart';
import '../datasources/biometric_preference_datasource.dart';

/// Composes the platform `local_auth` datasource with a `SharedPreferences`-
/// backed opt-in flag. The use case sees a single [BiometricCapability] and
/// a clean `bool` from [authenticate]; failure mapping happens here and in
/// the use case (which converts exceptions into `Result.Err`).
class BiometricRepositoryImpl implements BiometricRepository {
  BiometricRepositoryImpl({
    required BiometricDatasource datasource,
    required BiometricPreferenceDatasource preference,
    Logger logger = const Logger('auth.biometric'),
  }) : _datasource = datasource,
       _preference = preference,
       _logger = logger;

  final BiometricDatasource _datasource;
  final BiometricPreferenceDatasource _preference;
  final Logger _logger;

  @override
  Future<BiometricCapability> capability() async {
    final isAvailable = await _datasource.isDeviceSupported();
    final canCheck = await _datasource.canCheckBiometrics();
    final enrolled = isAvailable && canCheck
        ? await _datasource.getEnrolledBiometrics()
        : const [];
    final optedIn = await _preference.isOptedIn();
    return BiometricCapability(
      isAvailable: isAvailable && canCheck,
      hasEnrolledBiometrics: enrolled.isNotEmpty,
      userOptedIn: optedIn,
    );
  }

  @override
  Future<void> setOptIn(bool enabled) => _preference.setOptIn(enabled);

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _datasource.authenticate(reason: reason);
    } on BiometricCancelledException {
      // User cancellation — not an error path for the repo contract.
      _logger.info('biometric cancelled');
      return false;
    } on BiometricUnavailableException catch (e) {
      _logger.warn('biometric unavailable: ${e.runtimeType}');
      throw const BiometricFailedException('unavailable');
    }
  }
}
