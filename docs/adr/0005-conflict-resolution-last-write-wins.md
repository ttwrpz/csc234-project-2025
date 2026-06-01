# ADR-0005 - Conflict Resolution: Last-Write-Wins by `updatedAt`

**Status:** Accepted
**Date:** 2026-04-29
**Deciders:** orchestrator + architect
**Related:** ADR-0004 (Drift offline-first schema)

## Context

ADR-0004 introduces a Drift local store as the UI source of truth, with a `MoodSyncManager` that pushes pending mutations to Firestore and a Firestore listener that mirrors remote changes back into Drift. When a user signs in on two devices and edits the same `MoodEntry` within the 24-hour mutability window, both Drift instances will eventually receive the other's change. Without an explicit resolution rule, the listener's upsert path either thrashes (last-arrival overwrites in either direction depending on race) or silently corrupts state.

The 24-hour immutability invariant means concurrent edits are vanishingly rare in practice - one user, two devices, both online within 24h of `createdAt`. This makes a sophisticated CRDT approach overkill: per-field version vectors would inflate the schema and the wire format for almost no real-world benefit. We need a deterministic, low-complexity rule that the sync manager can apply inside the same transaction that does the upsert.

## Decision

**Last-write-wins by `updated_at`.** The row with the larger `updated_at` value wins. Same-millisecond tie → larger `device_id` (lexicographic). Missing `updated_at` (legacy Sprint 2 docs) → treat as `created_at`; if still tied, the remote wins.

### Algorithm - `MoodDao.upsertFromRemote(remote)`

```
local = getById(remote.id)

if local == null:
    insert(remote with sync_state='synced'); return

// Local pending write that is at least as new - drop the remote echo
if local.sync_state in {pending, syncing}
   and local.updated_at >= remote.updated_at:
    return

if remote.updated_at > local.updated_at:
    overwrite(local with remote, sync_state='synced')
elif remote.updated_at < local.updated_at:
    return                                  // local wins
else:
    // millisecond tie
    if remote.device_id == local.device_id: return            // idempotent
    if remote.device_id < local.device_id:                    // lexicographic
        overwrite(local with remote)
    else:
        return
```

The whole sequence runs inside a Drift transaction so the read-then-write is atomic against concurrent writes from the user's own mutations.

### `device_id`

Stable per-install UUID stored in `SharedPreferences` under key `mood.device_id`, generated lazily on first launch. Not PII per CLAUDE.md (random per install, not tied to identity). Lives at `apps/mobile/lib/app/providers.dart` as `deviceIdProvider`.

### Edge cases

- **Soft-deleted locally + remote `modified`**: keep the soft-delete; the queued local `delete` mutation will eventually win when it drains. The remote `modified` is dropped because the local row's `sync_state` is `pending` and `updated_at >= remote.updated_at` (the soft-delete updated `updated_at`).
- **Hard-deleted remotely + local pending edit**: the Firestore listener's `removed` change wins. Drop the queued `update`, `MoodDao.hardDelete(id)`, surface a one-time toast: *"An entry you were editing was removed on another device."* (Copy must comply with CLAUDE.md - no fix-your-mood verbs; "notice" / "removed" are acceptable.)
- **Clock skew between devices**: relies on the writer's local clock, which is fine in the *common* case. The fix is normalisation: when the queued mutation drains, the Cloud Function or Firestore `serverTimestamp()` produces the canonical `updated_at` and the listener writes it back. So a skewed device may transiently show "locked" too early or too late, but the eventual state across devices is consistent.
- **Two devices edit within the same millisecond**: `device_id` lexicographic tiebreak is deterministic. The losing device's listener will receive the winner's update on the next snapshot and overwrite. Both devices converge.

## Alternatives Considered

- **CRDTs (per-field LWW or G-Counter for `intensity`)**. Rejected: schema cost (per-field version columns), wire-format cost (DTO inflation), and zero real-world benefit at the rate of conflicts our 24h invariant produces.
- **Server-side reconciliation via Cloud Function transaction**. Rejected: adds a function call to every save, doubles the cost of the offline-first happy path, and centralises a problem that only exists for the multi-device subset of users.
- **Vector clocks**. Rejected: complexity-to-benefit ratio is even worse than CRDTs at our scale.
- **First-write-wins by `created_at`**. Rejected: `created_at` is immutable, so it can't differentiate between an original write and a subsequent edit. Doesn't solve the problem.
- **No tiebreak (just `updated_at` >`)**. Rejected: same-millisecond writes from two devices would diverge silently. Tiebreak is cheap and deterministic.

## Consequences

- Positive: deterministic, bounded-cost, transactional. Easy to test (the ADR-0004 test plan includes the LWW cases). The wire format requires only `updated_at` and `device_id` (which we already have).
- Negative: a user who edits on a slow-clock device after editing on a fast-clock device may see the slow-clock edit "lose" silently. The likelihood is low (24h invariant + same user typing) and the resolution is "edit again, preferably on a clock-correct device." We do not surface a merge UI in Sprint 3.
- Follow-up: if multi-device conflict telemetry shows a user-perceived issue (e.g., > 0.1% of edits silently overwritten), Sprint 5+ revisits with a per-field merge UI. The current decision is reversible because LWW is a strict subset of richer reconciliation strategies.

## Compliance Check

- [ ] Determinism - same inputs always produce the same outcome on every device.
- [ ] Domain layer purity - no leakage of `device_id` or `updated_at` semantics into the domain entity (`MoodEntry`); these live in `MoodEntryRow` (Drift) and the DTO mapper.
- [ ] Test coverage - ADR-0004 test plan §B explicitly includes LWW newer-wins, older-loses, and `device_id`-tiebreak cases in `mood_dao_test.dart`.
- [ ] CLAUDE.md "Never log PII (mood text, email, uid-with-text)" - toast copy in the hard-delete edge case names neither the entry text nor the user.
