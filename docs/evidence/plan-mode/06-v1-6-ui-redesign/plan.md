# MoodBloom Phone / Tablet / Desktop UI Redesign (v1.6)

> **Window:** 2026-05-26 → 2026-05-28 (3-day redesign sweep on `feat/s5-v1.6-redesign`, post-v1.5 tag).
> **Approved:** 2026-05-26, after a Plan-Mode session that surveyed the Claude Design prototype bundle and mapped each prototype screen to a Flutter target. Implementation proceeded over 3 days of incremental commits with `flutter analyze` between edits (no test runs during the refactor — goldens re-baselined at the end).
> **Outcome target:** v1.6 visual polish wave (the actual surfaces this plan produced now live in the live app — `garden_screen.dart` SkyHeader, two-column `settings_screen.dart`, `skin_shop_screen.dart`, calendar view rework, etc.).

## Context

The user uploaded a Claude Design handoff bundle (`CSC231-234 MoodBloom-handoff.zip`, extracted to `.tmp-handoff/csc231-234-moodbloom/`) containing HTML/CSS/JSX prototypes for phone (390×844), tablet (820×1180), and desktop (1440×900). The bundle defines the canonical visual treatment for v1.6 and adds new content shapes (weekly score card, garden plot grid, global skin model, skin shop) that the current Flutter app doesn't have.

**Goal:** rebuild the Flutter UI so every screen matches the prototype across all three form factors. Honor the user's directives:
- Features in the current Flutter app but **not** in the prototype: keep them, re-place them in the redesigned shell. Don't remove.
- Features in the prototype but **not** in the Flutter app: skip and notify at the end, **except** the skin shop which the user opted into (see Locked Decisions).
- Widget swaps between screens: follow the prototype.
- SVGs: copy exactly (mood glyphs, brand bloom, sun glyph, token gem).
- **No tests run during the refactor.** Migrate pixel-perfect / golden tests at the very end. Per the new CLAUDE.md test-iteration rule, use `flutter analyze` between edits.

