import 'dart:async';

/// Outcome of a browser WebAuthn ceremony. The repository layer
/// converts these into the domain `Result<…, WebauthnRegisterFailure>`
/// / `Result<…, WebauthnVerifyFailure>` types.
///
/// All binary fields are base64url-encoded strings so the repository
/// can pass them straight through to the Cloud Function call payload
/// without re-encoding.
class WebauthnRegistrationResponse {
  const WebauthnRegistrationResponse({
    required this.id,
    required this.rawId,
    required this.clientDataJSON,
    required this.attestationObject,
    required this.transports,
  });

  final String id;
  final String rawId;
  final String clientDataJSON;
  final String attestationObject;
  final List<String> transports;

  Map<String, Object?> toJson() => {
    'id': id,
    'rawId': rawId,
    'type': 'public-key',
    'response': {
      'clientDataJSON': clientDataJSON,
      'attestationObject': attestationObject,
      'transports': transports,
    },
    'clientExtensionResults': const <String, Object?>{},
  };
}

class WebauthnAssertionResponse {
  const WebauthnAssertionResponse({
    required this.id,
    required this.rawId,
    required this.clientDataJSON,
    required this.authenticatorData,
    required this.signature,
    this.userHandle,
  });

  final String id;
  final String rawId;
  final String clientDataJSON;
  final String authenticatorData;
  final String signature;
  final String? userHandle;

  Map<String, Object?> toJson() => {
    'id': id,
    'rawId': rawId,
    'type': 'public-key',
    'response': {
      'clientDataJSON': clientDataJSON,
      'authenticatorData': authenticatorData,
      'signature': signature,
      if (userHandle != null) 'userHandle': userHandle,
    },
    'clientExtensionResults': const <String, Object?>{},
  };
}

/// Raised by the browser when the user dismisses the WebAuthn prompt.
/// The repository maps this to `WebauthnRegisterFailure.userCanceled`
/// or `WebauthnVerifyFailure.userCanceled`.
class WebauthnUserCanceledException implements Exception {
  const WebauthnUserCanceledException();
}

/// Raised when the browser refuses to invoke WebAuthn entirely (e.g.
/// `navigator.credentials` is undefined on the platform).
class WebauthnUnsupportedException implements Exception {
  const WebauthnUnsupportedException();
}

/// Abstract seam over `navigator.credentials.create()` /
/// `.get()` so tests can stub the browser ceremony without touching
/// `package:web`. The production binding lives in the (web-only)
/// `webauthn_browser_datasource_web.dart` companion.
///
/// The Dart-side fake used by widget tests implements this directly —
/// the test passes a `_FakeWebauthnBrowserDatasource` via Riverpod
/// override so the integration test path never instantiates the real
/// `package:web` binding.
///
/// **Dark-feature note:** when `kEnableWebauthn` is `false`, this
/// datasource is never instantiated — the `webauthnAvailableProvider`
/// short-circuits at the provider level. The class exists in the repo
/// so a future flag flip can light it up.
abstract class WebauthnBrowserDatasource {
  /// Invoke `navigator.credentials.create({publicKey: ...})` with the
  /// server-issued [optionsJson] (the `PublicKeyCredentialCreationOptionsJSON`
  /// shape from `@simplewebauthn/server`). Returns the registration
  /// response with all binary fields base64url-encoded.
  ///
  /// Throws [WebauthnUserCanceledException] when the user dismisses the
  /// prompt, [WebauthnUnsupportedException] when the browser refuses,
  /// and rethrows any other failure for the repository to map to
  /// `verificationFailed` / `unknown`.
  Future<WebauthnRegistrationResponse> createCredential(
    Map<String, Object?> optionsJson,
  );

  /// Invoke `navigator.credentials.get({publicKey: ...})` with the
  /// server-issued [optionsJson] (the `PublicKeyCredentialRequestOptionsJSON`
  /// shape). Returns the assertion response with all binary fields
  /// base64url-encoded.
  ///
  /// Throws [WebauthnUserCanceledException] when the user dismisses the
  /// prompt, [WebauthnUnsupportedException] when the browser refuses,
  /// and rethrows any other failure for the repository to map.
  Future<WebauthnAssertionResponse> getAssertion(
    Map<String, Object?> optionsJson,
  );
}

/// Dark-feature placeholder — every method throws
/// [WebauthnUnsupportedException]. The real `package:web` binding is
/// deferred until `kEnableWebauthn` flips to `true` to keep the build
/// dependency-light. Today, the providers' `kEnableWebauthn`
/// short-circuit ensures this class is never reached from the live UI.
///
/// Implementing the full `dart:js_interop` binding now would still pull
/// `package:web` into the build graph; a future change will add it as
/// a direct `pubspec.yaml` dep and replace this stub. The interface
/// above is the load-bearing seam for the tests + that swap.
class WebauthnBrowserDatasourceUnsupportedStub
    implements WebauthnBrowserDatasource {
  const WebauthnBrowserDatasourceUnsupportedStub();

  @override
  Future<WebauthnRegistrationResponse> createCredential(
    Map<String, Object?> optionsJson,
  ) => Future<WebauthnRegistrationResponse>.error(
    const WebauthnUnsupportedException(),
  );

  @override
  Future<WebauthnAssertionResponse> getAssertion(
    Map<String, Object?> optionsJson,
  ) => Future<WebauthnAssertionResponse>.error(
    const WebauthnUnsupportedException(),
  );
}
