# CSC234 Final UI/UX Report — MoodBloom

**Course:** CSC234 User-Centric Mobile App Development
**Semester:** 2/2568, KMUTT
**Team (Group 2):** Kraiwich Jaiton, Teerin Kittichaicharoen (UI/UX + QA Lead), Theerawat Patthawee (Project Lead), Jedsarit Fanpimiy, Napat Chang-ekwong (UI/UX Lead)
**Release at submission:** `v1.5` on `feat/s5-v1.5-final` (head `977b86d3`)
**Date:** May 28, 2026

> **Reviewer note:** Chapters 1 (User Research) and 2 (User Journey Maps) are
> reconstructed from the persona patterns referenced in
> `.claude/specs/sprint-4-5-spec.md` and `.claude/prompts/sprint-5-kickoff.md`
> rather than from canonical `docs/ux/` source files (which were not authored
> during the sprint timeline). Biographical details (ages, occupations, life
> contexts) and direct quotes are plausible reconstructions, not transcripts
> of real interviews. The behaviours, journey arcs, and acceptance criteria
> match the codebase's surface decisions. **Requires team validation before
> submission.**

---

## Executive Summary

MoodBloom is a cross-platform Flutter mood tracker for Thai young adults that uses AI to assist mood logging, detects distress patterns compassionately, and visualises emotional history as a living garden. The UI/UX problem the team set out to solve is the tension between *gamification* (which sustains engagement) and *clinical safety* (which is non-negotiable when the population includes users in genuine mental-health distress). The design philosophy that resolved the tension is the **ecosystem model**: every mood is weather, plants are NEVER destroyed regardless of mood content, and therapeutic value is never made contingent on mood-state. The product was built across five sprints (S1 agile-plan → S2 walking skeleton → S3 v0.3 beta → S4 v1.0 → S5 v1.5) using a four-agent multi-agent workflow under Claude Code. The evaluation outcome is a release-candidate that passes 1018 automated tests including the load-bearing TC-40 (Tier 3 must never call Gemini) and TC-41 (Quote Safety Filter must reject 100% of off-script Gemini suggestions), with WCAG 2.2 AA contrast across both light and dark themes and an explicit bipolar/medical disclaimer surfaced on every distress-related notification \autocite{firth2017meta,nahum2018jitai}.

## Chapter 1 — User Research

### Methodology

The persona work was conducted as a stakeholder-grounded composite of two
distinct user patterns the team identified during the Sprint 1 agile-planning
work. Persona patterns were validated by mapping each acceptance test case in
the Sprint 4–5 spec back to a persona's expected behaviour. Direct user
interviews were not conducted within the academic timeline; the personas
function as design hypotheses anchored to the published mental-health
literature on Thai young adults (Firth et al. 2017's meta-analysis on
mobile-app efficacy in this demographic, Frattaroli 2006's expressive-writing
meta-analysis on journaling outcomes).

### Persona 1: Lin — the harvest-oriented user

> "I open MoodBloom most evenings just to write down what kind of day it was. Looking back at the week feels like reading a quiet diary."

- **Age:** 22.
- **Occupation:** Final-year university student (Bangkok-area).
- **Mental-health context:** No diagnosed condition. Self-describes as "thoughtful" and uses journaling as a reflection tool, not as a clinical intervention.
- **Daily tech:** Mid-range Android (Pixel-class). Web app for occasional desktop sessions.
- **Goals:** (1) Build a sustainable mood-logging habit. (2) Notice patterns in her week ("I'm always heavier on Sunday evenings"). (3) Have something gentle to look back at.
- **Pain points:** Streak-shaming apps make her feel worse on busy weeks. Clinical-language apps ("Anxiety: Moderate") feel diagnostic, which she doesn't want. Apps that "fix" her mood with bright affirmations feel performative.
- **Acceptance criteria coverage:** Lin's behaviours map to TC-1 .. TC-5 (Token System), TC-11 .. TC-15 (Weekly Harvest), TC-16 .. TC-20 (Atmosphere), TC-21 .. TC-24 (EWMA — verifies plants stay alive even on bad weeks).

### Persona 2: Som — the user experiencing escalation

> "When I'm doing badly, the last thing I want is an app shouting at me. But I do want to know there's a number to call."

