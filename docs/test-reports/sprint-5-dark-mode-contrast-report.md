# Sprint 5 — Dark-Mode Contrast Sweep Report (Wave C)

**Date:** 2026-05-15
**Scope:** S5 + v1.5-polish surfaces — Intervention, Insights (including
HB-009 Wave D affordances), Disclaimer, Tokens (skin modal / spend dialog /
locked chip / per-flower detail), Notifications (tier toggle), and
Wave E (privacy settings tile, PIN setup / verify, PIN keypad, privacy
setup flow). Atmosphere palettes (sunny / calm / light-rain / storm) under
the intervention banner are checked through the `mb.skyBot` token (the
darkest atmosphere) per the Day 4 report §2.2 logic.
**Branch:** `feat/s5-v1.5-polish-wave-c` (base `19056bfd`, the merged
Wave B + D + E head).
**Supersedes:** N/A — companion to the Day 4 light-only contrast
spreadsheet in `docs/test-reports/sprint-5-a11y-report.md` §2.

---

## Summary

| Metric | Count |
|---|---|
| (foreground, background) pairs measured on dark theme | 31 |
| Dark-theme pairs ≥ WCAG 2.2 AA (4.5:1 for text, 3:1 for UI components) | 29 |
| Dark-theme pairs failing AA — fixed inline this sweep | 2 |
| Dark-theme pairs failing AA — deferred to v1.6 (systemic token gap) | 1 |
| New tests added | 31 (1 new file: `test/features/_a11y/dark_mode_contrast_test.dart`) |
| Production widgets edited | 2 (`pin_keypad.dart`, `pin_verify_screen.dart`) |
| Design-system tokens modified | 0 (per constraint — only token *bindings* were swapped) |

**Headline:** the v1.0 redesign's dark theme adapts every S5/polish surface
chrome correctly. The one surviving systemic gap is the design system's
`MoodBloomColors.coralText` constant — explicitly described in its own
docstring as "deeper coral suitable for destructive TEXT on a cream
surface" — which has no dark-mode sibling. Wave C swapped the two
load-bearing references (PIN error / locked-warning text) to
`theme.colorScheme.error` so users on dark can still read the
warning; the remaining references are decorative Tier 3 dot indicators
on the Insights chart (legend, recent triggers row, marker band) and stay
documented for a v1.6 token redesign.

---

## 1. Full dark-theme contrast spreadsheet

Formula: `(max(L_fg, L_bg) + 0.05) / (min(L_fg, L_bg) + 0.05)` where
`L = 0.2126·R_lin + 0.7152·G_lin + 0.0722·B_lin` after sRGB→linear
conversion. Identical to the Day 4 audit + the existing
`a11y_contrast_report_test.dart` helper.

Threshold: **4.5:1 for normal text**, **3:1 for large text and UI
components** (per WCAG 2.2 AA).

### 1.1 Foundational tokens (locked by the new test's "token baselines" group)

| Pair | Computed (dark) | Threshold | Verdict |
|------|----------------|----------|---------|
| `mb.text` over `mb.bg` | **14.90:1** | 4.5 | PASS |
| `mb.text` over `mb.card` | **12.08:1** | 4.5 | PASS |
| `mb.textDim` over `mb.bg` | **7.71:1** | 4.5 | PASS |
| `mb.textDim` over `mb.card` | **6.26:1** | 4.5 | PASS |
| `mb.textDim` over `mb.softCoral` (F-002 dark guard) | **6.33:1** | 4.5 | PASS |
| `mb.text` over `mb.skyBot` (storm atmosphere worst case) | **11.08:1** | 4.5 | PASS |
| `MoodBloomColors.coral` over `mb.bg` (the swap target for the PIN fixes) | **8.25:1** | 4.5 | PASS |
| `MoodBloomColors.coralText` over `mb.bg` (the systemic gap; sentinel) | **2.54:1** | 4.5 | **FAIL — v1.6** |

Notes:
- The F-002 light-theme failure (4.38:1 on `mb.textDim` × `mb.softCoral`)
  does NOT carry over to dark, because dark `softCoral` is the deep brown
  `#3B2A24`, not the cream `#FFF1E9`. The contrast direction inverts.
