// Web-only implementation of the WebAuthn browser datasource (ADR-0014
// Decision A). Picked by the conditional-import seam in `providers.dart`
// when `dart.library.js_interop` is available.
//
// What this binding does:
//
//   1. Takes the `PublicKeyCredentialCreationOptionsJSON` /
//      `PublicKeyCredentialRequestOptionsJSON` map issued by
//      `@simplewebauthn/server` (base64url-encoded binary fields).
//   2. Reshapes the binary fields into JS `ArrayBuffer`s for the
//      `CredentialsContainer.create()` / `.get()` calls.
//   3. Invokes `navigator.credentials.create({publicKey: ...})` /
//      `.get({publicKey: ...})` dynamically via `callMethod` (the
//      typed `package:web` surface requires the deeply-typed
//      `PublicKeyCredentialCreationOptions` extension type, which is
//      tedious to mirror field-by-field for what is essentially a
//      pass-through of the server payload).
//   4. Reads the returned `PublicKeyCredential` and serialises every
//      binary field back to base64url so the repository can ship the
//      response straight to the finish CF.
//
// What this binding deliberately does NOT do:
//   - Verify the assertion. That is the server's job.
//   - Mutate Firestore. That is the CF's job.
//   - Hold any state across calls. Each call is a single
//     async-then-finish round trip.
//
// Error mapping:
//   - `DOMException` with name `NotAllowedError` (the WebAuthn spec's
//     "user dismissed the prompt" signal) → [WebauthnUserCanceledException].
//   - `NotSupportedError` / `SecurityError` / `InvalidStateError` →
//     [WebauthnUnsupportedException].
//   - Anything else is rethrown for the repository to map to
//     `verificationFailed` / `unknown`.

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'webauthn_browser_datasource.dart';

/// Web-build factory. Returns the live JS-interop binding.
WebauthnBrowserDatasource createWebauthnBrowserDatasource() =>
    const _WebauthnBrowserDatasourceWeb();

class _WebauthnBrowserDatasourceWeb implements WebauthnBrowserDatasource {
  const _WebauthnBrowserDatasourceWeb();

  @override
  Future<WebauthnRegistrationResponse> createCredential(
    Map<String, Object?> optionsJson,
  ) async {
    final credentials = _credentialsOrThrow();

    final publicKey = _buildCreationOptions(optionsJson);
    final init = _wrapPublicKey(publicKey);

    final result = await _invoke(
      () => (credentials as JSObject)
          .callMethod<JSPromise<JSAny?>>('create'.toJS, init)
          .toDart,
    );
    if (result == null) {
      throw const WebauthnUserCanceledException();
    }

    // Cast through JSObject — the returned Credential is structurally a
    // PublicKeyCredential when the publicKey option drove the call. We
    // read the fields off via dynamic JS property access rather than
    // typing through the deep `PublicKeyCredential` extension type to
    // keep this binding ergonomic.
    final pkc = result as JSObject;
    final response = pkc.getProperty<JSObject>('response'.toJS);
    final transports = _readTransports(response);

    return WebauthnRegistrationResponse(
      id: (pkc.getProperty<JSString>('id'.toJS)).toDart,
      rawId: _bufferToBase64Url(pkc.getProperty<JSArrayBuffer>('rawId'.toJS)),
      clientDataJSON: _bufferToBase64Url(
        response.getProperty<JSArrayBuffer>('clientDataJSON'.toJS),
      ),
      attestationObject: _bufferToBase64Url(
        response.getProperty<JSArrayBuffer>('attestationObject'.toJS),
      ),
      transports: transports,
    );
  }

