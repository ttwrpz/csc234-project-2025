// HTTPS-callable Cloud Function for the Tiered Intervention push.
//
// Per-tier complement to `sendCheerUpPush`. Fires AFTER the client has
// successfully written the audit doc at
// `users/{uid}/interventions/{dispatchId}` (the dispatcher's Ok path).
// The client invokes this CF with `{ tier, dispatchId }`; the CF reads
// the audit doc back, enforces the per-tier opt-out + the 24h push
// rate-limit, then sends a LOCKED per-tier notification payload.
//
// **Tier 3 fence (server-side).** The notification body is a module-scope
// constant per tier — there is NO request field for body text, and the
// CF NEVER reads `dispatch.body` from Firestore for the notification
// payload. That means even if the audit doc's body has been tampered
// with (it can't be, per rules), it cannot leak into the push. The
// tier is read from the request, validated against the audit doc
// (defense in depth), then drives the payload constant. Mirrors the
// client-side `AiAllowedTier { one, two }` invariant: the structure
// of this function makes it impossible to send a per-dispatch body for
// any tier.
//
// Validation order:
//   1. Auth check (HttpsError unauthenticated if no uid).
//   2. Schema check: tier ∈ {one,two,three}, dispatchId non-empty string.
//   3. Read intervention audit doc; must exist, tier must match, must
//      not be opted-out.
//   4. Read `users/{uid}/settings/notifications`; per-tier toggle must be
//      true.
//   5. Filter tokens; bail with `no_tokens` if empty.
//   6. Atomic 24h rate-limit consume (1 push per uid per day, separate
//      collection from cheer-up). Defense in depth above the client-side
//      48h cooldown the dispatcher already enforces.
//   7. Send multicast with the LOCKED per-tier title/body + channel
//      `cheer_up`.
//   8. Prune `registration-token-not-registered` tokens.
//   9. Allowlisted structured log line — never the body, never tokens.
//
// CF posture: region `asia-southeast1`, 256MiB, 30s, no App Check
// (matches the existing CF suite).

import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

import { consumeToken } from './rateLimit.js';

// -----------------------------------------------------------------------------
// LOCKED per-tier payloads. Module-scope constants so no caller field
// can route per-dispatch text into the notification — the Tier 3 fence
// is enforced by the SHAPE of this function. Copy obeys CLAUDE.md rules:
// no clinical labels, no "you should", no hotline number in the body
// (Hotline 1323 is the in-app crisis-screen surface, never a push body).
// -----------------------------------------------------------------------------

const CHANNEL_ID = 'cheer_up';

interface TierPayload {
  readonly title: string;
  readonly body: string;
}

const PAYLOADS: Readonly<Record<'one' | 'two' | 'three', TierPayload>> = {
  one: {
    title: 'Take a breath?',
    body: "MoodBloom noticed your week. A 2-minute breathing exercise is here if you'd like.",
  },
  two: {
    title: 'A few quiet words?',
    body: "MoodBloom noticed your week. A short journaling prompt is here if you'd like.",
  },
  three: {
    title: "We're here",
    body: "MoodBloom noticed your week. Some resources are here if you'd like to look.",
  },
};

// 24h rate limit — at most 1 intervention push per uid per day. Defense
// in depth on top of the client-side 48h cooldown the dispatcher already
// enforces. Separate collection so it does not interact with
// `rateLimits.cheerUp`, `rateLimits/{uid}` (analyzeMoodText), or
// `rateLimits.patterns/{uid}` (analyzePatterns).
const RATE_LIMIT_WINDOW_MS = 86_400_000; // 24h
const RATE_LIMIT_MAX = 1;
const RATE_LIMIT_COLLECTION = 'rateLimits.intervention';

type TierWire = 'one' | 'two' | 'three';

function isTierWire(v: unknown): v is TierWire {
  return v === 'one' || v === 'two' || v === 'three';
}

interface TokenRecord {
  token: string;
  platform?: string;
  lastSeenAt?: unknown;
}

interface NotificationsSettings {
  cheerUpEnabled?: boolean;
  tier1Enabled?: boolean;
  tier2Enabled?: boolean;
  tier3Enabled?: boolean;
  tokens?: TokenRecord[];
}

interface InterventionAuditDoc {
  tier?: string;
  optedOut?: boolean;
  // `body` exists on the audit doc but is INTENTIONALLY UNREAD here —
  // the notification body is a module-scope constant. See the file header.
}

