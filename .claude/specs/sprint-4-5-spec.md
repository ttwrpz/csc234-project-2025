# Sprint 4–5 Ecosystem Spec

**Authoritative reference for all Sprint 4–5 work.** Every agent must read this before working on any S4–S5 task. Sprints 1–3 are unchanged and out of scope here.

---

## 1. Core Philosophy

**Plants are NEVER destroyed/wilting/dying in any visual state, copy, or notification.** Every mood is weather; the ecosystem holds. Replaces the original "wilting plants for negative intensity 1–3 / rain clouds 4–5" reframing from Sprint 3.

**Grounded in:**
- Self-compassion (Neff 2003, *Self and Identity*; 2023, *Annual Review of Psychology*)
- DBT validation principle (Linehan 1993, *Cognitive-Behavioral Treatment of Borderline Personality Disorder*, Guilford)
- ACT "emotions as weather" metaphor (Hayes, Strosahl & Wilson 1999, *ACT*, Guilford; Harris 2008, *The Happiness Trap*)
- Narrative externalization (White & Epston 1990, *Narrative Means to Therapeutic Ends*, Norton)

In ALL user-facing copy, garden states, animations, and notifications — plants must be alive. The worst tier ("Storm Season") shows plants sheltered under rain, lanterns glowing brighter, never dead/wilting.

---

## 2. Formulas

### 2.1 Mood Score (per entry)

```
S_t = v × (i / 5)

v ∈ {-1, +1}    sign by emotion category
i ∈ {1, 2, 3, 4, 5}
S_t ∈ [-1, +1]
```

**Sign mapping:**
- Positive (v = +1): Joy, Calm, Okay
- Negative (v = -1): Sadness, Anger, Anxiety

**Examples:**
- Joy intensity 4 → S = +0.8
- Anxious intensity 3 → S = -0.6
- Calm intensity 1 → S = +0.2
- Anger intensity 5 → S = -1.0

**Citations:** Russell (1980, *JPSP* 39, 1161–1178); Watson, Clark & Tellegen (1988, *JPSP* 54, 1063–1070).

### 2.2 Daily Atmosphere

```
For all entries i logged today:
  S_i = v_i × intensity_i / 5
avg_S_today = (1/n) × Σ S_i

avg_S_today ≥ 0 → Positive atmosphere (peaceful, sunlit)
avg_S_today < 0 → Negative atmosphere (rain, storm)
```

**Intensity scaling:**
- Positive + |avg_S| < 0.3 → calm sunny
- Positive + |avg_S| ≥ 0.3 → bright sunny
- Negative + |avg_S| < 0.3 → light rain / overcast
- Negative + |avg_S| ≥ 0.3 → storm

**Critical:** Even in "storm," plants are NEVER dead. Storm is weather around the garden; plants are sheltered.

Resets at midnight every day.

### 2.3 Garden Health EWMA

```
H_t = α × S_t + (1 - α) × H_{t-1}
α = 0.15
H_0 = 0  (resets weekly)
```

**Why α=0.15:** ~13-day window via α ≈ 2/(N+1), aligns with PHQ-9's 2-week period. One bad day shifts H by ≤ 0.15 — garden cannot drop more than one tier in a single day.

**Worked example:**
- H_0 = 0
- Day 1: S = +0.6 → H_1 = 0.15(0.6) + 0.85(0) = +0.09
- Day 2: S = -0.8 → H_2 = 0.15(-0.8) + 0.85(0.09) = -0.04
- Day 3: S = +0.4 → H_3 = 0.15(0.4) + 0.85(-0.04) = +0.03

**Plant State Mapping:**

| H_t | State | Visual |
|---|---|---|
| ≥ +0.4 | Flourishing | Full bloom, butterflies |
| +0.1 ≤ H < +0.4 | Thriving | Steady growth, full leaves |
| -0.1 ≤ H < +0.1 | Resting | Neutral, dormant |
| -0.4 ≤ H < -0.1 | Weathering | Overcast, gentle rain (NOT damage) |
| < -0.4 | Storm Season | Rain falls, plants sheltered (NEVER dead) |

**Citations:** Smit, Schat & Ceulemans (2022), *Assessment* 30(4), 1354–1376; Kroenke, Spitzer & Williams (2001), *J Gen Intern Med* 16, 606–613.

