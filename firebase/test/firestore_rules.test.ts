/**
 * Firestore + Storage Security Rules — emulator tests (WBS 2.3).
 *
 * These tests boot the Firestore + Storage emulators (via firebase emulators:exec)
 * and exercise every branch of `firebase/firestore.rules` and
 * `firebase/storage.rules` against the canonical 15-case audit table from the
 * Sprint 3 handoff brief (`.claude/briefs/sprint-3/security-rules.md`).
 *
 * The brief mandates ALL 15 cases pass; if any rules-API limitation prevents a
 * case from being expressed, the alternative is documented inline rather than
 * silently skipped.
 *
 * Run locally:
 *   firebase emulators:exec --only firestore,storage,auth \
 *     "cd firebase/test && npm test"
 */

import * as fs from "fs";
import * as path from "path";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertSucceeds,
  assertFails,
} from "@firebase/rules-unit-testing";
import {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  Timestamp,
} from "firebase/firestore";
import { ref, uploadBytes } from "firebase/storage";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const PROJECT_ID = "moodbloom-rules-test";
const USER_A = "userA";
const USER_B = "userB";

const ONE_HOUR_MS = 60 * 60 * 1000;
const TWENTY_FIVE_HOURS_MS = 25 * 60 * 60 * 1000;

/**
 * Build a `createdAt` Timestamp guaranteed to fall on the same UTC
 * calendar day as the rule's `request.time`. Uses today's UTC midnight
 * + 1 hour so the timestamp is always after the day boundary,
 * regardless of when CI runs. Replaces the previous "now - 23h"
 * heuristic, which crossed the midnight boundary on roughly half the
 * runs (CI machines run at all hours of the UTC day).
 */
function todayMidnightUtcPlus(hourOffsetMs: number): Timestamp {
  const now = new Date();
  const utcMidnight = Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate(),
  );
  return Timestamp.fromMillis(utcMidnight + hourOffsetMs);
}

// ---------------------------------------------------------------------------
// Test environment lifecycle
// ---------------------------------------------------------------------------

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../firestore.rules"),
        "utf8",
      ),
      host: "127.0.0.1",
      port: 8080,
    },
    storage: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../storage.rules"),
        "utf8",
      ),
      host: "127.0.0.1",
      port: 9199,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Seed a mood entry directly into Firestore bypassing rules. Used to set up
 * pre-existing documents (e.g. an entry created 25h ago for the lock-window
 * tests) that we then attempt to mutate as the user.
 */
async function seedMoodEntry(
  uid: string,
  moodId: string,
  data: Record<string, unknown>,
): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, `users/${uid}/moods/${moodId}`), data);
  });
}

/**
 * Build a valid mood-entry payload. `createdAt` must be supplied by the caller
 * because it is meaningful to most tests (server-time on create vs. Timestamp
 * fixed in the past for lock-window cases).
 */
