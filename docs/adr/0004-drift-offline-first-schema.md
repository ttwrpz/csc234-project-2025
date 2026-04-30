# ADR-0004 — Drift Offline-First Schema and Sync Manager

**Status:** Accepted
**Date:** 2026-04-29
**Deciders:** orchestrator + architect
**Related:** ADR-0005 (LWW conflict resolution); CLAUDE.md (Drift mandatory for offline-first persistence)

## Context

At Sprint 2 close, `MoodRepositoryImpl` writes straight to Firestore (`apps/mobile/lib/features/mood/data/mood_repository_impl.dart`). Loss of network = loss of save. The pivot-feature acceptance criterion in Sprint 3 — "log a mood with airplane mode on → save succeeds immediately → reconnect → entry syncs within 10 seconds" — requires a local-first store that becomes the single UI source. The 24-hour immutability invariant requires enforcement at three layers (domain, data, Firestore rules) so a malicious client cannot bypass the guard.

The mood-entry domain entity (`apps/mobile/lib/features/mood/domain/entities/mood_entry.dart:37-38`) already exposes `isLocked({DateTime? now})`. The `MoodFailure.locked()` variant already exists at `mood_failure.dart:12,40-43`. The current `update()` enforces it (`mood_repository_impl.dart:81`); `delete()` does **not** (`mood_repository_impl.dart:102-114`). This ADR closes that gap as part of the cutover.

Drift web support is fragile (Safari OPFS quotas, sql.js BLOB limits). Sprint 3 ships Android-only; web continues to use the existing Firestore-only repository via a conditional provider on `dart.library.io`. Sprint 4 revisits with `drift_flutter`'s OPFS path.

## Decision

### Schema

Times are stored as **INTEGER epoch milliseconds UTC**. Decouples the local layer from Firestore `Timestamp`, simplifies indexing, and lets tests inject a deterministic clock.

**`mood_entries`**

| Column | Type | Constraints |
|---|---|---|
| `id` | TEXT PRIMARY KEY | UUID v4; reused as Firestore doc id |
| `user_id` | TEXT NOT NULL | composite-indexed with `created_at` |
| `mood` | TEXT NOT NULL | stores `MoodType.name` |
| `intensity` | INTEGER NOT NULL | CHECK 1..5 |
| `text` | TEXT NOT NULL | CHECK length ≤ 500 |
| `created_at` | INTEGER NOT NULL | epoch ms; immutable post-insert |
| `updated_at` | INTEGER NULL | epoch ms; advances on mutation |
| `media_refs` | TEXT NOT NULL DEFAULT `'[]'` | JSON via `TypeConverter` |
| `sync_state` | TEXT NOT NULL | `pending` / `syncing` / `synced` / `error` |
| `device_id` | TEXT NOT NULL | per-install UUID; LWW tiebreak (ADR-0005) |
| `deleted_at` | INTEGER NULL | tombstone marker |

Indexes: `(user_id, created_at DESC)` for history queries; `(sync_state)` for sync-worker scans.

**`sync_queue`**

| Column | Type | Constraints |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | FIFO ordering |
| `entry_id` | TEXT NOT NULL | indexed |
| `operation` | TEXT NOT NULL | `create` / `update` / `delete` |
| `payload` | TEXT NOT NULL | JSON snapshot of the entry at mutation time |
| `attempt_count` | INTEGER NOT NULL DEFAULT 0 | |
| `last_error` | TEXT NULL | truncated 200 chars; PII-safe |
| `last_error_code` | TEXT NULL | Firestore error code |
| `retry_after` | INTEGER NOT NULL DEFAULT 0 | epoch ms |
| `created_at` | INTEGER NOT NULL | |

Index: `(retry_after, id)` drives the "next due mutation" query.

Coalescing rules (DAO-side, in `enqueue` transaction):
- Pending `update` for the same `entry_id` → replace payload (idempotent).
- New `delete` → drop pending `create`/`update` for the same `entry_id`, insert single `delete`.

This caps the queue at one row per entry, bounding worst-case storage.

`schemaVersion = 1` for Sprint 3. v2 will use `MigrationStrategy.onUpgrade` step-by-step; `drift_dev schema dump` snapshot committed alongside the v2 PR for diffability.

### Sync state machine

```
pending → syncing → synced              (happy path)
pending → syncing → error → pending     (retry with exponential backoff)
synced  → pending                       (re-edit within 24h)
```