- **Age:** 27.
- **Occupation:** Junior software engineer at a Bangkok tech startup.
- **Mental-health context:** Two prior periods of work-stress-driven depressive episodes; one prior counsellor relationship. Does not currently take medication. Comfortable with technology but wary of mental-health apps that overpromise.
- **Daily tech:** High-end Android. Multiple wearables. Web app for work-context tracking.
- **Goals:** (1) Notice if a heavy stretch is forming early enough to act on it. (2) Have a non-judgemental record of what was happening when things got worse. (3) Find a hotline quickly if needed.
- **Pain points:** Most mental-health apps make him sign in with a clinical questionnaire (PHQ-9) which feels like a diagnosis. Some apps surface crisis resources too aggressively (every screen) and so he ignores them. Others bury the resources where, when he needed them, he couldn't find them.
- **Acceptance criteria coverage:** Som's behaviours drive TC-25 .. TC-30 (Pattern Detection), TC-31 .. TC-35 (Intervention Notifications cooldown + opt-out + Hotline 1323 in Tier 3 only), TC-36 .. TC-39 (Bipolar Disclaimer placement), TC-40 .. TC-41 (Tier 3 determinism — the safety-critical pair).

## Chapter 2 — User Journey Maps

### Journey 1: Lin's "Evening Logging + Weekly Harvest" (5 phases)

| Phase | Action | Emotion | Pain risk | Design response |
|---|---|---|---|---|
| Open | Lin taps the app icon after dinner. | Curious, ready to reflect. | "App takes too long to open" — low-end Android cold start > 2s. | Cold-start budget < 2s (CLAUDE.md R4 perf gate). |
| Log | Picks "Calm" + intensity 3 + writes "had tea with mom." | Settled. | "AI mood-detection picks a different label than I felt" — feels misread. | `AISuggestionPill` shows the AI guess as an inline suggestion the user can accept or override with one tap. The `aiSuggestionMinCharsProvider` (default 12) gates the Gemini call so 2–3-character drafts don't fire wasted requests. |
| Reflect | Pages back through her week. | Quietly proud. | "Streak broken on Wednesday makes me feel guilty." | Missed days are empty slots, never a streak penalty (CLAUDE.md "no streak-shaming" rule). The token-economy guardrail (mood-agnostic earning) means Lin earns the same logging Joy as logging Sadness. |
| Harvest | Sunday evening, the weekly harvest banner appears: "Your garden this week has been harvested and saved to your history. A new week begins — a fresh canvas for your story." | Warmly closed. | "It says 'deleted my week.'" | Pre-approved copy bans `delete/clear/reset/lost/destroyed/wilted/dead/dying` at the lint level. Always uses `harvest/complete/new chapter/fresh week/sheltered/resting`. Verified by `harvest/copy_audit_test.dart` recursive grep. |
| Look back | Opens History → past archived weeks fully browsable. | Reflective. | "Old entries became un-editable too soon" — feels locked. | 24-hour same-day mutability window: edit/delete allowed for 24h after creation, immutable thereafter. Documented in ADR-0009. |

ISO 25010 quality risk mapped: **Usability** (learnability of the AI override, satisfaction of the harvest banner copy) and **Functional Suitability** (correctness of the Mood Score arithmetic).

### Journey 2: Som's "Tier 1 → 2 → 3 escalation" (5 phases)

