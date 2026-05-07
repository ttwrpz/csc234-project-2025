# v1.5 merge plan — 23 PRs in topology-safe order

**Authored:** Sprint 5 Day 5 prep.
**Owner:** human reviewer (Enterprise R3 — non-author approval; no agent merges).
**Goal:** land all open Sprint-5 PRs onto `main` in an order that preserves stacked-PR base relationships, then tag `v1.5`.

## Topology

Three classes of PR:

1. **Off `main`** — independent; can land in any order relative to each other.
2. **Stacked PRs** — base is another open PR; the parent must merge first OR the head re-bases onto `main` after the parent merges (squash-merge changes the SHA, so re-base is required either way for stacks ≥2 deep).
3. **Re-base required** — stacked PRs whose base, once merged, will need their head fast-forwarded.

## Wave 1 — independent PRs off `main` (any order; merge in parallel)

These have base=`main` and don't depend on any other open PR. Land them first to shrink the PR queue:

| PR | Branch | What |
|---|---|---|
| #23 | `chore/s5-day1-carryover` | AndroidManifest perms + MainActivity + ci.yml gh CLI |
| #24 | `docs/s5-architecture` | HB-003 + HB-004 + ADR-0008 + ADR-0009 |
| #25 | `feat/7.3a-integ-tests` | auth + mood-log/history integration flows |
| #26 | `docs/s4-retro-and-audit-skeleton` | S4 retro + Audit Report §1-8 |
| #27 | `chore/pr-template` | `.github/PULL_REQUEST_TEMPLATE.md` |
| #28 | `fix/cheer-up-banner-semantics-and-test` | banner Semantics fix + 9-test parity suite |
| #29 | `docs/devops-followups` | `docs/runbooks/devops-followups.md` |
| #31 | `feat/5.5a-cheer-up-controller` | CheerUpController + InterventionStateRepository |
| #34 | `feat/2.4a-account-deletion-domain` | AuthCredentials + DeleteAccountUseCase |
| #38 | `feat/7.3b-pattern-intervention` | pattern-intervention integration flow |
| #39 | `chore/evidence-package-script` | `tool/package_evidence.sh` (canonical 324-line) |
| #40 | `docs/sprint-5-retro-skeleton` | `docs/retros/sprint-5-retro.md` (canonical 28KB) |
| #42 | `docs/s5-day2-evening` | Android matrix + Web matrix + `flutter drive` entrypoint |
| #43 | `test/s5-missing-goldens` | 9 golden test files / 16 baselines |
| #44 | `docs/s5-security-posture-v1-5` | v1.5 Security Posture Report supplement |
| #45 | `docs/v1-6-backlog` | v1.6 backlog (8 items captured) |

**16 PRs in Wave 1.** All can land in parallel — no inter-dependencies. Recommended ordering for review-load amortisation: docs first (lightest review), then features.

## Wave 2 — first-tier stacks (after Wave 1 lands)

Each of these has `base=<a-Wave-1-PR>`. After Wave 1 lands, GitHub will offer a "rebase + merge" or the head needs `git rebase main && git push --force-with-lease`. Squash-merge after.

| PR | Stacked on | What |
|---|---|---|
| #30 | #23 (`chore/s5-day1-carryover`) | FCM toggle + R-002/R-003 fixes |
| #32 | #31 (`feat/5.5a-cheer-up-controller`) | hotline footer verification |
| #33 | #25 (`feat/7.3a-integ-tests`) | ai-override flow |
| #36 | #34 (`feat/2.4a-account-deletion-domain`) | deleteAccount CF + emulator E2E |

After Wave 1 finishes, these PRs' `base` branches no longer exist — the heads need to rebase onto `main`. Procedure for each:

```bash
git checkout <head>
git rebase origin/main          # resolve any conflicts
git push --force-with-lease origin <head>
```

Then squash-merge.

## Wave 3 — second-tier stacks (after Wave 2 lands)

