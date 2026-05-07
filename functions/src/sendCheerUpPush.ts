// Firestore-trigger Cloud Function for the cheer-up push notification
// (HB-003 §5.5b). Fires on document-create at
// `users/{uid}/cheerUpEvents/{evtId}`. The event-doc id is
// `${dayUtc}-${reason}` so the client's idempotent same-day write
// collapses two re-evaluations on a single create — meaning this CF
// runs at most once per (uid, day, reason) tuple. The 24h rate limit
// below caps that further to one push per uid per day, regardless of
// reason.
//
// Validation order:
//   1. Read `users/{uid}/settings/notifications` — opt-out short-circuit
//      if the doc is missing or `cheerUpEnabled !== true`.
//   2. Filter tokens; bail with `no_tokens` if empty.
//   3. Atomic 24h rate-limit consume (1 push per uid per day).
//   4. Send multicast with the locked title/body + channelId='cheer_up'.
//   5. Prune `registration-token-not-registered` tokens.
//   6. Structured log line — allowlisted fields only (no token strings,
//      no payload body, no PII).
//
// Architectural notes:
//  - The payload is fixed at module scope so even a future "personalised
//    body" feature can't accidentally route through this function. PII
//    fence per ADR-0003 / HB-003 §"Out-of-scope guardrails".
//  - On a successful send we also clean up the Firestore-side state by
//    pruning dead tokens; this is a self-contained follow-up update,
//    NOT a separate trigger.
//  - We do NOT delete the event doc — it's an append-only audit log
//    (rules block deletes); the CF is the only "consumer" but the doc
//    persists for traceability.

import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

import { consumeToken } from './rateLimit.js';

// Locked payload — no PII, no clinical language, no hotline copy.
// CLAUDE.md copy rules: "noticing" instead of "improve/boost/overcome",
// no "you should". Hotline 1323 is in-app footer only (HB-003
// "Out-of-scope guardrails").
const TITLE = 'A gentle check-in';
const BODY = "Noticing you've had a rough stretch. We're here.";
const CHANNEL_ID = 'cheer_up';

// 24h rate limit — one push per uid per day even if multiple reasons
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
 * Outcome enum logged on every invocation. Allowlisted in the log
 * payload schema below — never widen this without auditing the PII
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

export const sendCheerUpPush = onDocumentCreated(
  {
    document: 'users/{uid}/cheerUpEvents/{evtId}',
    region: 'asia-southeast1',
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (event) => {
    const uid = event.params.uid;
    // Firestore event id — log correlation across the CF invocation +
    // any follow-up settings update + the consumeToken call.
    const requestId = event.id;
    const startMs = Date.now();
    const db = getFirestore();

    // 1. Read settings — opt-out short-circuit.
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
      return;
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
      return;
    }

    // 2. Rate limit — at most 1 push per uid per 24h. Consumed BEFORE
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
      return;
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
      return;
    }

    // 3. Send multicast. Locked payload — `notification` only, no
    // `data` payload (deep-link routing is v1.6+, would need its own
    // ADR + permission audit).
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

    if (dead.length > 0) {
      const survivors = (settings.tokens ?? []).filter(
        (t) => !dead.includes(t.token),
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
  },
);
