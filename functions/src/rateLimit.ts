// Per-uid rate limiter backed by a Firestore transaction.
//
// Window: 60s sliding-on-rollover (NOT a true sliding window - once the window
// starts, the next 10 calls all count against it; we only roll over when the
// next request lands >=60s after `windowStartMs`). Rationale: atomic, cheap,
// transparent to users.
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
  /** Tokens left in the current window (0..max-1). */
  remaining: number;
  /** Seconds until the next window starts. 0 when `allowed` is true. */
  retryAfterSec: number;
}

/** Per-call rate-limit options; defaults preserve the analyzeMoodText posture. */
export interface RateLimitOptions {
  windowMs?: number;
  max?: number;
  /**
   * Document path for the limiter doc. Defaults to `rateLimits/{uid}`. The
   * `analyzePatterns` callsite passes `rateLimits.patterns/{uid}` so the
   * tighter 1/30s window does not collide with the 10/60s window of
   * `analyzeMoodText` for the same uid.
   */
  collection?: string;
}

interface RateLimitDoc {
  windowStartMs: number;
  count: number;
  expireAt: number;
}

/**
 * Atomically consume one token for `uid`. Reads/writes the rate-limit doc via
 * a Firestore transaction so concurrent calls are serialised and racing
 * over-the-cap calls cannot all squeak through.
 *
 * Defaults match the original analyzeMoodText behaviour (10 calls / 60s in
 * `rateLimits/{uid}`), so the byte-identical migration only requires
 * `analyzeMoodText` to keep calling `consumeToken(uid)` with no opts.
 */
export async function consumeToken(
  uid: string,
  nowMs: number = Date.now(),
  opts: RateLimitOptions = {},
): Promise<RateLimitDecision> {
  const windowMs = opts.windowMs ?? RATE_LIMIT_WINDOW_MS;
  const max = opts.max ?? RATE_LIMIT_MAX_PER_WINDOW;
  const collection = opts.collection ?? 'rateLimits';

  const db = getFirestore();
  const ref = db.doc(`${collection}/${uid}`);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = (snap.exists ? (snap.data() as RateLimitDoc) : undefined) ?? undefined;

    // Fresh window: never seen, or the previous window has fully elapsed.
    if (!data || nowMs - data.windowStartMs >= windowMs) {
      const next: RateLimitDoc = {
        windowStartMs: nowMs,
        count: 1,
        expireAt: nowMs + windowMs,
      };
      tx.set(ref, next);
      return {
        allowed: true,
        remaining: max - 1,
        retryAfterSec: 0,
      };
    }

    if (data.count >= max) {
      const msUntilReset = data.windowStartMs + windowMs - nowMs;
      const retryAfterSec = Math.max(1, Math.ceil(msUntilReset / 1000));
      return {
        allowed: false,
        remaining: 0,
        retryAfterSec,
      };
    }

    // Note (R-M01 from 2026-04-29 security audit): we deliberately do NOT
    // refresh `expireAt` on this in-window update. The Firestore TTL policy
    // cleans the doc up ~windowMs after the window opens, regardless of how
    // many in-window updates landed. Refreshing `expireAt` here would extend
    // retention indefinitely under sustained traffic, defeating the TTL's
    // storage-bound guarantee. Operational follow-up: confirm the TTL policy
    // is configured for both `rateLimits.expireAt` AND
    // `rateLimits.patterns.expireAt` in the Firebase console.
    tx.update(ref, { count: data.count + 1 });
    return {
      allowed: true,
      remaining: max - 1 - data.count,
      retryAfterSec: 0,
    };
  });
}
