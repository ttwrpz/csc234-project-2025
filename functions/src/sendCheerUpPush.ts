// Firestore-trigger Cloud Function for the cheer-up push notification.
// Fires on document-create at
// `users/{uid}/cheerUpEvents/{evtId}`. The event-doc id is
// `${dayUtc}-${reason}` so the client's idempotent same-day write
// collapses two re-evaluations on a single create - meaning this CF
// runs at most once per (uid, day, reason) tuple. The 24h rate limit
// below caps that further to one push per uid per day, regardless of
// reason.
//
// Validation order:
//   1. Read `users/{uid}/settings/notifications` - opt-out short-circuit
//      if the doc is missing or `cheerUpEnabled !== true`.
//   2. Filter tokens; bail with `no_tokens` if empty.
//   3. Atomic 24h rate-limit consume (1 push per uid per day).
//   4. Send multicast with the locked title/body + channelId='cheer_up'.
//   5. Prune `registration-token-not-registered` tokens.
//   6. Structured log line - allowlisted fields only (no token strings,
//      no payload body, no PII).
//
// Architectural notes:
//  - The payload is fixed at module scope so even a future "personalised
//    body" feature can't accidentally route through this function (PII
//    fence).
//  - On a successful send we also clean up the Firestore-side state by
//    pruning dead tokens; this is a self-contained follow-up update,
//    NOT a separate trigger.
//  - We do NOT delete the event doc - it's an append-only audit log
//    (rules block deletes); the CF is the only "consumer" but the doc
//    persists for traceability.

// HTTPS-callable cheer-up push. Implemented as `onCall` (not a
// Firestore document-create trigger) because the project's Firestore
// database is in `asia-southeast3` (Bangkok), which neither Cloud
// Functions v1 nor v2 currently support as a Firestore-trigger
// location - the v2 Eventarc allowlist excludes southeast3, and the v1
// trigger validator rejects it too. `onCall` is region-independent and
// matches the pattern already in use by `analyzeMoodText`,
// `analyzePatterns`, `wipeUserData`, and `wipeWeeklyGarden` (all
// `asia-southeast1`).
//
// Idempotency moves from "Firestore event id is server-allocated"
// to "client passes a deterministic requestId derived from the
// {dayUtc}-{reason} event-doc id it just wrote". The 24h rate
// limit below already collapses any duplicate same-day calls; the
// requestId is for log correlation only.

import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

import { consumeToken } from './rateLimit.js';

// Locked payload - no PII, no clinical language, no hotline copy.
// CLAUDE.md copy rules: "noticing" instead of "improve/boost/overcome",
// no "you should". Hotline 1323 is in-app footer only.
const TITLE = 'A gentle check-in';
const BODY = "Noticing you've had a rough stretch. We're here.";
const CHANNEL_ID = 'cheer_up';

// 24h rate limit - one push per uid per day even if multiple reasons
// trigger same-day. Uses the existing `consumeToken` machinery from
// rateLimit.ts on a separate `rateLimits.cheerUp` doc family so it
// does not interact with analyzeMoodText (`rateLimits/{uid}`) or
// analyzePatterns (`rateLimits.patterns/{uid}`).
const RATE_LIMIT_WINDOW_MS = 86_400_000; // 24h
const RATE_LIMIT_MAX = 1;
const RATE_LIMIT_COLLECTION = 'rateLimits.cheerUp';

interface TokenRecord {
  token: string;
  platform?: string;
  lastSeenAt?: unknown;
}

interface NotificationsSettings {
  cheerUpEnabled?: boolean;
  tokens?: TokenRecord[];
}

/**
 * Returns `true` if the doc carries any token record with an empty/
 * non-string `token` field or an invalid `platform`. Per PR #35 audit
 * R-005 - the survivor filter at step 4 drops these defensively, but
 * we only trigger an `update` when something would actually change,
 * so a quiet day with all-good tokens doesn't bump the doc's
 * updatedAt. Pure helper; no side effects.
 */
function hasMalformedEntries(tokens: TokenRecord[] | undefined): boolean {
  if (!tokens) return false;
  for (const t of tokens) {
    if (typeof t.token !== 'string' || t.token.length === 0) return true;
    if (t.platform !== 'android' && t.platform !== 'web') return true;
  }
  return false;
}

/**
 * Outcome enum logged on every invocation. Allowlisted in the log
 * payload schema below - never widen this without auditing the PII
 * canary tests.
 */
type Outcome =
  | 'sent'
  | 'opted_out'
  | 'no_tokens'
  | 'rate_limited'
  | 'internal';

interface LogPayload {
  event: 'cheerUpPush';
  requestId: string;
  uid: string;
  outcome: Outcome;
  tokenCount?: number;
  deliveredCount?: number;
  failedCount?: number;
  prunedCount?: number;
  latencyTotalMs?: number;
  rateLimit?: { remaining: number; retryAfterSec: number };
  errorReason?: string;
}

