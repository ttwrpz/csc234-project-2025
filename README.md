# MoodBloom — Claude Code Orchestration Bundle

**Group 2 · CSC231 + CSC234 · Semester 2/2568**

This folder is what you drop into your MoodBloom Flutter repository root. Once in place, Claude Code sessions run with a consistent multi-agent workflow across Sprints 2–5.

## Starting state of the repo

Sprint 1 (before Apr 21 – Apr 21) produced **agile planning artifacts only — no Flutter code**. At the start of Sprint 2, the repo contains only:

- `flutter create` scaffold (default `lib/main.dart`, default `pubspec.yaml`)
- `flutterfire configure` output (`lib/firebase_options.dart`, `android/app/google-services.json`)
- `firebase init` baseline (`firebase.json`, empty `firestore.rules`, empty `storage.rules`)
- This bundle: `CLAUDE.md` and `.claude/`

Everything else — every feature, every screen, every test, every security rule — is built greenfield from Sprint 2 onward by the agent team following the per-sprint kickoff prompts.

## Sprint tags

| Tag | At end of | Contains |
|---|---|---|
| `v0.2-walking-skeleton` | Sprint 2 (Apr 28) | Auth + mood logging walking skeleton on Clean Architecture |
| `v0.3-beta`              | Sprint 3 (May 5)  | + Gemini AI detection, offline-first, security rules, line chart |
| `v1.0`                   | Sprint 4 (May 12) | + compassionate reframing, pattern analysis, test suite |
| `v1.5`                   | Sprint 5 (May 19) | + cheer-up intervention, cross-platform QA, finalized reports |

## What's in the bundle

```
CLAUDE.md                                  ← project memory; loaded on every session
.claude/
├── agents/
│   ├── architect.md                       ← designs, never implements
│   ├── flutter-engineer.md                ← implements, writes domain unit tests
│   ├── qa-engineer.md                     ← widget/golden/integration tests, reviewer
│   └── security-reviewer.md               ← read-only security audit, sign-off
├── prompts/
│   ├── sprint-2-kickoff.md                ← paste at start of Sprint 2
│   ├── sprint-3-kickoff.md                ← paste at start of Sprint 3
│   ├── sprint-4-kickoff.md                ← paste at start of Sprint 4
│   └── sprint-5-kickoff.md                ← paste at start of Sprint 5
└── hooks/
    └── settings.json                      ← format, analyze, secret-scan, layer-purity hooks
```

## How to install

1. Clone the MoodBloom repo.
2. Copy this entire folder (`CLAUDE.md` + `.claude/`) to the repo root:
   ```bash
   cp -r claude_code_bundle/CLAUDE.md claude_code_bundle/.claude ./
   ```
3. Commit:
   ```bash
   git add CLAUDE.md .claude
   git commit -m "chore: add Claude Code multi-agent orchestration bundle"
   ```
4. Verify Claude Code picks it up:
   ```bash
   claude config list
   ```

## How to use each sprint

### Before every sprint

1. Pull latest `main`.
2. Open Claude Code at the repo root: `claude`.
3. Paste the relevant `.claude/prompts/sprint-N-kickoff.md` content into the first prompt.
4. The orchestrator enters Plan Mode, produces a day-by-day plan, lists ADRs and handoff briefs to write, names agents per task.
5. Review the plan. Approve or ask for edits.
6. Approve. Orchestrator then delegates to subagents in sequence.

### During the sprint

- Orchestrator invokes subagents via the Task tool with a clear handoff brief.
- Subagents produce deterministic outputs (ADRs, code, test files, risk registers).
- Orchestrator manages handoffs: flutter-engineer writes → qa-engineer reviews → security-reviewer audits if sensitive → merge.
- Team members on the human side work in parallel — Kraiwich might be reviewing a PR while Napat pairs with the architect on UI questions.

### End of sprint

- Run the final smoke tests.
- Tag the release (`v0.1-alpha-clean`, `v0.2-beta`, `v1.0`, `v1.5`).
- Produce a sprint retrospective. Append it to `docs/retros/sprint-N-retro.md`. The Enterprise Audit Report (Section D3) pulls from these.

## How each agent is invoked

### Architect
Use when you need a decision, a handoff brief, or a cross-cutting answer. Not for implementation.

```
> @architect Write an ADR on how to handle the 24-hour immutability guard — should it be in the domain layer, the data layer, or enforced twice (domain + Firestore rules)?
```

### Flutter Engineer
Use when you have an architect handoff brief ready. Not for design.

```
> @flutter-engineer Implement WBS 3.4 per handoff brief HB-003 in docs/handoffs/. Create the feature branch feat/3.4-gemini-mood-detection.
```

### QA Engineer
Use when code is merged or ready for review. Also for test suite maintenance.

```
> @qa-engineer Review PR #42 (WBS 3.4 Gemini Mood Detection). Add widget tests for the AI suggestion pill and confirm domain coverage ≥80%.
```

