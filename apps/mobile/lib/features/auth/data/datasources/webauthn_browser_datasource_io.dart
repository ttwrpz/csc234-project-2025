// Non-web build of the WebAuthn browser datasource (ADR-0014 Decision A).
//
// Picked by the conditional-import seam in `providers.dart` when
// `dart.library.js_interop` is NOT available (Android / iOS / desktop).
// The native build has no `navigator.credentials` to bind, so the only
// thing to provide is the unsupported-stub that throws
// [WebauthnUnsupportedException] on every call — the repository maps the
// throw to a `Failure` and the UI falls back to PIN.
//
// The web counterpart lives in `webauthn_browser_datasource_web.dart`
// and binds `package:web` + `dart:js_interop`. Keeping the two surfaces
// behind a conditional import keeps `package:web` out of the native
// build graph entirely.

import 'webauthn_browser_datasource.dart';

/// Native-build factory. Returns the unsupported stub.
WebauthnBrowserDatasource createWebauthnBrowserDatasource() =>
    const WebauthnBrowserDatasourceUnsupportedStub();