| PR | Stacked on | What |
|---|---|---|
| #35 | #30 + #31 (transitively #23) | sendCheerUpPush CF + R-001 channel registration |
| #37 | #36 (`feat/2.4b-account-deletion-cf`) | Settings Danger zone + reauth modal |

Same rebase-onto-main procedure as Wave 2. PR #35 in particular merges work from #30 + #31 + the carry-over base; the rebase will be more involved.

## Wave 4 — third-tier stack (last)

| PR | Stacked on | What |
|---|---|---|
| #41 | #35 (`feat/5.5b-send-cheer-up-push`) | PR #35 audit follow-ups (R-004/R-005/R-006) + **`flutter_local_notifications` desugar production-build fix** |

**Critical:** PR #41 carries the desugar fix — without it, no Android build of v1.5 succeeds (per `docs/qa/android-matrix-20260515.md` Run 2). Even if you skip every other follow-up, **this PR cannot be skipped** before tagging.

## Pre-tag checklist

Before `git tag -a v1.5 ... && git push origin v1.5`:

1. [ ] All 23 PRs merged into `main` (or each one explicitly rejected with a written reason)
2. [ ] CI green on `main` at the merge HEAD: flutter + firestore-rules + functions jobs
3. [ ] `flutter test` count ≥ 400 on `main` (target per audit report §4.1)
4. [ ] `flutter test --tags=golden` green; ≥ 9 golden test files (closes S4 acceptance bar)
5. [ ] `pnpm test` for `functions/` ≥ 45 cases (after #36 lands)
6. [ ] `firebase emulators:exec` for `firebase/test/` ≥ 41 cases
7. [ ] **Optional but recommended:** re-create the conditional-Drift fix for Chrome web (v1.6 backlog B1) before tag — the kickoff acceptance bar demands "AND Chrome web". Without B1, v1.5 ships Android-only with a documented gap.
8. [ ] `tool/package_evidence.sh --dry-run --no-ci` exits 0
9. [ ] Demo run-through (kickoff §Day 5 script) on the connected Samsung device
10. [ ] `docs/retros/sprint-5-retro.md` + audit report runtime numbers filled in

## Tag

```bash
git tag -a v1.5 main -m "MoodBloom v1.5 — Sprint 5 final release (cheer-up FCM + account deletion + cross-platform QA)"
git push origin v1.5
```

## Post-tag

1. Run `tool/package_evidence.sh --zip` → produces `docs/submission.zip`
2. Author Sprint 5 retro Day-5-fill section (test counts, demo recap, Crashlytics screenshot, final checkboxes)
3. Submission deadlines:
   - May 26 — CSC231 Project Report
   - May 28 — CSC234 UX/UI Report
   - May 30 — Final evidence package upload

## Risks during merge

- **Wave 2/3/4 rebase conflicts.** Likely on `firestore.rules` (multiple PRs add new rule blocks) and `pubspec.yaml` (multiple PRs add deps). Resolve by keeping all rule blocks + all deps; the order they appear in those files is alphabetical convention, not semantic.
- **Coverage-comment CI step on PR template (#27).** First merge that hits `main` after #27 lands will exercise the new `gh pr comment` step. If it fails (gh auth, permission, etc.), `continue-on-error: true` keeps CI green per the carry-over PR design.
- **Goldens may shift slightly on Linux CI.** Windows-rendered goldens generated for PR #43 fall within the 4% tolerance configured in `flutter_test_config.dart`, but if a baseline drifts > 4% on Linux, regenerate via `flutter test --update-goldens --tags=golden` on the CI runner or on Kraiwich's Linux machine.

## Cross-references

- Sprint 5 plan §11 (risk register)
- Sprint 5 retro: `docs/retros/sprint-5-retro.md` (PR #40)
- Audit Report: `docs/audit/enterprise-audit-report.md` §4 (quality gates) + §6 (agent challenges)
- Evidence script: `tool/package_evidence.sh` (PR #39)
- v1.6 backlog: `docs/v1-6-backlog.md` (PR #45)
