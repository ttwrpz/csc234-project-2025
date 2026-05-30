import 'package:core/core.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_credential.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_register_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_verify_failure.dart';
import 'package:moodbloom/features/auth/domain/repositories/webauthn_repository.dart';

/// Hand-rolled fake for [WebauthnRepository]. Matches the project's
/// no-mockito policy (see fake_pin_repository.dart). The fake holds
/// canned `Result`s for [register] / [verify], a settable credential
/// stream for the Privacy UI, and records every call so widget tests
/// can assert dispatch.
class FakeWebauthnRepository implements WebauthnRepository {
  FakeWebauthnRepository({
    Result<WebauthnCredential, WebauthnRegisterFailure>? registerResult,
    Result<void, WebauthnVerifyFailure>? verifyResult,
    WebauthnCredential? credential,
  }) : _registerResult = registerResult,
       _verifyResult = verifyResult,
       _initialCredential = credential;

  Result<WebauthnCredential, WebauthnRegisterFailure>? _registerResult;
  Result<void, WebauthnVerifyFailure>? _verifyResult;
  Result<String, WebauthnVerifyFailure>? _loginResult;
  final WebauthnCredential? _initialCredential;

  final List<String> registerCalls = [];
  final List<String> verifyCalls = [];
  int loginCalls = 0;

  set registerResult(
    Result<WebauthnCredential, WebauthnRegisterFailure>? value,
  ) => _registerResult = value;

  set verifyResult(Result<void, WebauthnVerifyFailure>? value) =>
      _verifyResult = value;

  set loginResult(Result<String, WebauthnVerifyFailure>? value) =>
      _loginResult = value;

  @override
  Future<Result<WebauthnCredential, WebauthnRegisterFailure>> register({
    required String uid,
  }) async {
    registerCalls.add(uid);
    return _registerResult ??
        Ok(WebauthnCredential(credentialId: 'fake-cred', createdAt: _now()));
  }

  @override
  Future<Result<void, WebauthnVerifyFailure>> verify({
    required String uid,
  }) async {
    verifyCalls.add(uid);
    return _verifyResult ?? const Ok<void, WebauthnVerifyFailure>(null);
  }

  @override
  Future<Result<String, WebauthnVerifyFailure>> loginWithSecurityKey() async {
    loginCalls += 1;
    return _loginResult ?? const Ok<String, WebauthnVerifyFailure>('fake-token');
  }

  @override
  Stream<WebauthnCredential?> watchCredential({required String uid}) =>
      Stream<WebauthnCredential?>.value(_initialCredential);

  DateTime _now() => DateTime.utc(2026, 5, 15);
}