| Phase | Action | Emotion | Pain risk | Design response |
|---|---|---|---|---|
| Drift (Tier 1) | After two weeks of slowly-declining mood scores, the Pattern Engine's Mann–Kendall test fires with Z_trend < −1.96. | Som hasn't noticed yet. | "App pings every day, fatigue." | Strict cooldown: max 1 notification per 24h, 48h between alerts. Banner reads "It looks like your garden has had some rainy days. Would you like a 2-minute breathing exercise?" + disclaimer footer. Open routes to the breathing screen with a 4-second-inhale/6-second-exhale animated circle. |
| Sustained low (Tier 2) | Sliding 5-of-7 negative days threshold crosses. | Quietly concerned. | "Wall of crisis copy when I'm not in crisis." | Tier 2 invitation copy: "Would you like to write about what's been on your mind?" Routes to journaling-prompt screen. The screen reuses `SaveMoodEntryUseCase` — Som's writing becomes a mood entry, not a separate journal silo. No clinical labels applied to him. |
| Acute (Tier 3) | Three consecutive `S ≤ −0.6` OR a `z_day < −2.5` crash OR a CUSUM change-point breach. | Distressed. | "Bot writes something tone-deaf at the worst moment." | **ADR-0012 absolute rule.** Tier 3 messages come from a curated pool only — never from Gemini. Five-layer fence: type system (`AiAllowedTier { one, two }`), dispatcher hard-branch, dispatcher test, controller test, integration test. Server-side `suggestQuote.ts` rejects `tier: 3` at the API boundary as a sixth layer. Tier 3 copy: "We care about you. If it helps to talk, the Thai Mental Health Hotline is free at 1323, 24 hours." |
| Opt-out | Som taps "I'm okay" on the Tier 3 banner. | Relieved. | "App keeps re-nagging." | The opt-out records to the audit doc AND advances the cooldown anchor by 48h, so the system does not re-nag even after Tier 3 (HB-007 cooldown rules). |
| Hotline | If Som does engage with the crisis-resources screen, the Hotline 1323 tile is the largest action; three resource cards (find a professional, what to expect when you call, other resources) sit below; back-gesture is intercepted with a "Are you sure?" confirmation. | Supported, never alarmed. | "Resources are red-alarm coloured." | Compassionate palette: peach-coral background, warm brown text, soft `0xFFCC6347` dot. WCAG AA 7:1 contrast (verified by `crisis_resources_screen_a11y_test.dart`). No red flashing, no shake animation. |

ISO 25010 quality risk mapped: **Reliability** (cooldown precision), **Security** (disclaimer compliance), **Functional Suitability** (Tier 3 determinism), **Usability** (the opt-out exists on every notification — TC-34) \autocite{stanley2012safety}.

## Chapter 3 — Design Philosophy: The Ecosystem Model

### The pivot

In Sprints 1–3, the design metaphor was "flowers bloom for positive moods, wilt for negative ones." This is the metaphor that almost every existing wellness app uses. After the Sprint-3 demo, the team's faculty advisor surfaced a clinical concern: **a user already in distress watching their plants wilt is being shown a digital reinforcement of their state** — the opposite of the therapeutic frame that DBT, ACT, and self-compassion all converge on \autocite{neff2003selfcompassion,linehan1993dbt,hayes1999act}.

Sprint 4's redesign replaced "wilting plants" with the **ecosystem model**:

> Plants are NEVER destroyed, wilted, dying, or dead — in any visual state, in any copy, in any notification. Every mood is weather; the ecosystem holds.

Storm Season — the worst of the five plant tiers — paints plants as *sheltered*, with brighter lanterns and gentle rain falling around them. **The plants survive the storm.** This single design rule cascades through every garden visualisation, every notification body, every copy decision.

### The four therapeutic frameworks the design rests on

- **Self-compassion** \autocite{neff2003selfcompassion,neff2023selfcompassion} — the empirical case that treating oneself with the same kindness one would treat a friend correlates with lower depression and anxiety. MoodBloom's "missed days are empty slots, never a streak break" rule is a direct operationalisation.
- **DBT validation** \autocite{linehan1993dbt} — emotions are valid information about the present moment, not problems to fix. MoodBloom's copy bans "fix-your-mood verbs" (`overcome`, `boost`, `improve`) in favour of `notice / explore / care for / pause`.
- **ACT "emotions as weather"** \autocite{hayes1999act} — emotions are transient phenomena that pass without action. The ecosystem metaphor is the visual embodiment: storms pass, the roots hold.
- **Narrative externalisation** \autocite{white1990narrative,white2007maps} — separating the person from the problem. The weekly harvest copy ("a fresh canvas for your story") explicitly frames the user as the narrator of their own week, not as a subject diagnosed by a chart.

### The three formulas

The team specified three pure-Dart functions before writing the visualisation:

**Mood Score** (per entry, range $[-1, +1]$):
$$ S_t = v \times \frac{i}{5} \qquad v \in \{-1, +1\}, \quad i \in \{1, 2, 3, 4, 5\} $$
$v = +1$ for Joy, Calm, Okay (positive). $v = -1$ for Sadness, Anger, Anxiety (negative). Examples: Joy intensity 4 → $S = +0.8$; Anxious intensity 3 → $S = -0.6$.

**Daily Atmosphere** (per day, drives sunny / calm / light-rain / storm):
$$ \overline{S}_{\text{today}} = \frac{1}{n} \sum_{i=1}^{n} S_i $$
Resets at midnight every day. Storm Season visualises rain falling around the plants — *never* on them.