  @override
  Future<WebauthnAssertionResponse> getAssertion(
    Map<String, Object?> optionsJson,
  ) async {
    final credentials = _credentialsOrThrow();

    final publicKey = _buildRequestOptions(optionsJson);
    final init = _wrapPublicKey(publicKey);

    final result = await _invoke(
      () => (credentials as JSObject)
          .callMethod<JSPromise<JSAny?>>('get'.toJS, init)
          .toDart,
    );
    if (result == null) {
      throw const WebauthnUserCanceledException();
    }

    final pkc = result as JSObject;
    final response = pkc.getProperty<JSObject>('response'.toJS);
    final userHandle = response.getProperty<JSAny?>('userHandle'.toJS);

    return WebauthnAssertionResponse(
      id: (pkc.getProperty<JSString>('id'.toJS)).toDart,
      rawId: _bufferToBase64Url(pkc.getProperty<JSArrayBuffer>('rawId'.toJS)),
      clientDataJSON: _bufferToBase64Url(
        response.getProperty<JSArrayBuffer>('clientDataJSON'.toJS),
      ),
      authenticatorData: _bufferToBase64Url(
        response.getProperty<JSArrayBuffer>('authenticatorData'.toJS),
      ),
      signature: _bufferToBase64Url(
        response.getProperty<JSArrayBuffer>('signature'.toJS),
      ),
      userHandle: (userHandle == null || !userHandle.isA<JSArrayBuffer>())
          ? null
          : _bufferToBase64Url(userHandle as JSArrayBuffer),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  web.CredentialsContainer _credentialsOrThrow() {
    // `navigator.credentials` is statically typed on the `Navigator`
    // extension type, but a feature-disabled or non-secure context can
    // legitimately return a degraded surface. The defensive read keeps
    // us in the documented `Unsupported` error mode rather than crashing
    // with a runtime cast failure.
    try {
      return web.window.navigator.credentials;
    } catch (_) {
      throw const WebauthnUnsupportedException();
    }
  }

  /// Wrap a JS object describing the WebAuthn `publicKey` options into
  /// the `{publicKey: …}` shape expected by `CredentialsContainer`.
  JSObject _wrapPublicKey(JSObject publicKey) {
    final init = JSObject();
    init.setProperty('publicKey'.toJS, publicKey);
    return init;
  }

  /// Convert `PublicKeyCredentialCreationOptionsJSON` (Dart map with
  /// base64url binary fields) into the JS object the browser expects
  /// (binary fields as ArrayBuffer).
  JSObject _buildCreationOptions(Map<String, Object?> options) {
    final out = options.jsify() as JSObject;
    _replaceBase64UrlField(out, 'challenge');
    final user = out.getProperty<JSAny?>('user'.toJS);
    if (user != null && user.isA<JSObject>()) {
      _replaceBase64UrlField(user as JSObject, 'id');
    }
    final exclude = out.getProperty<JSAny?>('excludeCredentials'.toJS);
    if (exclude != null && exclude.isA<JSArray>()) {
      _replaceBase64UrlFieldInArray(exclude as JSArray<JSAny?>, 'id');
    }
    return out;
  }

  /// Same shape as the creation options but for the assertion side —
  /// only `challenge` and `allowCredentials[].id` are binary.
  JSObject _buildRequestOptions(Map<String, Object?> options) {
    final out = options.jsify() as JSObject;
    _replaceBase64UrlField(out, 'challenge');
    final allow = out.getProperty<JSAny?>('allowCredentials'.toJS);
    if (allow != null && allow.isA<JSArray>()) {
      _replaceBase64UrlFieldInArray(allow as JSArray<JSAny?>, 'id');
    }
    return out;
  }

  void _replaceBase64UrlField(JSObject obj, String key) {
    final raw = obj.getProperty<JSAny?>(key.toJS);
    if (raw == null || !raw.isA<JSString>()) return;
    final str = (raw as JSString).toDart;
    final bytes = _decodeBase64Url(str);
    obj.setProperty(key.toJS, bytes.buffer.toJS);
  }

  void _replaceBase64UrlFieldInArray(JSArray<JSAny?> arr, String key) {
    final dart = arr.toDart;
    for (final entry in dart) {
      if (entry != null && entry.isA<JSObject>()) {
        _replaceBase64UrlField(entry as JSObject, key);
      }
    }
  }

  /// Pull the `transports` array off the attestation response. Some
  /// authenticators return an empty array; some omit the function
  /// entirely. The repository tolerates either.
  List<String> _readTransports(JSObject response) {
    final getter = response.getProperty<JSAny?>('getTransports'.toJS);
    if (getter == null || !getter.isA<JSFunction>()) return const <String>[];
    final arr = response.callMethod<JSArray<JSString>>('getTransports'.toJS);
    return arr.toDart.map((s) => s.toDart).toList(growable: false);
  }

  /// Decode a base64url string (with or without padding) to bytes.
  Uint8List _decodeBase64Url(String value) {
    var s = value.replaceAll('-', '+').replaceAll('_', '/');
    final pad = s.length % 4;
    if (pad == 2) {
      s += '==';
    } else if (pad == 3) {
      s += '=';
    }
    return base64.decode(s);
  }

  /// Encode a JS ArrayBuffer to a base64url string with no padding.
  String _bufferToBase64Url(JSArrayBuffer buffer) {
    final bytes = buffer.toDart.asUint8List();
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Invoke a `JSPromise`-backed call and translate the standard
  /// `DOMException` family into our domain exceptions.
  Future<T> _invoke<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      if (e is WebauthnUserCanceledException ||
          e is WebauthnUnsupportedException) {
        rethrow;
      }
      // `dart:js_interop` promise rejections deliver the JS error as a
      // `JSObject` (DOMException is a JS object). Extract the `.name`
      // property to map to our domain exceptions; fall through to a
      // rethrow on anything we don't recognise.
      final name = _extractDomExceptionName(e);
      if (name == 'NotAllowedError' || name == 'AbortError') {
        throw const WebauthnUserCanceledException();
      }
      if (name == 'NotSupportedError' ||
          name == 'SecurityError' ||
          name == 'InvalidStateError') {
        throw const WebauthnUnsupportedException();
      }
      // Anything else — rethrow for the repository's catch-all to map
      // to `verificationFailed` / `unknown`.
      rethrow;
    }
  }

  /// Pull the `name` property off a JS error object if the thrown
  /// value is a `JSObject`-shaped DOMException. Returns null otherwise.
  ///
  /// `Object is JSObject` runtime checks are not platform-stable per
  /// the analyzer's `invalid_runtime_check_with_js_interop_types` lint;
  /// we cast unconditionally and rescue with a try/catch instead.
  String? _extractDomExceptionName(Object thrown) {
    try {
      final js = thrown as JSObject;
      final nameAny = js.getProperty<JSAny?>('name'.toJS);
      if (nameAny == null || !nameAny.isA<JSString>()) return null;
      return (nameAny as JSString).toDart;
    } catch (_) {
      return null;
    }
  }
}
