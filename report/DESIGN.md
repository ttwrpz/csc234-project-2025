# MoodBloom Design System — Claude Prompt-Ready Reference

> **Purpose of this document.** This is a complete, self-contained design specification for MoodBloom. Hand the entire file to another Claude instance (or any AI design assistant) and it can produce screens, components, and copy that match the rest of the app without having to read the codebase.
>
> **Read me first.** MoodBloom is a cross-platform Flutter app (Android + Web; tablet + desktop responsive) for mood tracking, AI-assisted journaling, distress-pattern detection, and a "living garden" visualization of emotional history. The product brand is gentle, non-clinical, garden-coded, self-compassion forward. Every design decision in this doc reflects that tone.

---

## 0. Table of contents

1. [Brand & voice](#1-brand--voice)
2. [Color tokens (exact hex values)](#2-color-tokens-exact-hex-values)
3. [Typography](#3-typography)
4. [Spacing, radii, elevation](#4-spacing-radii-elevation)
5. [Iconography](#5-iconography)
6. [Motion](#6-motion)
7. [Component library (every `Mb*` widget)](#7-component-library-every-mb-widget)
8. [Theming — light/dark/day-night](#8-theming--lightdarkday-night)
9. [Breakpoints — phone / tablet / desktop](#9-breakpoints--phone--tablet--desktop)
10. [Phone layout guide](#10-phone-layout-guide)
11. [Tablet layout guide](#11-tablet-layout-guide)
12. [Desktop layout guide](#12-desktop-layout-guide)
13. [Per-screen responsive recipes](#13-per-screen-responsive-recipes)
14. [Modal presentation rules](#14-modal-presentation-rules)
15. [Copy rules (non-negotiable)](#15-copy-rules-non-negotiable)
16. [Accessibility checklist](#16-accessibility-checklist)
17. [Code patterns — how to USE the design system](#17-code-patterns--how-to-use-the-design-system)
18. [Anti-patterns — do NOT do these](#18-anti-patterns--do-not-do-these)
19. [Prompt template for another Claude](#19-prompt-template-for-another-claude)

---

## 1. Brand & voice

### 1.1 Product identity

- **Name:** MoodBloom
- **Mark/glyph:** flower emoji "🌸" (used in the toast brand chip)
- **Tagline-flavored phrasing:** "Your garden, today." / "A new week begins."
- **Genre:** mental-wellness companion (NOT a medical device; the app explicitly disclaims diagnosis).
- **Personality:** warm, slow, garden-coded, gently encouraging, non-judgmental.

### 1.2 Voice & tone

| Trait | Do | Don't |
|---|---|---|
| Warmth | "Want to pause for a minute?" | "You need to take a break." |
| Specificity | "Storms pass. The roots hold." | "It will get better." |
| Agency | "If it helps, try…" | "You should…" |
| Compassion | "Empty days are fine." | "You broke your streak." |
| Non-clinical | "heavier stretches" | "depressive episode" |

### 1.3 Garden metaphor — the foundation

Plants in MoodBloom are **never destroyed, wilting, or dying**, no matter how bad the user's week was. Mood is **weather**; the ecosystem **holds**. The 5 plant tiers are:

- **Flourishing** — abundant growth
- **Thriving** — healthy and full
- **Resting** — quiet days for the soil
- **Weathering** — roots hold through a soft week
- **Storm Season** — sheltered, weather passes

This metaphor governs all copy. See §15 for the enforced word lists.

---

## 2. Color tokens (exact hex values)

All colors are defined in `packages/design_system/lib/src/tokens/colors.dart`. **Use the named tokens — never hex literals in screens.**

### 2.1 Raw constants (`MoodBloomColors`)

```
// Brand
seed              #2E7D5B   primary deep green (seed of the brand)
seedDark          #1F5A41   primary, dark variant
softGreen         #E8F3ED   soft green tint

// Semantic accent
amber             #E8A23B   warning / medium confidence
coral             #F4A78C   error / destructive on white (bright)
coralText         #7A1E13   destructive text on cream (deep — AAA 9.5:1)

// Light neutrals
surfaceCream      #FBFAF6   light scaffold ("cream")
surfaceDim        #EEEFDF   light dim surface variant
outline           #ECE7DC   light 1px border / divider
onSurface         #1F2937   light primary text
onSurfaceMuted    #6B7280   light secondary / dimmed text

// Dark neutrals
surfaceCreamDark  #161F2C   dark scaffold ("navy")
surfaceDimDark    #22303F   dark dim surface variant
outlineDark       #2E3B4B   dark 1px border / divider
onSurfaceDark     #F0F3F7   dark primary text
onSurfaceMutedDark #A6B2C2  dark secondary / dimmed text
```

### 2.2 Mood palette (`MbMoodKind` + `MbMoodPalette`)

The 6 moods. Color and emoji do NOT swap between light and dark.

| Mood | Color | Emoji | Sign for `S_t = v × i/5` |
|---|---|---|---|
| happy | `#F6C45A` | 🌻 | + |
| calm | `#8FBFA3` | 🌱 | + |
| okay | `#A7B3A9` | 🌿 | + |
| sad | `#7A96AE` | 💧 | − |
| angry | `#8B6F63` | ⛈️ | − |
| anxious | `#B8A15E` | 🌾 | − |

**Access:** `Theme.of(context).extension<MbMoodPalette>()!.colorOf(MbMoodKind.happy)`.

### 2.3 Theme extension (`MbColors`) — semantic roles

Read via `Theme.of(context).extension<MbColors>()!`. The shorthand `mb` is used throughout the codebase.

| Token | Light | Dark | Role |
|---|---|---|---|
| `mb.bg` | `#FBFAF6` | `#161F2C` | Scaffold background |
| `mb.card` | `#FFFFFF` | `#22303F` | Card / surface |
| `mb.line` | `#ECE7DC` | `#2E3B4B` | 1px border / divider |
| `mb.text` | `#1F2937` | `#F0F3F7` | Primary text |
| `mb.textDim` | `#6B7280` | `#A6B2C2` | Secondary text |
| `mb.destructiveText` | `#7A1E13` | `#F4A78C` | Destructive **text** (sign-out, delete) |
| `mb.skyTop` | `#FFE4D1` | `#2B3A52` | Garden sky gradient — top |
| `mb.skyMid` | `#F5E9DA` | `#25334A` | Garden sky gradient — mid |
| `mb.skyBot` | `#E8F3ED` | `#1F3A2E` | Garden sky gradient — bottom |
| `mb.sun1` | `#FFD9A6` | `#D9D4A0` | Sun highlight 1 |
| `mb.sun2` | `#FFC98C` | `#A6A07A` | Sun highlight 2 |
| `mb.ground` | `#8FBFA3` | `#1F3A2E` | Garden ground |
| `mb.ground2` | `#7AAF92` | `#183325` | Garden ground variant |
| `mb.grass` | `#4C8B6A` | `#2E5541` | Grass / flora |
| `mb.navBg` | `rgba(255,255,255,0.9)` | `rgba(34,48,63,0.9)` | Translucent nav background (over backdrop blur) |
| `mb.softCoral` | `#FFF1E9` | `#3B2A24` | Soft destructive surface tint |
| `mb.aiBg` | `#F5F2EA` | `#1E2A3A` | AI suggestion card background |
| `mb.aiBd` | `#E6DFCC` | `#304056` | AI suggestion card border |

### 2.4 `ColorScheme` mapping

When the screen calls `Theme.of(context).colorScheme`, the following Material 3 roles are wired:

| Material role | Light | Dark |
|---|---|---|
| `primary` | `#2E7D5B` (seed) | `#2E7D5B` |
| `surface` | `mb.bg` | `mb.bg` |
| `surfaceContainer` | `mb.card` | `mb.card` |
| `onSurface` | `mb.text` | `mb.text` |
| `onSurfaceVariant` | `mb.textDim` | `mb.textDim` |
| `outline` | `mb.line` | `mb.line` |
| `error` | `#7A1E13` (coralText) | `#F4A78C` (coral) |

**The `error` token is theme-aware** — use `theme.colorScheme.error` on destructive button backgrounds; the deep-coral text variant is only inside `mb.destructiveText` for text-only affordances.

---

## 3. Typography

### 3.1 Families

- **Display / titles:** Fraunces (serif). Called via `MbFonts.fraunces(...)`.
- **Body / labels:** Nunito (sans). Called via `MbFonts.nunito(...)`.

> **Note.** At time of writing the font assets are not bundled — `MoodBloomTypography.fontFamily` is `null`, so both helpers currently render with the platform default (Roboto on Android, system on web). The `MbFonts.fraunces` / `MbFonts.nunito` helpers are still the source of truth for **size + weight + letter-spacing**; when fonts land, every call site updates centrally.

### 3.2 Canonical scale (Material 3 `TextTheme`)

| Token | Size | Weight | Letter-spacing | Use |
|---|---|---|---|---|
| `displayLarge` | 34 | w600 | -0.25 | Hero on landing surfaces (rare) |
| `displayMedium` | 28 | w600 | 0 | Big stat callouts |
| `displaySmall` | 24 | w600 | 0 | Display headings |
| `headlineLarge` | 22 | w600 | 0 | AppBar title, screen title |
| `headlineMedium` | 20 | w600 | 0 | Section heading |
| `headlineSmall` | 18 | w600 | 0 | Subsection heading |
| `titleLarge` | 18 | w600 | 0 | Prominent label |
| `titleMedium` | 16 | w600 | +0.15 | Important label |
| `titleSmall` | 14 | w600 | +0.1 | Emphasized body |
| `bodyLarge` | 16 | w400 | +0.15 | Large body |
| `bodyMedium` | 14 | w400 | +0.15 | Standard body |
| `bodySmall` | 12 | w400 | +0.2 | Caption |
| `labelLarge` | 14 | w600 | +0.1 | Button label / badge |
| `labelMedium` | 12 | w600 | +0.4 | Small label / tag |
| `labelSmall` | 11 | w600 | +0.5 | Section caption (uppercase) |

### 3.3 Common ad-hoc styles in screens

```dart
// Screen title in AppBar
MbFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: mb.text)

// Body paragraph
MbFonts.nunito(fontSize: 14, height: 1.5, color: mb.text)

// Dimmed body / caption
MbFonts.nunito(fontSize: 13, height: 1.5, color: mb.textDim)

// SECTION LABEL (uppercase)
MbFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: mb.textDim)

// Button label
MbFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600)
```

### 3.4 Type rules

- **Line-height:** 1.5 for body, 1.3 for headings, default for buttons.
- **Letter-spacing:** never override on display sizes; mostly +0.5 on uppercase tiny labels.
- **Color:** title = `mb.text`, body = `mb.text`, dim = `mb.textDim`. Don't use raw black/white.
- **Capitalization:** sentence case for content; UPPERCASE only for section labels (rendered via `MbSectionLabel`).
- **Never bold the body.** Use Nunito w600 for emphasis at most; w700/w800 are reserved for app bar titles and nav brand.

---

## 4. Spacing, radii, elevation

### 4.1 Spacing scale (4dp grid)

All values are dp / logical pixels. Tokens live in `MoodBloomSpacing`.

```
xs    4
sm    8
md   12
lg   16
xl   24
xxl  32
xxxl 48
pagePadding 18   // horizontal page padding (phone)
tapTargetMin 48  // Material minimum
```

### 4.2 Radii

```
radiusSm        8    // tiny chips, intensity dots
radiusMd       12    // input fields, icon buttons
radiusLg       16    // generic surfaces
radiusButton   14    // MbPrimaryButton, MbGhostButton
radiusCardLg   20    // MbCard
radiusCluster  26    // grouped card cluster
radiusSky      32    // hero / illustration surfaces
radiusFull    999    // pills, chips, FAB
```

### 4.3 Elevation

```
level0  0
level1  1
level2  3
level3  6
level4  8
```

Most cards render `elevation: 0` and rely on a 1px border instead. Shadows are reserved for the highlighted "Add" FAB in bottom nav (`primary @ 33%` blur 12 offset (0,4)) and for toasts.

---

## 5. Iconography

- **Source:** Material Icons (`package:flutter/material.dart` → `Icons.*`).
- **Style:** **outlined** by default (`Icons.home_outlined`, `Icons.settings_outlined`, `Icons.lock_outline`). Filled icons reserved for the highlighted "Add" tab.
- **Sizes:**
  - 14 — `MbIconButton.sm` interior icon
  - 18 — sidebar tab icon, `MbIconButton.md` interior icon
  - 22 — bottom-nav tab icon (active + inactive)
  - 24 — highlighted "Add" FAB icon
  - 56 — large confirmation / illustration glyph
- **Color:** inherits from text color (`mb.text` / `mb.textDim` / `primary`). Never hard-code black or white.

### Canonical glyphs

| Concept | Icon |
|---|---|
| Home | `home_outlined` |
| History | `menu_book_outlined` |
| Add mood (highlighted) | `add` |
| Patterns / Insights | `insights_outlined` |
| Settings | `settings_outlined` |
| Disclosure / chevron | `chevron_right` |
| Back | `arrow_back` |
| Lock (immutability) | `lock_outline` |
| Biometric | `fingerprint` |
| PIN / key | `password_outlined` / `key` |
| Theme: light | `light_mode_outlined` |
| Theme: dark | `dark_mode_outlined` |
| Theme: auto | `brightness_auto_outlined` / `schedule_outlined` |
| AI sparkle | `auto_awesome` |
| Error / warning | `error_outline`, `warning_amber_outlined` |
| Sign-out | `logout` |

---

## 6. Motion

| Pattern | Duration | Curve | Notes |
|---|---|---|---|
| Toast slide-in + fade | 360 ms | `easeOut` | From above; auto-dismiss 5s |
| `MbSegmentedToggle` indicator slide | 220 ms | `easeOut` | The only "tab" motion in the app |
| Page transitions | **0 ms** | n/a | Custom `_NoTransitionsBuilder` disables Material default slides; routes swap instantly |
| Day/night ticker | 15 min | n/a | Periodic re-evaluation while `followDeviceTime` is selected |
| Bottom-nav active swap | instant | n/a | Tap feedback is the highlighted FAB shadow, not a transition |

**Rule:** if you find yourself adding a 200–400 ms slide animation, stop — MoodBloom's UX favors instant swaps + carefully chosen ambient motion (toast, indicator). Don't add Rive, Lottie, or hero animations.

---

## 7. Component library (every `Mb*` widget)

All exported from `package:design_system/design_system.dart`.

### 7.1 Layout / surface

#### `MbCard`
White card with a 1px border, radius 20, default padding 16. Use for every grouped content surface.

```dart
MbCard(
  padding: EdgeInsets.all(MoodBloomSpacing.lg),
  child: Column(...),
)
```

Props: `child` (required), `padding`, `onTap`, `decoration`, `clipBehavior`. Default padding `EdgeInsets.all(16)`.

#### `MbSectionLabel`
Tiny uppercase caption above a card cluster. Renders `nunito(11, w600, +0.5 letter-spacing, textDim)`.

```dart
MbSectionLabel('PRIVACY')
const SizedBox(height: 6)
MbCard(child: PrivacyLockSettingsTile())
```

### 7.2 Buttons

#### `MbPrimaryButton`
Primary CTA. Filled with `primary` (#2E7D5B), white text, radius 14, min height 48, defaults to `fullWidth: true`.

```dart
MbPrimaryButton(
  label: 'Continue to new week',
  leading: Icon(Icons.check, size: 18, color: Colors.white),
  loading: status is HarvestArchiveRunning,
  onPressed: status is HarvestArchiveRunning ? null : () => controller.acknowledge(),
)
```

Props: `label` (required), `onPressed` (required, nullable), `leading`, `fullWidth = true`, `loading = false`.

#### `MbGhostButton`
Secondary CTA. Card background, 1px line border, `mb.text` foreground, radius 14, min height 48.

```dart
MbGhostButton(label: 'Sign out instead', onPressed: _signOut)
```

#### `MbIconButton`
Square icon button. Two sizes: `sm` (28×28) and `md` (36×36). Card bg, 1px line, radius 12, icon size = 50% of button.

```dart
MbIconButton(
  size: MbIconButtonSize.md,
  icon: Icon(Icons.chevron_right),
  onPressed: () => context.push('/history/${entry.id}'),
  semanticLabel: 'Open entry detail',
)
```

### 7.3 Inputs

#### `MbInputField`
Tiny uppercase label above a borderless `TextField` inside a soft container (card bg, 1px line, radius 14).

```dart
MbInputField(
  label: 'Email',
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  errorText: error,                 // turns the border red
  textInputAction: TextInputAction.next,
)
```

### 7.4 Tags / pills

#### `MbMoodChip`
Pill with mood emoji + name, tinted with the mood's own color (13% bg, 33% border).

```dart
MbMoodChip(mood: MbMoodKind.happy)             // medium
MbMoodChip(mood: MbMoodKind.sad, size: MbChipSize.sm)
MbMoodChip(mood: MbMoodKind.calm, label: 'feeling settled')
```

Sizes: `sm` (font 11, emoji 12, padding 8/4) · `md` (12/14/10/5) · `lg` (14/16/12/6).

#### `MbFilterChip`
Filter / tab chip. Selected = `primary` fill + white text; unselected = `mb.card` + `mb.textDim`. Pill shape (radius 999).

```dart
MbFilterChip(label: 'All time', selected: true, onTap: ...)
```

#### `MbConfidenceBadge`
Pill with a colored dot and "[level] confidence" label. Used on AI suggestions, pattern insights.

```dart
MbConfidenceBadge(level: MbConfidenceLevel.high)   // green dot, "high confidence"
MbConfidenceBadge(level: MbConfidenceLevel.medium) // amber dot
MbConfidenceBadge(level: MbConfidenceLevel.low)    // neutral grey dot
```

#### `MbLockBadge`
Small lock pill rendered on entries past the 24h immutability window. Variant `small: true` for list rows.

```dart
MbLockBadge()              // h8/v3, font 11, icon 13, with "locked" label
MbLockBadge(small: true)   // h6/v2, font 10, icon 11, no label
```

#### `MbIntensityDots`
Row of 5 dots, filled up to `value`. Used for the intensity 1–5 selector.

```dart
MbIntensityDots(value: 3, color: palette.colorOf(MbMoodKind.happy))
```

### 7.5 Toggle

#### `MbSegmentedToggle<T>`
Pill-shaped segmented control with sliding active indicator (220ms easeOut).

```dart
MbSegmentedToggle<HistoryTab>(
  items: [
    MbSegmentedItem(value: HistoryTab.list, label: 'List'),
    MbSegmentedItem(value: HistoryTab.calendar, label: 'Calendar'),
  ],
  value: currentTab,
  onChanged: (v) => ref.read(historyTabProvider.notifier).state = v,
)
```

Height default 40 (radius 20). Container has a 3px inner padding so the active indicator sits inside the line border.

### 7.6 Feedback

#### `MbAppToast`
Top-anchored dark-glass toast with a coral brand chip. Slides from above (360ms easeOut), auto-dismisses after 5s.

```dart
MbAppToast.show(
  context,
  title: 'Saved',
  body: 'Your mood is now part of this week\'s garden.',
  leadingIcon: const Icon(Icons.check, size: 14, color: Colors.white),
);
```

### 7.7 Navigation (app-shell only)

These live in `apps/mobile/lib/app/widgets/` (not the design_system package, but they ARE part of the system).

#### `MbBottomNav`
Translucent bottom nav for phone. Height 70, padding 8/8/8/22 (safe area bottom), backdrop blur `sigma 12`, 1px top line.

5 items in this order: Home, History, **Add (highlighted)**, Patterns, Settings. Exactly one item may have `highlighted: true` — that item renders as a 52×52 circular primary-tinted FAB with a `primary @ 0x55` shadow.

```dart
MbBottomNav(
  currentIndex: 0,
  onTap: (i) => navigationShell.goBranch(i),
  items: const [
    MbBottomNavItem(icon: Icons.home_outlined, label: 'Home'),
    MbBottomNavItem(icon: Icons.menu_book_outlined, label: 'History'),
    MbBottomNavItem(icon: Icons.add, label: 'Add', highlighted: true),
    MbBottomNavItem(icon: Icons.insights_outlined, label: 'Patterns'),
    MbBottomNavItem(icon: Icons.settings_outlined, label: 'Settings'),
  ],
)
```

#### `MbSideNav`
240dp sidebar for tablet/desktop. Brand row at top (32×32 icon + "MoodBloom" 17/w700), nav items 14/w500 with 10dp radius active-state highlight, then `Spacer`, then footer actions (theme picker + sign-out via `MbSideNavAction`).

```dart
MbSideNav(
  currentIndex: branchIndex,
  onTap: _goBranch,
  items: [...same 5 items],
  actions: [
    MbSideNavAction(
      icon: _iconForThemePref(themePref),
      label: _labelForThemePref(themePref),
      onTap: () => _showThemeDialog(...),
      trailing: const Icon(Icons.unfold_more, size: 14),
    ),
    MbSideNavAction(
      icon: Icons.logout,
      label: 'Sign out',
      destructive: true,
      onTap: _confirmSignOut,
    ),
    const SizedBox(height: 8),
  ],
)
```

---

## 8. Theming — light/dark/day-night

### 8.1 Two themes

`buildLightTheme()` and `buildDarkTheme()` return a `ThemeData`. Both register the same two extensions:

```dart
extensions: <ThemeExtension<dynamic>>[
  MbColors.light()  // or MbColors.dark()
  MbMoodPalette.shared,  // singleton, same values in light + dark
]
```

### 8.2 User preference (4 options)

```dart
enum ThemeModePreference {
  system,            // follow OS
  light,             // force light
  dark,              // force dark
  followDeviceTime,  // light 07:00–18:59, dark 19:00–06:59 (local time)
}
```

`followDeviceTime` polls every 15 min via a periodic ticker; the boundary at 07:00 / 19:00 flips automatically on the next rebuild.

### 8.3 Resolution

```dart
final themeMode = ref.watch(currentThemeModeProvider);
// returns ThemeMode.light / dark / system
```

`MaterialApp.themeMode = themeMode`. The day/night strategy is in `apps/mobile/lib/features/settings/domain/services/day_night_strategy.dart`.

### 8.4 The "no flash-of-light" rule

Theme preference must be resolved **before `runApp()`** (eager SharedPreferences load + `ProviderScope.overrides`). Same applies to the Privacy Lock state — see §13.0.

---

## 9. Breakpoints — phone / tablet / desktop

The **app-shell** breakpoints (in `apps/mobile/lib/app/router.dart` → `_AppShell`):

```
Phone     w <  600 dp
Tablet  600 <= w <  900 dp
Desktop  w >= 900 dp
```

Many screens have their own (slightly different) breakpoints for content-shape decisions; see §13. When in doubt, **use the app-shell numbers** for navigation/chrome decisions and screen-specific numbers for body layout.

### Per-form-factor decision matrix

| Concern | Phone (<600) | Tablet (600–899) | Desktop (≥900) |
|---|---|---|---|
| Primary nav | `MbBottomNav` | `MbBottomNav` | `MbSideNav` (240dp left) |
| Content max width | `double.infinity` | 840 dp center column | 1280 dp center column |
| Horizontal page padding | 18–24 | 32 | 24 / 32 / 48 (see §12.2) |
| Modal presentation | bottom sheet | centered Dialog (560–640 dp) | centered Dialog (560–640 dp) |
| Garden layout | 1 col | 2 col (60/40) at ≥720 | 2 col, capped 1100 dp |
| Insights layout | 1 col | mixed 2-col above chart | 3 col below chart |
| Log mood form | 1 col | 2 col at ≥720 | 2 col, capped 1080 dp |
| Calendar view | sheet-on-tap | side panel at ≥720 | side panel |

---

## 10. Phone layout guide

Target: ≤ 599 dp wide. Reference device: Pixel 7 portrait, iPhone 14.

### 10.1 Chrome

- **Bottom nav** (`MbBottomNav`, height 70) — 5 tabs, Add highlighted in the center.
- **Status bar / safe area** — every page wrap with `SafeArea` once; do NOT nest.
- **AppBar** — present on detail/modal pages (privacy lock, entry detail, archived week, sign-in). Hidden on the 5 shell branches.

### 10.2 Body

- **Padding:** horizontal `MoodBloomSpacing.pagePadding` (18) by default, or 24 on flow screens.
- **Content reaches edge** (no max-width cap on phone).
- **Bottom padding** of every scrollable page: `kMbBottomNavHeight + bottomSafePad + 16` so cards don't hide behind the translucent nav.

### 10.3 Lists

- Use `ListView` with `ListTile` for settings or `MbCard` rows for richer cells.
- **Calendar view** on phone: full calendar; tapping a day opens a `DraggableScrollableSheet` (initial size 0.5).

### 10.4 Forms

- **Single column.** Each field is `MbInputField` with `textInputAction: TextInputAction.next` chained; the last field uses `done`.
- The primary CTA (`MbPrimaryButton`) is **inline at the end of the form**, not pinned to the bottom of the viewport.
- Keep paragraphs ≤ 60 characters per line (phone width naturally enforces this).

### 10.5 Mood logging — phone

Single column:

```
[ AppBar: "How are you feeling?" ]
[ MoodTypeGrid — 3 columns × 2 rows of mood tiles, tile h=84 ]
[ IntensitySlider — full width ]
[ MbInputField — note ]
[ Media picker row ]
[ MbPrimaryButton "Save" ]
```

---

## 11. Tablet layout guide

Target: 600–899 dp wide. Reference device: iPad mini portrait, Galaxy Tab A.

### 11.1 Chrome

- **Bottom nav stays** (do not swap to sidebar at this width — that's a desktop-only swap).
- AppBar present where it would be on phone.

### 11.2 Body

- Center the content in a `ConstrainedBox(maxWidth: 840)` so a single 22sp paragraph doesn't stretch across 1024dp.
- Horizontal padding: 32 (vs 18 on phone).

### 11.3 Two-column unlocks

When the screen's responsive breakpoint hits at 720dp, switch to a 2-column layout. Examples:

- **Garden screen:** SkyHeader + DailyScoreStrip on the left (flex 6), Recent moods on the right (flex 4).
- **Log mood:** Mood grid + intensity on the left, note + media + save on the right.
- **Calendar:** Calendar grid (flex 5) + day-entries side panel (flex 4).

### 11.4 Modals become dialogs

At ≥600 dp wide, **bottom sheets convert to centered Dialogs**:

```dart
if (mediaQuery.size.width >= 600) {
  showDialog(...);
} else {
  showModalBottomSheet(...);
}
```

Max dialog width 560–640 dp, max height `80%` of viewport.

### 11.5 Privacy Lock screen — tablet

- Title font 22 (same as phone).
- Body card capped at 560 dp wide, centered.
- Padding 32 horizontal.

---

## 12. Desktop layout guide

Target: ≥ 900 dp wide. Reference device: 1440×900 laptop, 1920×1080 monitor, Chrome web.

### 12.1 Chrome — sidebar replaces bottom nav

`MbSideNav` (240 dp, full height, left edge) replaces `MbBottomNav`. Same 5 items + the theme & sign-out actions in the footer.

The shell layout:

```
+--------+----------------------------------------------+
| Side   |   ConstrainedBox(maxWidth: 1280)             |
| Nav    |   Padding(horizontal: hPadding)              |
| 240dp  |       <body>                                 |
|        |                                              |
+--------+----------------------------------------------+
```

### 12.2 Padding scales with available width

After subtracting the sidebar:

```
bodyAvailable < 1100 → hPadding = 24
bodyAvailable < 1400 → hPadding = 32
bodyAvailable ≥ 1400 → hPadding = 48
```

### 12.3 Reading-width cap

Hard cap on body max-width: **1280 dp**. A 22sp paragraph at 2000dp wide is unreadable; the cap keeps cards & charts at a humane width even on a 4K monitor.

### 12.4 Two-column / three-column body

- **Garden:** 2 columns (60/40), inner cap 1100 dp.
- **Insights:** chart full-width, with 3-column row below (reading-guide / legend / recent-triggers).
- **Settings:** still single column — readability beats column count.

### 12.5 Modals

Same rule as tablet — Dialog, not sheet. Max width 560–640 dp.

### 12.6 Web-specific

- `kIsWeb` gates:
  - WebAuthn ("Use security key") button on sign-in.
  - Sync section in Settings hidden on web (Drift is native-only; web uses Firestore directly).
- Google sign-in uses `signInWithPopup` on web (not the native Credential Manager flow).
- Don't use Drift / `local_auth` / FCM / `flutter_local_notifications` on web — they have no web impl.

---

## 13. Per-screen responsive recipes

### 13.0 Pre-`runApp()` gates (universal)

Every cold launch must complete BEFORE `runApp()`:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp(...)`
3. Firestore offline settings (native only)
4. Crashlytics handlers (native only)
5. Remote Config defaults + fire-and-forget `fetchAndActivate()`
6. FCM notification channel (native only)
7. Google Sign-In `initialize(...)` (native only)
8. `SharedPreferences.getInstance()`
9. Pre-resolve `BiometricCapability` (try/catch on web)
10. Pre-resolve Privacy Lock opt-in
11. `runApp(ProviderScope(overrides: [...], child: MoodBloomApp()))`

This is what guarantees the GoRouter redirect sees **synchronous** privacy-lock state on the very first frame — no flash-of-home.

### 13.1 Onboarding

5 slides. Breakpoints: 600 / 900 dp.

| Form factor | Content max width | Padding |
|---|---|---|
| phone | 480 | 20 h, 28 v |
| tablet | 720 | 28 h, 28 v |
| desktop | 960 | 28 h, 28 v |

Art slot 260×200 on every form factor. Disclaimer slide title font 26 / 28 / 30 by form factor.

### 13.2 Sign-in / Sign-up / Forgot password

Centered card, **fixed** max width (does NOT scale with form factor):

- Sign-in / Sign-up: 420 dp
- Forgot password: 480 dp
- Padding: 28 all sides
- `SingleChildScrollView` host so the keyboard doesn't push fields off-screen.

The Google button is always present. The WebAuthn ("Use security key") button is only rendered on web (`kIsWeb && kEnableWebauthn`).

### 13.3 Privacy Lock screen (`/privacy-lock`)

Breakpoints 600 / 900 dp.

| Form factor | Body max width | h padding | Title font |
|---|---|---|---|
| phone | ∞ | 24 | 22 |
| tablet | 560 | 32 | 22 |
| desktop | 640 | 32 | 28 |

Layout: AppBar "Privacy lock" → title → instruction caption → (optional rate-limit countdown) → big body slot. The body slot swaps between `PinKeypad` and a "Verifying with biometric…" placeholder when the OS prompt is up. Below the body: "Use biometric instead" `TextButton.icon` (only when biometric available). Above the body, footer: "Sign out instead" `MbGhostButton`.

### 13.4 Garden / Home screen

Breakpoints **720 / 1080** (not the app-shell defaults).

- **Phone (<720):** single column.
  - SkyHeader (hero)
  - "Take a breath" pill button
  - GardenSummaryRow (tier label + token chip + Patterns shortcut)
  - CheerUp banner (only when triggered)
  - DailyScoreStrip card
  - Recent moods list
  - Bottom padding 140 (clears nav + center FAB)

- **Tablet (720–1079):** two columns 60/40.

- **Desktop (≥1080):** two columns 60/40, outer cap 1100, page padding 32.

`GardenSummaryRow` has its OWN sub-breakpoint at 400 dp: below 400 it stacks the tier + token chip on the left and the Patterns button below; above 400 it's a single row.

### 13.5 Log mood

Breakpoint **720** dp.

- **<720:** single column (mood grid → intensity → note → media → save).
- **≥720:** two columns — left (mood grid + intensity), right (note + media + save). Outer cap 1080 dp.

`MoodTypeGrid` always renders 3 columns; each tile width is clamped to `72..240` dp; tile height 84 dp.

### 13.6 History

Header breakpoint **520** dp. Below 520, the screen title and the list/calendar `MbSegmentedToggle` stack vertically; above 520 they share a row.

`CalendarView` has its OWN breakpoint **720** dp:
- <720: tap a day → bottom sheet with that day's entries.
- ≥720: split layout — calendar on the left (flex 5), day entries panel on the right (flex 4).

### 13.7 Insights (Patterns)

Breakpoints **600** + **900** dp.

- **<600:** single column. Reading guide is collapsed inside an `ExpansionTile`.
- **600–899:** above the chart, 2 cols (guide + chips on the left, legend + triggers on the right). Chart full-width below. Reading guide expanded by default.
- **≥900:** chips full-width, chart full-width, then a 3-column row (reading guide, legend, recent triggers).

The disclaimer ack dialog must have been accepted (gated by `insightsDisclaimerAckedProvider`).

### 13.8 Settings

Single column at every breakpoint. The sections from top to bottom:

```
ACCOUNT        – email row, sign-out
PRIVACY        – PrivacyLockSettingsTile (unified biometric + PIN switch)
WEBAUTHN       – only on web (kIsWeb)
NOTIFICATIONS  – per-tier toggles
DISCLAIMER     – bipolar/medical disclaimer panel
THEME          – ThemeModePreference radio
SYNC           – Drift sync controls (NATIVE ONLY, `if (!kIsWeb)`)
DEBUG          – debug-only block (`if (kDebugMode)`)
ABOUT          – version, build, links
DELETE ACCOUNT – destructive, opens delete_account_dialog
```

Padding: `MoodBloomSpacing.pagePadding` (18) by default on phone; the shell adds the desktop sidebar offset + 24/32/48 padding above this.

### 13.9 Weekly summary (harvest popup)

A pushed `MaterialPageRoute<void>` that appears when `pendingWeeklySummaryProvider` resolves non-null.

```
AppBar "Your week" (no back button)
  hero GardenBed (280×140)
  Banner "Your garden this week has been harvested..."
  AVERAGE MOOD — slider marker on a −1.0..+1.0 scale
  DOMINANT EMOTIONS — top 3 chips
  PATTERN CHECK-INS — sentence
  MbPrimaryButton "Continue to new week"
```

Single column on every form factor. Pops automatically on `HarvestArchiveSuccess`.

### 13.10 Entry detail

AppBar with back, title is the day's date. Body: hero mood chip + intensity dots + note + attachments + LockBanner (if past 24h) + ActionsRow (Edit + Delete).

**Delete uses the canonical destructive pattern**: `theme.colorScheme.error` (NOT raw coral). Confirm dialog's "Delete" button is `FilledButton` with `backgroundColor: colors.error, foregroundColor: colors.onError`.

Single column on every form factor.

### 13.11 Intervention (Tier 1 / 2 / 3) screens

Reached from the InterventionBanner (top-of-shell). Nested under `/home` so the bottom nav (or sidebar) stays visible while the user breathes / journals / reads crisis resources.

- **Tier 1 — `BreathingScreen`** — 2-min breathing exercise, big animated breathing circle, timer.
- **Tier 2 — `JournalingPromptScreen`** — single prompt + `MbInputField`-flavored textarea + save.
- **Tier 3 — `CrisisResourcesScreen`** — list of resource cards, **Hotline 1323 footer**, opt-out button.

All three single-column. Tier-3 NEVER calls Gemini — its quotes are pre-curated. Tier-1/2 may call Gemini but the safety filter only lets pre-approved phrases through.

---

## 14. Modal presentation rules

The same content should be a **bottom sheet on phone** and a **centered Dialog on tablet/desktop**. The breakpoint is **600 dp** (app-shell tablet boundary).

```dart
final isTabletOrWider = MediaQuery.sizeOf(context).width >= 600;
if (isTabletOrWider) {
  showDialog(context: context, builder: (_) => MyDialog(...));
} else {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => MyBottomSheet(...),
  );
}
```

Dialog constraints:
- Max width 560 dp (most modals) / 640 dp (skin picker, large content)
- Max height `viewport.height * 0.8`
- Bottom sheet drag handle is hidden in the Dialog variant.

---

## 15. Copy rules (non-negotiable)

These are enforced by `harvest/copy_audit_test.dart`. **Reviewer agents reject PRs that violate them.**

### 15.1 Forbidden words (for the garden / weekly archive)

> "delete", "clear", "reset", "lost", "destroyed", "wilted", "wilting", "dead", "dying"

### 15.2 Use instead

> "harvest", "complete", "new chapter", "fresh week", "sheltered", "resting"

### 15.3 Other rules

- **No clinical labels for the user:** never "depression", "anxiety disorder", "symptom", "diagnosis", "bipolar" *as a label*. "bipolar" may appear ONLY inside the disclaimer.
- **No streak-shaming.** Missed days are empty slots, never "you broke your streak."
- **No fix-your-mood verbs.** Prefer "notice", "explore", "care for", "pause" over "improve", "boost", "overcome".
- **No mood-contingent rewards.** Tokens are earned for *showing up*, not for feeling better. Never imply "earn by feeling better."
- **Compassionate imperatives.** "Want to…?" / "If it helps…" rather than "You should" / "You must."
- **Hotline 1323** appears on **Tier 3 only**, never as a primary CTA on regular surfaces.

### 15.4 Locked phrasing (verbatim — match character for character)

| Where | Exact string |
|---|---|
| **Weekly harvest banner** | "Your garden this week has been harvested and saved to your history. A new week begins - a fresh canvas for your story." |
| **Tier 1 (breathing)** | "It looks like your garden has had some rainy days. Would you like a 2-minute breathing exercise?" |
| **Tier 2 (journaling)** | "Would you like to write about what's been on your mind?" |
| **Tier 3 (crisis)** | "We care about you. Here are some resources that might help." + crisis links + Hotline 1323. |
| **Storm caption** | "Storms pass. The roots hold." / "Rain helps the soil." |
| **Disclaimer footer (every notification)** | "MoodBloom is not a medical device. Not a substitute for professional care." |
| **Disclaimer ack dialog (first Insights view)** | "MoodBloom is not a medical device. It cannot diagnose conditions like bipolar disorder, depression, or anxiety. Consult a qualified professional. [I understand]" |

> **Typography note.** The historical version of these strings used em-dashes (—). The app now uses hyphens (-) project-wide. If you're updating copy and your reviewer flags it, use a hyphen, not an em-dash.

### 15.5 Plant tier taglines

| Tier | Tagline |
|---|---|
| Flourishing | "Flourishing - the garden has bloomed." |
| Thriving | "Thriving - the garden has grown." |
| Resting | "Resting - quiet days for the soil." |
| Weathering | "Weathering a soft week - roots hold." |
| Storm Season | "Storm Season - sheltered, weather passes." |

---

## 16. Accessibility checklist

Run this before sending a PR.

- [ ] **Semantics labels** on every tappable widget. `MbIconButton`'s `semanticLabel` parameter is required for icon-only buttons.
- [ ] **Tap targets ≥ 48×48** dp. `MoodBloomSpacing.tapTargetMin` is the constant.
- [ ] **Color contrast** — WCAG 2.2 AA (4.5:1 body / 3:1 large). The `MbColors` tokens are designed to pass; the deep-coral `coralText` is AAA on cream.
- [ ] **Dynamic type** — text scales with `MediaQuery.textScalerOf(context)`. Don't hard-code fontSize on container heights; use `min/max` constraints.
- [ ] **Theme contrast** — dark theme has different `error` and `destructiveText` to maintain contrast on navy.
- [ ] **Live region** on transient state (toast: `Semantics(liveRegion: true)`; privacy lock screen too).
- [ ] **Focus management** — auth fields use `TextInputAction.next` chain; modals trap focus.
- [ ] **No info conveyed by color alone** — confidence badges have a colored dot AND a "high/medium/low confidence" label.

---

## 17. Code patterns — how to USE the design system

### 17.1 Reading the theme

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  final mb = theme.extension<MbColors>()!;
  final palette = theme.extension<MbMoodPalette>()!;
  final colors = theme.colorScheme;
  ...
}
```

### 17.2 A "standard" screen

```dart
class FooScreen extends ConsumerWidget {
  const FooScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        backgroundColor: mb.bg,
        elevation: 0,
        title: Text(
          'Foo',
          style: MbFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: mb.text),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.lg,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MbSectionLabel('SECTION ONE'),
              const SizedBox(height: MoodBloomSpacing.md),
              MbCard(child: ...),
              const SizedBox(height: MoodBloomSpacing.xl),
              MbPrimaryButton(label: 'Continue', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 17.3 A responsive screen

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          if (w >= 1080) return _buildDesktop(context, w);
          if (w >= 720) return _buildTablet(context, w);
          return _buildPhone(context);
        },
      ),
    ),
  );
}
```

Reuse the **same content sub-widgets** in each `_build*` method; the only thing that changes is the layout container (Row vs Column, max widths, padding).

### 17.4 A destructive action

```dart
final colors = Theme.of(context).colorScheme;
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: colors.error,
    foregroundColor: colors.onError,
  ),
  onPressed: _confirmDelete,
  child: const Text('Delete'),
)
```

For destructive **text-only** affordances (sidebar Sign out, list-row delete link):

```dart
final mb = Theme.of(context).extension<MbColors>()!;
TextButton(
  onPressed: _signOut,
  child: Text('Sign out', style: TextStyle(color: mb.destructiveText)),
)
```

### 17.5 A mood-tinted surface

```dart
final palette = Theme.of(context).extension<MbMoodPalette>()!;
final color = palette.colorOf(mood);
Container(
  decoration: BoxDecoration(
    color: color.withAlpha(0x21),     // 13% bg
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: color.withAlpha(0x55)), // 33% border
  ),
  child: ...,
);
```

### 17.6 An adaptive modal

```dart
Future<T?> showAdaptive<T>(BuildContext context, Widget body) {
  final isTabletOrWider = MediaQuery.sizeOf(context).width >= 600;
  if (isTabletOrWider) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: body,
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (_) => body,
  );
}
```

---

## 18. Anti-patterns — do NOT do these

- ❌ **Hard-coded hex** like `Color(0xFFF4A78C)` inside a screen. Use `MoodBloomColors.coral` (or, for destructive intent, `theme.colorScheme.error`).
- ❌ **`Theme.of(context).colorScheme.error.withOpacity(0.x)`** — `withOpacity` is deprecated. Use `.withAlpha(0xNN)` or `.withValues(alpha: 0.NN)`.
- ❌ **`!` null-assertion in production code.** Use `if-null` or explicit null guards. The one exception in the codebase is `theme.extension<MbColors>()!` — that's always non-null because the extensions are registered in `buildLightTheme`/`buildDarkTheme`.
- ❌ **Custom page transitions.** The app deliberately disables Material's default slides via `_NoTransitionsBuilder`.
- ❌ **Custom button shapes / colors.** Wrap `MbPrimaryButton` or `MbGhostButton` — don't roll your own.
- ❌ **EmoticonRail / EmojiPicker** — moods are picked via `MbMoodChip` or `MoodTypeGrid`; the emoji glyphs are static and live in `MbMoodPalette`.
- ❌ **Mood-contingent copy.** Never write "Try harder!" or "You can do this." Read §15 again.
- ❌ **Em-dashes (—) in user-facing strings.** Project-wide convention is hyphens (-).
- ❌ **`Drift` / `local_auth` / `flutter_local_notifications` / `image_picker` on web.** Guard with `if (!kIsWeb)` or use a web-specific datasource fork.
- ❌ **Domain-layer Flutter imports.** `lib/features/*/domain/` is pure Dart only. No `package:flutter/*`, no `package:firebase_*`.
- ❌ **Hot reload assumptions.** The Riverpod-3 `Notifier`s in this app rebuild from `build()` on hot reload — don't store mutable state outside `state =`.
- ❌ **Mocking the database in integration tests.** Use the in-memory Drift connection (`FakeSyncManager.create()`) or the Firestore emulator.

---

## 19. Prompt template for another Claude

Copy-paste this when you ask another Claude (or any AI design assistant) to produce a MoodBloom screen.

```
You are designing a screen for MoodBloom, a Flutter mood-tracker app on Android + Web.

DESIGN SYSTEM:
- Read report/DESIGN.md in this repo before writing any code.
- All colors come from MoodBloomColors / MbColors / MbMoodPalette.
- All spacing uses MoodBloomSpacing.
- All fonts go through MbFonts.fraunces (display/title) or MbFonts.nunito (body/label).
- All buttons are MbPrimaryButton or MbGhostButton.
- All cards are MbCard with default padding 16.
- Destructive uses theme.colorScheme.error (NEVER raw coral).
- Em-dashes are forbidden in user-facing strings. Use hyphens.
- Read CLAUDE.md §"Copy rules" — the forbidden / required word lists are enforced.

ARCHITECTURE:
- Clean Architecture, feature-first. presentation/domain/data per feature.
- State via Riverpod 2.x. No Provider, GetIt, BLoC.
- Navigation via GoRouter.
- Domain layer MUST NOT import Flutter or Firebase.

RESPONSIVE REQUIREMENTS:
- Phone (<600 dp): single column, MbBottomNav, edge-to-edge.
- Tablet (600..900 dp): bottom nav stays, content centered in maxWidth 840.
- Desktop (>=900 dp): MbSideNav 240dp left, content max 1280 dp, padding scales 24/32/48.
- Modal presentation: bottom sheet on phone (<600), centered Dialog on tablet+.
- Use LayoutBuilder + breakpoint switch on the body when content shape changes.

ACCESSIBILITY:
- Tap targets >= 48 dp.
- Semantics labels on icon-only buttons.
- Colors pass WCAG AA. Never use color alone to convey meaning.
- Dynamic type scaling supported.

OUTPUT:
1. Sketch the layout for phone, tablet, and desktop (ASCII or short prose).
2. List the components used and their props.
3. Write the Dart code, presentation layer only. Use Riverpod ConsumerWidget.
4. Note any new providers needed (don't implement data/domain — list them).
5. Note any test cases you'd add.

The screen I need is:
[INSERT YOUR SCREEN BRIEF HERE]
```

---

## Appendix A — File index for design system code

| Concern | Path |
|---|---|
| Color tokens | `packages/design_system/lib/src/tokens/colors.dart` |
| Spacing tokens | `packages/design_system/lib/src/tokens/spacing.dart` |
| Elevation tokens | `packages/design_system/lib/src/tokens/elevation.dart` |
| Typography (text theme builder) | `packages/design_system/lib/src/tokens/typography.dart` |
| Font helpers | `packages/design_system/lib/src/widgets/mb_fonts.dart` |
| Theme builders | `packages/design_system/lib/src/theme.dart` |
| All widgets | `packages/design_system/lib/src/widgets/` |
| Public export | `packages/design_system/lib/design_system.dart` |
| App shell (responsive) | `apps/mobile/lib/app/router.dart` (`_AppShell`) |
| Bottom nav | `apps/mobile/lib/app/widgets/mb_bottom_nav.dart` |
| Side nav | `apps/mobile/lib/app/widgets/mb_side_nav.dart` |
| Day/night strategy | `apps/mobile/lib/features/settings/domain/services/day_night_strategy.dart` |
| Theme mode controller | `apps/mobile/lib/features/settings/presentation/controllers/theme_mode_controller.dart` |

## Appendix B — Quick reference card

```
COLOR
  bg/text/textDim/card/line     mb.* (via Theme extension)
  destructive button bg         theme.colorScheme.error
  destructive text              mb.destructiveText
  mood color                    palette.colorOf(mood)
  brand primary                 #2E7D5B

TYPE
  title 22 w700                 MbFonts.fraunces(...)
  body 14 line-height 1.5       MbFonts.nunito(fontSize: 14, height: 1.5, color: mb.text)
  caption 13 textDim            MbFonts.nunito(fontSize: 13, height: 1.5, color: mb.textDim)
  SECTION LABEL                 MbSectionLabel('LABEL')

SPACE
  page padding 18               MoodBloomSpacing.pagePadding
  gap sm/md/lg/xl 8/12/16/24    MoodBloomSpacing.{sm,md,lg,xl}
  tap target min 48             MoodBloomSpacing.tapTargetMin

RADIUS
  button 14                     MoodBloomSpacing.radiusButton
  card 20                       MoodBloomSpacing.radiusCardLg
  pill 999                      MoodBloomSpacing.radiusFull

NAV
  bottom nav height 70          kMbBottomNavHeight
  side nav width 240            kMbSideNavWidth

BREAKPOINTS (app shell)
  phone   < 600
  tablet  600..899
  desktop >= 900

BREAKPOINTS (Garden/LogMood body shape)
  1 col   < 720
  2 col   >= 720 (desktop cap 1080–1100)

DOM
  scaffold background           mb.bg
  card background               mb.card
  border                        mb.line, 1px

MOTION
  page transition               NONE
  toast slide                   360 ms easeOut
  segmented toggle indicator    220 ms easeOut

COPY
  garden words                  harvest / complete / new chapter / sheltered / resting
  forbidden                     delete / clear / reset / lost / dying / wilting
  destructive                   theme.colorScheme.error, never raw coral
  em-dash                       use hyphen instead
```