### Security Reviewer
Use when a PR touches Firestore rules, Cloud Functions, authentication, or secrets. Also monthly for the posture report.

```
> @security-reviewer Audit PR #42 — it adds a new Cloud Function (analyzeMoodText) and calls out to Gemini. Produce the risk register.
```

## Hooks behavior

The `hooks/settings.json` configures four automatic behaviors:

1. **Secret scan on every write** — blocks any write that contains something matching common API-key patterns.
2. **Domain-layer purity check** — blocks any write to `domain/` files that imports Flutter or Firebase.
3. **Auto-format on every Dart edit** — runs `dart format` on the edited file.
4. **Analyze on every Dart edit** — runs `flutter analyze` on the feature folder.

Hooks 1 and 2 are blocking (they prevent the write). Hooks 3 and 4 are non-blocking (they run and report, but don't prevent the write). This matches the Enterprise Handbook's "enforce invariants you do not want to rely on prompting for" principle.

## Permission model

The `permissions.allow` list is generous on development commands but locks down:
- Force pushes
- `rm -rf`
- Arbitrary `curl`/`wget` (preventing exfiltration)
- Firebase deploys (must be manual)
- Writing any file that would contain a secret (`.env`, `google-services.json`, etc.)

## Expected workflow per PR

```
1. Orchestrator delegates to architect → handoff brief
2. Orchestrator delegates to flutter-engineer → feature branch + code
3. flutter-engineer opens PR with domain unit tests included
4. CI runs format + analyze + test (blocking)
5. Orchestrator delegates to qa-engineer → widget/golden tests added, review comment
6. If Firestore rules / Cloud Functions / auth touched:
     Orchestrator delegates to security-reviewer → risk register comment
7. Orchestrator merges (squash) after QA ✅ and Security ✅ (or N/A)
8. Post-merge: auto-deploy to Firebase Hosting (Web) + internal Android APK upload
```

## Troubleshooting

**"CLAUDE.md isn't being picked up."**
Run `claude config list` — confirm it sees the memory file. If not, check you're running `claude` at the repo root (not a subdirectory).

**"The architect keeps writing code."**
The architect prompt explicitly has `tools: Read, Glob, Grep, WebFetch` — no Edit, no Write. If you see it trying to write code, you likely aren't invoking the subagent properly; use `@architect` to route the task.

**"The flutter-engineer is approving its own work."**
Orchestrator failure. Enforce: after flutter-engineer opens a PR, delegate review to qa-engineer (and security-reviewer if needed). Do NOT merge without those separate reviews.

**"The hooks are blocking legitimate code."**
The domain-layer purity hook is intentionally strict. If it blocks a write, the code is wrong — redesign the boundary. Never disable the hook to make a PR pass.

**"Claude Code runs out of context mid-sprint."**
Use subagents aggressively. The orchestrator's context should only hold the plan + handoffs. Implementation context lives inside flutter-engineer's sessions. Test context lives inside qa-engineer's sessions.

## What NOT to do

- Don't edit `.claude/agents/*.md` mid-sprint. The agents rely on consistent instructions; change them at sprint boundaries, with team agreement.
- Don't share one Claude Code session across multiple features. Open fresh sessions per feature branch.
- Don't skip the architect step because "the feature is simple". Even a one-hour task benefits from a one-sentence handoff brief that names the WBS ID and the files to touch.
- Don't merge without qa-engineer's ✅. The implementer-cannot-approve rule is an Enterprise Term Assignment R3 requirement.

## Model assignments

Default model assignments (in `settings.json`):
- **architect** → Claude Opus 4.7 (highest reasoning, rarely invoked but matters when it is)
- **flutter-engineer** → Claude Opus 4.7 (high volume, writes most code)
- **qa-engineer** → Claude Sonnet 4.6 (test generation is more mechanical, lower-cost model works fine)
- **security-reviewer** → Claude Opus 4.7 (high-stakes judgment)

Override per-invocation if needed, but these are sensible defaults for a 5-person student team on a tight budget.

## Links to related artifacts

- **Architecture diagrams** — `docs/architecture/` (Mermaid source + PNG renders)
- **Journey maps & personas** — `docs/ux/` (informs handoff briefs' acceptance criteria)
- **WBS + Backlog + PDM + GANTT** — `docs/pm/` (feeds sprint plans)
- **Enterprise Audit Report (WIP)** — `docs/report/enterprise-audit.md`
- **ADRs** — `docs/adr/NNNN-*.md`

## Feedback loop

If an agent prompt is producing bad output:
1. Capture a concrete failure case (paste the input + output into `docs/agent-feedback.md`).
2. Discuss at the next stand-up — which prompt needs edits?
3. Update the prompt at a sprint boundary, tag as a chore commit, everyone rebases.

Never edit agent prompts mid-sprint unless an agent is actively harmful.
