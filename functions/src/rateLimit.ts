// Per-uid rate limiter backed by a Firestore transaction.
//
// Window: 60s sliding-on-rollover (NOT a true sliding window — once the window
// starts, the next 10 calls all count against it; we only roll over when the
// next request lands >=60s after `windowStartMs`). See ADR-0003 §"Rate limit"
// for rationale (atomic, cheap, transparent to users).
//
// The token is consumed BEFORE the Gemini call so a Gemini outage cannot DoS
// the project's Gemini quota.

import { getFirestore } from 'firebase-admin/firestore';

export const RATE_LIMIT_WINDOW_MS = 60_000;
export const RATE_LIMIT_MAX_PER_WINDOW = 10;

/** Result of attempting to consume a token for a uid. */
export interface RateLimitDecision {
  /** True if the call may proceed. */
  allowed: boolean;
  /** Tokens left in the current window (0..9). */
  remaining: number;
  /** Seconds until the next window starts. 0 when `allowed` is true. */
  retryAfterSec: number;
}

interface RateLimitDoc {
  windowStartMs: number;
  count: number;
  expireAt: number;
}

/**
 * Atomically consume one token for `uid`. Reads/writes `rateLimits/{uid}` via
 * a Firestore transaction so concurrent calls are serialised and racing 11th
 * calls cannot all squeak through.
 */
export async function consumeToken(
  uid: string,
  nowMs: number = Date.now(),
): Promise<RateLimitDecision> {
  const db = getFirestore();
  const ref = db.doc(`rateLimits/${uid}`);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = (snap.exists ? (snap.data() as RateLimitDoc) : undefined) ?? undefined;

    // Fresh window: never seen, or the previous window has fully elapsed.
    if (!data || nowMs - data.windowStartMs >= RATE_LIMIT_WINDOW_MS) {
      const next: RateLimitDoc = {
        windowStartMs: nowMs,
        count: 1,
        expireAt: nowMs + RATE_LIMIT_WINDOW_MS,
      };
      tx.set(ref, next);
      return {
        allowed: true,
        remaining: RATE_LIMIT_MAX_PER_WINDOW - 1,
        retryAfterSec: 0,
      };
    }

    if (data.count >= RATE_LIMIT_MAX_PER_WINDOW) {
      const msUntilReset = data.windowStartMs + RATE_LIMIT_WINDOW_MS - nowMs;
      const retryAfterSec = Math.max(1, Math.ceil(msUntilReset / 1000));
      return {
        allowed: false,
        remaining: 0,
        retryAfterSec,
      };
    }

    tx.update(ref, { count: data.count + 1 });
    return {
      allowed: true,
      remaining: RATE_LIMIT_MAX_PER_WINDOW - 1 - data.count,
      retryAfterSec: 0,
    };
  });
}
