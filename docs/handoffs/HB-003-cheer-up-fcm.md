# HB-003 — Cheer-Up FCM Brief (Sprint 5)

**Author:** architect
**For:** flutter-engineer + qa-engineer (parallel: client copy + CF surface)
**Sprint:** 5 (May 13–19, 2026)
**WBS:** 5.5 (cheer-up FCM fan-out)
**Status:** Retroactive backfill — implementation already shipped at `v1.5` as `functions/src/sendCheerUpPush.ts`, `apps/mobile/lib/features/garden/data/cheer_up_events_repository_impl.dart`, and `apps/mobile/lib/features/garden/presentation/widgets/cheer_up_banner.dart`. This document re-creates the brief that drove that work so the section-references in shipped tests (`cheer_up_banner_test.dart:33` cites "HB-003 §5.5a") and in shipped ADRs (`ADR-0008` cites "HB-003 OQ-B" and "HB-003 §5.5b") have a canonical source.
**Related:** ADR-0007 (pattern analysis fallback strategy — statistical-primary); ADR-0008 (intervention cooldown persistence — Firestore-primary, SharedPreferences-mirror); CLAUDE.md "Pivot features" §5 (cheer-up intervention, 5-of-7 trigger, 48h cooldown); `.claude/specs/sprint-4-5-spec.md` §5.5

## Goal

When the client-side cheer-up detector trips (sliding 5-of-7 negative-day rule OR 3-consecutive-high-intensity rule), surface the dispatched event in three places:

1. **In-app banner** at the top of `GardenScreen`: a soft, locked-copy invitation to try a two-minute breathing exercise. Dismissible; non-blocking; never alarmist.
2. **Append-only audit doc** at `users/{uid}/cheerUpEvents/{evtId}` with `evtId = ${dayUtc}-${reason}` (idempotent — same-day re-evaluation collapses on doc-id).
3. **FCM push** to every registered token via the `sendCheerUpPush` Cloud Function. One push per uid per day, regardless of how many reasons triggered.

## Inputs

- `InterventionStateRepository` (S5; see ADR-0008) — Firestore-primary anchor at `users/{uid}/interventionState/current` with `lastTriggeredAt`, `firstTriggeredAt`, `schemaV`. The 48h client cooldown is read from here.
- `RunPatternEngineUseCase` output (S4 / S5; ADR-0011) — emits a `Tier?` per day, but the cheer-up surface is a parallel path that reads the underlying scalar signals (negative-day count, consecutive-high-intensity count) directly. The Pattern Engine produces the data; the cheer-up detector applies its own simpler rule.
- `users/{uid}/settings/notifications` — preferences doc carrying `cheerUpEnabled: bool` plus the FCM `tokens[]` list.
- Firebase Cloud Messaging Admin SDK (server side; via `getMessaging()` inside `functions/src/sendCheerUpPush.ts`).

## Files to create

- `apps/mobile/lib/features/garden/domain/cheer_up_events_repository.dart` — abstract.
- `apps/mobile/lib/features/garden/data/cheer_up_events_repository_impl.dart` — Firestore-backed; idempotent `record(reason)` writes `users/{uid}/cheerUpEvents/${dayUtc}-${reason}`.
- `apps/mobile/lib/features/garden/data/datasources/cheer_up_events_firestore_datasource.dart` — thin Firestore wrapper.
- `apps/mobile/lib/features/garden/presentation/controllers/cheer_up_controller.dart` — Notifier that watches the detector, idempotent-creates the event doc, then invokes the `sendCheerUpPush` callable.
- `apps/mobile/lib/features/garden/presentation/widgets/cheer_up_banner.dart` — the in-app surface.
- `functions/src/sendCheerUpPush.ts` — the Cloud Function (Tier-1 cheer-up only; Tier 2/3 deferred to HB-007).
- `functions/src/__tests__/sendCheerUpPush.test.ts` — the 7 cases listed in §5.5b.
- `apps/mobile/test/features/garden/presentation/widgets/cheer_up_banner_test.dart` — locked-copy parity tests.

## §5.5 — Surfaces

### §5.5a — In-app banner (locked copy)

The banner's user-visible sentence is locked at the **CLAUDE.md** copy-rule layer:

> **It's been a heavy week. Want to try a two-minute breathing exercise?**

Implementation rules:

- Render as two `Text` widgets visually (the first stanza in `titleSmall`, the second in `bodyMedium`) — the visual split is fine, but the `Semantics(label: ...)` MUST contain the full sentence verbatim so screen readers hear the complete prompt.
- The reason code (`5_of_7_negative` vs `3_consecutive_high_intensity` vs anything else) drives the underlying icon and `cheerUpEventsRepository.record(reason)` call but DOES NOT change the locked sentence — a future reason that the engine adds must still surface with the same opening line. Unknown reason codes do not crash; they fall through to the same locked sentence.
- Dismissible. Tapping the close affordance fires `cheerUpController.dismiss()` which clears the in-app state without recording an opt-out (the audit doc + cooldown anchor are the source of truth for the next-fire decision; the banner is presentation).
- Never alarmist: no red palette, no shake animation, no modal interruption. Reuses the `MbCard` design-system surface with the brand seed-green accent.

**Tests to write** (committed at `cheer_up_banner_test.dart`):

1. Locked sentence appears in `Semantics(label:)` for `reason = '5_of_7_negative'`.
2. Locked sentence appears in `Semantics(label:)` for `reason = '3_consecutive_high_intensity'`.
3. Locked sentence appears for any unknown reason code (parity contract).

### §5.5b — Cloud Function `sendCheerUpPush`