### 2.4 Pattern Engine — 5 Algorithms

#### Algorithm 1: Mann-Kendall Trend Test

```
Step 1: S = Σ_{i<j} c_ij where c_ij = sign(x_j - x_i)
Step 2: V = n(n-1)(2n+5) / 18
Step 3: Z_trend = (S - 1)/√V if S>0; 0 if S=0; (S+1)/√V if S<0
Step 4: |Z_trend| > 1.96 → significant trend (α = 0.05)
        Z_trend < -1.96 → Tier 1
        Z_trend > +1.96 → encouragement (no alert)
```

Window: 14 days. Two-tailed (1.96) over one-tailed (1.645) — fewer false alarms, less alert fatigue.

**Citations:** Mann (1945), *Econometrica* 13, 245–259; Kendall (1975), *Rank Correlation Methods*.

#### Algorithm 2: Sliding 5-of-7

```
neg_days = count(S_t < 0 in last 7 days)
neg_days ≥ 5 → Tier 2
```

Mirrors PHQ-9 "more than half the days."

#### Algorithm 3: 3-Consecutive High-Intensity

```
S_{t-2} ≤ -0.6 AND S_{t-1} ≤ -0.6 AND S_t ≤ -0.6 → Tier 3
```

#### Algorithm 4: Z-Score Anomaly (single-day)

```
z_day = (S_t - μ_30) / σ_30

|z_day| > 2 → flag unusually extreme
z_day < -2.5 → Tier 3
```

**IMPORTANT:** `z_day` is NOT the same as `Z_trend` from Mann-Kendall. They use the same letter but detect different things:
- `Z_trend` = trend over 14 days (gradual worsening)
- `z_day` = single day vs personal 30-day baseline (sudden crash)

#### Algorithm 5: CUSUM Change-Point

```
C_t = max(0, C_{t-1} + (μ_30 - k) - S_t)
k = 0.5 × σ_30   (slack)
h = 4 × σ_30      (threshold)
C_t > h → Tier 3
```

**Citation:** Page (1954), *Biometrika* 41, 100–115.

#### Why five methods?

| Algorithm | Catches |
|---|---|
| Mann-Kendall | Gradual worsening |
| Sliding 5-of-7 | Sustained lows |
| 3-Consecutive | Acute crisis |
| Z-score | One-off alarming day |
| CUSUM | Sudden sustained shift |

No single method covers all five failure modes. Together they form a comprehensive net.

### 2.5 Tiered Intervention

| Tier | Trigger | Response |
|---|---|---|
| 1 (Mild) | Mann-Kendall Z_trend < -1.96 | 2-min breathing exercise |
| 2 (Moderate) | 5-of-7 negative days | Journaling prompt with supportive copy |
| 3 (Acute) | 3-consecutive S ≤ -0.6 OR z_day < -2.5 OR CUSUM breach | Crisis resources + Hotline 1323 |

**Dosing rules:**
- Max 1 notification per day
- 48-hour cool-down between alerts
- Every notification includes opt-out / "I'm okay" button
- Tier 3 ALWAYS includes professional help signposting + Hotline 1323

**Citation:** Just-In-Time Adaptive Interventions framework — Nahum-Shani et al. (2018), *Annals of Behavioral Medicine* 52(6), 446–462.

### 2.6 Pipeline

```
Mood entry → Compute S_t → Update H_t (EWMA)
                               │
                               ├── Render today's ATMOSPHERE (avg_S_today)
                               ├── Render PLANT STATE (H_t)
                               └── PATTERN CHECK (5 algorithms)
                                       │
                                       ├── If trigger AND cooldown OK:
                                       │     → Emit Tier-N notification
                                       │       (Tier 1/2: Gemini quote → safety filter; Tier 3: curated only)
                                       └── Else: passive logging only
```

---

## 3. Quote Library Architecture

### 3.1 Tier 3 — CURATED ONLY (deterministic safety)

**No Gemini call ever.** Tier 3 messages come exclusively from the pre-approved curated phrase pool. This is non-negotiable. A bad message at Tier 3 — when the user is at their most vulnerable — could cause real harm. Determinism over personalization.