Backoff: `min(2^attempt × 5s, 1h)` with full jitter `(0.5..1.0) × delay`. Cap at 12 attempts; row sits in `error` until manual retry. `permission-denied` is a poison pill (no retry — surfaces to UI immediately).

Worker triggers (any wakes the drain loop):
- App foreground (router shell observer)
- `connectivity_plus` reports any non-`none` result
- New mutation enqueued (StreamController signal from the repository)
- 60-second belt-and-braces timer

The drain loop is a single `Future` guarded by `package:synchronized`'s `Lock`, so reentrancy is impossible within an isolate. Sprint 3 has no background isolate; Sprint 4's WorkManager hand-off must use a SQLite advisory lock (Drift transaction) to claim queue rows safely across isolates.

### Write path

`save(entry)`:
1. Defense-in-depth re-check of `intensity` and `text.length` (domain factory should catch upstream, but the data layer guards).
2. Drift transaction: `MoodDao.upsertFromLocal(row, sync_state: pending)` + `SyncQueueDao.enqueue(create, payload)`.
3. `syncManager.kick()` outside the transaction (no-op if offline).
4. Return `Ok(entry)` immediately. The UI never waits on the network.

`update(entry)`:
1. **Lock guard**: `if (entry.isLocked(now: clock.now())) return Err(MoodFailure.locked())`. Already enforced today; kept.
2. Same path as `save` with `operation: update`. Coalescing collapses repeated edits to one queue row.

`delete({userId, id})`:
1. `MoodDao.getById(id)` — if absent, `Err(MoodFailure.notFound(id))`.
2. **Lock guard** (NEW): reconstruct domain entity, `if (entry.isLocked(...)) return Err(MoodFailure.locked())`. This closes the gap at `mood_repository_impl.dart:102`.
3. Transaction: `MoodDao.softDelete(id, now)` + `SyncQueueDao.enqueue(delete)`.
4. `syncManager.kick()`.
5. Return `Ok(null)`.

### Read path

`watchAll({required userId})` returns `MoodDao.watchAllForUser(userId).map(_rowsToEntities)`. The mapper goes through `MoodEntry.create(...)` to enforce invariants; malformed rows are skipped with a `warn` log (matches existing behavior at `mood_repository_impl.dart:32`). The Drift stream invalidates whenever any DAO method commits.

Background reconciliation lives in `MoodSyncManager` (not the repository):
- On user sign-in / app resume, attach a Firestore listener `users/{uid}/moods.snapshots()`.
- For each `DocumentChange`: `added`/`modified` → `MoodDao.upsertFromRemote(row)` (LWW per ADR-0005); `removed` → `MoodDao.hardDelete(docId)`.
- Detach on sign-out / dispose.

The repository never talks to Firestore directly anymore. All cloud I/O passes through the sync manager + the existing `MoodFirestoreDatasource` (reused, not replaced).

### Migration (S2 → S3)

On first launch after S3 ships, `MoodSyncManager.bootstrap(uid)`:
1. If `MoodDao.isEmpty()` for this user, do a one-shot `MoodFirestoreDatasource.watchAll(uid).first.timeout(10s)`, batch-cursor at 100 entries per Drift transaction, seed via `upsertFromRemote` with `sync_state: synced`. No queue rows.
2. On timeout/error, attach the live listener anyway — incremental sync handles the backfill.
3. Marker key `mood.seeded.{uid} = true` in `SharedPreferences`. Idempotent (upsertFromRemote is safe to re-run; partial seeds re-finish on next launch).

### 24h immutability — three-layer enforcement

| Layer | Where | Status |
|---|---|---|
| Domain | `MoodEntry.isLocked(now)` at `mood_entry.dart:37-38` | Already shipped |
| Data — update | `MoodRepositoryImpl.update` at `mood_repository_impl.dart:81` | Already enforced |
| Data — delete | `MoodRepositoryImpl.delete` at `mood_repository_impl.dart:102` | **NEW: must fetch + check** |
| Firestore rules | `users/{uid}/moods/{moodId}` allow update/delete | **NEW** — see ADR-0005 §D handoff brief |

`LockedFailure` placement: keep `MoodFailure.locked()` (already exists, already used). Do NOT hoist a generic `LockedFailure` to `packages/core` — YAGNI until Sprint 5's journal feature introduces a second lockable resource.

### Files

