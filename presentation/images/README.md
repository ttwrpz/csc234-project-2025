# Presentation Images

**Generated:** 2026-06-02 · release `v1.6` / `0e55021a`

All images below are **real repo artifacts** copied from `docs/evidence/` (captured 2026-05-31 on the live codebase — no fabrication). The deck references them as `images/<file>`.

## Embedded in the deck

| File | Source | Slide(s) |
|---|---|---|
| `android-s23-onboarding-1-welcome.png` | `docs/evidence/platform-execution/screenshots/` | 7 (Android) |
| `android-s23-onboarding-2-log-moods.png` | same | 7 (spare / interactivity proof) |
| `web-chrome-fullscreen.png` | same | 8 (Web) |
| `cheer_up_banner_5_of_7.png` | `docs/evidence/goldens/garden/.../` | 10 (intervention banner) |
| `cheer_up_banner_3_consec.png` | same | 10 (spare) |
| `breathing_overlay_initial.png` | same | 10 (breathing sheet) |
| `hotline_footer_light.png` / `_dark.png` | same | 10/19 (Tier-3 footer, spare) |
| `plant_tier_group_flourishing/thriving/resting/weathering/storm_season.png` | same | 4 (all-alive tiers, optional) |
| `atmosphere_overlay_bright_sunny/calm_sunny/light_rain/storm.png` | same | 9 (animated atmosphere, optional) |
| `settings_screen_light.png` / `_dark.png` | `docs/evidence/goldens/settings/.../` | 9 (a11y light+dark, optional) |
| `garden_bed_sunflower/lavender/daisy.png` | `docs/evidence/goldens/garden/.../` | 9 (cosmetic skins, optional) |
| `pattern_insight_card_high/medium/disabled.png` | `docs/evidence/goldens/analytics/.../` | spare (Insights) |

> Only a subset is wired into `presentation.tex` by default (Slide 8 cross-platform; Slide 10 intervention). The rest are pre-staged so the team can drop them into the "optional" slots without hunting through `docs/evidence/`.

## Still to capture (team — before the talk)

These are **not** in the repo and are intentionally left as live-demo or fresh-capture items:

- **Live Android Home** with a seeded garden (5+ entries) — for the live demo, not a still.
- **Live Web Home** in Chrome — live demo.
- **Crashlytics dashboard** screenshot — `[CLAUDE_CODE_FILL: capture from Firebase Console before the talk]` (Slide 21; verbal fallback is fine per the checklist).
- **Backup demo videos** (5 clips) — see `evidence-checklist.md`; host unlisted or keep local mp4.

## Architecture diagram

Slide 15 draws the three-layer Clean Architecture diagram **natively in TikZ** inside `presentation.tex` — there is **no** PNG dependency and nothing to capture. (The planning-team's HTML/PNG export referenced in the original brief does not exist in the main tree; TikZ is cleaner and version-controlled.)