**Pre-approved Tier 3 messages (rotate from this fixed pool):**
1. "We care about you. If it helps to talk, the Thai Mental Health Hotline is free at 1323, 24 hours."
2. "These feelings can be very heavy. You don't have to face them alone. Hotline 1323 is available any time."
3. "Reaching out for support is a sign of strength. Hotline 1323 connects to trained listeners, free, 24 hours."

(Team to expand to 8–12 curated entries during S5 implementation. ALL phrasings to be reviewed by the full team before merge — read aloud, sense-check.)

**Tier 3 footer:** Always includes the disclaimer + Hotline 1323 link.

### 3.2 Tier 1 / Tier 2 — Hybrid (Gemini + Safety Filter)

Gemini may suggest a quote, but the **Quote Safety Filter** runs first. If the suggestion contains anything off-script — clinical terms ("depression," "bipolar," "diagnosis," "medication," "therapy"), urgency words ("must," "should," "now"), or any language not in the pre-approved tag pool — the filter REJECTS Gemini's output and falls back to a curated phrase from the corresponding tier pool.

**Filter implementation:**
- Whitelist-based: phrases must contain ≥80% of words from the tier's approved-word list, OR match a curated template.
- Forbidden-word blacklist: any match → reject, no exceptions.
- Length cap: 140 chars max (notification body).
- Fallback: if Gemini call fails or filter rejects → curated phrase.

**Tier 1 curated examples:**
- "It looks like your garden has had some rainy days. Would you like a 2-minute breathing exercise?"
- "Rainy days happen. A short breath might help — only if you'd like."

**Tier 2 curated examples:**
- "Would you like to write about what's been on your mind?"
- "Sometimes putting feelings into words helps. Want to try?"

---

## 4. Bipolar/Medical Disclaimer

### Wording (canonical — do not paraphrase)

**Full version (onboarding slide, Settings, Insights ack):**
> "MoodBloom is not a medical device. It cannot diagnose conditions like bipolar disorder, depression, or anxiety. The patterns and insights it shows are observational only. If you're concerned about your mental health, please consult a qualified professional."

**Short version (notification footer):**
> "MoodBloom is not a medical device. Not a substitute for professional care."

### Placement (b + c combined per product decision)

1. **Onboarding slide** — first launch only, dismissible after read.
2. **Settings → About → Disclaimer** — always available.
3. **Notification footer** — every Tier 1, 2, 3 intervention notification.
4. **Insights screen mandatory ack** — first time the user opens Insights / Pattern Detection screen, a non-dismissible dialog appears with the full version. User must tap "I understand" to proceed. State persisted in `users/{uid}.insightsDisclaimerAcked`.

---

## 5. Token Economy

### Earning rules
- Tokens earned ONLY by daily login + mood log.
- Daily cap: 5–10 tokens (suggested: first log = 5, additional logs up to 10).
- Tokens are **NEVER** tied to mood content. Logging "Sad intensity 5" earns the same as "Joy intensity 5."
- No streak punishment — missed days lose nothing.

### Spending rules
- Spent ONLY on cosmetic flower skins.
- Therapeutic features (analytics, pattern detection, interventions, disclaimer) are ALWAYS free.

### Anti-pattern guardrails
1. No premium currency, only one currency type.
2. No FOMO (no expiring items, no limited-time pressure).
3. No leaderboards, no friend comparison.
4. No loss aversion — tokens never decay.
5. Cosmetic only — no mechanical advantage.
6. Optional visibility — user can hide token UI in Settings.

**Citations:**
- Self-Determination Theory: Deci & Ryan (2000), *American Psychologist* 55, 68–78.
- Cheng et al. (2019), *JMIR Mental Health* 6(6), e13717 — warning against contingent rewards on mood content.

---

## 6. Weekly Harvest Cycle

- 7-day cycle. At week's end, garden archives to History page.
- New empty garden begins; H_0 resets to 0.
- All past gardens preserved and browseable in History.
- Weekly Summary screen appears before harvest with: dominant emotions, growth highlights, week's avg mood, pattern triggers (if any). User taps "Continue to new week."

