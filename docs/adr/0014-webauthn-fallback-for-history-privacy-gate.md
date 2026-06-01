# ADR-0014 - WebAuthn Fallback for /history Privacy Gate (Web-Only, Coexists with PIN)

**Status:** Accepted (Sprint 5 polish - v1.5)
**Date:** 2026-05-15
**Deciders:** orchestrator + architect (security-reviewer to ratify the CF surface and the new Firestore rule blocks before merge)
**Related:** ADR-0013 (parent - defines the privacy gate, the `users/{uid}/security/**` namespace, and the cold-boot biometric pattern); ADR-0003 (CF deployment contract - region `asia-southeast1`, App Check posture, structured-log discipline); ADR-0009 (account-deletion cascade - the WebAuthn docs must be drained by `wipeUserData`)

## Context

ADR-0013 Decision E §4 deferred WebAuthn to v1.6 on a five-days-to-deadline budget; PIN shipped as the universal fallback for both Web and Android-without-enrolled-biometric. The orchestrator has reclassified WebAuthn as a v1.5 deliverable on the strength of (1) the PIN path landing on schedule, leaving four days of slack against the May 19 tag; (2) the user's explicit ask to bring WebAuthn forward; and (3) the schema room ADR-0013 §"WebAuthn deferral note" deliberately preserved at `users/{uid}/security/webauthn/{credentialId}` so no migration is needed.

The three structural choices are already settled by the orchestrator (web-only; coexists with PIN; single credential per account in v1.5) and are not re-litigated here. This ADR's job is to turn those three into a buildable spec: the library choice, the four Cloud Function callables, the Firestore schema + rule additions, the Privacy-UI extensions, the recovery flow, the origin handling, and the rollback story.

The native Android Credential Manager port and multi-credential management (list, name, remove > 1 credential) are explicitly v1.6 work - see §"Open follow-ups."

## Decision

### Summary

A web-only WebAuthn factor is added to the History privacy gate alongside the v1.5 PIN factor. Registration and authentication run through four new HTTPS-callable Cloud Functions in `asia-southeast1` (`webauthnRegisterStart`, `webauthnRegisterFinish`, `webauthnAssertionStart`, `webauthnAssertionFinish`) backed by `@simplewebauthn/server@^11` (MIT). Credentials store at `users/{uid}/security/webauthn/{credentialId}`; in-flight challenges live at `users/{uid}/security/webauthnChallenges/{challengeId}` with a 5-minute TTL. The Privacy-UI gains a single "Register a security key" tile that is gated to web + WebAuthn-capable browsers + PIN-already-set. The verify flow promotes a "Use security key" button above the PIN keypad when a credential exists. PIN remains the recovery path - WebAuthn cannot be enabled without a PIN. The whole stack is short-circuited by the existing `historyPrivacyLockEnabled` Remote Config flag; no new flag is introduced.

### Decision A - Libraries

**Server:** `@simplewebauthn/server@^11.x` (MIT, verified). Added to `functions/package.json` `dependencies` (currently lists `@google/genai`, `firebase-admin`, `firebase-functions`, `zod` - `functions/package.json:19..25`). The library's `generateRegistrationOptions`, `verifyRegistrationResponse`, `generateAuthenticationOptions`, `verifyAuthenticationResponse` cover the four callables 1-to-1. ~150 KB minified; Node 20 ESM compatible per the project's `"type": "module"` declaration (`functions/package.json:6`).

**Client:** hand-rolled JS interop via `dart:js_interop` + `package:web`. `package:web` is already in `pubspec.lock:1588..1594` as a transitive dep; the implementer must promote it to a direct `dependencies` entry in `apps/mobile/pubspec.yaml:9..50` (same promotion the `crypto` package received) so the WebAuthn binding code can `import 'package:web/web.dart'` without a transitive-pin risk. The Flutter-web WebAuthn binding consists of two top-level extern functions - `navigator.credentials.create({publicKey: ...})` for registration, `navigator.credentials.get({publicKey: ...})` for assertion - plus base64url codec helpers for the binary fields (`challenge`, `userId`, `credentialId`, `rawId`, `clientDataJSON`, `attestationObject`, `authenticatorData`, `signature`). No third-party Dart WebAuthn package exists at production quality as of this ADR; hand-rolling against `package:web` is the right call.