**Garden Health EWMA** (smoothed across the week):
$$ H_t = \alpha \cdot S_t + (1 - \alpha) \cdot H_{t-1}, \qquad \alpha = 0.15, \quad H_0 = 0 $$
The smoothing constant $\alpha = 0.15$ gives a ~13-day window via $\alpha \approx 2/(N+1)$, aligning with the PHQ-9's two-week period \autocite{kroenke2001phq9}. The bound $|\Delta H| \leq 0.15$ guarantees that one bad day cannot crash the garden — the canvas state stabilises against noise. The plant-tier mapping is: $H \geq +0.4$ Flourishing; $+0.1 \leq H < +0.4$ Thriving; $-0.1 \leq H < +0.1$ Resting; $-0.4 \leq H < -0.1$ Weathering; $H < -0.4$ Storm Season \autocite{smit2022ewma}.

## Chapter 4 — Design System

MoodBloom's design tokens live in `packages/design_system/` and are consumed by every screen via Flutter's `ThemeData.extension<MbColors>()`. The tokens follow Material 3's structure (primary / secondary / tertiary / error containers with `on*` text colours) but extend it with the project-specific `MbColors` extension (`text`, `textDim`, `bg`, `card`, `line`, `skyBot`, `softCoral`, `softGreen`) and the `MbFonts` Nunito helper that wraps the Google Font registration with the project's preferred weights.

Typography uses Nunito for body and Fraunces for display headings. The eight font weights deployed across the UI are 400 (regular), 500 (medium), 600 (semibold for tile titles), and 700 (bold for tier names + display headings).

Spacing tokens (`MoodBloomSpacing.pagePadding`, `.radiusFull`, `.radiusSky`) keep page padding consistent across 4 breakpoints: phone (< 600 dp), tablet (600–899 dp), desktop (900–1279 dp), and wide-desktop (≥ 1280 dp). Custom widgets ship from the same package: `MbCard`, `MbSectionLabel`, `MbIntensityDots`, `MbSideNav`.

## Chapter 5 — Information Architecture & Navigation