### Copy rules (CRITICAL)
- **NEVER use:** delete, clear, reset, lost, destroyed, gone, erased
- **ALWAYS use:** harvest, complete, new chapter, fresh week, archived, preserved

**Citations:**
- White (2007), *Maps of Narrative Practice*, Norton — narrative chapters.
- Locke & Latham (2002), *American Psychologist* 57, 705–717 — goal cycles.

---

## 7. Test Cases (35 — must all pass)

### Token System (5)
1. User logs mood → receives tokens (5–10, within daily cap).
2. User logs "Joy intensity 5" → same tokens as "Sad intensity 5" (mood-agnostic).
3. User reaches 10 tokens in a day → additional logs do not earn more.
4. Token counter resets at midnight.
5. User who misses a day → no tokens lost, no streak broken, no punishment.

### Flower Skins (5)
6. User unlocks a sunflower skin → ALL sunflowers in current garden display new skin.
7. User taps a flower → mood entry detail view opens correctly.
8. Skin modal shows locked skins with correct token cost.
9. Spending tokens reduces balance correctly with confirmation dialog.
10. Default skin always available without purchase.

### Weekly Harvest (5)
11. After 7 days → garden archives to History; new garden starts with H_0 = 0.
12. Archived garden fully viewable in History page.
13. Tapping a flower in archived garden shows original mood entry.
14. Weekly summary screen appears before harvest with correct stats.
15. User-facing copy NEVER says "delete," "clear," or "reset."

### Atmosphere (5)
16. User logs 1 positive (S=+0.8) and 1 negative (S=-0.4) → avg_S = +0.2 → positive atmosphere.
17. Atmosphere resets at midnight regardless of previous day.
18. Storm atmosphere shows plants as sheltered, NEVER dead.
19. Day/night theme matches device settings when "Follow device theme" is selected.
20. Day/night theme matches local time when "Follow device time" is selected.

### Garden Health EWMA (4)
21. H starts at 0 for a new week.
22. After logging Joy intensity 4 (S=+0.8): H = 0.15(0.8) + 0.85(0) = +0.12.
23. One negative day (S=-1.0) from H=+0.4 → H = +0.19; still Thriving, NOT crashed.
24. Plants are alive in EVERY plant state, including Storm Season.

### Pattern Detection (6)
25. 5 of last 7 days negative → Tier 2 fires (if cooldown allows).
26. 3 consecutive S ≤ -0.6 → Tier 3 fires.
27. Mann-Kendall on steadily declining 5-day window → Z = -2.21 → Tier 1 fires.
28. Z-score: μ_30=+0.3, today=-0.9 → z_day large negative → flagged.
29. CUSUM: sustained mood below personal mean accumulates C_t → crosses threshold → Tier 3.
30. Pattern detection works correctly across week boundaries (sliding windows do NOT reset on harvest).

### Intervention Notifications (5)
31. Max 1 notification per 24h — second trigger same day suppressed.
32. After firing, 48h cooldown prevents another.
33. Tier 3 always includes crisis resources + Hotline 1323 link.
34. All notifications include "I'm okay" opt-out button.
35. Intervention features are NEVER locked behind tokens.

### Bipolar Disclaimer (additional — 4)
36. First Insights screen view shows mandatory ack dialog; user must tap "I understand" to proceed.
37. Ack state persists across app restarts (`users/{uid}.insightsDisclaimerAcked`).
38. Every Tier 1/2/3 notification body includes disclaimer footer line.
39. Settings → About contains the full disclaimer text.

### Tier 3 Determinism (additional — 2)
40. For any input pattern producing Tier 3, output message is byte-for-byte from the curated pool — NO Gemini call attempted (verify by mocking Gemini and asserting it was not called).
41. Quote Safety Filter rejects 100% of test cases containing forbidden terms (depression, bipolar, diagnosis, medication).

---

## 8. Citations (37)

