// WebAuthn server-side constants.
//
// **Production origin is a release blocker.** Until a production
// hosting target is provisioned (and the build-time `kEnableWebauthn`
// flag flips to `true`), `WEBAUTHN_PRODUCTION_ORIGIN` defaults to the
// empty string. The four `webauthn*` CFs read these constants and, when
// the production origin is empty AND the caller's origin is not in the
// staging allow-list, reject every call with
// `{ ok: false, code: 'webauthn_not_provisioned' }` — the server-side
// safety net for the client kill-switch.
//
// All three params are env-var driven:
//   firebase functions:config:set webauthn.production_origin="https://moodbloom.app"
//   firebase functions:config:set webauthn.rpid="moodbloom.app"
//   firebase functions:config:set webauthn.staging_origins="http://localhost:5173,..."
//
// The `defineString` mechanism (Firebase Functions params v2) reads
// these at deploy time and binds them into the function's runtime
// environment. The same params can be overridden per-environment via
// `firebase deploy --only functions --project=...`.

import { defineString } from 'firebase-functions/params';

/**
 * The HTTPS origin of the production deployment, exact-match against
 * `clientDataJSON.origin` from the browser ceremony.
 *
 * Empty default — when this is empty AND the caller's origin is not in
 * the staging allow-list, registration / assertion CFs reject with
 * `webauthn_not_provisioned`.
 */
export const WEBAUTHN_PRODUCTION_ORIGIN = defineString(
  'WEBAUTHN_PRODUCTION_ORIGIN',
  { default: '' },
);

/**
 * Comma-separated list of staging origins. Defaults to the localhost
 * dev ports we use across the Flutter web + Vite tooling.
 */
export const WEBAUTHN_STAGING_ORIGINS = defineString(
  'WEBAUTHN_STAGING_ORIGINS',
  {
    default:
      'http://localhost:5173,http://localhost:3000,http://127.0.0.1:5173',
  },
);

/**
 * The RPID (Relying Party id) — typically the host portion of the
 * production origin (no scheme, no port). Per FIDO2 spec the RPID must
 * be a registrable domain (eTLD+1 minimum). Empty default — same dark
 * posture as the production origin.
 */
export const WEBAUTHN_RPID = defineString('WEBAUTHN_RPID', { default: '' });

/**
 * Resolve the list of accepted origins for `expectedOrigin` on the
 * `verify*Response` calls. Production (when non-empty) is appended
 * after the staging list so the order favours dev environments during
 * dual-deploy scenarios.
 */
export function resolveExpectedOrigins(): string[] {
  const staging = WEBAUTHN_STAGING_ORIGINS.value()
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  const production = WEBAUTHN_PRODUCTION_ORIGIN.value().trim();
  return production.length > 0 ? [...staging, production] : staging;
}

/**
 * Resolve the RPID. Returns `null` when unset — callers should treat
 * `null` as "not provisioned" and short-circuit before issuing a
 * challenge.
 */
export function resolveExpectedRpId(): string | null {
  const v = WEBAUTHN_RPID.value().trim();
  return v.length > 0 ? v : null;
}

/**
 * True when the production origin is set AND a non-empty RPID exists.
 * Default: false. The CFs short-circuit with
 * `webauthn_not_provisioned` when this is false, regardless of how
 * the caller's origin compares against the staging allow-list.
 *
 * Why the `||`-with-staging check is NOT here: staging origins are
 * legitimately reachable during local development, but registering a
 * credential against `http://localhost:5173` and then trying to assert
 * against the same origin from a different developer's machine would
 * fail anyway (per-origin rules). The dark-flag check happens at the
 * client level via `kEnableWebauthn`; the staging allow-list serves
 * dev iteration, not "production-or-staging-OK".
 */
export function isProvisioned(): boolean {
  return (
    WEBAUTHN_PRODUCTION_ORIGIN.value().trim().length > 0 &&
    resolveExpectedRpId() !== null
  );
}