function validMoodPayload(
  overrides: Partial<Record<string, unknown>> = {},
): Record<string, unknown> {
  return {
    mood: "happy",
    intensity: 3,
    text: "Felt the sunshine on my walk.",
    mediaRefs: [],
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Cases 1-12 — Firestore rules
// ---------------------------------------------------------------------------

describe("Firestore rules — users/{uid}/moods", () => {
  it("Case 1: userB cannot write to userA's moods (per-user RBAC)", async () => {
    const userB = testEnv.authenticatedContext(USER_B).firestore();
    await assertFails(
      setDoc(doc(userB, `users/${USER_A}/moods/m1`), validMoodPayload()),
    );
  });

  it("Case 2: create with createdAt != request.time is denied", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    // Backdated timestamp — must NOT equal request.time (server time).
    const backdated = Timestamp.fromMillis(Date.now() - ONE_HOUR_MS);
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/moods/m1`),
        validMoodPayload({ createdAt: backdated }),
      ),
    );
  });

  it("Case 3: create with intensity = 0 is denied (below 1..5)", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/moods/m1`),
        validMoodPayload({ intensity: 0 }),
      ),
    );
  });

  it("Case 4: create with intensity = 6 is denied (above 1..5)", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/moods/m1`),
        validMoodPayload({ intensity: 6 }),
      ),
    );
  });

  it("Case 5: create with text > 500 chars is denied", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    const longText = "x".repeat(501);
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/moods/m1`),
        validMoodPayload({ text: longText }),
      ),
    );
  });

  it("Case 6: create with mood='melancholy' (not in enum) is denied", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/moods/m1`),
        validMoodPayload({ mood: "melancholy" }),
      ),
    );
  });

  it("Case 7: update of an entry created on a previous day is denied", async () => {
    const lockedCreatedAt = Timestamp.fromMillis(
      Date.now() - TWENTY_FIVE_HOURS_MS,
    );
    await seedMoodEntry(USER_A, "m1", {
      mood: "okay",
      intensity: 2,
      text: "yesterday",
      mediaRefs: [],
      createdAt: lockedCreatedAt,
    });

    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/moods/m1`), {
        text: "trying to edit a locked entry",
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("Case 8: update of entry created earlier the same UTC day is allowed", async () => {
    // Anchor `createdAt` at today's UTC midnight + 1h. The rule
    // permits updates when `request.time.year/month/day` equals
    // `resource.data.createdAt.year/month/day`, so this is the test
    // for "same day" — replacing the prior 24h-window semantics.
    const recentCreatedAt = todayMidnightUtcPlus(ONE_HOUR_MS);
    await seedMoodEntry(USER_A, "m1", {
      mood: "okay",
      intensity: 2,
      text: "earlier today",
      mediaRefs: [],
      createdAt: recentCreatedAt,
    });

    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertSucceeds(
      updateDoc(doc(userA, `users/${USER_A}/moods/m1`), {
        text: "small refinement",
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("Case 9: update mutating createdAt is denied", async () => {
    const original = Timestamp.fromMillis(Date.now() - ONE_HOUR_MS);
    await seedMoodEntry(USER_A, "m1", {
      mood: "okay",
      intensity: 2,
      text: "ok",
      mediaRefs: [],
      createdAt: original,
    });

    const userA = testEnv.authenticatedContext(USER_A).firestore();
    // Try to shift createdAt — rules require equality with resource.data.createdAt.
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/moods/m1`), {
        createdAt: Timestamp.fromMillis(Date.now() - 5 * 60 * 1000),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("Case 10: update mutating userId (outside affectedKeys whitelist) is denied", async () => {
    const original = Timestamp.fromMillis(Date.now() - ONE_HOUR_MS);
    await seedMoodEntry(USER_A, "m1", {
      mood: "okay",
      intensity: 2,
      text: "ok",
      mediaRefs: [],
      createdAt: original,
      userId: USER_A,
    });

    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/moods/m1`), {
        userId: "spoofed-uid",
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("Case 11: delete of an entry created on a previous day is denied", async () => {
    const lockedCreatedAt = Timestamp.fromMillis(
      Date.now() - TWENTY_FIVE_HOURS_MS,
    );
    await seedMoodEntry(USER_A, "m1", {
      mood: "sad",
      intensity: 4,
      text: "yesterday",
      mediaRefs: [],
      createdAt: lockedCreatedAt,
    });

    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(deleteDoc(doc(userA, `users/${USER_A}/moods/m1`)));
  });

  it("Case 12: read of another user's rateLimits/{otherUid} is denied", async () => {
    // rateLimits is admin-SDK only — even the owner cannot read.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(doc(adminDb, `rateLimits/${USER_A}`), { count: 7 });
    });

    const userB = testEnv.authenticatedContext(USER_B).firestore();
    await assertFails(getDoc(doc(userB, `rateLimits/${USER_A}`)));
  });

  // -------------------------------------------------------------------------
  // Cases 16-17 — R-1 and R-2 from the security-reviewer audit (2026-04-29)
  // -------------------------------------------------------------------------

  it("Case 16 (R-1): update with client-supplied past updatedAt is denied", async () => {
    // Seed a recent doc that's well within the 24h lock window.
    const recentCreatedAt = Timestamp.fromMillis(Date.now() - ONE_HOUR_MS);
    await seedMoodEntry(USER_A, "m1", {
      mood: "okay",
      intensity: 2,
      text: "earlier today",
      mediaRefs: [],
      createdAt: recentCreatedAt,
    });

    const userA = testEnv.authenticatedContext(USER_A).firestore();
    // Client tries to backdate updatedAt — rules require == request.time, so
    // any client-supplied Timestamp (past or future) must be rejected.
    const backdatedUpdatedAt = Timestamp.fromMillis(
      Date.now() - 10 * 60 * 60 * 1000,
    );
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/moods/m1`), {
        text: "spoofed updatedAt",
        updatedAt: backdatedUpdatedAt,
      }),
    );
  });

  it("Case 17 (R-2): update with text as a list (not string) is denied", async () => {
    const recentCreatedAt = Timestamp.fromMillis(Date.now() - ONE_HOUR_MS);
    await seedMoodEntry(USER_A, "m1", {
      mood: "okay",
      intensity: 2,
      text: "earlier today",
      mediaRefs: [],
      createdAt: recentCreatedAt,
    });

    const userA = testEnv.authenticatedContext(USER_A).firestore();
    // Lists respond to .size() so size-only validation would let this through;
    // the new `text is string` clause on update is what rejects it.
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/moods/m1`), {
        text: ["x"],
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

// ---------------------------------------------------------------------------
// Cases 18-23 — users/{uid}/settings/notifications (WBS 6.3, HB-003)
// ---------------------------------------------------------------------------

describe("Firestore rules — users/{uid}/settings/notifications", () => {
  /** Seed a notifications-settings doc bypassing rules. */
  async function seedSettings(
    uid: string,
    data: Record<string, unknown>,
  ): Promise<void> {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(doc(adminDb, `users/${uid}/settings/notifications`), data);
    });
  }

  /** Build a valid notifications-settings payload for create. */
  function validSettingsPayload(
    overrides: Partial<Record<string, unknown>> = {},
  ): Record<string, unknown> {
    return {
      cheerUpEnabled: true,
      tokens: [
        {
          token: "device-token-1",
          platform: "android",
          lastSeenAt: Timestamp.now(),
        },
      ],
      updatedAt: serverTimestamp(),
      ...overrides,
    };
  }

  it("Case 18: owner can create users/{uid}/settings/notifications", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertSucceeds(
      setDoc(
        doc(userA, `users/${USER_A}/settings/notifications`),
        validSettingsPayload(),
      ),
    );
  });

  it("Case 19: userB cannot read userA's notifications settings", async () => {
    await seedSettings(USER_A, {
      cheerUpEnabled: true,
      tokens: [],
      updatedAt: Timestamp.now(),
    });
    const userB = testEnv.authenticatedContext(USER_B).firestore();
    await assertFails(
      getDoc(doc(userB, `users/${USER_A}/settings/notifications`)),
    );
  });

  it("Case 20: create at /settings/{otherDocId} is denied (only 'notifications')", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/settings/other`),
        validSettingsPayload(),
      ),
    );
  });

  it("Case 21: create with non-bool cheerUpEnabled is denied", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/settings/notifications`),
        validSettingsPayload({ cheerUpEnabled: "yes" }),
      ),
    );
  });

  it("Case 22: update flipping cheerUpEnabled is allowed", async () => {
    await seedSettings(USER_A, {
      cheerUpEnabled: true,
      tokens: [],
      updatedAt: Timestamp.now(),
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertSucceeds(
      updateDoc(doc(userA, `users/${USER_A}/settings/notifications`), {
        cheerUpEnabled: false,
        tokens: [],
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("Case 23: update introducing an unknown field is denied (affectedKeys)", async () => {
    await seedSettings(USER_A, {
      cheerUpEnabled: true,
      tokens: [],
      updatedAt: Timestamp.now(),
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/settings/notifications`), {
        cheerUpEnabled: true,
        tokens: [],
        updatedAt: serverTimestamp(),
        // Unknown field outside the affectedKeys whitelist.
        attackerControlled: true,
      }),
    );
  });

  it("Case 24: client delete of notifications settings is denied", async () => {
    await seedSettings(USER_A, {
      cheerUpEnabled: true,
      tokens: [],
      updatedAt: Timestamp.now(),
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      deleteDoc(doc(userA, `users/${USER_A}/settings/notifications`)),
    );
  });

  it("Case 25 (audit R-002): userB cannot write to userA's notifications settings", async () => {
    // Mirrors Case 1 for the moods collection. The outer `match
    // /users/{uid}` block already gates this, but the new
    // `match /settings/{settingId}` block re-grants per-document
    // permissions and we want explicit regression coverage so a
    // future drift on the parent rule cannot silently open a hole.
    const userB = testEnv.authenticatedContext(USER_B).firestore();
    await assertFails(
      setDoc(
        doc(userB, `users/${USER_A}/settings/notifications`),
        validSettingsPayload(),
      ),
    );
  });
});

// ---------------------------------------------------------------------------
// Cases 26-32 — users/{uid}/cheerUpEvents (HB-003 §5.5b)
// ---------------------------------------------------------------------------

describe("Firestore rules — users/{uid}/cheerUpEvents", () => {
  /** Build a valid cheerUpEvents payload for create. */
  function validEventPayload(
    overrides: Partial<Record<string, unknown>> = {},
  ): Record<string, unknown> {
    return {
      reason: "5_of_7_negative",
      dayUtc: "2026-05-13",
      createdAt: serverTimestamp(),
      schemaV: 1,
      ...overrides,
    };
  }

  it("Case 26: owner creates cheerUpEvents with canonical id format", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertSucceeds(
      setDoc(
        doc(userA, `users/${USER_A}/cheerUpEvents/2026-05-13-5_of_7_negative`),
        validEventPayload(),
      ),
    );
  });

  it("Case 27: create with malformed id (unknown reason) is denied", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    // The reason segment fails the regex alternation in the rule.
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/cheerUpEvents/2026-05-13-invalid_reason`),
        validEventPayload({ reason: "invalid_reason" }),
      ),
    );
  });

  it("Case 28: create with malformed id (bad date format) is denied", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    // Date segment is not YYYY-MM-DD.
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/cheerUpEvents/2026-5-13-5_of_7_negative`),
        validEventPayload(),
      ),
    );
  });

  it("Case 29: create with client-supplied past createdAt is denied", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    // Rule requires createdAt == request.time — any client Timestamp must fail.
    const backdated = Timestamp.fromMillis(Date.now() - ONE_HOUR_MS);
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/cheerUpEvents/2026-05-13-5_of_7_negative`),
        validEventPayload({ createdAt: backdated }),
      ),
    );
  });

  it("Case 30: update on cheerUpEvents is denied (append-only audit log)", async () => {
    // Seed an event bypassing rules so we can attempt to mutate it.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(
        doc(adminDb, `users/${USER_A}/cheerUpEvents/2026-05-13-5_of_7_negative`),
        {
          reason: "5_of_7_negative",
          dayUtc: "2026-05-13",
          createdAt: Timestamp.now(),
          schemaV: 1,
        },
      );
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      updateDoc(
        doc(userA, `users/${USER_A}/cheerUpEvents/2026-05-13-5_of_7_negative`),
        { reason: "3_consecutive_high_intensity" },
      ),
    );
  });

  it("Case 31: client delete of cheerUpEvents is denied", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(
        doc(adminDb, `users/${USER_A}/cheerUpEvents/2026-05-13-5_of_7_negative`),
        {
          reason: "5_of_7_negative",
          dayUtc: "2026-05-13",
          createdAt: Timestamp.now(),
          schemaV: 1,
        },
      );
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      deleteDoc(
        doc(userA, `users/${USER_A}/cheerUpEvents/2026-05-13-5_of_7_negative`),
      ),
    );
  });

  it("Case 32 (regression analog of Case 25): userB cannot write to userA's cheerUpEvents", async () => {
    // Mirrors Case 25 for the new collection — the outer per-user
    // RBAC gate and the new match block must both deny cross-user
    // creates, with explicit coverage so future drift cannot silently
    // open a hole.
    const userB = testEnv.authenticatedContext(USER_B).firestore();
    await assertFails(
      setDoc(
        doc(userB, `users/${USER_A}/cheerUpEvents/2026-05-13-5_of_7_negative`),
        validEventPayload(),
      ),
    );
  });
});

// ---------------------------------------------------------------------------
// Cases 33-37 — users/{uid}/interventionState/current (HB-003 §5.5a/b, ADR-0008)
// ---------------------------------------------------------------------------

describe("Firestore rules — users/{uid}/interventionState/current", () => {
  /** Build a valid interventionState/current payload for create. */
  function validAnchorPayload(
    overrides: Partial<Record<string, unknown>> = {},
  ): Record<string, unknown> {
    return {
      lastTriggeredAt: Timestamp.fromMillis(Date.now()),
      firstTriggeredAt: Timestamp.fromMillis(Date.now()),
      schemaV: 1,
      ...overrides,
    };
  }

  it("Case 33: owner creates interventionState/current with canonical shape", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertSucceeds(
      setDoc(
        doc(userA, `users/${USER_A}/interventionState/current`),
        validAnchorPayload(),
      ),
    );
  });

  it("Case 34: create at /interventionState/{otherDocId} is denied (only 'current')", async () => {
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      setDoc(
        doc(userA, `users/${USER_A}/interventionState/other`),
        validAnchorPayload(),
      ),
    );
  });

  it("Case 35: update with disallowed field is denied (affectedKeys guard)", async () => {
    // Seed an existing anchor doc bypassing rules.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(
        doc(adminDb, `users/${USER_A}/interventionState/current`),
        validAnchorPayload(),
      );
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/interventionState/current`), {
        // Unknown field outside the affectedKeys whitelist.
        attackerControlled: true,
      }),
    );
  });

  it("Case 36: update setting lastTriggeredAt to non-timestamp is denied", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(
        doc(adminDb, `users/${USER_A}/interventionState/current`),
        validAnchorPayload(),
      );
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/interventionState/current`), {
        // Rule allows timestamp OR null; a string must fail.
        lastTriggeredAt: "now",
      }),
    );
  });

  it("Case 37: client delete of interventionState/current is denied", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(
        doc(adminDb, `users/${USER_A}/interventionState/current`),
        validAnchorPayload(),
      );
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      deleteDoc(doc(userA, `users/${USER_A}/interventionState/current`)),
    );
  });

  it("Case 38 (audit R-001): update mutating schemaV is denied (immutable post-creation)", async () => {
    // PR #35 audit finding R-001: the update affectedKeys allowlist
    // previously included `schemaV` without a type guard, letting a
    // buggy or malicious client overwrite it with arbitrary values.
    // The fix tightens affectedKeys to ['lastTriggeredAt','firstTriggeredAt']
    // — schemaV is set on create and is immutable thereafter (a real
    // schema migration runs in a Cloud Function under admin SDK,
    // bypassing this rule). This test guards the invariant so a future
    // permissive-allowlist regression fails CI.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(
        doc(adminDb, `users/${USER_A}/interventionState/current`),
        validAnchorPayload(),
      );
    });
    const userA = testEnv.authenticatedContext(USER_A).firestore();
    await assertFails(
      updateDoc(doc(userA, `users/${USER_A}/interventionState/current`), {
        schemaV: 2,
      }),
    );
  });
});

// ---------------------------------------------------------------------------
// Cases 13-15 — Storage rules
// ---------------------------------------------------------------------------

describe("Storage rules — users/{uid}/media/**", () => {
  // 1×1 transparent PNG — small valid image fixture.
  const SMALL_PNG = new Uint8Array([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
    0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
  ]);

  it("Case 13: upload to users/{otherUid}/media is denied (per-user RBAC)", async () => {
    const userB = testEnv.authenticatedContext(USER_B).storage();
    const targetRef = ref(userB, `users/${USER_A}/media/photo.png`);
    await assertFails(
      uploadBytes(targetRef, SMALL_PNG, { contentType: "image/png" }),
    );
  });

  it("Case 14: upload of 30MB file is denied (size cap < 25MB)", async () => {
    const userA = testEnv.authenticatedContext(USER_A).storage();
    const targetRef = ref(userA, `users/${USER_A}/media/big.jpg`);
    // 30 MiB filled with arbitrary bytes; contentType matches image/* so the
    // rejection here is unambiguously the size cap.
    const thirtyMb = new Uint8Array(30 * 1024 * 1024);
    await assertFails(
      uploadBytes(targetRef, thirtyMb, { contentType: "image/jpeg" }),
    );
  });

  it("Case 15: upload of application/pdf is denied (contentType allowlist)", async () => {
    const userA = testEnv.authenticatedContext(USER_A).storage();
    const targetRef = ref(userA, `users/${USER_A}/media/notes.pdf`);
    const pdfBytes = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);
    await assertFails(
      uploadBytes(targetRef, pdfBytes, { contentType: "application/pdf" }),
    );
  });
});
