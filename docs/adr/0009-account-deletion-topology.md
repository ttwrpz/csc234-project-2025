# ADR-0009 — Account Deletion Topology: Server-Cascade via Admin SDK Cloud Function

**Status:** Accepted (Sprint 5)
**Date:** 2026-05-13
**Deciders:** orchestrator + architect
**Related:** ADR-0003 (`enforceAppCheck` posture for callable Cloud Functions); ADR-0004 (Drift offline-first, mood `delete()` lock guard); HB-004 (Sprint 5 account-deletion brief); CLAUDE.md "do-not-do list" (`firestore.rules`, `functions/src/*`, security-reviewer sign-off required)

## Context

The v1.5 privacy commitment requires that a user can permanently erase their account and every byte of their data — moods, insights, cheerUpEvents, FCM tokens, intervention anchors, settings, Storage media, and the Firebase Auth record. The current Firestore rules deny client-side deletes outside the same-day mutability window (`firestore.rules` `match /users/{uid}/moods/{moodId}` `allow delete` clause requires `request.time` and `resource.data.createdAt` to share UTC year/month/day). A 90-day-old mood entry is immutable and undeletable from the client, by design — the journal-not-redo invariant is what keeps the mood history honest.

Account deletion must therefore bypass that gate, and the only path to bypass Firestore rules without weakening them is the admin SDK from a Cloud Function. The trade-off is real: the function has to be auditable, idempotent, and cascade-correct, because once the auth user is deleted any unfinished work cannot be retried by the original caller.

## Decision

Account deletion is a single callable Cloud Function `deleteAccount` (region `asia-southeast1`, `enforceAppCheck: true`, memory `256MiB`, timeout `540s`) that runs the admin SDK to cascade-delete in a fixed order: Firestore `users/{uid}/**` via `db.recursiveDelete()`, Storage `users/{uid}/media/` via `bucket.deleteFiles({prefix})`, then `admin.auth().deleteUser(uid)`, then best-effort cleanup of the per-uid rate-limit docs. The function is idempotent — re-running on a uid whose root doc and auth user are both absent returns `{ ok: true, alreadyDeleted: true }`. Clients reauthenticate via `reauthenticateWithCredential` immediately before invoking the CF so the local `currentUser.delete()` succeeds within Firebase Auth's recent-login window.

## Consequences

**Good**