The handoff bundle and current app already share design tokens (the prototype's `tokens.css` is 1:1 with the existing `MbColors` / `MoodBloomColors` / `MoodBloomSpacing`). The actual work is **layout + content shape + new global skin model + font bundling + SVG migration**, not a token rewrite.

---

## Locked decisions (from user)

| Question | Decision |
|---|---|
| Patterns window picker | **7d / 14d / 30d** (match prototype; overrides earlier 7/30/90 lock) |
| Home / Garden depth | **Full restructure** — weekly score card + tier banner + 7-day garden plot grid |
| Fonts | **Bundle Fraunces + Nunito via `google_fonts`** |
| Skin model | **Migrate to prototype's global model** — 5 skins (Meadow / Origami / Lantern / Constellation / Crystal) that retheme every mood. Throw away the current per-species catalog. |

---

## Source-of-truth files in the handoff

The plan references these by path; the implementing engineer reads them directly:

| Concern | Handoff file |
|---|---|
| Tokens | `.tmp-handoff/csc231-234-moodbloom/project/shared/tokens.css` |
| SVGs (mood, brand, sun, token) | `.tmp-handoff/.../project/prototype/svgs.jsx` |
| Phone artboard composition | `.tmp-handoff/.../project/prototype/phone.html` |
| Tablet artboard composition | `.tmp-handoff/.../project/prototype/tablet.html` |
| Desktop artboard composition | `.tmp-handoff/.../project/prototype/desktop.html` |
| Shell (bottom nav, side nav, modals) | `.tmp-handoff/.../project/prototype/shell.jsx` |
| Garden + 5 mains | `.tmp-handoff/.../project/prototype/screens.jsx` |
| History / Patterns / Settings / Modals | `.tmp-handoff/.../project/prototype/screens-extra.jsx` |
| Onboarding | `.tmp-handoff/.../project/prototype/onboarding.jsx` |
| 5 global skins (plant SVG variants) | `.tmp-handoff/.../project/prototype/skins.jsx` |
| Skin shop + purchase modal | `.tmp-handoff/.../project/prototype/skin-shop.jsx` |
| Garden tier atmospheres | `.tmp-handoff/.../project/prototype/garden-stages.html` |
| Design system catalog | `.tmp-handoff/.../project/design-system.html` |
| Sample data | `.tmp-handoff/.../project/shared/data.js` |

---

## Phased execution plan

Each phase ends with `flutter analyze`. **No `flutter test` runs until Phase 13.**

### Phase 1 — Foundation: fonts, SVGs, breakpoint constants

**Goal:** ground the rebuild on shared primitives so subsequent phases compose.

1. Add `google_fonts: ^6.x` to `apps/mobile/pubspec.yaml`.
2. Rewrite `packages/design_system/lib/src/widgets/mb_fonts.dart`:
   - `MbFonts.fraunces(...)` → `GoogleFonts.fraunces(...)`
   - `MbFonts.nunito(...)` → `GoogleFonts.nunito(...)`
   - Keep current call-site API; only the resolution changes.
3. Add `packages/design_system/lib/src/widgets/mb_svg.dart` — `CustomPainter` implementations of the 9 prototype SVGs:
   - `MbBrandSvg` (5-petal bloom; tinted by `color`)
   - `MbMoodSvg.happy` / `.calm` / `.okay` / `.sad` / `.angry` / `.anxious` (single `MbMoodSvg(mood: MbMoodKind)` enum-dispatch)
   - `MbSunGlyphSvg` (radial gradient sun, for SkyHeader)
   - `MbTokenGlyphSvg` (gem icon for token balance + skin cost)
   - **All paths copied verbatim** from `svgs.jsx`; sizes via `Size`, colors via `color: currentColor` mapped to `Paint.color`.
4. Add `packages/design_system/lib/src/tokens/breakpoints.dart`:
   ```dart
   abstract final class MbBreakpoints {
     static const double phone = 600;   // < 600
     static const double tablet = 900;  // 600..899
     static const double desktop = 900; // >= 900
     // screen-internal:
     static const double homeWide = 720;       // GardenScreen two-col unlock
     static const double homeDesktop = 1080;   // GardenScreen desktop cap
     static const double logMoodWide = 720;    // LogMoodScreen two-col unlock
     static const double historySidePanel = 720;
     static const double insightsTablet = 600;
     static const double insightsDesktop = 900;
   }
   ```
   Replace scattered literals (`<600`, `<720`, `<900`, `<1080`) across screens with these constants in their respective phases.
5. Export new symbols from `packages/design_system/lib/design_system.dart`.

### Phase 2 — Verify tokens (no-op expected)

Compare `tokens.css` line-by-line against `packages/design_system/lib/src/tokens/colors.dart` and `spacing.dart`. Any drift gets reconciled by editing the Dart side. Expected: zero edits (the tokens were authored against the same spec).

### Phase 3 — Shell chrome (`MbBottomNav` + `MbSideNav`)

**Bottom nav (`apps/mobile/lib/app/widgets/mb_bottom_nav.dart`):**
- Height **70 dp**, padding **8h / 8t / 22b** (already matches).
- Tab structure: 5 items (Home, History, **Add (FAB)**, Patterns, Settings).
- FAB: 52×52 circle, `translateY(-12)`, `var(--mb-seed)` background, white icon (24), shadow `0 6 14 rgba(seed,0.30)`.
- Inactive tab: icon (22) `--mb-text-dim`, label (10 / w500) `--mb-text-dim`.
- Active tab: icon + label `--mb-seed`, label w700.
- Background: `mb.navBg` over `BackdropFilter(blur: 14)`; 1px top border `mb.line`.

**Side nav (`apps/mobile/lib/app/widgets/mb_side_nav.dart`):**
- Width **240 dp** (already matches).
- Brand row: 36×36 gradient icon (linear seed → seedDark) + "MoodBloom" (Fraunces 17 w700).
- Nav items (same 5): icon 18 + label 14 w500; active = `--mb-soft-green` bg + `--mb-text` color + w600; FAB (Add) item paints `--mb-seed` bg + white text always.
- Footer actions: theme toggle, sign-out (`destructive: true`).
- 1px right border `mb.line`.

**App shell (`apps/mobile/lib/app/router.dart` `_AppShell`):**
- Phone (`<600`): bottom nav + edge-to-edge content.
- Tablet (`600..899`): bottom nav + `ConstrainedBox(maxWidth: 720)` centered (was 840).
- Desktop (`>=900`): side nav + content cap **1280 dp**, horizontal padding `24 / 32 / 48` keyed on body width (already aligned).

### Phase 4 — Onboarding refresh

`apps/mobile/lib/features/onboarding/presentation/onboarding_screen.dart` + a new `widgets/onboarding_art.dart` painter file.

Reproduce the 5 slides from `onboarding.jsx` verbatim:

| # | Eyebrow | Title (multiline) | Body excerpt | CTA / Secondary |
|---|---|---|---|---|
| 0 | WELCOME | "A quiet place / for your weather." | "MoodBloom is a garden you tend..." | Begin / Skip intro |
| 1 | LOG WHAT YOU FEEL | "Six moods, / your intensity." | "Tap a mood, set how strongly..." | Got it / Back |
| 2 | WATCH YOUR GARDEN | "Plants never wilt. / Only the weather changes." | "Each entry grows a plant..." | Tell me more / Back |
| 3 | GENTLE NUDGES | "A soft reminder, / once a day." | "MoodBloom can send one gentle notification..." | Allow notifications / Not now |
| 4 | BEFORE YOU START | "Not a substitute / for care." | "MoodBloom is not a medical device..." | I understand / Read full disclaimer |

**Layout:**
- Phone: max 480 dp / padding 20h, 28v.
- Tablet: max 720 / padding 28.
- Desktop: max 960 / padding 28.

**Art slot (260×200 in every form factor):** five new `CustomPainter` subclasses in `onboarding_art.dart`, one per slide. The paths/shapes are described in `onboarding.jsx`; the agent reads them directly and ports to `Canvas` ops (use `Path`, gradient `Paint.shader`, `BlendMode.srcOver`).

**Header:** brand logo (32×32 from `MbBrandSvg`) + "MoodBloom" (Fraunces 17 w700) + slide counter "N / 5" right-aligned (Nunito 12 textDim).

**Footer:** progress dots (8 dp circles, 22 dp pill when active, `mb.seed`/`mb.line`) + MbPrimaryButton (CTA) + MbGhostButton (secondary, 22 dp tall when present).

The notification slide's "Allow notifications" CTA keeps the existing `FcmDatasource.requestPermission()` wiring.

### Phase 5 — Auth screens refresh

Files: `sign_in_screen.dart`, `sign_up_screen.dart`, `screens/forgot_password_screen.dart`.

Refresh to match the prototype's `SignInScreen` / `SignUpScreen` shapes (in `screens-extra.jsx`):
- Centered card, max 420 dp (auth) / 480 dp (forgot password).
- Brand mark (`MbBrandSvg` 48 dp) + "MoodBloom" title (Fraunces 28 w600).
- Subtitle below title.
- Fields use `MbInputField` (already done).
- "Sign in" / "Create account" `MbPrimaryButton`.
- "─ or ─" divider component (port from `_OrDivider` and verify it matches prototype).
- Google sign-in button + (web only, when `kEnableWebauthn`) "Use security key" button.
- Disclaimer footer line.
- Padding 28 dp around the card.

### Phase 6 — Home / Garden full restructure (BIGGEST PIECE)

File: `apps/mobile/lib/features/garden/presentation/garden_screen.dart` + new widgets in `widgets/`.

**New widget files:**
- `widgets/weekly_score_card.dart` — "THIS WEEK" eyebrow + large serif weekly average (e.g. `+0.58`, Fraunces 36 w600) + 7-bar mini chart (Mon..Sun, bar heights from each day's mean score, colored by dominant mood that day) + "weekly average" caption.
- `widgets/weekly_tier_banner.dart` — Tier tagline strip below the score card (e.g. "Thriving - the garden has grown."), Fraunces 18 w600 center-aligned, background tinted by tier.
- `widgets/garden_plot_grid.dart` — 7 daily cards stacked vertically (Mon..Sun). Each card:
  - Header row: weekday + date (Nunito 11 w600 uppercase).
  - Plot art: up to 5 plants (3 front-row full-height 64, 2 back-row smaller 48), colored by mood, rendered via the **new global Skin** (Phase 12) — until Phase 12 lands, use existing flower-species mapping as a placeholder.
  - "+N" overflow pill if day has more than 5 entries.
  - Empty-day placeholder: dashed border + "A quiet day. Empty slots are fine." (Nunito 12 textDim).
  - On tap a plant → existing `PerFlowerDetailModal.show(...)` flow (re-place).

**New SkyHeader treatment (`widgets/sky_header.dart`):**
- Refresh existing `CustomPainter` to match the prototype's tier-specific atmospheres. Each of the 5 tiers (Flourishing / Thriving / Resting / Weathering / Storm) has light + dark variants with distinct sky art:
  - Flourishing light: bright sun (radial gradient via `MbSunGlyphSvg`) + 14 rays + 3 cloud clusters + butterflies. Dark: aurora wisps + fireflies + starfield.
  - Thriving light: moderate sun + soft clouds. Dark: stars + full moon + cloud bank + bat silhouettes.
  - Resting light: sun-behind-cloud + soft clouds. Dark: crescent moon + cloud bank.
  - Weathering light: overcast + wind-blown leaves + wind wisps. Dark: heavy night clouds + single star + dark leaves.
  - Storm light: dark storm clouds + 36 diagonal rain lines + rainbow arc. Dark: same shape, darker palette.
- All shapes traced from `screens.jsx` and `garden-stages.html`. The agent reads those files and ports to Flutter `Canvas` ops.

**Composition order (top → bottom):**
1. `SkyHeader` (full-bleed atmospheric hero)
2. `WeeklyScoreCard`
3. `WeeklyTierBanner`
4. `CheerUpBanner` (RE-PLACED — was higher up, now sits after the tier banner when pattern fires)
5. `GardenPlotGrid` (7 daily cards)
6. `DailyScoreStrip` (RE-PLACED — collapsed into a "TODAY" `MbCard` between grid and recent moods; preserves the today-only intensity-bar feature)
7. Recent moods preview (RE-PLACED — bottom of the scroll surface, max 4 `MoodEntryTile` rows)
8. `HotlineFooter` (RE-PLACED — pinned at the bottom of the scroll surface; appears only after the 10-day threshold, unchanged behaviour)

**Responsive:**
- Phone (`<MbBreakpoints.homeWide`): single column.
- Tablet (`>=720, <1080`): 2-col grid (60 / 40) — left = SkyHeader + WeeklyScoreCard + TierBanner; right = GardenPlotGrid + DailyScoreStrip + Recent.
- Desktop (`>=1080`): same 2-col, outer `ConstrainedBox(maxWidth: 1100)`, page padding 32.

**Floating action button (Add) on phone:** existing center-tab in `MbBottomNav` stays the same. Desktop has the Add item in the sidebar.

### Phase 7 — Log Mood refresh

File: `apps/mobile/lib/features/mood/presentation/log_mood_screen.dart` (+ widgets/).

- Title: "How are you feeling?" (Fraunces 26 w600).
- **Mood grid:** 6 cells in 3×2 grid. Each cell uses `MbMoodSvg(mood: kind)` icon (28 dp) + label (Nunito 12 w600). Selected = tinted bg (mood color @ 13%) + colored border (mood color @ 33%); unselected = `mb.card` bg + `mb.line` border.
- **Intensity slider:** 5-step, ticks at 1..5, fill color = mood color (or `mb.seed` if no mood selected). Scale labels: "barely" ↔ "quite a bit".
- **Note field:** `MbInputField` with label "NOTE (OPTIONAL)" + placeholder "What's on your mind? (you can skip this)".
- **Attach row:** existing `MediaPickerButton` (RE-PLACED — same widget, refreshed style).
- **Save button:** "Save to your garden" (`MbPrimaryButton` with leading check icon).
- **Disclaimer:** "Tokens are earned for showing up. Empty days are fine." (Nunito 12 textDim).

**Responsive:**
- Phone: single column.
- Tablet+ (`>=MbBreakpoints.logMoodWide`): 2 col — left (mood grid + slider) / right (note + attach + save).
- Outer cap: 1080 dp on desktop.

**Edit mode:** existing `?edit=` query param continues to hydrate the form (RE-PLACED unchanged).
**AI suggestion pill:** existing widget keeps its placement above the note field (RE-PLACED).

### Phase 8 — History refresh

File: `apps/mobile/lib/features/history/presentation/history_screen.dart` + `calendar_view.dart` + `widgets/`.

**Header:** "History" (Fraunces 24 w600) + `MbSegmentedToggle<HistoryTab>` (List / Calendar / Harvest). Below 520 dp: title + toggle stack vertically.

**List view:**
- Filter chips row: "This week" (selected) / "This month" / "All time". Use `MbFilterChip`.
- Day sections (reverse chrono):
  - Day header: "SUN · APR 28" (Nunito 11 w600 uppercase textDim).
  - If empty: dashed `MbCard` with copy "A quiet day. Empty slots are fine."
  - If entries: stacked `MoodEntryTile`s. Tile: mood chip (icon + intensity dots) | excerpt | lock badge (if >24h) | chevron-right.

**Calendar view (`calendar_view.dart`):**
- 5-week month grid, single calendar card with 16 dp padding.
- Month header: month name + nav chevrons.
- Day cells (1:1 aspect ratio): mood icon mini (10 dp) + date number (12 dp), tinted by mood. Today gets outlined.
- Phone (`<historySidePanel`): tapping a day opens a `DayEntriesSheet` (bottom sheet).
- Tablet+ (`>=720`): split layout — calendar (flex 5) + day-entries side panel (flex 4).

**Harvest view (`weekly_harvests_tab.dart`):**
- Archived weekly summaries listed as cards. Each card: week range, dominant mood, mini garden preview, tap → `ArchivedWeekScreen`.

### Phase 9 — Patterns refresh

File: `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart`.

- Header: "Patterns" (Fraunces 24) + subtitle "A gentle read of how your garden has been moving lately."
- **Window picker:** `MbSegmentedToggle<InsightWindowPreset>` with **7d / 14d / 30d** (per locked decision).
  - In `lib/features/insights/domain/entities/insight_window.dart`: drop `quarter` enum value, restore `fortnight`, keep `week` and `month`. Default = `fortnight` (matches prototype's middle tab).
  - Update `_QuickStatsRow._windowDays` switch.
  - Update `analytics_screen_test.dart` assertions to expect 7d / 14d / 30d (deferred until Phase 13).
- **Line chart card:** "MOOD SCORE · LAST 14 DAYS" eyebrow + `MbConfidenceBadge` (high/medium/low) + 600×140 dp `MoodScoreChart` SVG. Baseline at y=0; positive moods above, negative below. Shaded area below curve.
- **Disclaimer banner** (pre-ack) OR **Pattern check-ins card** (post-ack) — current logic unchanged, refresh visual treatment to match prototype.
- **Recent triggers card** (post-ack only).
- **AI PatternInsightCard** — Remote Config gated, keep as-is.
- **Quick stats row** (3 cards: most-frequent mood / avg intensity / day streak).
- **Tier band legend** + **Chart reading guide** (collapsed on phone via `ExpansionTile`, expanded on tablet+).

**Responsive:**
- Phone: single column scroll.
- Tablet (`>=600, <900`): 2-col above the chart (guide+chips left, legend+triggers right); chart full-width below.
- Desktop (`>=900`): 3-col grid (reading guide / legend / recent triggers) under the full-width chart.

### Phase 10 — Settings refresh

File: `apps/mobile/lib/features/settings/presentation/settings_screen.dart`.

Section labels (uppercase 11 dp Nunito w600), order top-to-bottom:
1. **ACCOUNT** — email + sign-out
2. **GARDEN** — "Customize" link → opens Skin Shop (new in Phase 12); "Equipped: {skin name}" subtitle
3. **PRIVACY** — `PrivacyLockSettingsTile` + WebAuthn tile (web only) RE-PLACED
4. **NOTIFICATIONS** — cheer-up toggle + 3 tier toggles RE-PLACED
5. **SYNC** — last sync status, sync-now button, cellular toggle (RE-PLACED, native only `if (!kIsWeb)`)
6. **THEME** — radio rows: Light / Dark / Follow device / Follow device time
7. **DISCLAIMER** — AI suggestion card with locked text RE-PLACED
8. **ABOUT** — version, build, links
9. **DELETE ACCOUNT** — destructive zone with 2-step `DeleteAccountDialog` RE-PLACED

Debug zone (`if (kDebugMode)`):
- "Cycle plant tier" (shortened per earlier session) RE-PLACED
- "Force harvest" RE-PLACED
- "Clear local cache" RE-PLACED
- "Crash now" RE-PLACED
- "Grant tokens" RE-PLACED

**Responsive:** phone = single column; tablet+ (`>=600`) = 2-col grid where each section is a card. Desktop content cap = the shell's 1280 dp.

### Phase 11 — Modals & flows refresh

All modals follow the prototype's `ModalFrame` rule:
- Phone (`<600`): `showModalBottomSheet` (92% height, 14 dp top-corner radius, full width).
- Tablet+ (`>=600`): `showDialog` with `ConstrainedBox(maxWidth: 560)` (or 640 for SkinModalSheet), 86% height.

Files to refresh visually (no logic change):
- `weekly_summary_screen.dart` — already a `MaterialPageRoute`; refresh visual treatment per `HarvestScreen` in `screens-extra.jsx`.
- `entry_detail_screen.dart` — refresh layout per `EntryDetailScreen` in the prototype.
- `intervention/presentation/screens/breathing_screen.dart` — refresh per `BreathingScreen` prototype.
- `intervention/presentation/screens/journaling_prompt_screen.dart` — RE-PLACED, visual refresh only (prototype has no Tier-2 modal, this is an existing feature kept).
- `intervention/presentation/screens/crisis_resources_screen.dart` — RE-PLACED, visual refresh only.
- `intervention/presentation/widgets/intervention_banner.dart` — refresh card treatment per prototype.
- `auth/presentation/screens/privacy_lock_screen.dart` — refresh per `PrivacyLockScreen` prototype (already cold-boot scoped).
- `auth/presentation/screens/privacy_setup_flow_screen.dart` — RE-PLACED, visual refresh only.
- `disclaimer/presentation/widgets/disclaimer_ack_dialog.dart` — refresh dialog treatment.
- `settings/presentation/widgets/delete_account_dialog.dart` — RE-PLACED, visual refresh only.
- `garden/presentation/widgets/per_flower_detail_modal.dart` — RE-PLACED, visual refresh only.

### Phase 12 — Skin model migration (USER OPTED IN)

**This is the largest non-Home phase.** Throw away the per-species `SkinCatalog`, build the prototype's global model.

**New domain:**
- `lib/features/tokens/domain/entities/garden_skin.dart` — new entity: `GardenSkin { skinId, displayName, tagline, cost, paletteSeed }`. Five values: `meadow` (default, free), `origami` (12 tokens), `lantern` (20), `constellation` (30), `crystal` (40, locked behind "Reach the Flourishing tier").
- `lib/features/tokens/domain/services/garden_skin_catalog.dart` — replaces `skin_catalog.dart`. Static const list of 5 skins.
- `lib/features/tokens/domain/entities/skin_state.dart` — rewrite: track `equippedSkinId: String` and `unlockedSkinIds: Set<String>` (Meadow always unlocked).

**New SVG plant variants** (`packages/design_system/lib/src/widgets/mb_skin_plants.dart`):
- Five skin painters × six moods × variable intensity = 30 mood-plant variants.
- Sources from `skins.jsx`: Meadow (current plant shapes), Origami (folded paper), Lantern (hanging paper lanterns), Constellation (dashed stems + star clusters), Crystal (faceted gems).
- API: `MbSkinPlant(skin: GardenSkin, mood: MbMoodKind, intensity: int, color: Color)`.

**Migration of existing per-species code:**
- Delete `lib/features/tokens/domain/services/skin_catalog.dart` (the 20-entry per-species catalog).
- Update all callers: `garden_bed.dart`, `skin_modal_sheet.dart`, `flower_sprite.dart`, `skin_state_storage.dart`, etc.
- Skin state storage (Firestore + Drift): keep field `unlockedSkins` as a `List<String>` of skin ids, just with different ids (`meadow` / `origami` / etc instead of `sunflower_sunset` / etc). On migration, treat all existing per-species ids as if the user has Meadow only (the new defaults); they keep their balance.

**New skin shop screen:**
- File: `lib/features/tokens/presentation/screens/skin_shop_screen.dart`.
- Route: add `/garden/skins` (or similar) to `router.dart`; reachable from Settings → GARDEN card.
- Layout per `skin-shop.jsx`:
  - Header: "Customize your garden" (Fraunces 26) + subtitle + token balance pill (top-right).
  - Currently Equipped section: 80×80 preview window + 6 mood plants row + skin name + tagline (soft green card).
  - Skin Library grid: phone 1col / tablet 2col / desktop 3col. Each card: 3-plant preview window + skin name + price badge + tagline + action button (Equip / Equipped / Purchase / Need more tokens / Locked).
  - Disclaimer footer: "Skins are cosmetic only. Your entries and history are never affected."

**New purchase confirmation modal:**
- `widgets/skin_purchase_confirm_sheet.dart`.
- Layout per `SkinPurchaseConfirmScreen` in `skin-shop.jsx`: 120×120 preview + skin name + tagline + cost breakdown card (current balance, cost, after) + "Purchase & equip" primary button + "Maybe later" ghost.

**Replace `skin_modal_sheet.dart`:**
- Rewrite to show the 5 global skins in a grid (or just link out to the full Skin Shop screen). The current per-species sheet goes away.

### Phase 13 — Test migration (END only)

Per user directive: skip tests until Phase 12 is complete. Then:

1. `flutter analyze` clean across the whole app.
2. Update tests broken by:
   - `InsightWindowPreset` enum change (drop `quarter`, restore `fortnight`).
   - `_WindowChips` label change (90d → 14d).
   - Skin model migration (per-species → global). Many `skin_catalog_test.dart`, `flower_sprite_test.dart`, `skin_modal_sheet_test.dart` files affected.
   - Home screen widget rebuild (existing `garden_screen_test.dart` if any).
   - Onboarding art tests (if any).
3. Pixel-perfect / golden tests:
   - Re-baseline goldens by running `flutter test --update-goldens --tags=golden` in the touched feature directories.
   - Note: per CLAUDE.md test rule + the user's instruction, this is the only point we run goldens.
4. Run `flutter test --concurrency=8 --exclude-tags=golden,shader` once to confirm green.
5. Run goldens separately: `flutter test --tags=golden --update-goldens` then a confirm pass.

---

## Re-placement map (current features → new shell location)

| Current feature | New placement |
|---|---|
| `CheerUpBanner` | Home, after WeeklyTierBanner (was above DailyScoreStrip) |
| `DailyScoreStrip` | Home, collapsed into a "TODAY" `MbCard` between grid and recent moods |
| Recent moods preview | Home, bottom of scroll |
| `HotlineFooter` | Home, pinned bottom (10-day threshold gate unchanged) |
| `PerFlowerDetailModal` | Triggered from `GardenPlotGrid` plants (was `GardenBed`) |
| `WeeklySummaryScreen` popup | Auto-launched via `pendingWeeklySummaryProvider` (unchanged behaviour) |
| `PrivacyLockScreen` | Cold-boot gate (unchanged) |
| `PrivacySetupFlowScreen` | Modal from Settings → PRIVACY (unchanged) |
| WebAuthn tile | Settings → PRIVACY, web only (unchanged) |
| Cycle plant tier debug | Settings → DEBUG (kDebugMode only, unchanged) |
| Edit-mode log mood | `/log-mood?edit=<id>` (unchanged) |
| `DeleteAccountDialog` | Settings → DELETE ACCOUNT zone (unchanged) |
| `ForgotPasswordScreen` | Reachable from Sign-in (unchanged) |
| Tier-2 `JournalingPromptScreen` | Reachable from `CheerUpBanner` / `InterventionBanner` (unchanged) |
| Tier-3 `CrisisResourcesScreen` | Same (unchanged) |
| AI mood suggestion pill | Log Mood, above the note field (unchanged) |
| `DisclaimerAckDialog` | Triggered by inline banner tap in Patterns (unchanged) |

Every existing feature has a destination; nothing gets orphaned.

---

## Features in the prototype but NOT in the current Flutter app — skip + notify at end

Even with the skin model migration opted-in, several prototype additions are out of scope for this redesign and will be flagged in the final report:

- **Garden tier atmosphere refinements** beyond what the existing `SkyHeader`/`AtmosphereOverlay` painters can express — specifically the prototype's butterflies, fireflies, aurora wisps, bat silhouettes, wind-blown leaves with rotation. Phase 6 implements the BASE tier art; advanced creatures/particles are listed as follow-ups.
- **Toast notification frame** (`ToastFrame` in `screens-extra.jsx`) — the prototype shows a brand-chip top-anchored toast. Current app uses Material `SnackBar` + a basic `MbAppToast`. Not migrating to the prototype's full toast frame unless trivial.
- **Sample-data scenarios** (`data.js` has 5 sample weeks) — not relevant to production.
- **Prototype's design-canvas chrome** (Storybook-ish artboard host) — irrelevant.

---

## Files to add / modify (representative — pattern repeats)

**New files:**
- `packages/design_system/lib/src/widgets/mb_svg.dart` (Brand + 6 moods + Sun + Token)
- `packages/design_system/lib/src/widgets/mb_skin_plants.dart` (5 skins × 6 moods × intensity)
- `packages/design_system/lib/src/tokens/breakpoints.dart`
- `apps/mobile/lib/features/garden/presentation/widgets/weekly_score_card.dart`
- `apps/mobile/lib/features/garden/presentation/widgets/weekly_tier_banner.dart`
- `apps/mobile/lib/features/garden/presentation/widgets/garden_plot_grid.dart`
- `apps/mobile/lib/features/onboarding/presentation/widgets/onboarding_art.dart` (5 painters)
- `apps/mobile/lib/features/tokens/domain/entities/garden_skin.dart`
- `apps/mobile/lib/features/tokens/domain/services/garden_skin_catalog.dart`
- `apps/mobile/lib/features/tokens/presentation/screens/skin_shop_screen.dart`
- `apps/mobile/lib/features/tokens/presentation/widgets/skin_purchase_confirm_sheet.dart`

**Renamed / deleted:**
- Delete `lib/features/tokens/domain/services/skin_catalog.dart` (replaced by `garden_skin_catalog.dart`)
- Delete every `*_skin.dart` per-species entry's tests once the catalog is gone.

**Modified (representative):**
- `apps/mobile/pubspec.yaml` (+ `google_fonts`)
- `packages/design_system/lib/src/widgets/mb_fonts.dart` (use google_fonts)
- `packages/design_system/lib/design_system.dart` (re-export new widgets)
- `apps/mobile/lib/app/router.dart` (add `/garden/skins` route; minor _AppShell tweaks)
- `apps/mobile/lib/app/widgets/mb_bottom_nav.dart`, `mb_side_nav.dart` (visual refresh)
- `apps/mobile/lib/features/garden/presentation/garden_screen.dart` (full rewrite)
- `apps/mobile/lib/features/garden/presentation/widgets/sky_header.dart` (5-tier atmosphere refresh)
- `apps/mobile/lib/features/onboarding/presentation/onboarding_screen.dart` (copy + art swap)
- `apps/mobile/lib/features/auth/presentation/sign_in_screen.dart` + `sign_up_screen.dart` + `screens/forgot_password_screen.dart`
- `apps/mobile/lib/features/mood/presentation/log_mood_screen.dart` + its widgets
- `apps/mobile/lib/features/history/presentation/history_screen.dart` + `calendar_view.dart`
- `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart`
- `apps/mobile/lib/features/insights/domain/entities/insight_window.dart` (enum back to week/fortnight/month; drop `quarter`)
- `apps/mobile/lib/features/settings/presentation/settings_screen.dart`
- `apps/mobile/lib/features/intervention/presentation/widgets/intervention_banner.dart` + screens
- `apps/mobile/lib/features/harvest/presentation/weekly_summary_screen.dart` + `archived_week_screen.dart`
- `apps/mobile/lib/features/history/presentation/entry_detail_screen.dart`
- `apps/mobile/lib/features/garden/presentation/widgets/per_flower_detail_modal.dart`
- `apps/mobile/lib/features/auth/presentation/screens/privacy_lock_screen.dart` + `privacy_setup_flow_screen.dart`
- `apps/mobile/lib/features/disclaimer/presentation/widgets/disclaimer_ack_dialog.dart`
- `apps/mobile/lib/features/settings/presentation/widgets/delete_account_dialog.dart`
- `apps/mobile/lib/features/tokens/presentation/widgets/skin_modal_sheet.dart` (rewrite for new global model)
- `apps/mobile/lib/features/garden/presentation/widgets/garden_bed.dart` (uses new `MbSkinPlant`)
- `apps/mobile/lib/features/garden/presentation/widgets/flower_sprite.dart` (uses new `MbSkinPlant`)
- All other callers of the old per-species skin types

**Test updates (END only, Phase 13):**
- Many skin/catalog/sprite tests get rewritten or deleted.
- Window picker test (`analytics_screen_test.dart`): 90d → 14d.
- Onboarding tests if any (copy strings change).
- Golden tests get re-baselined.

---

## Verification

1. **`flutter analyze`** between every phase, must be clean at each handoff.
2. **`dart format .`** before commit.
3. **At Phase 13 only:**
   - `flutter test --concurrency=8 --exclude-tags=golden,shader` — must pass.
   - `flutter test --tags=golden --update-goldens` followed by a clean pass.
4. **Manual smoke** at three widths after Phase 6, Phase 10, and at the very end:
   - 390 dp (phone)
   - 820 dp (tablet)
   - 1440 dp (desktop)
   - Light theme + dark theme.
5. **Final commit** as ONE bundle on `feat/s5-v1.5-final` (or a new branch — see Open Question below): `feat(v1.6): Phone/Tablet/Desktop UI redesign per Claude Design handoff`.

---

## Open question for the implementer

This redesign is large enough that I'm going to push back to the user one more time before starting: do they want a single commit at the very end (consistent with the recent v1.5.1 bundle pattern), or phase-by-phase commits (better for review but more bookkeeping)? Default: single bundle, since they earlier said "bundled PR for related refactors."

## Final-report content (for the end of execution)

When everything ships, the post-execution summary must include:

- ✅ What was implemented (Phases 1-12 status, file counts).
- ⚠️ "Skip + notify" list (the prototype additions deferred — toast frame, sample data scenarios, advanced atmosphere particles).
- ⚠️ Any other deviations from prototype (with rationale).
- 🧪 Test status (analyze, regular tests, goldens — and re-baselined goldens noted).
- 📐 Manual smoke results at phone / tablet / desktop, light + dark.
- 🚧 Known follow-ups for v1.6.1.