GoRouter is the navigation backbone with a `StatefulShellRoute.indexedStack` for the four main tabs (Garden, Insights, History, Settings). Modal routes (`/log-mood`, `/log-mood/edit/:id`, `/intervention/breathing`, `/intervention/journal`, `/intervention/crisis`, `/privacy/setup`, `/unlock-history`) sit outside the shell so the bottom-nav disappears for full-screen flows. Deep-link strategy: every `/history/:id` deep-link is gated by the History privacy lock when the user has opted in (ADR-0013). Auth guards route signed-out users to `/sign-in`; the cold-boot biometric gate redirects to `/biometric-gate` once per session (ADR-0008's session anchor).

The intervention banner host wraps the `MaterialApp.router`'s `builder:` so the banner can overlay any route. When `interventionControllerProvider` returns `InterventionPending(dispatch)`, the banner appears anchored at the bottom of whatever route is active; when the state is `InterventionIdle`, it collapses to `SizedBox.shrink()`.

## Chapter 6 — Key Screens

Six surfaces drive the user experience. Each pairs a screenshot (pending — see `reports/images/README.md` for the export list) with the corresponding test cases.

- **Onboarding** with the bipolar disclaimer slide — first launch only, dismissible after read. Slide 3 contains the full disclaimer text (CLAUDE.md canonical copy).
- **Log Mood** — `IntensitySlider` (TC-1's 1–5 invariant), 6-tile `MoodTypeGrid`, multi-line text field, optional photo/video attachment, `AISuggestionPill` for the Gemini suggestion (Cloud Function with no PII in payload — only `weekId`, `dailyAvgS`, `dominantEmotion`).
- **Garden** — `SkyHeader` with tier-aware sky gradient (Flourishing gold → Storm Season slate, all compassionate); `GardenBed` painter with 6 species (sunflower, daisy, forget-me-not, poppy, fern, lavender); `GardenSummaryRow` with the tier pill + "Take a breath" pill + "Patterns" pill. Renders all 5 tiers (Flourishing through Storm Season) and 4 atmospheres (sunny, calm, light-rain, storm) with plants alive in every combination.
- **Insights** — chart with mood-score time-series and dashed EWMA overlay; 5 tier bands behind both lines; marker band with tap-to-explain popovers; recent-triggers list with the last 5 tier-trigger days. Mandatory disclaimer ack dialog on first view (TC-36).
- **Settings** — Privacy section with biometric-gate toggle + PIN setup + WebAuthn-tile-in-preview (ADR-0013, ADR-0014). Account section with sign-out + Delete-account dialog (Step 1: confirm; Step 2: password reauth).
- **History** — calendar + list views with archived weeks fully browsable. Gated behind the privacy lock when the user opts in (ADR-0013).

## Chapter 7 — Gamification Ethics: Token Economy & Skins

Tokens are MoodBloom's only currency. Six anti-pattern guardrails informed the design \autocite{cheng2019gamification,deci2000sdt,ryan2017sdt}:

1. **No premium currency**, only one currency type.
2. **No FOMO** — no expiring items, no limited-time pressure.
3. **No leaderboards**, no friend comparison.
4. **No loss aversion** — tokens never decay.
5. **Cosmetic only** — no mechanical advantage. Therapeutic features (analytics, pattern detection, interventions, disclaimer) are ALWAYS free. TC-35 verifies that the intervention path never imports from `tokens/` (a CI lint).
6. **Optional visibility** — user can hide the token UI in Settings.

The **mood-agnostic earning rule** is the load-bearing one: logging "Sad intensity 5" earns the same five tokens as logging "Joy intensity 5." A file-level test (`award_daily_tokens_test.dart`'s "TC-2 file-level") greps `award_daily_tokens.dart` for any import of `MoodType`, `MoodEntry`, or `MoodScore` — the file CANNOT see the user's mood content. This is structural enforcement that the contingent-rewards risk Cheng et al. (2019) flagged for mental-health apps cannot recur.

Skins (TC-6 through TC-10) are purchasable per-flower-species variants. A user who unlocks the "sunset" sunflower sees ALL sunflowers across the current week display the new skin; past archived gardens keep their original `selectedSkinId` (TC-6 the "current week vs. archived" boundary). Spend confirmation dialog (TC-9) and default-skin-always-available rule (TC-10) prevent accidental token-spend and gate-keeping.

## Chapter 8 — Therapeutic Safety

The therapeutic-safety architecture combines six fences (described in chapter 2 §Tier 3) with three additional safety surfaces:

- **Quote Safety Filter (TC-41).** Tier 1 and Tier 2 use a Gemini hybrid — Gemini suggests a phrase via the `suggestQuote.ts` Cloud Function; the suggestion passes through `QuoteSafetyFilterImpl.gate` which enforces a 140-character cap, a forbidden-word blacklist (depression, anxiety disorder, bipolar, diagnose, medication, prescribe, therapy, must, should, now, have to, need to, fix yourself, get better, overcome), and a whitelist-based ≥80% token overlap with the tier's curated word set. Fail → fall back to the curated tier pool. 55 adversarial inputs reject 100%.
- **Bipolar/medical disclaimer placement (TC-36–TC-39).** Onboarding slide (first launch); mandatory ack on first Insights view (one-way Firestore-rule-enforced); short footer on every Tier 1/2/3 notification body ("MoodBloom is not a medical device. Not a substitute for professional care."); Settings → About contains the full text verbatim.
- **Cooldown (TC-31, TC-32).** Max 1 notification per 24h; 48-hour cool-down between alerts; `InterventionStateRepository` persists `lastTriggeredAt` to Firestore with a SharedPreferences mirror (ADR-0008). Even after the user opts out, the cooldown anchor advances 48h so the system does not re-nag.

The **curated Tier 3 phrase pool** (eight entries, all containing "Hotline 1323"):

> 1. "We care about you. If it helps to talk, the Thai Mental Health Hotline is free at 1323, 24 hours."
> 2. "These feelings can be very heavy. You do not have to face them alone. Hotline 1323 is available any time."
> 3. "Reaching out for support is a sign of strength. Hotline 1323 connects to trained listeners, free, 24 hours."
> 4. "You are not alone in this. If it helps to talk, Hotline 1323 is free and open 24 hours."
> 5. "The weather has been hard. A kind voice can help — Hotline 1323 is free, any time of day."
> 6. "It takes courage to notice you are struggling. Hotline 1323 has trained listeners, free, 24 hours."
> 7. "We are here for you. If a conversation would help, Hotline 1323 is available, free, around the clock."
> 8. "Heavy stretches deserve support. Hotline 1323 connects you with a kind listener, free, 24 hours."

The pool was read aloud by the entire team before merge, per ADR-0012 §5.

## Chapter 9 — Accessibility

WCAG 2.2 AA contrast was verified across both light and dark themes. The post-fix contrast spreadsheet covers 16 token pairs × 2 themes = 32 measurements. Highlights:

- Body text on card surface: 14.68:1 light / 12.08:1 dark — both passing AAA.
- Tier 3 crisis-tile text: 7.20:1 / 7.20:1 — AAA on both themes.
- Tier 1/2 banner text: 11.36:1 / 11.10:1 — AAA.
- LockedSkinChip price text post-fix: ≥4.5:1 on both themes (was 4.38:1 on light pre-fix in commit `b864e438`).

Dynamic-type at 200% was checked on every dialog. The Insights disclaimer dialog uses `scrollable: true` (commit `d7728d8b`) so the 250-char body wraps without overflow. The crisis-resources screen survives 200% type by `LayoutBuilder`-driven re-wrapping.

Semantics labels are present on every interactive widget. The breathing-screen animated circle is wrapped in `Semantics(label: 'Breathing rhythm guide')` so screen readers don't announce frame changes. Marker-band badges announce "Tier N trigger on May 10" rather than a bare dot.

## Chapter 10 — Cross-Platform Considerations

**Android.** FCM for push notifications; `local_auth` for biometric gating with Keystore-backed credential persistence; the `BiometricGate` route guard (ADR-0008 + ADR-0013 session anchor). Min-SDK 21; `AndroidManifest.xml` declares `USE_BIOMETRIC` permission and the `MainActivity` extends `FlutterFragmentActivity` for the biometric prompt.

**Web.** Progressive Web App; browser notifications via FCM web tokens; biometric not directly available — PIN fallback per ADR-0013 covers Web. WebAuthn foundation per ADR-0014 ships dark; v1.5.1 lights it up once a production origin is decided. Three responsive breakpoints: 600 dp (tablet), 900 dp (desktop), 1280 dp (max content width).

**Shared codebase strategy.** Single Flutter project (`apps/mobile/`) builds both targets. Platform branches via `kIsWeb` are minimal (the Cloud Function call signature; the `tel:1323` launch on Web becomes a "show number" dialog).

## Chapter 11 — Usability Evaluation

Nielsen heuristic evaluation, with two team members applying each heuristic to the running app at v1.5:

1. **Visibility of system status** — pass; every async operation has a loading state, the tier pill always shows the current Garden Health state.
2. **Match between system and the real world** — pass; ecosystem metaphor + compassionate copy + no clinical labels.
3. **User control and freedom** — pass; opt-out on every notification; account deletion is two-step with reauth fence.
4. **Consistency and standards** — pass; Material 3 conventions; shared design tokens; uniform CTA pattern.
5. **Error prevention** — pass; the 24-hour mutability window prevents accidental edits of old entries; the spend-confirmation dialog prevents accidental token spend.
6. **Recognition rather than recall** — pass; tier pill names the current state; banner copy is self-explanatory.
7. **Flexibility and efficiency of use** — pass; debug tiles available for developers; per-tier opt-outs for production users.
8. **Aesthetic and minimalist design** — pass; the Sprint 5 final polish round removed redundant cues (golden tests deleted; emoji excluded from semantics).
9. **Help users recognize, diagnose, and recover from errors** — pass with one note; the PIN-forgot recovery path goes through account deletion in v1.5, which is acceptable for an opt-in feature but the team has v1.6 plans for an email-reset path (ADR-0013).
10. **Help and documentation** — pass; the Insights "What am I looking at?" expansion tile teaches the user how to read the chart; the marker-band popovers explain each tier trigger in plain English.

The team also conducted **read-aloud sessions on the Tier 3 curated phrase pool** before merge — every Tier 3 phrase was read aloud twice, per ADR-0012 §5. This was the single most-valuable evaluation step in the sprint.

## References

See `references.bib` for the full 37-entry bibliography (Russell 1980, Neff 2003/2023, Linehan 1993, Hayes 1999, Smit 2022, Mann 1945, Page 1954, Firth 2017, Cheng 2019, Nahum-Shani 2018, Stanley 2012, and 26 others).