function hasMalformedEntries(tokens: TokenRecord[] | undefined): boolean {
  if (!tokens) return false;
  for (const t of tokens) {
    if (typeof t.token !== 'string' || t.token.length === 0) return true;
    if (t.platform !== 'android' && t.platform !== 'web') return true;
  }
  return false;
}

function isPerTierEnabled(
  s: NotificationsSettings | undefined,
  tier: TierWire,
): boolean {
  if (!s) return false;
  // Mirror `sendCheerUpPush`'s `!== true` posture: missing or
  // not-strictly-true is opted-out. The dart side seeds `true` on
  // first write, and the Firestore rule requires all three flags on
  // create, so a doc that exists will always have the field — but the
  // fail-closed posture protects against schema drift.
  switch (tier) {
    case 'one':
      return s.tier1Enabled === true;
    case 'two':
      return s.tier2Enabled === true;
    case 'three':
      return s.tier3Enabled === true;
  }
}

type Outcome =
  | 'sent'
  | 'opted_out'
  | 'no_tokens'
  | 'rate_limited'
  | 'dispatch_missing'
  | 'dispatch_mismatch'
  | 'dispatch_opted_out'
  | 'internal';

interface LogPayload {
  event: 'dispatchIntervention';
  requestId: string;
  uid: string;
  tier: TierWire;
  outcome: Outcome;
  tokenCount?: number;
  deliveredCount?: number;
  failedCount?: number;
  prunedCount?: number;
  latencyTotalMs?: number;
  rateLimit?: { remaining: number; retryAfterSec: number };
  errorReason?: string;
}

interface DispatchInterventionRequest {
  /** Schema version, currently `1`. */
  v?: number;
  /** Required: 'one' | 'two' | 'three'. */
  tier?: unknown;
  /** Required: id of the audit doc the client just wrote. */
  dispatchId?: unknown;
  /** Optional log-correlation id; defaults to the dispatchId. */
  requestId?: unknown;
}

export const dispatchIntervention = onCall<
  DispatchInterventionRequest,
  Promise<{ ok: true; outcome: Outcome }>