### Theoretical
1. Russell (1980). Circumplex of affect. *JPSP* 39, 1161–1178.
2. Watson, Clark & Tellegen (1988). PANAS. *JPSP* 54, 1063–1070.
3. Neff (2003). Self-compassion. *Self and Identity* 2(2), 85–101.
4. Neff (2023). Self-compassion. *Annual Review of Psychology* 74, 193–218.
5. MacBeth & Gumley (2012). *Clinical Psychology Review* 32(6), 545–552.
6. Hayes, Strosahl & Wilson (1999). *ACT*. Guilford.
7. Linehan (1993). *DBT*. Guilford.
8. White & Epston (1990). *Narrative Means to Therapeutic Ends*. Norton.
9. White (2007). *Maps of Narrative Practice*. Norton.
10. Deci & Ryan (2000). SDT. *American Psychologist* 55, 68–78.
11. Ryan & Deci (2017). *Self-Determination Theory*. Guilford.
12. Barrett (2004). Emotional granularity. *Cognition and Emotion* 18, 713–724.
13. Kashdan, Barrett & McKnight (2015). *Current Directions in Psych Sci* 24, 10–16.
14. Kellert, Heerwagen & Mador (2008). *Biophilic Design*. Wiley.
15. Locke & Latham (2002). *American Psychologist* 57, 705–717.

### Algorithms & Methods
16. Smit, Schat & Ceulemans (2022). EWMA. *Assessment* 30(4), 1354–1376.
17. Mann (1945). *Econometrica* 13, 245–259.
18. Kendall (1975). *Rank Correlation Methods*. Griffin.
19. Page (1954). CUSUM. *Biometrika* 41, 100–115.
20. Kroenke, Spitzer & Williams (2001). PHQ-9. *J Gen Intern Med* 16, 606–613.

### Evidence of Efficacy
21. Firth et al. (2017). Mobile MH apps meta-analysis. *World Psychiatry* 16(3), 287–298. (g=0.38)
22. Kauer et al. (2012). *JMIR* 14(3), e67.
23. Bakker & Rickard (2018). MoodPrism. *J Affective Disorders* 227, 432–442.
24. Frattaroli (2006). Expressive writing meta-analysis. *Psychological Bulletin* 132(6), 823–865.
25. Liu et al. (2025). Virtual nature. *npj Digital Medicine*.
26. Hubbard et al. (2025). VR nature meta-analysis. *Applied Psychology: Health and Well-Being*.

### Gamification & Design
27. Cheng et al. (2019). Gamification in MH apps. *JMIR Mental Health* 6(6), e13717.
28. Marlatt & Gordon (1985). *Relapse Prevention*. Guilford.
29. Nahum-Shani et al. (2018). JITAIs. *Annals of Behavioral Medicine* 52(6), 446–462.
30. Stanley & Brown (2012). Safety planning. *Cognitive and Behavioral Practice* 19, 256–264.
31. Torous et al. (2019). Digital psychiatry. *World Psychiatry* 18(3).

### Nature & Wellbeing
32. Wilson (1984). *Biophilia*. Harvard.
33. Kaplan & Kaplan (1989). *The Experience of Nature*. Cambridge.
34. Ulrich (1984). View through a window. *Science* 224(4647), 420–421.
35. Pennebaker (1997). *Psychological Science* 8, 162–166.
36. Czeisler et al. (2014). *Health Affairs*.
37. Erickson et al. (2020). *Applied Ergonomics* 88.

---

## 9. Professor's Feedback Mapping

| Comment | Where Addressed |
|---|---|
| "References used in the work?" | 37 citations across all features. |
| "What happens to healthy garden when moody comes? Reference or formula?" | EWMA H_t = 0.15·S_t + 0.85·H_{t-1}; ≤0.15 daily shift; plants never die. Refs: Smit et al. 2022, Neff 2003/2023, Linehan 1993. |
| "Show real analytics and pattern recognition with math" | 5 algorithms: Mann-Kendall (4-step derivation), sliding window, 3-consecutive, Z-score, CUSUM. All formulas + worked examples. Refs: Mann 1945, Page 1954, Kroenke 2001. |
| "How can it help the user really?" | Firth et al. 2017 (g=0.38); Kauer 2012; Frattaroli 2006 (146 studies); Liu 2025. |
| Bipolar warning + medical disclaimer (post-S3) | (b)+(c) combined: notification footer + Insights ack-on-first-use + Settings + onboarding slide. See section 4. |
| Personalize quotes for notifications (post-S3) | Tier 1/2 = Gemini hybrid + Safety Filter; Tier 3 = curated only, deterministic, no Gemini. See section 3. |
