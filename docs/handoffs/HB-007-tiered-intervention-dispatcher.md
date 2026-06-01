# HB-007 - Tiered Intervention Dispatcher

**Author:** architect
**For:** flutter-engineer
**Sprint:** 5 (May 13–19, 2026)
**WBS:** 5.4
**Related:** ADR-0008 (cooldown persistence); ADR-0011 (client-side pattern engine); ADR-0012 (Tier 3 determinism - required reading); HB-008 (Quote Library + Safety Filter - must be developed in tandem); `.claude/specs/sprint-4-5-spec.md` §2.5 (Tiered Intervention), §7 TC-31..35, TC-38, TC-40

## Goal

Wire the Pattern Engine's `Tier?` triggers into user-visible notifications. When the engine emits a non-null `Tier`, dispatch a tier-appropriate response - Tier 1 = 2-minute breathing screen; Tier 2 = journaling prompt screen; Tier 3 = crisis-resources screen + Hotline 1323. Every dispatch records to Firestore for audit and respects a single shared cooldown anchor.

## Inputs

- `Tier?` from `RunPatternEngineUseCase.run(...)` (Day-3 wiring exists).
- `InterventionStateRepository.read()` returns the cooldown anchors (`lastTriggeredAt`, `firstTriggeredAt`) per ADR-0008.
- `NotificationsSettings.{tier1Enabled, tier2Enabled, tier3Enabled}` (new flags this sprint - Day 2 task).
- `QuoteLibrary` + `AIQuoteRepository` + `QuoteSafetyFilter` from HB-008. The dispatcher composes them, does not duplicate them.
- `DisclaimerCopy.notificationFooter` (already canonical at `apps/mobile/lib/features/disclaimer/domain/disclaimer_copy.dart`).

## Files to create

```
apps/mobile/lib/features/intervention/
├── domain/
│   ├── entities/
│   │   ├── intervention_dispatch.dart       (Freezed: tier, body, ctas, footer, dispatchId)
│   │   ├── intervention_record.dart         (Freezed: matches Firestore doc shape)
│   │   ├── cooldown_decision.dart           (sealed: Proceed | Blocked(reason))
│   │   └── intervention_failure.dart        (sealed Failure)
│   ├── repositories/
│   │   └── intervention_repository.dart     (abstract: writeRecord, watchHistory)
│   ├── services/
│   │   ├── tiered_intervention_dispatcher.dart   (pure-Dart, the orchestrator)
│   │   └── cooldown_guard.dart                   (pure-Dart: 1/24h + 48h gate)
│   └── usecases/
│       └── dispatch_intervention.dart       (entry point called from Pattern Engine hook)
├── data/
│   ├── datasources/
│   │   └── interventions_firestore_datasource.dart
│   ├── repositories/
│   │   └── intervention_repository_impl.dart
│   └── providers.dart
└── presentation/
    ├── controllers/
    │   └── intervention_controller.dart      (@riverpod)
    ├── widgets/
    │   ├── intervention_banner.dart          (in-app banner; routes to screen on tap)
    │   └── intervention_opt_out_button.dart  ("I'm okay" - TC-34)
    └── screens/
        ├── breathing_screen.dart             (Tier 1, 2-minute timer + animation)
        ├── journaling_prompt_screen.dart     (Tier 2, prompt + textarea + save)
        └── crisis_resources_screen.dart      (Tier 3, Hotline 1323 + 3 resource links)
```

## Files to extend

- `firebase/firestore.rules` - open writes on `match /users/{uid}/interventions/{id}` (immutable on update; field-level allow-list on create: `tier`, `dispatchedAt`, `quoteId`, `optedOut`, `cooldownUntil`); open writes on `match /users/{uid}/cooldowns/{type}` (allow-list: `lastDispatchedAt`, `cooldownUntil`). **security-reviewer sign-off required** per CLAUDE.md.
- `apps/mobile/lib/app/router.dart` - add routes `/intervention/breathing`, `/intervention/journal`, `/intervention/crisis`. **architect sign-off required.**
- `apps/mobile/lib/features/pattern_engine/domain/usecases/run_pattern_engine.dart` - emit `Tier?` to a sink that the dispatcher subscribes to. Keep the use case pure-Dart; sink is a `StreamController` injected by the controller layer.

