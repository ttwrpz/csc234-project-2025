// WebAuthn server-side constants.
//
// **Production origin is a release blocker.** Until a production
// hosting target is provisioned (and the build-time `kEnableWebauthn`
// flag flips to `true`), `WEBAUTHN_PRODUCTION_ORIGIN` defaults to the
// empty string. The four `webauthn*` CFs read these constants and, when
// the production origin is empty AND the caller's origin is not in the
// staging allow-list, reject every call with
// `{ ok: false, code: 'webauthn_not_provisioned' }` - the server-side
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
 * Empty default - when this is empty AND the caller's origin is not in
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
 * The RPID (Relying Party id) - typically the host portion of the
 * production origin (no scheme, no port). Per FIDO2 spec the RPID must
 * be a registrable domain (eTLD+1 minimum). Empty default - same dark
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
 * Resolve the statically-configured RPID. Returns `null` when unset.
 * This is the fallback used when the caller's origin can't be matched to
 * the allow-list (e.g. a non-browser caller with no `Origin` header).
 * Prefer `resolveRpIdForOrigin` on the start legs and
 * `resolveExpectedRpIds` on the finish legs.
 */
export function resolveExpectedRpId(): string | null {
  const v = WEBAUTHN_RPID.value().trim();
  return v.length > 0 ? v : null;
}

/**
 * The RPID for an origin is its host (no scheme, no port), e.g.
 * `http://localhost:5173` -> `localhost`. Per the WebAuthn spec the RPID
 * must equal, or be a registrable suffix of, the page's host; the host is
 * the most specific (safest) choice. Returns `null` for a bad origin.
 */
function originToRpId(origin: string): string | null {
  try {
    const host = new URL(origin).hostname;
    return host.length > 0 ? host : null;
  } catch {
    return null;
  }
}

/**
 * Pick the RPID for THIS ceremony from the caller's browser `Origin`. A
 * credential is bound to one RPID and the browser refuses a ceremony whose
 * RPID isn't the page's host, so a single static RPID can't serve both
 * localhost and the hosted origin - it must track the running origin.
 * Only allow-listed origins yield a derived RPID (others fall back to the
 * static `WEBAUTHN_RPID`), and finish still pins origin + rpIdHash, so a
 * mismatched start just fails closed.
 */
export function resolveRpIdForOrigin(
  callerOrigin: string | undefined,
): string | null {
  if (callerOrigin && resolveExpectedOrigins().includes(callerOrigin)) {
    const host = originToRpId(callerOrigin);
    if (host !== null) return host;
  }
  return resolveExpectedRpId();
}

/**
 * Every RPID a verification may accept: the host of each allow-listed
 * origin plus the static `WEBAUTHN_RPID`, deduped. Passed as `expectedRPID`
 * to `verify*Response` so a credential registered on localhost OR the
 * hosted origin verifies on its own environment. Empty array means not
 * provisioned.
 */
export function resolveExpectedRpIds(): string[] {
  const ids = new Set<string>();
  for (const origin of resolveExpectedOrigins()) {
    const host = originToRpId(origin);
    if (host !== null) ids.add(host);
  }
  const explicit = resolveExpectedRpId();
  if (explicit !== null) ids.add(explicit);
  return [...ids];
}

/**
 * True when at least one RPID can be resolved - i.e. at least one valid
 * origin (production OR a non-empty staging list) is configured, OR a
 * static `WEBAUTHN_RPID` is set. The CFs short-circuit with
 * `webauthn_not_provisioned` when this is false.
 *
 * Why staging origins count: a dev or staging deploy with a configured
 * staging allow-list is a legitimate, fully-verifiable environment - the
 * ceremony's `expectedOrigin` check still pins each assertion to one of
 * those origins, so the security boundary is unchanged. Previously the
 * gate refused staging-only setups, which made WebAuthn impossible to
 * exercise before a production origin existed. The dark-flag check still
 * happens client-side via `kEnableWebauthn`.
 */
export function isProvisioned(): boolean {
  return resolveExpectedRpIds().length > 0;
}
