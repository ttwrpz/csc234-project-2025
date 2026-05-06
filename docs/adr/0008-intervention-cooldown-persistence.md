# ADR-0008 — Intervention Cooldown Persistence: Firestore-Primary, SharedPreferences-Mirror

**Status:** Accepted (Sprint 5)
**Date:** 2026-05-13
**Deciders:** orchestrator + architect
**Related:** ADR-0007 (statistical-primary pattern analysis); CLAUDE.md pivot feature #5 (cheer-up intervention 5-of-7 trigger, 48h cooldown, 10-day escalation); HB-003 (Sprint 5 cheer-up FCM brief)

## Context

Sprint 4 shipped the cheer-up cooldown and escalation anchors as SharedPreferences-only state in `apps/mobile/lib/features/garden/data/intervention_state_storage.dart`. The detector reads `lastTriggeredAt` and `firstTriggeredAt` from local prefs, applies the 48h cooldown gate and the 10-day escalation rule, and returns an `InterventionState`. The S4 acceptance bar tolerated this because no consumer outside the local app process needed the anchors.

Sprint 5 changes that. The `sendCheerUpPush` Cloud Function (HB-003) needs a server-side signal that the user has just hit a fresh trigger so it can multicast to every registered FCM device. SharedPreferences is single-device-only — a user signed in on Android and Web sees two independent cooldowns, the CF cannot read either, and a server-driven 24h rate limit cannot collaborate with a client-driven 48h cooldown without a shared store.

A second concern: the Sprint-5 plan §11 risk #3 ("Hotline 1323 footer fires too early") is harder to audit when the anchor lives only in device-local prefs. A Firestore-resident anchor is inspectable by an emulator-driven security test that seeds `firstTriggeredAt = now - 11d` and asserts the footer surfaces; same test against SharedPreferences requires platform-channel mocking and is brittle.

## Decision

The cheer-up cooldown and escalation anchors persist primarily in Firestore at `users/{uid}/interventionState/current` (single doc, fields `lastTriggeredAt: timestamp | null`, `firstTriggeredAt: timestamp | null`, `schemaV: 1`). The existing `InterventionStateStorage` (SharedPreferences) is retained as the offline-read mirror only — every successful Firestore read warms the mirror, every successful Firestore write mirrors locally, and reads fall back to the mirror on Firestore failure. A new `InterventionStateRepository` abstract in the domain layer hides the topology from the detector.

## Consequences

**Good**

- Multi-device parity: signing in on Android and Web sees the same cooldown window. The 24h FCM rate limit on the server side and the 48h client cooldown collaborate via the shared anchor.
- The `sendCheerUpPush` CF reads `users/{uid}/interventionState/current` in the same trigger that fires on the new `cheerUpEvents` write, so the server-side decision is consistent with the client-side decision.
- The 10-day escalation footer is auditable from emulator E2E tests without platform-channel mocking.
- The repository abstraction lets the offline-read path stay warm without leaking SharedPreferences semantics into the domain layer (CLAUDE.md domain-zero-imports rule preserved).

**Bad**

- One additional Firestore write per trigger fire. Bounded — the trigger fires at most once per (uid, day, reason) combination by construction (idempotent event-doc id), and the anchor write is one document update per fire.
- Network-dependent write path: a user who triggers offline now sees a slightly degraded state — the local mirror is updated immediately so the local detector is correct, but the CF will not fire until the queued mutation drains. Documented in HB-003 OQ-B and the rollback runbook.
- Conflict surface: two devices that hit the trigger within milliseconds of each other will both write `lastTriggeredAt`. Last-write-wins per ADR-0005 applies; the millisecond difference is invisible to the 48h gate.

## Alternatives Considered

- **Firestore-only with `cloud_firestore` offline persistence enabled.** Rejected. Firestore's offline cache is opaque (no `sync_state` per row, no separation between "we wrote this and it's queued" and "we read this and it's stale"). The cheer-up cooldown is a small, tightly-bounded piece of state that benefits from explicit local control; collapsing it into the general offline cache makes the rollback risk register harder to reason about. The pattern matches ADR-0004's rejection of the same approach for moods.
- **SharedPreferences-only (current S4 state).** Rejected as the driver of this ADR. Cannot be read by the CF; cannot be inspected by emulator tests; cannot collaborate with multi-device sessions. The Sprint-5 push pipeline is impossible without a server-readable anchor.
- **Cloud Functions trigger that re-derives the cooldown from the `cheerUpEvents` collection on each fire.** Rejected. The detector also needs the anchor (the 48h cooldown gate runs client-side, before the event doc is written). A derive-on-server approach would require a round-trip on every render, contradicting the offline-first stance.

## Compliance Check

- Clean Architecture domain-zero-imports rule: satisfied. `InterventionStateRepository` is abstract in `apps/mobile/lib/features/garden/domain/`; `InterventionAnchors` is pure-Dart (no Flutter / Firebase imports). Implementation lives in `data/`.
- Enterprise Term Assignment requirements touched: **R3** (architecture quality — repository pattern preserved across the persistence shift); **R5** (security — Firestore rules enforce per-user isolation via `match /users/{uid}/interventionState/{docId}` block in `firestore.rules`).
- Quality gates affected: **Correctness** (multi-device parity is now testable); **Security** (per-user rule isolation, immutable schemaV, allowed-key set). Performance: one extra write per trigger fire, bounded.
- CLAUDE.md feature-flag rollback: N/A — anchors are state, not behaviour. The CF that consumes them is gated by `users/{uid}/settings/notifications.enabled`; if a runaway anchor is ever observed, the CF can be paused without touching the anchors.