Create:
- `apps/mobile/lib/features/mood/data/local/{mood_database.dart, mood_entry_table.dart, sync_queue_table.dart, mood_dao.dart, sync_queue_dao.dart}`
- `apps/mobile/lib/features/mood/data/sync/{mood_sync_manager.dart, connectivity_provider.dart}`
- `apps/mobile/lib/features/mood/data/mappers/mood_drift_mapper.dart`
- `apps/mobile/lib/app/providers.dart` additions: `databaseProvider`, `deviceIdProvider` (SharedPreferences key `mood.device_id`)

Modify:
- `apps/mobile/lib/features/mood/data/mood_repository_impl.dart` — route through DAOs + sync manager; add the missing `delete()` lock guard
- `apps/mobile/lib/features/mood/data/providers.dart` — add `moodDaoProvider`, `syncQueueDaoProvider`, `moodSyncManagerProvider`; rewire `moodRepositoryProvider`
- `apps/mobile/pubspec.yaml` — add `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `connectivity_plus`, `synchronized`, `uuid`; dev: `drift_dev`

Do not modify (intentional):
- `MoodEntry`, `MoodFailure`, `MoodEntryDto`, `MoodFirestoreDatasource`, `MoodEntryMapper` — reused as-is.

### Implementation sequencing (3 PRs for reviewability)

1. **PR 1 (schema only, no behavior change)**: tables + DAOs + database wiring. Tests pass. Repository still uses Firestore.
2. **PR 2 (sync manager, no repo cutover)**: `MoodSyncManager` + connectivity provider + listener attach. Manager writes to Drift but UI doesn't read from it yet.
3. **PR 3 (cutover + delete-side lock guard)**: rewrite `MoodRepositoryImpl`; add the delete guard; bootstrap migration. Guarded by `offlineFirstEnabledProvider` Riverpod-overridden flag for canary; flip ON after Day 4 evening canary.

## Alternatives Considered

- **Hive (NoSQL embedded)** instead of Drift. Rejected: CLAUDE.md locks Drift; Hive lacks structured queries for the analytics windowing in 5.2; SQL is testable.
- **Last-edit-wins-with-merge per field (CRDTs)**. Rejected: 24h immutability invariant means concurrent edits are vanishingly rare; CRDTs require per-field versioning across the schema. YAGNI at Sprint 3 scale.
- **Background isolate sync via WorkManager** in S3. Rejected: WorkManager + Drift requires advisory locks across isolates; main-isolate sync with a `Lock` is sufficient for foreground-only S3 demo. Deferred to S4.
- **Firestore-only with `enablePersistence: true`** (Firestore's built-in offline cache). Rejected: opaque cache, no `sync_state` per row, no queue inspection for the "pending uploads" UX, and no path to enforce the 24h domain guard on cached writes. Drift gives explicit control of every state.
- **Drift on web via OPFS now**. Rejected: fragility under Safari quotas plus 1+ day on the critical path. Conditional provider keeps web on Firestore-only for S3.

## Consequences

- Positive: offline saves work instantly; the UI is decoupled from Firestore; sync state is observable for the "pending uploads" badge; the 24h guard now has the missing delete-side enforcement; Drift's stream invalidation gives reactive UI without manual notify calls.
- Negative: three new abstractions (DAOs, sync manager, mapper) raise the surface area of the data layer; web shims through a different repository implementation; clock skew on a device can show "locked" too early or too late locally (mitigated by server-side rule using `request.time`).
- Follow-up: ADR-0005 (LWW conflict resolution); ADR-0007 or later (S4) — background isolate sync via WorkManager.

## Compliance Check

- [ ] CLAUDE.md "Drift (SQLite) for offline-first persistence" — satisfied.
- [ ] CLAUDE.md "Result<T, Failure> sealed class from repositories" — preserved; `MoodFailure` extended to surface lock + sync errors.
- [ ] CLAUDE.md "No `print()` in production" — sync manager uses `Logger` from `packages/core`.
- [ ] CLAUDE.md "Domain layer has zero Flutter/Firebase imports" — Drift code lives in `data/local/`; domain layer untouched.
- [ ] CLAUDE.md "Generated `*.g.dart` not hand-edited" — `mood_database.g.dart` produced by `build_runner`.
- [ ] CLAUDE.md "PR title references WBS ID" — PRs target `feat/3.5-drift-offline-first-{schema|sync-manager|cutover}`.