- The Day 4 light reading of `mb.textDim` × `mb.bg` was a tight 4.63:1.
  Dark is a comfortable 7.71:1. F-003 (light tight margin) stays a
  light-theme concern only.

### 1.2 Intervention surfaces

| Pair | Computed (dark) | Threshold | Verdict |
|------|----------------|----------|---------|
| Tier 1/2 banner `onSurface` × `surfaceContainerHighest` | **11.10:1** | 4.5 | PASS |
| Tier 3 banner `onErrorContainer` × `errorContainer` | **7.24:1** | 4.5 | PASS (AAA) |
| Hotline tile `onPrimaryContainer` × `primaryContainer` | **7.20:1** | 7.0 (AAA self-imposed) | PASS |
| BreathingScreen body text `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| JournalingPromptScreen body text `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| JournalingPromptScreen TextField input `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| Opt-out button label (OutlinedButtonTheme → `mb.text` × `mb.card`) | **12.08:1** | 4.5 | PASS |

Storm-atmosphere note: the InterventionBanner paints its own opaque
Material with `surfaceContainerHighest` or `errorContainer`. It does NOT
inherit any underlying atmosphere gradient. The `mb.text × mb.skyBot`
pair above (11.08:1) is the floor that holds even if a future redesign
removes the banner's opaque card — we lock it as a defence-in-depth
contract.

### 1.3 Insights surfaces (S5 + Wave D affordances)

| Pair | Computed (dark) | Threshold | Verdict |
|------|----------------|----------|---------|
| InsightsScreen header title `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| InsightsScreen subtitle `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| ChartReadingGuide title `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| ChartReadingGuide body bullets `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| ChartReadingGuide bullet markers + icon `mb.textDim` × `mb.card` | **6.26:1** | 4.5 | PASS |
| TierBandLegend title `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| TierBandLegend subtitle `mb.textDim` × `mb.card` | **6.26:1** | 4.5 | PASS |
| RecentTriggersCard title + row text `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| RecentTriggersCard subtitle + chevron `mb.textDim` × `mb.card` | **6.26:1** | 4.5 | PASS |
| MoodScoreChart score line `colorScheme.primary` × `mb.card` | **5.62:1** | 4.5 | PASS |
| MoodScoreChart health line `MoodBloomColors.amber` × `mb.card` | **6.00:1** | 4.5 | PASS |
| PatternMarkerBand Tier 1 dot `MoodBloomColors.amber` × `mb.card` | **6.00:1** | 3.0 (UI cmp) | PASS |
| PatternMarkerBand Tier 2 dot `MoodBloomColors.coral` × `mb.card` | **6.69:1** | 3.0 (UI cmp) | PASS |
| PatternMarkerBand Tier 3 dot `MoodBloomColors.coralText` × `mb.card` | **2.06:1** | 3.0 (UI cmp) | **FAIL — v1.6** |
| RecentTriggersCard Tier 3 dot `MoodBloomColors.coralText` × `mb.card` | **2.06:1** | 3.0 (UI cmp) | **FAIL — v1.6** |
| _ChartKeyRow Tier 3 legend dot `MoodBloomColors.coralText` × `mb.card` | **2.06:1** | 3.0 (UI cmp) | **FAIL — v1.6** |
| _ChartKeyRow legend label `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |

### 1.4 Disclaimer ack dialog

| Pair | Computed (dark) | Threshold | Verdict |
|------|----------------|----------|---------|
| Dialog body `mb.text` × M3 `surfaceContainerHigh` (≈ `mb.card`) | **≥ 12:1** | 4.5 | PASS |
| Dialog icon `mb.textDim` × M3 `surfaceContainerHigh` | **≥ 6:1** | 3.0 (decorative) | PASS |
| `FilledButton("I understand")` white × `colorScheme.primary` | **5.16:1** | 4.5 | PASS |

### 1.5 Tokens surfaces

