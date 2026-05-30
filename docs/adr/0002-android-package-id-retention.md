# ADR-0002 — Retain `com.cssit.usercentricapp` Android Package ID

**Status:** Accepted (retroactive; ratified 2026-05-30)
**Date:** 2026-05-30 (backfill of a Sprint 3 follow-up flagged in ADR-0001)
**Deciders:** orchestrator + architect
**Supersedes:** the rename plan in ADR-0001 Consequences §"Follow-up"
**Related:** ADR-0001 (Repository Structure + Clean Architecture); CLAUDE.md "Stack (locked)"; `apps/mobile/android/app/build.gradle.kts:12,35`; `apps/mobile/android/app/google-services.json:5`

## Context

ADR-0001 (Sprint 2) deferred the Android `applicationId` rename to a future
ADR-0002 in Sprint 3:

> "Defer the Android package id rename. Keep `com.cssit.usercentricapp`
> for Sprint 2. Rename to `com.moodbloom.app` in Sprint 3 alongside a
> planned `flutterfire configure` re-run, captured in ADR-0002 at that
> time." — ADR-0001 §Decision

The rename never executed. By Sprint 5 `v1.5` the code still ships with:

- `apps/mobile/android/app/build.gradle.kts:12` — `namespace = "com.cssit.usercentricapp"`
- `apps/mobile/android/app/build.gradle.kts:35` — `applicationId = "com.cssit.usercentricapp"`
- `apps/mobile/android/app/google-services.json:5` — `"project_id": "csc234-user-centric-mobile-app"` with its `mobilesdk_app_id` keyed off the current `applicationId`

The ADR was never written because the rename was never executed, and the
audit report (2026-05-30, `docs/audit-orchestration.md`) flagged this as
an outstanding gap (Appendix B "Outstanding documentation"). This ADR
closes that gap by ratifying the **retention** decision rather than
revisiting the rename.

## Decision

**Keep `com.cssit.usercentricapp` for the lifetime of the v1.x line.**
No rename in v1.5, v1.5.1, or v1.6. Any rename is deferred again, this
time explicitly past the course submission deadline (2026-05-30).

Concretely:
- `applicationId` and `namespace` in `build.gradle.kts` remain
  `com.cssit.usercentricapp`.
- `google-services.json` continues to be generated against the existing
  Firebase project `csc234-user-centric-mobile-app`.
- The product is presented to the user as "MoodBloom" via the launcher
  label, app icon (regenerated against the brand mark in the v1.6 polish
  wave), and in-app branding. The reverse-DNS `applicationId` is a
  build-tooling identifier that the user never sees.

## Alternatives Considered

### A. Rename to `com.moodbloom.app` in v1.5.1 (the original plan)
**Rejected.** The cost-benefit shifted across the project:
- Renaming `applicationId` requires re-creating the Android app in the
  Firebase console, re-running `flutterfire configure` against the new
  app, and re-issuing every `google-services.json` checked into the
  repo and CI.
- The existing FCM registration tokens at
  `users/{uid}/settings/notifications.tokens[]` are bound to the current
  Firebase `mobilesdk_app_id`. A rename invalidates them; every signed-in
  user on Android would silently lose their cheer-up push subscription
  until they re-launched the app to re-register a token. That's an
  undocumented post-rename surface no one would notice for days.
- The Play Store treats `applicationId` as an immutable primary key. If
  the app were ever published under the current id (it isn't yet, but
  the option matters for the course's demo deadline), a rename means
  publishing as a new product and losing install history. Once the
  course grading deadline passes the constraint relaxes; pre-deadline
  it's a load-bearing decision.
- No user-visible change. The end-user sees "MoodBloom" everywhere
  (launcher label, app icon, every screen). Reverse-DNS package ids are
  an Android-tooling concept invisible to end-users; their drift from
  the product name is purely a vanity concern at this stage.

### B. Rename to a vanity id like `com.kmutt.csc234.moodbloom`
**Rejected.** Same Firebase / FCM / Play-Store cost as Option A, with the
extra downside that `com.kmutt.csc234.moodbloom` ties the binary to a
specific course offering — every semester that re-uses MoodBloom as a
template would have to rename again. The current id at least reads as
generic "student-context user-centric app" rather than course-specific.

### C. Status quo — Option chosen (this ADR)
**Accepted.** No code churn; no Firebase re-provisioning; no FCM token
invalidation; no Play-Store risk. The trade-off is documented brand-vs-id
drift — accepted because it's invisible to end-users.

## Consequences

- **Positive:** zero risk of breaking the FCM token registration path or
  the `sendCheerUpPush` / `dispatchIntervention` Cloud Functions, both of
  which depend on the existing `users/{uid}/settings/notifications.tokens`
  schema being addressable under the current `mobilesdk_app_id`. The
  course submission goes out on a known-good Firebase wiring.
- **Negative:** the binary's reverse-DNS identifier does not match the
  product brand. New contributors reading
  `apps/mobile/android/app/build.gradle.kts` see `com.cssit.usercentricapp`
  and may briefly wonder if they're in the right repo. This ADR is the
  documented answer to that question.
- **Follow-up (out of scope):** if the project is ever published to the
  Play Store under a different identity, the rename can re-open as a
  new ADR (ADR-0015+) at that time, with a documented FCM-token
  re-registration migration plan.

## Compliance Check

- [x] **R2 — Clean Architecture.** Decision sits at the platform-config
      layer; no domain / presentation / data churn.
- [x] **R3 — Multi-Agent Workflow.** Architect-authored; orchestrator
      ratified; security-reviewer not required (no Firestore rules /
      Cloud Function / auth flow change).
- [x] **R5 — Quality Gates.** No tests touched; no CI step changes.

## Note on missing artifacts and out-of-band concerns

This ADR is a **retroactive backfill**. The audit report at
`docs/audit-orchestration.md` (HEAD `ef2c96ad`, dated 2026-05-30) honestly
states "ADR-0002 was never written" — that statement was correct at the
time of the audit. This file was added the same day, after the audit,
to close the gap. Future audits should treat the audit-report text as
historical context and this ADR as the canonical record of the decision.