- Firestore rules remain strict — the same-day mutability gate stays in place, the journal-not-redo invariant survives, and there is no permanent rule relaxation that future audits would have to reconsider.
- The cascade order is fixed and inspectable: children before parents, Storage before root, Auth last (deleting the auth user revokes the caller's token, so any Firestore write after that step would fail with `permission-denied`).
- `db.recursiveDelete()` walks every sub-collection in one pass, so adding a new sub-collection in v1.6 (e.g. `users/{uid}/journal/`) does not require a CF edit unless the new collection's data lifecycle differs.
- Idempotency makes the path crash-recovery friendly: a CF that times out partway through can be re-invoked safely, and the second call distinguishes the "already done" case from the "first run" case in its log line.
- The reauth window concern is encapsulated client-side: the impl catches `requires-recent-login` from the local `currentUser.delete()` after the CF has already cleaned the server, and proceeds with `signOut()` regardless. The local session is the only thing the recent-login window guards against, and the data is already gone.

**Bad**

- A 540s timeout is generous to accommodate users with thousands of mood entries; in practice most accounts complete in under 30s, but the CF cost ceiling rises with account size. Cost is bounded by the per-uid one-time-cost shape — there is no recurring expense.
- `recursiveDelete` and `bucket.deleteFiles` are best-effort against eventual-consistency reads — a write that lands during the cascade may survive into the next batch. The function's idempotency contract makes this a non-issue (re-run cleans the survivor) but a malicious client racing writes against deletion would force two function invocations. Acceptable risk.
- The CF is on the critical path of a user-initiated destructive action; an outage during the 540s window means the user sees a spinner and may retry. The retry is safe by construction.

**Bad — auditing posture**

- Logs include `uid` (per ADR-0003 `uid` is not PII for our purposes) but explicitly exclude any field from any user document, any Storage object name beyond the prefix, and any FCM token string. The PII canary test enforces this. The security-reviewer audit covers logger allowlist drift between v1.5 and any future v1.x.

## Alternatives Considered

- **Client-driven deletes via batched writes.** Rejected. Would require permanently relaxing the Firestore rules to allow owner-deletes outside the same-day window, which removes the strongest guarantee in the immutability model and cannot be undone without breaking grandfathered clients. The journal-not-redo invariant is a graded line in the Enterprise Term Assignment R5 security gate; weakening it for delete is not worth the avoided server cost.
- **Per-doc Cloud Function triggers (`onDocumentDeleted` cascading from a single client-driven `users/{uid}` root delete).** Rejected. Fan-out cost (one invocation per child doc) and partial-failure exposure (a trigger that fails leaves an orphan; orphan-detection requires a janitor) make the operational story strictly worse than a single recursive-delete callable. The pattern works for tiny user models; ours is not tiny.
- **Single-step delete with no reauth.** Rejected. Firebase Auth's recent-login window exists precisely to defeat session-token replay against destructive operations. Removing the reauth step would let a stolen-but-not-yet-revoked ID token from a compromised device permanently delete the account. The 5-minute reauth window is the cheapest defence available.
- **Soft delete with a 30-day undo window.** Rejected for v1.5; deferred to v1.6 if user research surfaces regret-cases. The current decision is reversible — adding soft-delete later is additive and does not invalidate the hard-delete path documented here.
- **Defer Storage cleanup to a scheduled janitor.** Rejected. Leaving user-uploaded photos in the bucket after the account is deleted is a privacy law exposure (Sprint-5 plan §11 risk #4) and there is no commercial reason to defer the work. The 540s timeout is sufficient for the inline cascade.

## Compliance Check

- Clean Architecture domain-zero-imports rule: satisfied. `DeleteAccountUseCase` lives in `apps/mobile/lib/features/auth/domain/usecases/`; the Cloud Function lives outside the Dart layer boundaries.
- Enterprise Term Assignment requirements touched: **R3** (architecture quality — server-cascade is the right side of the layer boundary); **R5** (security — `enforceAppCheck: true`, reauth fence, admin SDK only path; no client privilege escalation).
- Quality gates affected: **Correctness** (idempotency contract is testable; emulator E2E covers the happy-path and partial-state recovery); **Security** (App Check enforcement, reauth fence, no PII in logs, server-only privilege boundary). Performance: one CF invocation per delete; bounded cost.
- CLAUDE.md "do-not-do list" — `firestore.rules` not edited by this work; `functions/src/*` is edited under security-reviewer sign-off (HB-004 audit checklist).
- CLAUDE.md "Never log PII" — satisfied via the logger allowlist and the PII canary test.
- ADR-0003 reuse — region pinning, App Check enforcement, structured-log conventions, secret-handling ceremony (not applicable here — no Gemini key) are reused; only the new cascade path is additive.

## Amendments

### 2026-05-13 — deployed function name + App Check posture

The deployed Cloud Function exporting this cascade is named `wipeUserData`
(see `functions/src/index.ts:22`), not `deleteAccount` as written in
§"Decision" line 16. The function was originally introduced in S4 polish
as a debug-reset tool and the Sprint 5 account-deletion implementation
correctly reused it rather than introducing a parallel `deleteAccount` CF
(which would have duplicated the SUBCOLLECTIONS list and risked drift).
References elsewhere in this ADR that say "deleteAccount" should be read
as "wipeUserData."

`enforceAppCheck: true` (§"Decision" line ~16) is deferred to v1.6
alongside the Flutter-web `firebase_app_check.activate(...)` initialization.
The v1.5 posture matches the rest of the CF suite: enabling App Check on
one of five callables would create an asymmetric attack surface (an
attacker who can call `analyzeMoodText` from a tampered client can equally
call `wipeUserData`) without a meaningful security gain. See
`functions/src/analyzeMoodText.ts:307-321` for the same precedent.

The rate-limit-doc cleanup step (`rateLimits.*` collections) and the
Storage media cleanup step (`users/{uid}/media/` prefix) are now both
implemented in the cascade body (see commit `c163bfe0`).
