# ADR-0001 — Repository Structure and Clean Architecture Layout

**Status:** Accepted
**Date:** 2026-04-22
**Deciders:** orchestrator + architect

## Context

Sprint 1 produced agile-planning artifacts only — no Flutter feature code. At Sprint 2 start the repo is a flat `flutter create` scaffold (`lib/`, `android/`, `ios/`, `web/`) plus `lib/firebase_options.dart` from `flutterfire configure`, `CLAUDE.md`, and `.claude/`. CLAUDE.md (the locked spec) prescribes a monorepo: `apps/mobile/`, `packages/{design_system,core,analytics}/`, `functions/`, `firebase/`. The Claude Code hooks (`.claude/hooks/settings.json`) already assume the monorepo — every command runs `cd apps/mobile && ...` and the `domain-layer-purity` matcher pattern-matches `apps/mobile/lib/features/**/domain/**/*.dart`. The code on disk and the contracts that govern it are out of sync. We must reconcile.

Three scaffold defects compound the gap:
1. `pubspec.yaml` is named `user_centric_mobile_app`; CLAUDE.md uses `package:moodbloom/...` for cross-feature imports.
2. `lib/main.dart` ships the default counter app and contains two syntax errors (`.fromSeed`, `.center` — missing `ColorScheme` and `MainAxisAlignment` prefixes); it does not even compile.
3. `pubspec.yaml` declares `provider: ^6.1.5+1` (forbidden — Riverpod-only mandate) and `firebase_database: ^12.1.1` (we use Firestore, not Realtime Database). `firebase_options.dart` also embeds a stale `databaseURL` for RTDB.

A separate concern: the Android package id `com.cssit.usercentricapp` and the iOS bundle id are bound to the existing `google-services.json` / `GoogleService-Info.plist` and to the API keys in `firebase_options.dart`. Renaming them invalidates Firebase wiring and requires `flutterfire configure` re-run — which is denied by `.claude/hooks/settings.json` permissions.

## Decision

Adopt the monorepo layout from CLAUDE.md verbatim. Move the existing scaffold into `apps/mobile/` via `git mv` so history is preserved. Create `packages/design_system/`, `packages/core/`, and `packages/analytics/` as Dart packages, each with its own `pubspec.yaml`. Create empty `functions/` and `firebase/` directories with placeholder `README.md`s describing their Sprint 3 scope. Rename the Dart pubspec to `moodbloom`. Within `apps/mobile/lib/`, scaffold the feature-first Clean Architecture tree with seven feature modules: `auth/`, `mood/`, `garden/`, `analytics/`, `history/`, `settings/`, `onboarding/`. Each feature gets `presentation/`, `domain/`, `data/` subfolders, each with a `.gitkeep` until populated. Cross-cutting code lives in `apps/mobile/lib/app/` (`router.dart`, `theme.dart`, `bootstrap.dart`) and `apps/mobile/lib/main.dart`.

Drop `provider` and `firebase_database` from the pubspec on the same restructure PR. Add `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `go_router`, `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation` per the locked stack. Defer `drift`, `local_auth`, `firebase_remote_config`, `firebase_messaging`, `firebase_crashlytics`, and `fl_chart` to the sprint that introduces them.

Defer the Android package id rename. Keep `com.cssit.usercentricapp` for Sprint 2. Rename to `com.moodbloom.app` in Sprint 3 alongside a planned `flutterfire configure` re-run, captured in ADR-0002 at that time.

## Alternatives Considered

- Stay flat (`lib/` at root), update CLAUDE.md and hooks to match. Rejected: CLAUDE.md is the spec graded by the Enterprise Term Assignment R3; rewriting it weakens the contract. The hooks were designed for the monorepo intentionally so cross-package boundaries can be enforced.
- Move scaffold AND rename Android package id together in one PR. Rejected: rename invalidates `google-services.json` and forces `flutterfire configure`, which `.claude/hooks/settings.json` denies. Mid-foundation-sprint Firebase reconfigure is unnecessary risk for zero immediate benefit.
- Full Melos workspace orchestration. Rejected for now: Melos value comes from many packages and a complex `bootstrap` flow; we have one app and three small packages. Reconsider in Sprint 3 only if `flutter pub get` ergonomics across packages becomes painful.
- Keep `firebase_database` "just in case". Rejected: pulling unused Firebase modules inflates the Android method count, complicates security audits, and contradicts the locked stack. Removing now is cheaper than removing after features are built on top.

## Consequences

- Positive: hooks fire correctly; the `domain-layer-purity` matcher at `apps/mobile/lib/features/**/domain/**/*.dart` binds to real paths from day one. Imports match CLAUDE.md examples. Adding `functions/` Cloud Functions in Sprint 3 needs no further restructuring. The package boundary makes the design-system-vs-feature seam testable.
- Negative / trade-offs: Sprint 2 Day 1 begins with a restructure PR rather than feature work. Android Gradle's relative paths (`flutter.sdk` lookup, `applicationId`) need verification post-`git mv`. The team must run `flutter pub get` from `apps/mobile/` going forward — IDE run configurations need updating.
- Follow-up: ADR-0002 (Sprint 3) — Android package id rename + Firebase reconfigure plan with `flutterfire configure` exception. ADR-0003+ — Sprint 3 architectural decisions (Gemini Cloud Function contract, Drift schema, local-remote conflict resolution).

## Compliance Check

- Clean Architecture domain-zero-imports rule: ✅ enforced by the `domain-layer-purity` preWrite hook in `.claude/hooks/settings.json`.
- Enterprise Term Assignment requirements touched: R3 (architecture quality), R5 (CI gates land on the new layout).
- Quality gates affected: Correctness — CI runs from `apps/mobile/`. Security — removing `firebase_database` shrinks the Firebase attack surface. Accessibility, Performance: no impact.

## Note on missing artifacts and out-of-band concerns

`docs/ux/` (journey maps + persona files) is not yet present. Acceptance criteria flowing through handoff briefs reference Lin's user stories (`US-Lin-2`, `US-Lin-3`) by ID per `.claude/prompts/sprint-2-kickoff.md`; until `docs/ux/` lands, the source-of-truth for those criteria is the kickoff prompt text itself. Theerawat to author `docs/ux/` in Sprint 2 Day 2.

`apps/mobile/lib/firebase_options.dart` will be moved with the scaffold but **must have its `databaseURL` field stripped** in the same PR — RTDB is not in the stack and the URL leak is meaningless yet noisy. The embedded API keys (`AIzaSy...`) are public-by-design Firebase identifiers but will trigger the `secret-scan` preWrite hook regex `AIza[A-Za-z0-9_-]{35}`. Architect-approved exception: `firebase_options.dart` is a generated file with public client keys; security-reviewer to confirm in the Day 1 audit and document the hook bypass strategy (path allowlist, not regex weakening).

Per CLAUDE.md "Do-not-do list", `apps/mobile/lib/main.dart` and `apps/mobile/lib/app/router.dart` require architect sign-off on every change. Initial creation in this restructure PR is pre-approved by this ADR.