HTTPS-callable (NOT a Firestore trigger — the project's Firestore database lives in `asia-southeast3`, which neither Cloud Functions v1 nor v2 supports as a Firestore-trigger location). The CF is invoked by the client AFTER the audit doc at `users/{uid}/cheerUpEvents/${dayUtc}-${reason}` has been written. The `requestId` in the payload is the event-doc id — used as a structured-log correlation id only; idempotency is enforced by the per-uid daily rate limit, not the request id.

**Validation order** (mirror in `__tests__/sendCheerUpPush.test.ts`):

1. Read `users/{uid}/settings/notifications` — opt-out short-circuit if missing or `cheerUpEnabled !== true`. Outcome: `opted_out`. No rate-limit doc touched.
2. Filter tokens; bail with `no_tokens` if empty.
3. Atomic 24h rate-limit consume via `consumeToken` on `rateLimits.cheerUp/{uid}` (separate collection from `rateLimits/{uid}` to avoid colliding with `analyzeMoodText`).
4. Send multicast with the LOCKED title/body and `android.notification.channelId = 'cheer_up'`.
5. Prune `messaging/registration-token-not-registered` tokens by writing the survivor list back to the settings doc.
6. Structured allow-list log — `outcome`, `tokenCount`, `deliveredCount`, `failedCount`, `prunedCount`, `latencyTotalMs`, `rateLimit`. Never the title, body, or token strings.

**Locked notification payload** (module-scope constants in the CF):

- `TITLE = 'A gentle check-in'`
- `BODY = "Noticing you've had a rough stretch. We're here."`
- `CHANNEL_ID = 'cheer_up'`

The payload is fixed at module scope so even a future "personalised body" feature cannot accidentally route through this function — that's the PII fence.

**Tests to write** (committed as the 7 cases at `__tests__/sendCheerUpPush.test.ts`):

1. Happy path — 2 tokens, fresh rate limit → multicast sent with locked payload.
2. `opted_out` — `cheerUpEnabled = false` → no FCM call, no rate-limit consumption.
3. `no_tokens` — settings present, `cheerUpEnabled = true`, but `tokens` empty.
4. `rate_limited` — second invocation within 24h returns `rate_limited` without an FCM call.
5. Dead-token pruning — survivors written back without the dead token.
6. PII canary — neither title, body, nor token strings appear in any logger payload.
7. Channel-id literal — every multicast uses `channelId = 'cheer_up'`.

## Acceptance

- [x] CLAUDE.md §"Copy rules — Intervention banner text" lists the locked sentence; `cheer_up_banner_test.dart` enforces it across all three reason variants.
- [x] `functions/src/sendCheerUpPush.ts` passes all 7 §5.5b tests; `npm test` green.
- [x] The CF's rate-limit collection (`rateLimits.cheerUp/{uid}`) is admin-SDK only — default-denied by `firebase/firestore.rules`.
- [x] The audit doc collection (`users/{uid}/cheerUpEvents/{evtId}`) is append-only at the rule level (rules deny update + delete); doc-id format `${dayUtc}-${reason}` is the only idempotency key the system needs.
- [x] `ADR-0008` is the binding decision for the cooldown anchor; this brief defers to it for everything anchor-related.

## Open Questions for the orchestrator

### OQ-A — Cheer-up vs. tiered intervention overlap (resolved Sprint 5)

By S5 the project ships TWO push paths: this `sendCheerUpPush` (binary "fire / don't fire" based on the simpler 5-of-7 / 3-consecutive rules) AND the per-tier `dispatchIntervention` (HB-007's product, tier 1/2/3-aware). They share `rateLimits.*` separation, both honour `cheerUpEnabled` and per-tier opt-outs respectively, and they share the same `cheer_up` Android channel. The decision was: keep both. The cheer-up path remains the user-facing "we noticed" surface; the tiered path is the recommendation routing. Either alone has a use case; together they form the safety surface.

### OQ-B — Offline write path

A user who triggers the detector while offline sees a slightly degraded state: the local mirror updates immediately so the local detector is correct, but the CF will not fire until the queued mutation drains. **Acceptance:** documented in ADR-0008 §Consequences; the local-mirror correctness preserves the user-visible banner and the 48h cooldown; the push fires when connectivity returns. No additional mitigation in v1.5.

### OQ-C — Per-day vs. per-reason rate-limit shape

Considered: `rateLimits.cheerUp.${reason}/{uid}` with 24h windows per reason (so a `5_of_7_negative` push and a `3_consecutive_high_intensity` push could both fire same-day). **Decided against**: the user-experience cost of two pushes in 24h outweighs the diagnostic value of separating reasons. Resolution: single per-uid daily bucket; `outcome: 'rate_limited'` covers both.

## Non-goals (do NOT do in this PR)

- Per-tier per-dispatch FCM payloads (that's HB-007's `dispatchIntervention`, shipped in a later S5 PR).
- Notification-action buttons in the system shade ("I'm okay" from the lock screen) — deferred to a future sprint; the in-app banner's opt-out is the only path.
- Deep-link routing into the breathing screen from the notification tap — the FCM payload is `notification`-only (no `data`); the user lands on the home screen and the in-app banner surfaces.
- Server-side personalisation of the body. The PII fence is the locked module-scope constant.
- Per-platform copy. Android and iOS both receive the same locked payload (iOS support deferred per ADR-0001).

## Note on missing artifacts and out-of-band concerns

This handoff brief was **never committed during Sprint 5** — the work shipped (every file listed under "Files to create" exists at `v1.5`) but the brief itself was passed verbatim from architect to engineer in the orchestrator's chat and never landed in `docs/handoffs/`. The audit report at `docs/audit-orchestration.md` (HEAD `ef2c96ad`, dated 2026-05-30) flags "HB-003 is not present in the sequence" as an honest gap. This file is the **retroactive backfill** that closes the gap; section numbers and locked copy are the canonical text the shipped tests and ADR-0008 already cite.