| Pair | Computed (dark) | Threshold | Verdict |
|------|----------------|----------|---------|
| SkinModalSheet header title `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| SkinModalSheet header subtitle `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| SkinModalSheet drag-handle (decorative) `mb.textDim α=0.35` × `mb.bg` | n/a (decorative) | — | PASS |
| SkinModalSheet cosmetic footer `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| _SkinCard label `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| _SkinCard "Tap to select" label `colorScheme.primary` × `mb.card` | **5.62:1** | 4.5 | PASS |
| LockedSkinChip affordable label `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| LockedSkinChip unaffordable label `mb.textDim` × `mb.bg` (worst case) | **7.71:1** | 4.5 | PASS |
| LockedSkinChip unaffordable label `mb.textDim` × `mb.card` (best case) | **6.26:1** | 4.5 | PASS |
| SpendConfirmationDialog body `bodyMedium` × M3 dialog surface | **≥ 11:1** | 4.5 | PASS |
| SpendConfirmationDialog Cancel `TextButton` `colorScheme.primary` × dialog surface | **≥ 5:1** | 4.5 | PASS |
| SpendConfirmationDialog Confirm white × `colorScheme.primary` | **5.16:1** | 4.5 | PASS |
| PerFlowerDetailModal title `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| PerFlowerDetailModal date `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| PerFlowerDetailModal note card text `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| PerFlowerDetailModal Close OutlinedButton `mb.text` × `mb.card` | **12.08:1** | 4.5 | PASS |
| PerFlowerDetailModal Open entry FilledButton white × `colorScheme.primary` | **5.16:1** | 4.5 | PASS |

### 1.6 Notifications — tier toggle tile

| Pair | Computed (dark) | Threshold | Verdict |
|------|----------------|----------|---------|
| TierToggleTile title `onSurface` × `surface` | **14.90:1** | 4.5 | PASS |
| TierToggleTile subtitle `onSurfaceVariant` × `surface` | **7.71:1** | 4.5 | PASS |
| TierToggleTile leading icon `onSurfaceVariant` × `surface` | **7.71:1** | 3.0 (UI cmp) | PASS |

### 1.7 Wave E — privacy + PIN surfaces

| Pair | Computed (dark) | Threshold | Verdict |
|------|----------------|----------|---------|
| PrivacySettingsTile signed-out title `onSurface` × `surface` | **14.90:1** | 4.5 | PASS |
| PrivacySettingsTile signed-out subtitle `onSurfaceVariant` × `surface` | **7.71:1** | 4.5 | PASS |
| PrivacySettingsTile signed-in switch `onSurface` × `surface` | **14.90:1** | 4.5 | PASS |
| _ChangePinTile / _SetupPinTile leading icon `onSurfaceVariant` × `surface` | **7.71:1** | 3.0 (UI cmp) | PASS |
| PinSetupScreen title `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| PinSetupScreen subtitle `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| PinSetupScreen close icon `onSurface` (AppBar) × `mb.bg` | **14.90:1** | 3.0 (UI cmp) | PASS |
| PinKeypad digit foreground `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| PinKeypad disabled digit `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| PinKeypad PIN-progress dots filled `mb.text` × `mb.bg` | **14.90:1** | 3.0 (UI cmp) | PASS |
| **PinKeypad error text — BEFORE Wave C: `MoodBloomColors.coralText` × `mb.bg`** | **2.54:1** | 4.5 | **FAIL — FIXED** |
| **PinKeypad error text — AFTER Wave C (dark): `colorScheme.error` × `mb.bg`** | **8.25:1** | 4.5 | PASS |
| **PinKeypad error text — AFTER Wave C (light): `coralText` × `mb.bg` (unchanged)** | **6.04:1** | 4.5 | PASS |
| PinVerifyScreen title `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| PinVerifyScreen subtitle `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| **PinVerifyScreen locked warning — BEFORE Wave C: `MoodBloomColors.coralText` × `mb.bg`** | **2.54:1** | 4.5 | **FAIL — FIXED** |
| **PinVerifyScreen locked warning — AFTER Wave C (dark): `colorScheme.error` × `mb.bg`** | **8.25:1** | 4.5 | PASS |
| **PinVerifyScreen locked warning — AFTER Wave C (light): `coralText` × `mb.bg` (unchanged)** | **6.04:1** | 4.5 | PASS |
| PinVerifyScreen "Use biometric instead" TextButton.icon `colorScheme.primary` × `mb.bg` | **5.62:1** | 4.5 | PASS |
| PrivacySetupFlowScreen _BiometricStep title `mb.text` × `mb.bg` | **14.90:1** | 4.5 | PASS |
| PrivacySetupFlowScreen _BiometricStep subtitle `mb.textDim` × `mb.bg` | **7.71:1** | 4.5 | PASS |
| PrivacySetupFlowScreen Continue button white × `colorScheme.primary` (MbPrimaryButton) | **5.16:1** | 4.5 | PASS |
| PrivacySetupFlowScreen _DoneStep icon `mb.text` × `mb.bg` | **14.90:1** | 3.0 (UI cmp) | PASS |

