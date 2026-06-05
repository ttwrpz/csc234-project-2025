# Pre-Show Evidence Checklist

**Release:** v1.6 · commit `0e55021a` · generated 2026-06-02
**Goal:** when the committee says "show me X," any team member switches to it in two seconds.

> `[FILL]` = confirm the exact URL before the talk (repo org, Firebase project, video host). Local paths are real and verified in this repo.

## Browser tabs (pin in this order)

1. **GitHub repo main page** — `[FILL: https://github.com/<org>/csc234-project-2025]` — commits (157), tags (`v1.5`), branches.
2. **CLAUDE.md on GitHub** — show the locked copy rules + 12 pivot features.
3. **`.claude/specs/sprint-4-5-spec.md`** rendered — the 41 acceptance test cases + 37 citations (§7, §8).
4. **Firebase Console → Crashlytics** — `[FILL: console.firebase.google.com/project/<project>/crashlytics]`.
5. **Firebase Console → Remote Config** — show `ai_pattern_analysis_enabled`, `intervention_dispatch_enabled`, `gemini_detection_enabled`.
6. **Firebase Console → Firestore → Rules** — the live per-user rules.
7. **GitHub Actions** — most recent **green** run of "Lint Test and Validate" on `main` (2026-06-02 was green).
8. **ADR-0012** (Tier-3 fence) on GitHub — `docs/adr/0012-tier-3-determinism-and-gemini-mock-test.md`.
9. **HB-007** (dispatcher brief) on GitHub — `docs/handoffs/HB-007-tiered-intervention-dispatcher.md`.
10. **Backup demo videos** (`[FILL: unlisted YouTube links or local mp4 paths]`):
    - Android cross-platform log-mood flow (~45s)
    - Web cross-platform log-mood flow (~45s)
    - Offline-first airplane-mode demo (~60s)
    - A11y dynamic type to 200% (~30s)
    - Tier-1 banner walkthrough (~60s)

## Terminal windows (in this order)

1. **Android** — emulator or wired S23 with the app on a **fresh launch** (Home screen, seeded garden).
2. **Web** — Chrome serving the release build at `[FILL: http://localhost:8099]` (`cd apps/mobile/build/web && python -m http.server 8099`).
3. **Tests, ready to run on demand** — `cd apps/mobile && flutter test --concurrency=8 --exclude-tags=golden,shader` (the committed evidence run was **1045/1045**).
4. **Firestore emulator, ready** — `firebase emulators:exec --only firestore "..."` for "show me the rules pass."

## Physical setup

- Two screens (laptop + tablet/second laptop) for Beamer presenter view if using `show notes on second screen=right`. Default deck mode is `hide notes` — switch in the preamble if you want presenter mode.
- HDMI/USB-C adapter **tested with the venue projector** beforehand.
- **Phone hotspot** as backup network — venue Wi-Fi is the single most common live-demo failure.
- Printed speaker scripts (1 per presenter, ring-bound) from `speaker-script.md`.
- Water for every presenter.

## 15-minute pre-show drill

1. Cold-launch Android → Home loads in **< 2s**.
2. Cold-launch Web → Home loads.
3. Airplane mode → log a mood → reconnect → confirm Firestore sync appears.
4. Open Crashlytics → confirm the dashboard loads.
5. Open GitHub Actions → confirm the green run.
6. Play all five backup videos in order → confirm audio works.
7. Each presenter reads their **first transition line** aloud once (catches voice-handoff fumbles).

## Common failure recovery

| Symptom | Recovery |
|---|---|
| Live Android demo crashes | Switch to the backup video tab; keep narrating from the script's `[FALLBACK:]` line |
| Web build is offline | Show the locally-cached Chrome tab; or the `web-chrome-fullscreen.png` capture |
| Firestore rules won't load in console | Switch to the GitHub raw view of `firebase/firestore.rules` |
| Crashlytics dashboard slow | Skip the live dashboard; describe the no-PII logging policy verbally (Slide 21) |
| Network down entirely | Hotspot on; if still down, the deck + embedded screenshots carry the whole talk without live demo |
| Q&A runs long | Cut the conclusion (Slides 23–24) to one sentence, or drop Slide 16 (algorithms) to appendix A4; open the floor early (see `speaker-script.md` compression levers) |
| "Is it 1018 or 1045 tests?" | Q26 in `qa-prep.md` — tag was 1018, May-31 evidence run was 1045+94; show both logs |

## Appendix slides (Q&A jump-targets)

The deck holds 8 backup slides after Slide 24 (A1–A8). Don't present them — jump to one when the committee drills in. Map: A1 EWMA/α · A2 Firestore rule · A3 type fence · A4 pattern math · A5 cooldown · A6 account deletion · A7 disclaimer · A8 test pyramid. (Full trigger→slide table in `speaker-script.md` → "Appendix index".) **During the pre-show drill, confirm how your PDF viewer jumps to a page and back** (type page-number + Enter in most viewers).

## Source map (where each on-screen claim lives)

- Test counts → `docs/evidence/platform-execution/flutter-test-vm-host.log`, `functions-jest.log`
- Cross-platform screenshots → `docs/evidence/platform-execution/screenshots/` (also copied to `presentation/images/`)
- Tier visuals / atmosphere / banners → `docs/evidence/goldens/garden/.../`
- Tier-3 fence → `ai_allowed_tier.dart`, `tiered_intervention_dispatcher.dart`, ADR-0012
- Firestore rule → `firebase/firestore.rules:55–69`
- Router/guards → `apps/mobile/lib/app/router.dart`