>(
  { region: 'asia-southeast1', memory: '256MiB', timeoutSeconds: 30 },
  async (
    request: CallableRequest<DispatchInterventionRequest>,
  ): Promise<{ ok: true; outcome: Outcome }> => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError(
        'unauthenticated',
        'Sign in before calling dispatchIntervention.',
      );
    }
    const uid = auth.uid;
    const startMs = Date.now();
    const db = getFirestore();

    // 1. Schema check.
    const data = request.data ?? {};
    if (!isTierWire(data.tier)) {
      throw new HttpsError(
        'invalid-argument',
        "tier must be one of 'one' | 'two' | 'three'.",
      );
    }
    const tier: TierWire = data.tier;
    if (typeof data.dispatchId !== 'string' || data.dispatchId.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'dispatchId must be a non-empty string.',
      );
    }
    const dispatchId = data.dispatchId;
    const requestId =
      typeof data.requestId === 'string' && data.requestId.length > 0
        ? data.requestId
        : dispatchId;

    // 2. Read the audit doc. Defense in depth: the request tier must
    // match the audit doc tier, and the dispatch must not already be
    // opted-out (the user tapping "I'm okay" between dispatcher Ok and
    // this CF call wins).
    const auditRef = db.doc(`users/${uid}/interventions/${dispatchId}`);
    const auditSnap = await auditRef.get();
    if (!auditSnap.exists) {
      const payload: LogPayload = {
        event: 'dispatchIntervention',
        requestId,
        uid,
        tier,
        outcome: 'dispatch_missing',
        latencyTotalMs: Date.now() - startMs,
      };
      logger.info(payload);
      return { ok: true, outcome: 'dispatch_missing' };
    }
    const audit = auditSnap.data() as InterventionAuditDoc | undefined;
    if (audit?.tier !== tier) {
      const payload: LogPayload = {
        event: 'dispatchIntervention',
        requestId,
        uid,
        tier,
        outcome: 'dispatch_mismatch',
        latencyTotalMs: Date.now() - startMs,
      };
      logger.info(payload);
      return { ok: true, outcome: 'dispatch_mismatch' };
    }
    if (audit?.optedOut === true) {
      const payload: LogPayload = {
        event: 'dispatchIntervention',
        requestId,
        uid,
        tier,
        outcome: 'dispatch_opted_out',
        latencyTotalMs: Date.now() - startMs,
      };
      logger.info(payload);
      return { ok: true, outcome: 'dispatch_opted_out' };
    }

    // 3. Per-tier opt-out from `users/{uid}/settings/notifications`.
    const settingsRef = db.doc(`users/${uid}/settings/notifications`);
    const settingsSnap = await settingsRef.get();
    const settings = (settingsSnap.exists ? settingsSnap.data() : undefined) as
      | NotificationsSettings
      | undefined;
    if (!isPerTierEnabled(settings, tier)) {
      const payload: LogPayload = {
        event: 'dispatchIntervention',
        requestId,
        uid,
        tier,
        outcome: 'opted_out',
        latencyTotalMs: Date.now() - startMs,
      };
      logger.info(payload);
      return { ok: true, outcome: 'opted_out' };
    }

    // 4. Token filter.
    const rawTokens = settings?.tokens ?? [];
    const tokens = rawTokens
      .map((t) => t?.token)
      .filter((t): t is string => typeof t === 'string' && t.length > 0);
    if (tokens.length === 0) {
      const payload: LogPayload = {
        event: 'dispatchIntervention',
        requestId,
        uid,
        tier,
        outcome: 'no_tokens',
        latencyTotalMs: Date.now() - startMs,
      };
      logger.info(payload);
      return { ok: true, outcome: 'no_tokens' };
    }

    // 5. Rate-limit BEFORE the FCM send so a transient FCM outage
    // cannot DoS the user's push budget.
    let rateLimit;
    try {
      rateLimit = await consumeToken(uid, Date.now(), {
        windowMs: RATE_LIMIT_WINDOW_MS,
        max: RATE_LIMIT_MAX,
        collection: RATE_LIMIT_COLLECTION,
      });
    } catch (e) {
      const payload: LogPayload = {
        event: 'dispatchIntervention',
        requestId,
        uid,
        tier,
        outcome: 'internal',
        errorReason: 'rate_limit_tx_failed',
        latencyTotalMs: Date.now() - startMs,
      };
      logger.error({
        ...payload,
        cause: e instanceof Error ? e.name : 'unknown',
      });
      return { ok: true, outcome: 'internal' };
    }
    if (!rateLimit.allowed) {
      const payload: LogPayload = {
        event: 'dispatchIntervention',
        requestId,
        uid,
        tier,
        outcome: 'rate_limited',
        rateLimit: { remaining: 0, retryAfterSec: rateLimit.retryAfterSec },
        latencyTotalMs: Date.now() - startMs,
      };
      logger.info(payload);
      return { ok: true, outcome: 'rate_limited' };
    }

    // 6. Send multicast. LOCKED payload from PAYLOADS[tier] — no
    // per-dispatch text, no body from the audit doc, no Gemini output.
    // This is the Tier 3 fence: by construction, the only path to a
    // notification body is through this constant.
    const payloadCopy = PAYLOADS[tier];
    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: payloadCopy.title, body: payloadCopy.body },
      android: {
        notification: { channelId: CHANNEL_ID, priority: 'high' },
      },
    });

    // 7. Prune dead tokens. Identical pattern to sendCheerUpPush — drop
    // the canonical `registration-token-not-registered` returns AND any
    // malformed entries that may have crept in from older clients.
    const dead: string[] = [];
    response.responses.forEach((r, i) => {
      if (
        !r.success &&
        r.error?.code === 'messaging/registration-token-not-registered'
      ) {
        const t = tokens[i];
        if (typeof t === 'string') dead.push(t);
      }
    });
    if (dead.length > 0 || hasMalformedEntries(settings?.tokens)) {
      const survivors = (settings?.tokens ?? []).filter(
        (t) =>
          typeof t.token === 'string' &&
          t.token.length > 0 &&
          (t.platform === 'android' || t.platform === 'web') &&
          !dead.includes(t.token),
      );
      await settingsRef.update({ tokens: survivors });
    }

    // 8. Allowlisted structured log. NEVER include token strings, the
    // body, the title, or any field beyond the schema. The PII canary
    // test asserts this.
    const log: LogPayload = {
      event: 'dispatchIntervention',
      requestId,
      uid,
      tier,
      outcome: 'sent',
      tokenCount: tokens.length,
      deliveredCount: response.successCount,
      failedCount: response.failureCount,
      prunedCount: dead.length,
      latencyTotalMs: Date.now() - startMs,
      rateLimit: { remaining: rateLimit.remaining, retryAfterSec: 0 },
    };
    logger.info(log);
    return { ok: true, outcome: 'sent' };
  },
);