**Rejected:** `webauthn` (pub.dev - last published 2021, abandoned); `passkit` (Apple-only, wrong platform); rolling the browser API call via `dart:html` (deprecated by `package:web`).

### Decision B - Cloud Function surface

Four new callables, all in `asia-southeast1`, all 256 MiB / 30s timeout, all `enforceAppCheck: false` to match the existing CF suite (`functions/src/analyzeMoodText.ts:321`, `functions/src/analyzePatterns.ts:552`, `functions/src/suggestQuote.ts:296`, `functions/src/wipeUserData.ts:243..249`). Re-enabling App Check is deferred to the same v1.6 ADR that lights it up across the suite - asymmetric enforcement on one of five callables widens the attack surface without a meaningful security gain (ADR-0009 amendment §"2026-05-13" makes this point explicitly).

| Callable | Purpose | Input | Output |
|---|---|---|---|
| `webauthnRegisterStart` | Generate `PublicKeyCredentialCreationOptions`; persist challenge at `users/{uid}/security/webauthnChallenges/{challengeId}` with `purpose: 'register'`, `expiresAt: now + 5min`. | `{ v: 1 }` (no client input - uid + rpId derived server-side) | `{ ok: true, options: PublicKeyCredentialCreationOptionsJSON, challengeId: string }` |
| `webauthnRegisterFinish` | Verify attestation via `verifyRegistrationResponse`; on success persist credential at `users/{uid}/security/webauthn/{credentialId}`; delete the challenge doc. | `{ challengeId: string, response: RegistrationResponseJSON, v: 1 }` | `{ ok: true, credentialId: string }` or `{ ok: false, code }` |
| `webauthnAssertionStart` | Read the user's registered credential, generate `PublicKeyCredentialRequestOptions` with `allowCredentials: [credentialId]`; persist challenge with `purpose: 'assert'`. | `{ v: 1 }` | `{ ok: true, options: PublicKeyCredentialRequestOptionsJSON, challengeId: string }` |
| `webauthnAssertionFinish` | Verify assertion via `verifyAuthenticationResponse`; increment `counter` on the credential doc; update `lastUsedAt`; clear failure-counter / `lockedUntil`. | `{ challengeId: string, response: AuthenticationResponseJSON, v: 1 }` | `{ ok: true }` or `{ ok: false, code }` |

Index export added at `functions/src/index.ts:18..23` between `suggestQuote` and `wipeUserData`. Wire format mirrors ADR-0003 §"Wire format" - result-typed `{ ok: true | false, code }` discriminated union; the only exception is `unauthenticated`, which throws `HttpsError('unauthenticated')` short-circuit.

**Rate-limit:** mirrors the PIN ladder from `apps/mobile/lib/features/auth/data/pin_repository_impl.dart:44..47` (5 failures → 60s soft lock; 10 failures/hour → 30 min hard lock). The CF reuses `functions/src/rateLimit.ts` `consumeToken()` with `opts.collection: 'rateLimits.webauthn'` (per the existing pattern at `functions/src/rateLimit.ts:32..36`). `wipeUserData.ts` RATE_LIMIT_COLLECTIONS list at `functions/src/wipeUserData.ts:68..73` must be extended to include `'rateLimits.webauthn'` in the same patch - security-reviewer must verify this addition in the merge audit.

**Counter rollover:** WebAuthn §6.1.1 mandates the authenticator's signature counter MUST be monotonic; a counter that does not exceed the stored value on an otherwise-valid assertion indicates either a cloned authenticator OR a buggy authenticator that does not maintain a counter (some platform authenticators legitimately return `0` for every assertion). **Decision: reject the assertion AND emit a `webauthn.counter_regression` structured log line** with `uid`, `credentialId` (last 8 chars only, to avoid making the log itself a credential leak), `storedCounter`, `assertedCounter`. The user is bounced to the PIN keypad. The trade-off is that legitimate zero-counter authenticators (e.g. some iCloud Keychain implementations) will fail every assertion after their first; v1.6 ADR can revisit with a per-credential `counterStrategy: 'monotonic' | 'always_zero'` flag once telemetry shows real-world distribution. For v1.5, "fail closed on a counter regression" is the FIDO2-conformant choice; accepting-and-logging would silently admit a cloned-authenticator attack, which is the exact threat the counter exists to detect.

