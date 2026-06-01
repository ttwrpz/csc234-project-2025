<!--
PR title format: include the WBS ID and a short imperative.
  Examples:
    feat(5.5b): sendCheerUpPush CF + token registry
    fix(2.4): account-deletion CF idempotency on partial-state recovery
    docs(s5-d1): HB-003 + HB-004 + ADR-0008 + ADR-0009
    chore(s5-d1): carry-over bundle - biometric/FCM manifest + ci.yml gh CLI
    test(7.3a): mood_log_history integration flow

Squash merge only. No self-reviews - the agent that writes the code
is not the agent that approves it (Enterprise R3).
-->

## Summary

<!--
1-3 bullets. Lead with the *why*, not the *what* - well-named
identifiers and the diff already describe the what. Cite the WBS row,
the ADR, or the handoff brief that drove the change.
-->

- 

## Change category

<!-- Tick all that apply. -->

- [ ] feat - new user-facing behaviour
- [ ] fix - bug fix
- [ ] refactor - internal restructure, no behaviour change
- [ ] test - test-only addition or refactor
- [ ] docs - documentation only (ADR, brief, retro, runbook, audit)
- [ ] chore - build, CI, deps, tooling
- [ ] security - security-impacting change (Firestore rules, Cloud Functions, secrets, auth)

## Linked work

<!--
Reference the artifact that authorised this work. Pick whichever apply.
-->

- WBS: <!-- e.g. 5.5b -->
- Sprint plan section: <!-- e.g. .claude/plans/refactored-growing-alpaca.md §4 -->
- Handoff brief: <!-- e.g. .claude/briefs/sprint-5/cheer-up-fcm.md -->
- ADR: <!-- e.g. docs/adr/0008-intervention-cooldown-persistence.md -->
- Closes / Relates to: <!-- #issue-or-PR-number -->

## Test plan

<!--
Bulleted checklist of what proves correctness. CI is necessary but not
sufficient - call out manual + cross-platform steps explicitly.
-->

- [ ] `cd apps/mobile && flutter analyze` clean
- [ ] `cd apps/mobile && flutter test` green; domain coverage ≥ 80% (`tool/check_domain_coverage.dart`)
- [ ] `cd apps/mobile && flutter test --tags=golden` green
- [ ] `cd functions && pnpm test && pnpm lint && pnpm build` green (if `functions/` touched)
- [ ] `cd firebase/test && pnpm test` green (if `firestore.rules` or `storage.rules` touched)
- [ ] Manual: <!-- describe device matrix, e.g. flutter run -d android happy path -->
- [ ] Manual: <!-- web parity if applicable -->

## Quality gates

<!-- Mandatory unless N/A. -->

- [ ] **Domain purity** - no `package:flutter/*`, `package:firebase_*/*`, `package:cloud_firestore/*` under `apps/mobile/lib/features/*/domain/` (CI grep enforces; CLAUDE.md "the one rule that cannot break")
- [ ] **No PII in logs** - logger payloads use the allowlist; no mood text, email, FCM token, or Storage path beyond the user prefix
- [ ] **Copy rules** - no clinical language ("depression", "diagnosis", "symptom"), no streak-shaming, no fix-your-mood verbs ("improve", "boost", "overcome"); compassionate imperatives only
- [ ] **No `// TODO`** without a linked issue
- [ ] **No null-assertion `!`** in production Dart code

## Security review (tick if any apply)

<!--
CLAUDE.md "do-not-do list" - these paths require security-reviewer
sign-off before merge:
  - firebase/firestore.rules
  - firebase/storage.rules
  - functions/src/*
  - apps/mobile/lib/main.dart
  - apps/mobile/lib/app/router.dart
  - apps/mobile/android/app/build.gradle
  - apps/mobile/android/app/src/main/AndroidManifest.xml
  - .github/workflows/*
-->

- [ ] None of the above paths touched
- [ ] Touched, and `security-reviewer` audit attached or linked below
- [ ] Touched, but waiver granted by orchestrator (link the decision)

## Risks + rollback

<!--
What's the blast radius if this lands and breaks? How is it rolled back?
Feature flag, revert, hotfix, or runbook reference.
-->

- Blast radius: 
- Rollback path: 

## Generated files

<!--
- [ ] `dart format` ran clean (auto-applied via hook)
- [ ] Codegen ran (`flutter pub run build_runner build --delete-conflicting-outputs`) and `*.g.dart` / `*.freezed.dart` are committed
- [ ] No hand-edits to `*.g.dart` / `*.freezed.dart`
-->

- [ ] N/A - no codegen outputs touched
- [ ] Codegen ran; generated files committed verbatim

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