## Dispatcher state machine

```
PatternEngine emits Tier?  ────────────┐
                                       ▼
                          ┌──────────────────────┐
                          │  CooldownGuard.check │
                          │  reads               │
                          │  InterventionState   │
                          │  Repository          │
                          └─────────┬────────────┘
                                    │
                  ┌─────────────────┴────────────────┐
                  ▼                                  ▼
               Blocked                            Proceed
            (return early)                           │
                                                    ▼
                                  ┌─────────────────┴────────────────┐
                                  ▼                                  ▼
                            tier == Tier.three            tier == Tier.one | Tier.two
                                  │                                  │
                                  ▼                                  ▼
                     QuoteLibrary.pickTier3             AIQuoteRepository.requestSuggestion
                     (curated, deterministic              → QuoteSafetyFilter.gate
                      seed: today)                        → fallback curated on reject/fail
                                  │                                  │
                                  └────────────────┬─────────────────┘
                                                   ▼
                                ┌──────────────────────────────────────┐
                                │  build InterventionDispatch          │
                                │   body = quote + "\n\n" + footer     │
                                │   ctas = tier-specific buttons       │
                                │   footer = DisclaimerCopy            │
                                │            .notificationFooter       │
                                └──────────────────┬───────────────────┘
                                                   ▼
                            ┌──────────────────────┴────────────────────┐
                            ▼                                           ▼
            InterventionRepository.writeRecord          InterventionStateRepository
            (audit doc at                                .writeLastTriggeredAt(now)
             users/{uid}/interventions/{id})              (ADR-0008 path)
                                                   │
                                                   ▼
                                       emit Dispatch to controller
                                                   │
                                                   ▼
                                       UI shows banner + routes
```

## Cooldown guard rules

Reuse `InterventionStateRepository.read()` for anchors. Decision logic:

- If `lastTriggeredAt != null AND now - lastTriggeredAt < 24h`: `Blocked(reason: dailyLimit)`. (TC-31)
- If `lastTriggeredAt != null AND now - lastTriggeredAt < 48h`: `Blocked(reason: cooldown)`. (TC-32)
- Otherwise: `Proceed`.

When the user taps "I'm okay" (TC-34), set `interventions/{id}.optedOut = true` and call `InterventionStateRepository.writeLastTriggeredAt(now)` - the 48h cooldown applies even after opt-out so the system does not re-nag.

## Acceptance

- TC-31: max 1 notification per 24h enforced.
- TC-32: 48h cooldown between alerts enforced.
- TC-33: Tier 3 always includes Hotline 1323 link + crisis resources.
- TC-34: All notifications include "I'm okay" opt-out.
- TC-35: Intervention features NEVER locked behind tokens. (No `tokensRepository` import allowed in this feature folder; CI lint.)
- TC-38: Every Tier 1/2/3 notification body contains `DisclaimerCopy.notificationFooter` as a substring. Unit test asserts this for all three tiers.
- TC-40 covered by HB-008 + ADR-0012; this dispatcher's Tier 3 arm is the subject of that test.

## Open questions for the engineer

- **OQ-A:** Should the dispatcher emit an in-app banner only, or also fire an FCM push when the app is background? Default: **banner in foreground, FCM push in background**, using the existing `sendCheerUpPush.ts` CF as the per-tier delivery path (the CF decides at message build time; the dispatcher writes the `interventions/{id}` doc which the CF trigger reads). Confirm with architect at start of Day 1.
- **OQ-B:** Tier-specific cooldown vs. global cooldown? Default: **global** - one anchor across all tiers, matching the spec's "max 1 notification/day" rule. A Tier 1 today blocks a Tier 3 tomorrow if inside 48h. Spec §2.5 supports this read. Flag to architect if the engineer wants per-tier nuance.

## Non-goals (do NOT do in this PR)

- Do not edit `pattern_engine/` domain code beyond adding the emit hook. The 5 algorithms are frozen post-S4.
- Do not edit `DisclaimerCopy` - strings are canonical.
- Do not build a new cooldown store. Reuse `InterventionStateRepository` (ADR-0008).
- Do not add a `tokensRepository` dependency. Intervention features are always free (TC-35).