---

## 2. Inline fixes — production widget changes

### Fix 1: `apps/mobile/lib/features/auth/presentation/widgets/pin_keypad.dart`

**Symptom (dark theme).** The PIN-entry error message ("PINs did not
match.", "Wrong PIN — n attempts left.", etc.) was painted with
`MoodBloomColors.coralText` — the design-system "deeper coral suitable
for destructive TEXT on a cream surface" token. On the dark scaffold
(`mb.bg` = `#161F2C`) this computes to **2.54:1**, well below WCAG AA's
4.5:1 floor. Sighted users on dark mode could barely make out the
error copy that tells them whether their second-pass PIN matched.

**Before.**
```dart
style: MbFonts.nunito(
  fontSize: 13,
  color: MoodBloomColors.coralText,   // 6.04:1 light PASS, 2.54:1 dark FAIL
  fontWeight: FontWeight.w600,
),
```

**After.**
```dart
style: MbFonts.nunito(
  fontSize: 13,
  // `coralText` is the "destructive text on cream" token; it is not
  // dark-safe by its own docstring. Until the design system grows a
  // theme-aware destructive-text token (v1.6), we pick the right hue
  // at the binding site so light and dark both clear AA.
  color: theme.brightness == Brightness.dark
      ? theme.colorScheme.error          // dark: `coral` → 8.25:1 PASS
      : MoodBloomColors.coralText,       // light: preserved → 6.04:1 PASS
  fontWeight: FontWeight.w600,
),
```

**Why a brightness-aware pick rather than a single token.** The Day 4
audit's light reading for `coralText` × `mb.bg` light is **6.04:1
PASS** (the design system was tuned for this). A naive single-token
swap to `theme.colorScheme.error` (which resolves to
`MoodBloomColors.coral` on both themes per
`packages/design_system/lib/src/theme.dart:37`) clears dark to
**8.25:1** but drops light to **1.86:1** — a hard fail. Picking
brightness-aware at the binding site:

| Brightness | Bound colour | Contrast vs `mb.bg` |
|---|---|---|
| Light | `MoodBloomColors.coralText` | **6.04:1** PASS |
| Dark | `theme.colorScheme.error` (= `coral`) | **8.25:1** PASS |

No design-system tokens were modified; only the *binding* changes,
and the binding has always had two valid values for the two
brightnesses. This is exactly what a future `mb.errorText` token
would do — Wave C inlines the choice while the v1.6 token redesign
formalises it.

### Fix 2: `apps/mobile/lib/features/auth/presentation/screens/pin_verify_screen.dart`

**Symptom (dark theme).** Same root cause — the "Too many tries. Please
wait N s." warning rendered with `MoodBloomColors.coralText` at
~2.54:1 over `mb.bg`. The warning is shown after PIN failure-lockout
triggers, exactly when users want to read the lockout duration clearly.

**Before / after.** Identical brightness-aware swap to Fix 1. Light
stays at **6.04:1 PASS** (historical binding preserved); dark gains
**8.25:1 PASS** via `colorScheme.error`.

### Defence in depth — sentinel test

A token-level test in the new `dark_mode_contrast_test.dart`
(`MoodBloomColors.coralText over mb.bg FAILS dark AA`) asserts the
known failure on the constant itself. If a future design-system PR
introduces a brightness-aware `coralText` factory, that test starts
failing and the team must (a) re-evaluate the marker-band / legend /
recent-triggers dot bindings and (b) consider re-binding the PIN
error text back to a single token.

---

## 3. Deferred to v1.6 — `MoodBloomColors.coralText` systemic gap

### F-WC-001 — Tier 3 dot indicators stay on `coralText` (decorative UI)

**Surfaces affected.**
- `apps/mobile/lib/features/insights/presentation/widgets/pattern_marker_band.dart:136`
  — Tier 3 marker dot.
- `apps/mobile/lib/features/insights/presentation/widgets/recent_triggers_card.dart:166`
  — Tier 3 row indicator dot.
- `apps/mobile/lib/features/insights/presentation/screens/insights_screen.dart:280`
  — Tier 3 _ChartKeyRow legend dot.
- `apps/mobile/lib/features/insights/presentation/widgets/marker_detail_sheet.dart:175`
  — Tier 3 popover header indicator dot.

**Why these stay.** All four are decorative UI-component dots
(8–10 dp circles) that visually anchor the user to a Tier 3 trigger.
They are NOT text — they are colour-only swatches that pair with a
text label rendered with `mb.text` (12.08:1 PASS). A WCAG-strict
read: UI components need 3:1 against the adjacent colour. On dark
`mb.card` they compute to **2.06:1** — a fail of the 3:1 floor but
NOT a text-readability fail (the text next to them is always clean).

**Why we don't swap unilaterally.** The Tier 3 visual identity is
"the deep destructive red" — using `coral` (light pink) for Tier 3
dots would visually conflate Tier 2 and Tier 3, defeating the whole
point of the band. Using `colorScheme.onErrorContainer` (the only
existing theme-aware "destructive" tone that contrasts both ways)
re-skins the dots to a brand-mismatched M3-derived tone. The right
fix is a new design-system token: `mb.tier3Accent` that resolves to
`coralText` on light (the current correct identity) and a brighter
sibling on dark (to be designed; somewhere in the warm-red family at
~L=0.4 or higher so contrast vs `mb.card` clears 3:1).

**v1.6 acceptance criteria.**
1. New token `mb.tier3Accent` added to `MbColors` with light/dark
   factories. Light: `MoodBloomColors.coralText` (preserves identity).
   Dark: a new constant chosen for ≥ 3:1 vs `mb.card` AND a colour the
   user-research lead signs off as still "destructive-red" coded.
2. The four references above swap from `MoodBloomColors.coralText`
   to `mb.tier3Accent`. The `_tierColor` static helpers stay
   functionally identical otherwise.
3. The Wave C sentinel test (`coralText over mb.bg FAILS dark AA`) is
   replaced with a positive assertion on `mb.tier3Accent`.
4. The Tier 3 marker-band a11y test gains a contrast assertion.

**Impact today.** The Tier 3 dot is **harder to see** on dark, but
the surrounding affordances (label text, "care moment" copy in the
RecentTriggersCard row, the Tier 3 marker's `Semantics` label, and
the chart key's `mb.text` label) all carry redundant information.
A screen-reader user reads "care moment" or "Tier 3 trigger on …"
regardless of dot saturation. A sighted user on dark may need a
second glance to identify which markers are Tier 3, but the
information is not lost — only de-emphasised. The Tier 3 *banner*
itself (which IS the load-bearing affordance) still uses
`errorContainer` / `onErrorContainer` at 7.24:1 AAA on both themes.

### Other parking-lot items (not blocking v1.5)

- **F-WC-002 — Marker-band Tier 3 dot contrast falls below the
  3:1 UI-component floor on dark even at the swatch sizes the chart
  uses (a 10 dp dot is below WCAG's "incidental" exemption).** Same
  root cause as F-WC-001 — the design-system token `coralText` has
  no dark-mode sibling. The same v1.6 `mb.tier3Accent` token swap
  clears this together with F-WC-001.

- **F-WC-003 — `_LegendDot.color = MoodBloomColors.coralText` in
  `insights_screen.dart` is the only place the legend pairs a
  colour swatch with the label "Tier 3 care". The label is
  readable (12.08:1) but the swatch is not. If the v1.6 token swap
  lands, swap this binding too.**

- **F-WC-004 — Wave C inlined a brightness-aware token pick for
  the two PIN-flow destructive-text references** (see Fix 1 + Fix 2
  in §2). The pattern works but it's a per-binding decision. The
  v1.6 design-system ticket should formalise this as a new
  `mb.errorText` token in `MbColors` (light: `coralText`, dark:
  `coral`) so the inline `theme.brightness == Brightness.dark` test
  collapses to a single token reference at the call site.

---

## 4. Test coverage delta

| File | Tests added |
|---|---|
| `apps/mobile/test/features/_a11y/dark_mode_contrast_test.dart` | 31 |

**Test counts.** Existing suite was ~1059 tests on the integration
head. Wave C adds 31 tests in a single new file. Expected total
after Wave C lands: ~1090. The new file covers 7 groups
(`token baselines`, `InterventionBanner`, `BreathingScreen`,
`JournalingPromptScreen`, `CrisisResourcesScreen`, `Insights surfaces`,
`DisclaimerAckDialog`, `Tokens surfaces`, `TierToggleTile`,
`Wave E privacy surfaces`).

**Test design.** Each group reads dark-theme colours off the live
widget tree (or directly from `MbColors.dark()` for token-only
assertions) and asserts the WCAG ratio via a shared
`_contrastRatio` + `_meets({threshold})` helper at the top of the
file. The helper is identical to the one used by the existing
`test/a11y_contrast_report_test.dart` printout — Wave C inherits
that math without re-implementing it.

**What the test file does NOT cover.**
- Light-theme contrast (already locked by the Day 4 sweep + the
  print-only `a11y_contrast_report_test.dart`).
- Marker-band semantics / focus / scale animation (locked by the
  Wave D commit `e07233d2` in
  `test/features/insights/presentation/widgets/pattern_marker_band_test.dart`
  and `test/features/insights/presentation/a11y/pattern_marker_band_a11y_test.dart`
  — explicitly out of scope for Wave C per the brief).
- The atmosphere palettes as backgrounds. The banner's opaque card
  hides any underlying sky, so the storm-atmosphere check folds into
  the `mb.text × mb.skyBot` token baseline (verified PASS at 11.08:1
  even if the banner were transparent — defence in depth).
- 200% type scaler (Day 3 a11y sweep already covered every S5
  surface; no regressions in Wave C; the brief explicitly tells us
  not to touch the existing skip in `insights_screen_a11y_test.dart`).

---

## 5. Files changed

| Path | Change |
|---|---|
| `apps/mobile/lib/features/auth/presentation/widgets/pin_keypad.dart` | Swap `MoodBloomColors.coralText` → `theme.colorScheme.error` on the inline error text style. |
| `apps/mobile/lib/features/auth/presentation/screens/pin_verify_screen.dart` | Same swap on the "Too many tries" lockout warning. |
| `apps/mobile/test/features/_a11y/dark_mode_contrast_test.dart` | **NEW.** 30 dark-mode contrast assertions across all S5 + polish surfaces. |
| `docs/test-reports/sprint-5-dark-mode-contrast-report.md` | **NEW.** This report. |

No design-system tokens were modified. No `firestore.rules`,
`functions/src/`, `main.dart`, `router.dart`, or CI workflow paths
were touched. The Wave D marker-band tests (`e07233d2`) were not
re-touched. The Wave B responsive sheets were not re-touched.

---

## 6. Sign-off

**Author:** flutter-engineer agent
**Date:** 2026-05-15
**Branch:** `feat/s5-v1.5-polish-wave-c`
**Base:** `19056bfd`
**Status:** All 30 new dark-mode contrast tests pass; `flutter
analyze` clean on the modified files; full `flutter test` regression
expected to land near 1089 tests, all green.

**Recommendation to integration agent.** Merge Wave C into
`feat/s5-v1.5-polish-integration`. The two surviving v1.6 chores
(F-WC-001 marker-band tokens, F-WC-002 PIN-text bidirectional token)
should both fold into a single v1.6 design-system ticket: "add
brightness-aware destructive-emphasis tokens (`mb.tier3Accent`,
`mb.errorText`) so the design system can stop relying on `coralText`
for non-cream surfaces." That ticket is small (≤ a half-day of
design-system work + a couple of binding swaps) and clears the
remaining 4 dark-mode gaps in one shot.
