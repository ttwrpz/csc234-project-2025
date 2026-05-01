# Sprint 5 Kickoff — v1.5: Cheer-Up Intervention + Cross-Platform QA + Release

**Sprint window:** May 13 – May 19, 2026 (5 working days)
**Sprint goal:** Ship the cheer-up intervention (gentle banner + FCM + breathing exercise + 10-day Hotline 1323 escalation), complete integration tests, run accessibility + performance sweeps, execute cross-platform QA on Android and Web, finalize the Enterprise Audit Report and both course reports. By end-of-sprint MoodBloom is **v1.5 — final release**, ready to present and submit.

**Release target:** v1.5 tag after Sprint 5 presentation on May 19. Report submissions follow on May 26 (CSC231) and May 28 (CSC234); final submission May 30.

---

## Paste this prompt into the main Claude Code session at the start of Sprint 5

Orchestrator, your Sprint 5 plan is below. Enter Plan Mode. Produce the decomposition, then wait for my approval before delegating.

### Context recap from Sprint 4

We tagged `v1.0` at the Sprint 4 demo. Wilting plants and rain clouds landed (Som's scenario works end-to-end visually). Pattern analysis with confidence labels is live. Feature flag rollback rehearsed successfully on stage. Dark mode works. ≥6 widget tests and ≥6 golden tests committed.

Two items entering S5:
- The pattern detector (5.4) fires a state update but **does not yet surface any UI** — no banner, no notification. That's S5 work.
- The Enterprise Audit Report draft (8.1) is mid-progress. S5 finalizes it.

Sprint 5 is where the **safety net goes live and the ship gets polished**. QA dominates this sprint, and `qa-engineer` is the bottleneck.

### Sprint 5 committed backlog (WBS IDs)

**Bucket 2 — Security cleanup:**
- 2.4 Account deletion with full Firestore + Storage cleanup

**Bucket 5 — Intervention:**
- 5.5 Cheer-up intervention: gentle FCM notification + compassionate home banner + 10-day escalation with Thai Hotline 1323 (the flagship pivot feature)

**Bucket 6 — Settings completion:**
- 6.3 FCM notification toggle + permission request flow

**Bucket 7 — QA sweep:**
- 7.3 Integration tests (completes: AI override scenario, intervention flow)
- 7.4 Cross-platform QA (Android + Web) + accessibility sweep (WCAG 2.2 AA) + performance profile

**Bucket 8 — Reporting:**
- 8.1 Enterprise Audit & Orchestration Report finalize
- 8.2 Compile CSC231 Project Report + CSC234 UI Report + evidence package

### Sprint 5 critical path (from PDM)

U (Integration Tests, 2.0d) → X (Cross-Platform QA + a11y + Performance, 2.0d) → Y (Finalize Reports, 1.0d) → [day 19.5 of 20]

Parallel tracks converging on X:
- V (Cheer-up Intervention, 1.5d) on Theerawat
- W (FCM Toggle + Account Deletion, 1.5d) on Jedsarit + Theerawat

**Project finishes day 19.5 of 20 — half a day buffer.** Treat every day as precious.

### Your orchestration plan

**Day 1 (May 13)** —
- `architect` writes the final handoff brief for the cheer-up intervention (5.5). Specify: banner component shape, FCM payload format, breathing exercise screen state machine, 48h cooldown persistence (Firestore `users/{uid}/cooldowns` sub-doc), 10-day escalation trigger + Hotline 1323 footer rendering rules.
- `flutter-engineer` starts FCM toggle + permission request (6.3) — depends on nothing, low risk.
- `flutter-engineer` starts the breathing exercise overlay + 4-7-8 rhythm animation.
- `qa-engineer` completes integration tests (7.3): AI override scenario test and intervention flow test (latter requires a seeded 5-of-7 dataset fixture).

**Day 2 (May 14)** —
- `flutter-engineer` implements the cheer-up banner + wires PatternDetector state → banner visibility. Banner copy: exactly "It's been a heavy week. Want to try a two-minute breathing exercise?" — copy-reviewed.
- `flutter-engineer` implements the FCM notification path: Cloud Function triggers on pattern detection, composes payload (no mood text — just "Noticing you've had a rough stretch. We're here."), FCM delivers to device.
- `flutter-engineer` implements the 10-day escalation check — banner footer: "If it helps to talk, the Thai Mental Health Hotline is free at 1323, 24 hours."
- `flutter-engineer` implements account deletion (2.4) in parallel — deletes `users/{uid}`, all subcollections, all Storage media, revokes Auth account.
- `security-reviewer` audits account deletion end-to-end: no orphaned Storage files, no ghost Firestore docs, Auth record genuinely revoked.

**Day 3 (May 15)** —
- `qa-engineer` executes Android test matrix (7.4) on a real Android emulator. Run: every widget test, every integration test, full app smoke including intervention trigger. Document in `docs/qa/android-matrix-20260515.md` with screenshots.
- `qa-engineer` starts the accessibility sweep. Walk every screen. Check Semantics labels, focus states, contrast ratios, dynamic type up to 200%. Document in `docs/qa/a11y-sweep-20260515.md`. Flag failures for `flutter-engineer` to fix same day.
- `flutter-engineer` addresses any a11y findings as they come in.
- `Theerawat` continues the Enterprise Audit Report — Sections 5–8 (orchestration workflow, agent challenges, handoff examples).

**Day 4 (May 18)** —
- `qa-engineer` executes Chrome web test matrix on Chromium. Same scope as Android. Document in `docs/qa/web-matrix-20260518.md`.
- `qa-engineer` runs performance profile: `flutter run --profile --trace-startup`, measure cold start, TTI, frame rate on analytics scroll, memory on 200-entry history. Document in `docs/qa/perf-20260518.md`.
- `flutter-engineer` addresses any perf regressions flagged.
- `security-reviewer` produces final Security Posture Report: no HIGH/CRITICAL `npm audit`, no HIGH/CRITICAL Dart deps, no secrets in source, PII-in-logs clean, Firestore rules pass all emulator tests, Cloud Functions rate-limited.

**Day 5 (May 19 — presentation day)** —
- `qa-engineer` runs one final smoke pass on both platforms after any same-day hotfixes.
- `flutter-engineer` addresses any blocker bugs from qa-engineer's smoke pass.
- `Theerawat` finalizes the Enterprise Audit Report (8.1) with test results, a11y findings, perf numbers, Crashlytics dashboard screenshots, Plan Mode transcripts.
- Merge everything. Tag `v1.5`.
- Sprint 5 demo: switch app to Som's seeded data → 5-of-7 pattern triggers → FCM notification arrives → tap banner → breathing exercise plays → user completes it. Demo continues to seeded day 10 → banner shows Hotline 1323 footer. Demo account deletion → user confirms → all data goes. Flip AI feature flag → Insights hide gracefully. A11y narrator (TalkBack) walks one screen live.

### May 20 – May 30: Report writing & submission (post-sprint)

After tagging v1.5, the team is in report-writing mode:
- **May 20–22** — Theerawat finalizes CSC231 Project Report (consolidates WBS, Backlog, PDM, GANTT, Personas, Journey Maps, Architecture). All members review.
- **May 23** (Saturday — buffer day) — team reviews both reports.
- **May 25** — Napat + Teerin finalize CSC234 UX/UI Report.
- **May 26** — CSC231 Project Report due. Submit.
- **May 28** — CSC234 UX/UI Report due. Submit.
- **May 30** — Final submission deadline. Verify both reports accepted; submit the evidence package (code repo link, screenshots, Crashlytics dashboards, Plan Mode transcripts).

### High-risk items requiring your attention

1. **Cheer-up intervention correctness (5.5)** — the most important user-visible feature of the whole pivot. If the banner fires wrong (too often, not often enough, wrong copy), the pivot fails. Test the seeded fixtures thoroughly. Have two team members read the banner copy out loud before merge. Never use clinical language.

2. **Hotline 1323 escalation** — do not ship with the Hotline 1323 URL/link broken, incorrect, or prematurely shown. This is a duty-of-care obligation. `security-reviewer` verifies the link and the 10-day threshold on day 2.

3. **Cross-platform divergence** — if a widget test passes on Android but fails on Chrome, or vice versa, it's not done. Fix, don't skip.

4. **Accessibility sweep with WCAG 2.2 AA contrast** — the compassion palette (compassion coral, rain gray) may not pass contrast in certain combinations. If any combination fails, adjust tokens in `packages/design_system/` and re-run goldens. Budget half a day for this.

5. **Report writing bandwidth** — Theerawat is the single owner of AA1/AA2. If Theerawat slips on report work, the team rallies: Kraiwich writes the Security Matrix section, Jedsarit writes the Observability + Rollback section. Pre-decide these fallbacks now, not on day 5.

### Acceptance criteria for Sprint 5 presentation + v1.5 release

- [ ] Seeding Som's 5-of-7 dataset triggers the cheer-up banner within 60s
- [ ] Tapping the banner opens the breathing exercise overlay; 4-7-8 rhythm animation works; "Done" returns to Home
- [ ] FCM notification arrives on device from the Cloud Function when pattern detected (verified on emulator with test token)
- [ ] 10-day escalation adds the Hotline 1323 footer — link opens hotline information, never auto-dials
- [ ] FCM permission request flow works on Android (permission prompt) and Web (browser permission)
- [ ] Account deletion removes all user data across Firestore, Storage, and Auth (verified in Firebase console)
- [ ] All integration tests pass on both Android and Chrome
- [ ] Accessibility sweep documented: every screen ≥ WCAG 2.2 AA contrast, Semantics labels present, dynamic type to 200% renders legibly
- [ ] Performance profile documented: cold start < 2s on mid-range Android, no frame > 16ms on analytics scroll, memory < 150MB on 200-entry history
- [ ] Enterprise Audit Report complete (5–8 pages, all required sections)
- [ ] Evidence package compiled: repo link, audit report, presentation slides, screenshots, Crashlytics dashboards, golden test files, Plan Mode transcripts
- [ ] Tag `v1.5` pushed after demo
- [ ] Zero HIGH/CRITICAL security findings

### Out of scope for Sprint 5 (do not start these)

- Thai localization (v2.0)
- iOS build (v2.0)
- Event sourcing for mood history (v2.0)
- Therapist-facing shared mood export (v2.0)
- Any new features not in the committed backlog

### Now enter Plan Mode

Produce the plan, the handoff brief for the cheer-up intervention (5.5), the handoff brief for account deletion (2.4). Wait for my approval. Do not write production code until I approve.

At the end of the sprint, produce a retrospective in `docs/retros/sprint-5-retro.md` — what worked in the multi-agent workflow, what broke, what the human team caught that the agents missed. This is part of the Enterprise Audit Report evidence.