**Cross-origin replay defence:** the `verifyRegistrationResponse` / `verifyAuthenticationResponse` calls receive `expectedOrigin` and `expectedRPID`. Both are server-derived - the client never tells the server what origin to expect.

**Challenge TTL:** 5 minutes per WebAuthn §13.1. Stored on the challenge doc as `expiresAt` (Firestore TTL policy auto-reaps after the window; the CF also explicitly deletes the doc on `webauthnRegisterFinish` / `webauthnAssertionFinish` success). On a stale challenge (`request.time > expiresAt`), `webauthn*Finish` returns `{ ok: false, code: 'challenge_expired' }` and the client restarts the flow.

### Decision C - Firestore schema

**`users/{uid}/security/webauthn/{credentialId}` - one doc per registered credential.**

Field allow-list (mirrors the PIN schema's `pinAllowedKeys()` helper in `firebase/firestore.rules:341..344`):
- `credentialId` (string, base64url, also the doc id - checked via `request.resource.data.credentialId == credentialId` in the rule)
- `publicKeyBase64` (string)
- `counter` (int, ≥ 0)
- `transports` (list of strings; values constrained to `['usb','nfc','ble','internal','hybrid']`)
- `aaguid` (string)
- `createdAt` (timestamp, == `request.time` on create)
- `lastUsedAt` (timestamp | null)
- `failedAttempts` (int, ≥ 0, default 0)
- `lockedUntil` (timestamp | null)

**`users/{uid}/security/webauthnChallenges/{challengeId}` - one doc per in-flight registration or assertion.**

Field allow-list:
- `challenge` (string, base64url)
- `purpose` (string, one of `'register' | 'assert'`)
- `expiresAt` (timestamp, ≤ `request.time + 5min` on create - enforced via `request.resource.data.expiresAt <= request.time.toMillis() + 5*60*1000` in the rule)
- `createdAt` (timestamp, == `request.time`)

**Firestore rules (under the existing `match /security/{docId}` block at `firebase/firestore.rules:340..381`, OR a sibling `match /security/webauthn/{credentialId}` block - implementer's call, but I prefer two sibling blocks for clarity since the existing PIN block hard-codes `docId == 'pin'` throughout its body).**

- Owner-only read on `users/{uid}/security/webauthn/{credentialId}` - restricted by the same rate-limit gate (`lockedUntil` check) the PIN block uses at `firestore.rules:364..367`. Read is allowed so the Privacy UI can render the "registered May 15, last used May 17" status tile directly without a CF round-trip. **No client writes ever** - `allow create, update, delete: if false`. The admin SDK from `webauthnRegisterFinish` / `webauthnAssertionFinish` writes the doc; the client is strictly read-only.
- `users/{uid}/security/webauthnChallenges/{challengeId}`: `allow read, write: if false`. Both creation and deletion are admin SDK only. The client never reads the challenge - `webauthnRegisterStart` / `webauthnAssertionStart` return the `PublicKeyCredentialCreationOptions` payload directly, which contains the challenge for the browser API to consume.

The client-side read of the credential metadata (for the Privacy UI status tile) is the only departure from "client never touches webauthn/ docs." A `webauthnList` CF wrapper was considered and rejected - it adds a round-trip for what is functionally a one-doc read with no business logic, and the doc fields (createdAt, lastUsedAt) are deliberately benign. The rule's read-allow + write-deny is the cleanest seam.

### Decision D - Privacy UI extensions

The existing Privacy section in `apps/mobile/lib/features/auth/presentation/widgets/privacy_settings_tile.dart` (the master switch tile referenced from `apps/mobile/lib/features/settings/presentation/settings_screen.dart:137`) and the "Set up / Change PIN" tiles get a new sibling tile inserted between Change PIN and the bottom of the card:

```
PRIVACY
┌─────────────────────────────────────────────────────────────────┐
│ ⌥ Require unlock to view history          [ Switch: ON  ]        │
│   …                                                              │
├─────────────────────────────────────────────────────────────────┤
│ ⌥ Change PIN                              [ Change → ]           │
│   Replace your existing PIN.                                    │
├─────────────────────────────────────────────────────────────────┤  ← new
│ ⌥ Register a security key                 [ Set up → ]           │
│   Use your device's fingerprint sensor or a USB key on the web. │
│   PIN stays as your fallback.                                   │
└─────────────────────────────────────────────────────────────────┘
```

The tile is visible only when ALL of:
1. `kIsWeb == true` (the WebAuthn tile is web-only; on Android/iOS the existing `local_auth` flow already covers biometric).
2. `historyPrivacyLockEnabled` Remote Config flag is `true` (the same gate the existing PIN tiles obey via `privacyLockMasterEnabledProvider` at `apps/mobile/lib/features/auth/data/providers.dart:254..258`).
3. `privacyLockEnabledProvider` is `true` (the user has flipped the master switch ON).
4. `webauthnAvailableProvider` is `true` - a new provider that checks `navigator.credentials != null && navigator.credentials.create != null` via `dart:js_interop`. False in Firefox < 60, Safari < 14, any browser the user has disabled WebAuthn in.
5. The user has a PIN set (Decision E - WebAuthn cannot exist without a recovery PIN).
6. No credential is yet registered (`webauthnCredentialProvider` - a `StreamProvider<WebauthnCredential?>` watching `users/{uid}/security/webauthn`).

When a credential IS registered, the tile mutates in-place to a status tile:
```
│ ⌥ Security key registered                                        │
│   Registered May 15. Last used May 17.        [ Remove ]         │
```

"Remove" writes a `webauthnUnregister` call (a fifth, optional CF - OR the simpler path: a direct client delete via admin-SDK-backed CF; recommend fifth CF). Removing reverts the user to PIN-only unlock. v1.5 ships removal; multi-credential management (registering a second key, naming keys, choosing which to use) is v1.6.

The verify flow (`apps/mobile/lib/features/auth/presentation/screens/pin_verify_screen.dart`) gains a "Use security key" button above the PIN keypad when `webauthnCredentialProvider` is non-null. Tapping it kicks off `webauthnAssertionStart` → `navigator.credentials.get()` → `webauthnAssertionFinish` → on success flip `historyUnlockedThisSessionProvider` via `ref.read(historyUnlockedThisSessionProvider.notifier).unlock()` (the same call `_onUnlocked()` makes today at `pin_verify_screen.dart:76..79`). On any failure (user cancels, counter regression, network), the button enters a transient "Try again" state and the PIN keypad remains usable as the fallback. The existing biometric auto-trigger at `pin_verify_screen.dart:42..46` is preserved untouched - on web it no-ops (capability false); on native it continues to fire first.

### Decision E - Recovery flow

**WebAuthn cannot be enabled without a PIN already in place.** This is the orchestrator's settled decision and is enforced at three layers:

1. **UI:** the "Register a security key" tile is disabled (greyed out) when `webauthnCredentialProvider` is null AND no PIN is set. Subtitle copy: `"Set up a PIN first - it's your fallback if you lose this device."`
2. **CF guard:** `webauthnRegisterStart` reads `users/{uid}/security/pin` at the top of the handler; if no PIN doc exists, return `{ ok: false, code: 'pin_required' }` and abort before issuing a challenge. This guarantees a tampered client cannot skip the UI guard.
3. **Master switch precondition:** turning the master switch ON without a PIN already routes through the existing `/privacy/setup` flow (ADR-0013 Decision G) which forces PIN setup. WebAuthn registration is a separate, subsequent step.

Lost-authenticator recovery is therefore: the user signs in, navigates to `/history`, sees the unlock screen, taps "Use PIN instead," verifies with PIN, navigates to Settings → Privacy → "Remove security key," then optionally re-registers a new authenticator. No CF or admin path is needed - the PIN was the recovery path all along.

If the user has WebAuthn AND has forgotten their PIN AND lost the authenticator, the v1.5 escape hatch is the same as ADR-0013 §"Reset flow (v1.5)" - account deletion. v1.6 adds the email-reset path.

### Decision F - Origin handling

WebAuthn binds credentials to a `rpId` (Relying Party id) at registration time; assertions are only valid for the same `rpId`. The `expectedOrigin` parameter passed to `verifyRegistrationResponse` / `verifyAuthenticationResponse` is checked verbatim against the `origin` field in the `clientDataJSON` payload. Both are server-side constants - the client never tells the server what origin to expect.

**Production origin: v1.5-release-blocker.** `firebase.json:1..55` contains no `hosting` block. The only origin strings in the codebase are `csc234-user-centric-mobile-app.firebaseapp.com` (the default Firebase Hosting domain - `apps/mobile/lib/firebase_options.dart:54`, `apps/mobile/web/firebase-messaging-sw.js:27`). Until the orchestrator confirms the v1.5 deployment target (one of `https://csc234-user-centric-mobile-app.web.app`, `https://csc234-user-centric-mobile-app.firebaseapp.com`, or a custom domain), the `WEBAUTHN_PRODUCTION_ORIGIN` constant cannot be set. **This block ships in `functions/src/webauthnConstants.ts` and security-reviewer must verify the value before merge.**

**Staging origins:** an env-var-driven allowlist `WEBAUTHN_STAGING_ORIGINS` (comma-separated). Defaults: `http://localhost:5173,http://localhost:3000,http://127.0.0.1:5173`. Read via `firebase-functions/params` `defineString` at handler init time. The CF cross-checks the asserted origin against `[productionOrigin, ...stagingOrigins]`; assertion-origin not in the set → `{ ok: false, code: 'invalid_origin' }`.

The Dart client does NOT pass `Uri.base.origin` to the CF (avoids client-can-claim-its-own-origin foot-gun); the server uses its own deployment target as ground truth. The single ambiguity here - multi-environment CF deployments - is handled by the staging-allowlist env var, which only the project owner can set.

**RPID derivation:** `rpId` is derived from the production origin's host (no scheme, no port). For `https://moodbloom.app` → `rpId = 'moodbloom.app'`. For `https://csc234-user-centric-mobile-app.web.app` → `rpId = 'csc234-user-centric-mobile-app.web.app'`. The implementer must verify the FIDO2 spec's RPID rules permit the chosen domain (eTLD+1 minimum; the default `*.web.app` domain is on the public-suffix list so RPIDs of the form `<project>.web.app` are accepted by Chrome but the spec permits browsers to reject them - another reason to confirm the production origin before merge).

### Decision G - Compliance + rollback

**Remote Config kill-switch:** the existing `historyPrivacyLockEnabled` flag (`apps/mobile/lib/app/feature_flags.dart:28..35`) gates the entire privacy stack - PIN and WebAuthn share one switch, one mental model. If a WebAuthn bug surfaces post-release, flipping `historyPrivacyLockEnabled = false` short-circuits the router redirect (`apps/mobile/lib/app/router.dart:134`), hides the entire Privacy card in Settings, and stops all four CFs from being invoked (the UI never reaches the call site). Existing WebAuthn credentials remain at rest in Firestore; re-enabling the flag restores the feature without data loss. **No new `webauthnEnabled` flag is introduced** - the orchestrator's explicit instruction.

**Account deletion cascade (interaction with ADR-0009):** `functions/src/wipeUserData.ts:48..58` `SUBCOLLECTIONS` array lists nine subcollections but does NOT include `'security'`. This is a pre-existing v1.5 gap - ADR-0009 §"Decision" describes `db.recursiveDelete()` but the implementation uses a fixed allow-list, so `users/{uid}/security/pin` already survives `wipeUserData` today as of `f8686d0b`. **This ADR mandates the implementer extend SUBCOLLECTIONS to include `'security'`** in the same patch as the WebAuthn surface. The drain walks `users/{uid}/security/{*}` (catches `pin`, `webauthn/{*}`, `webauthnChallenges/{*}` as one collection-group at the document level - the implementer should verify Firestore's `recursiveDelete()` is the right primitive here, OR walk each sub-path explicitly with the same batched-500 pattern already used at `wipeUserData.ts:130..145`). The `RATE_LIMIT_COLLECTIONS` array at `wipeUserData.ts:68..73` is similarly extended to include `'rateLimits.webauthn'`. **security-reviewer sign-off explicitly required for both extensions.**

**Architecture compliance:**
- `apps/mobile/lib/features/auth/domain/**` stays pure-Dart (zero Flutter / Firebase / `package:web` imports). New domain entities for WebAuthn: `WebauthnCredential` (Freezed; `credentialId`, `createdAt`, `lastUsedAt`, `failedAttempts`, `lockedUntil`), `WebauthnRegisterFailure` (sealed sub-type of `Failure`), `WebauthnVerifyFailure` (sealed sub-type of `Failure`). Use cases: `RegisterWebauthnUseCase`, `VerifyWebauthnUseCase`, `UnregisterWebauthnUseCase`. Abstract repo: `WebauthnRepository` mirroring the shape of `apps/mobile/lib/features/auth/domain/repositories/pin_repository.dart:20..65`.
- `apps/mobile/lib/features/auth/data/**` may import `package:web`, `dart:js_interop`, `cloud_functions`. The new JS-interop binding lives at `apps/mobile/lib/features/auth/data/datasources/webauthn_browser_datasource.dart` and is the ONLY place `package:web` is referenced from the auth feature.
- `apps/mobile/lib/features/auth/presentation/**` may import everything; new widget `WebauthnSettingsTile` lives next to `PrivacySettingsTile` at `apps/mobile/lib/features/auth/presentation/widgets/`.

**Security-reviewer sign-off required before merge for:**
1. `firebase/firestore.rules` additions (two new `match` blocks).
2. The four new CFs in `functions/src/webauthn*.ts`.
3. The `wipeUserData.ts` SUBCOLLECTIONS + RATE_LIMIT_COLLECTIONS extensions.
4. The chosen production origin constant value (Decision F) - this is the v1.5-release-blocker.

## Consequences

### Good

- Closes the CLAUDE.md "biometric fallback required" commitment on web with a real platform authenticator path - not a PIN-shaped hand-wave.
- The four-CF surface is a direct 1-to-1 with the FIDO2 reference flow; the server library is the canonical FIDO2-conformant implementation; the code is shallow.
- Schema room from ADR-0013 §"WebAuthn deferral note" pays off - no migration, no data shuffle.
- One Remote Config flag still drives the whole stack; rollback story is unchanged.
- The PIN factor stays exactly as it is - ADR-0013's design ages well.
- Account-deletion cascade extension also fixes a pre-existing ADR-0009 bug (the security subcollection was being orphaned today).

### Bad / Trade-offs

- A web user with a WebAuthn credential and no longer-functional authenticator who has also forgotten their PIN has only the account-deletion path. Same trade-off as ADR-0013 §"Reset flow"; the user opted into the protection knowingly.
- The "production origin" decision is a literal release blocker. If the orchestrator cannot pin the deployment domain by May 18, WebAuthn does not ship - but the rest of v1.5 is unaffected (PIN keeps working; the Privacy UI WebAuthn tile is hidden by the `historyPrivacyLockEnabled` short-circuit if the implementer ships behind a build-time flag, OR by `webauthnAvailableProvider` returning false when the constant is unset).
- The counter-regression-rejects-the-assertion policy will false-positive on legitimately-stateless platform authenticators (notably some iCloud Keychain implementations that always return `counter: 0`). Users with those authenticators will fail every assertion after their first and be forced back to PIN. Telemetry from v1.5 (the `webauthn.counter_regression` log volume vs. registered-credential count) informs the v1.6 ADR's per-credential strategy flag.
- Adding `'security'` to the `wipeUserData` SUBCOLLECTIONS list expands the blast radius of any future bug in that CF. The risk is bounded because the function is already destructive by design and the security subcollection is explicitly meant to be wiped on account deletion (the user expects their PIN AND their security key to die with the account).
- Hand-rolled `dart:js_interop` bindings are a maintenance surface. v1.6 should re-evaluate whether a Dart WebAuthn package has matured to the point of being a drop-in (none has at this ADR's date).

### Alternatives Considered

Items the orchestrator settled and that this ADR does NOT re-litigate (one line each):

- Multi-credential management in v1.5 - explicitly deferred to v1.6.
- Native Android Credential Manager port - explicitly deferred to a future ADR.
- Replacing PIN with WebAuthn (no coexistence) - explicitly rejected; PIN is the recovery factor.
- A separate `webauthnEnabled` Remote Config flag - explicitly rejected; one switch, one mental model.

Items this ADR weighed and rejected:

- `webauthn` pub.dev package - abandoned (last update 2021); rejected vs. hand-rolled `dart:js_interop`.
- A single combined `webauthnRegister` callable (no start/finish split) - rejected because WebAuthn's challenge-issued-then-verified-against-response shape is inherently two-phase; collapsing the round trips breaks the spec.
- Client-issued challenges - rejected; WebAuthn §13.1 mandates server-side randomness.
- Client-side counter verification - rejected; the credential doc is server-managed (admin SDK write); the client only reads it.
- `webauthnList` CF wrapper for the Privacy-UI status tile - rejected as a needless round-trip vs. a strict read-only rule.
- Enabling App Check on the four new CFs alone - rejected per ADR-0009 amendment; asymmetric enforcement is worse than uniform deferral.

## Compliance Check

- **Clean Architecture domain-zero-imports rule:** satisfied. `apps/mobile/lib/features/auth/domain/**` adds Freezed entities and pure-Dart use cases; the JS-interop binding lives in `data/datasources/`. Verified against the existing pattern at `apps/mobile/lib/features/auth/domain/repositories/pin_repository.dart:1..3` (imports only `package:core`).
- **Enterprise Term Assignment requirements touched:** **R3** (architecture quality - feature-first folder structure preserved; one repo per factor; reuse of the existing rate-limit infra rather than duplication); **R5** (security - FIDO2-conformant counter check, server-side challenge, server-side origin verification, owner-only rule isolation, admin-SDK-only writes to the credential doc, Remote Config kill-switch, PII-clean structured logs per ADR-0003 §"Logging schema").
- **CLAUDE.md feature-flag rollback:** satisfied via existing `historyPrivacyLockEnabled`. No new flag.
- **CLAUDE.md do-not-do list:**
  - `firebase/firestore.rules` - touched (adds two new `match` blocks under `users/{uid}/security`). **security-reviewer sign-off required.**
  - `functions/src/*` - touched (four new files + extension of `wipeUserData.ts` SUBCOLLECTIONS / RATE_LIMIT_COLLECTIONS + new export line in `index.ts`). **security-reviewer sign-off required.**
  - `apps/mobile/lib/main.dart` - NOT touched.
  - `apps/mobile/lib/app/router.dart` - NOT touched (the existing `/unlock-history` route handles the assertion flow; WebAuthn is presented as an alternative inside `PinVerifyScreen`).
  - `apps/mobile/pubspec.yaml` - touched (promote `web` from transitive to direct). **architect sign-off: this ADR is the sign-off.**
- **CLAUDE.md "Never log PII":** satisfied. CF structured logs include `uid`, `event`, `outcome`, `credentialId[-8:]` (last 8 chars only, treating the full credential id as PII-adjacent), `latencyMs`. Never log `publicKey`, `clientDataJSON`, `authenticatorData`, `signature`, `attestationObject`.
- **ADR-0003 CF contract reuse:** region `asia-southeast1`, `enforceAppCheck: false`, memory `256MiB`, timeout `30s`, result-typed responses, `HttpsError('unauthenticated')` short-circuit only - all preserved verbatim.

## Implementation plan

4 days remaining (May 15 today; tag May 19).

**Day 1 (May 15 - today):** ADR-0014 (this doc) + production-origin decision unblocked by orchestrator. Domain layer (`WebauthnCredential`, `WebauthnRegisterFailure`, `WebauthnVerifyFailure`, `WebauthnRepository` abstract, three use cases). Pure-Dart, fully unit-testable. No Flutter, no Firebase. ~200 LOC + tests.

**Day 2 (May 16):** Server-side. Four CFs in `functions/src/webauthn*.ts`. `webauthnConstants.ts` with `WEBAUTHN_PRODUCTION_ORIGIN` and `WEBAUTHN_STAGING_ORIGINS` env-var wiring. Extend `functions/src/index.ts:18..23` exports. Extend `wipeUserData.ts` SUBCOLLECTIONS + RATE_LIMIT_COLLECTIONS. Firestore rules: two new `match` blocks. Pass 1 of security-reviewer sign-off on the server side. ~600 LOC + Jest tests for the four handlers.

**Day 3 (May 17):** Client side. `WebauthnBrowserDatasource` (the `dart:js_interop` + `package:web` binding). `WebauthnRepositoryImpl`. The `webauthnAvailableProvider` + `webauthnCredentialProvider`. `WebauthnSettingsTile` widget. `PinVerifyScreen` extension (the "Use security key" button + flow). ~500 LOC + widget tests. Stub-test the JS interop (a `_FakeWebauthnBrowserDatasource` Riverpod override drives the widget tests without invoking the browser).

**Day 4 (May 18):** Integration tests (Chrome only - desktop integration test invoking the local emulator + a virtual authenticator via Chrome DevTools Protocol). A11y sweep (focus order on the new tile; the "Use security key" button announces correctly). Pass 2 of security-reviewer sign-off (full surface). Manual smoke test on the deployed staging origin (the orchestrator's confirmed value).

**Buffer (May 19):** release tag.

**Cuts to make first if a day slips:**

1. The "Remove security key" affordance and its CF (fifth callable). v1.5 ships register-only; users who want to remove must wait for v1.6. The CF exists in spec but the UI tile shows the status only, no Remove button. ~half a day saved.
2. The native-Chrome integration test. Fall back to manual smoke + the widget-level tests with the JS-interop stub. ~half a day saved.
3. If both above are cut and the slip is still bad, the entire WebAuthn surface is hidden behind a build-time `kEnableWebauthn = false` and ships dark; v1.5.1 enables it ~2 weeks later once the production origin and a green CI run land. PIN remains the only factor. The rest of v1.5 ships unaffected.

## Open follow-ups (for the engineer)

1. **PRODUCTION ORIGIN.** Resolve before any code lands. Check the Firebase console for the deployed hosting target. If no production hosting target exists, this entire ADR's CF surface ships hidden (build-time flag false) until one is provisioned. See Decision F.
2. Confirm `recursiveDelete()` semantics on `users/{uid}/security/{anycollection}` - Firestore admin SDK's `recursiveDelete()` walks subcollections from a collection-group query; verify it actually drains `webauthn/*` and `webauthnChallenges/*` from a starting point of `users/{uid}/security`. If not, walk each child explicitly using the batched-500 pattern already at `wipeUserData.ts:130..145`.
3. Promote `web` package from transitive to direct in `apps/mobile/pubspec.yaml` (current state at `pubspec.lock:1588..1594` is transitive only).
4. Confirm `@simplewebauthn/server@^11.x` works under Node 22 (the deployed runtime per `firebase.json:11`). The library targets Node 20+; v11 ships ESM cleanly under Node 22. Build a quick smoke build before committing to the dep.
5. Verify FIDO2 RPID rules on the final production origin domain. If the domain is `<project>.web.app`, some browsers may reject the RPID per the public-suffix-list ambiguity - Chrome accepts, Firefox may not. Cross-browser smoke required.
6. The CF's `verifyRegistrationResponse` call accepts an `attestationType` parameter. v1.5 uses `'none'` (no attestation verification) - the user-tracking implications of attestation are out of scope and the spec permits `'none'` for non-enterprise deployments. v1.6 may revisit if the project moves to attestation-verified enrolments.
7. The `webauthn.counter_regression` log volume needs a dashboard alert in v1.5.1 - if the rate is non-trivial, a per-credential strategy flag enters v1.6's ADR.
8. Decide whether the "Use security key" button auto-fires (parallel to the existing biometric auto-fire at `pin_verify_screen.dart:42..46`) or requires an explicit tap. Auto-fire is more aggressive UX; explicit tap is friendlier to users who want PIN by muscle memory. Recommendation: explicit tap in v1.5; revisit after telemetry.