interface SendCheerUpPushRequest {
  /**
   * Deterministic id the client derived from the cheerUpEvent doc it
   * just wrote (e.g. `2026-05-10-trend`). Used as the structured-log
   * `requestId` for cross-step correlation. The 24h rate limit below
   * is the actual idempotency guard.
   */
  requestId?: string;
}

export const sendCheerUpPush = onCall<
  SendCheerUpPushRequest,
  Promise<{ ok: true; outcome: Outcome }>
>(
  { region: 'asia-southeast1', memory: '256MiB', timeoutSeconds: 30 },
  async (
    request: CallableRequest<SendCheerUpPushRequest>,
  ): Promise<{ ok: true; outcome: Outcome }> => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError(
        'unauthenticated',
        'Sign in before calling sendCheerUpPush.',
      );
    }
    const uid = auth.uid;
    const requestId = request.data?.requestId ?? 'unknown';
    const startMs = Date.now();
    const db = getFirestore();

    // 1. Read settings - opt-out short-circuit.
    const settingsRef = db.doc(`users/${uid}/settings/notifications`);
    const settingsSnap = await settingsRef.get();
    const settings = (settingsSnap.exists ? settingsSnap.data() : undefined) as
      | NotificationsSettings
      | undefined;

    if (!settings || settings.cheerUpEnabled !== true) {
      const payload: LogPayload = {
        event: 'cheerUpPush',
        requestId,
        uid,
        outcome: 'opted_out',
      };
      logger.info(payload);
      return { ok: true, outcome: 'opted_out' };
    }

    const rawTokens = settings.tokens ?? [];
    const tokens = rawTokens
      .map((t) => t?.token)
      .filter((t): t is string => typeof t === 'string' && t.length > 0);

    if (tokens.length === 0) {
      const payload: LogPayload = {
        event: 'cheerUpPush',
        requestId,
        uid,
        outcome: 'no_tokens',
      };
      logger.info(payload);
      return { ok: true, outcome: 'no_tokens' };
    }

    // 2. Rate limit - at most 1 push per uid per 24h. Consumed BEFORE
    // the FCM call so a transient FCM outage cannot DoS the push
    // budget for the user.
    let rateLimit;
    try {
      rateLimit = await consumeToken(uid, Date.now(), {
        windowMs: RATE_LIMIT_WINDOW_MS,
        max: RATE_LIMIT_MAX,
        collection: RATE_LIMIT_COLLECTION,
      });
    } catch (e) {
      const payload: LogPayload = {
        event: 'cheerUpPush',
        requestId,
        uid,
        outcome: 'internal',
        errorReason: 'rate_limit_tx_failed',
        latencyTotalMs: Date.now() - startMs,
      };
      logger.error({ ...payload, cause: e instanceof Error ? e.name : 'unknown' });
      return { ok: true, outcome: 'internal' };
    }

    if (!rateLimit.allowed) {
      const payload: LogPayload = {
        event: 'cheerUpPush',
        requestId,
        uid,
        outcome: 'rate_limited',
        rateLimit: { remaining: 0, retryAfterSec: rateLimit.retryAfterSec },
        latencyTotalMs: Date.now() - startMs,
      };
      logger.info(payload);
      return { ok: true, outcome: 'rate_limited' };
    }

    // 3. Send multicast. Locked payload - `notification` only, no
    // `data` payload (deep-link routing would need its own permission
    // audit).
    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: TITLE, body: BODY },
      android: {
        notification: { channelId: CHANNEL_ID, priority: 'high' },
      },
    });

    // 4. Prune dead tokens. Firebase returns per-token success / error
    // arrays in the same order as the input; we collect the strings
    // that came back with the canonical "not registered" code and
    // remove them from the settings doc in a single update.
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

    // Survivors: drop dead tokens AND any malformed entries that may
    // have crept in from older clients. Per PR #35 audit R-005 - the
    // rule cap (tokens.size <= 25) is the only server-side guard on
    // element shape, so this filter is the canonical hygiene pass.
    // Triggers an update only when something would actually change,
    // so a quiet day with all-good tokens does not bump updatedAt.
    if (dead.length > 0 || hasMalformedEntries(settings.tokens)) {
      const survivors = (settings.tokens ?? []).filter(
        (t) =>
          typeof t.token === 'string' &&
          t.token.length > 0 &&
          (t.platform === 'android' || t.platform === 'web') &&
          !dead.includes(t.token),
      );
      await settingsRef.update({ tokens: survivors });
    }

    // 5. Allowlist log. NEVER include the token strings, the BODY, the
    // TITLE, or any field beyond the schema. The PII canary test
    // asserts this.
    const payload: LogPayload = {
      event: 'cheerUpPush',
      requestId,
      uid,
      outcome: 'sent',
      tokenCount: tokens.length,
      deliveredCount: response.successCount,
      failedCount: response.failureCount,
      prunedCount: dead.length,
      latencyTotalMs: Date.now() - startMs,
      rateLimit: { remaining: rateLimit.remaining, retryAfterSec: 0 },
    };
    logger.info(payload);
    return { ok: true, outcome: 'sent' };
  },
);
