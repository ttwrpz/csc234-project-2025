# MoodBloom — Live Demo Script (Whole-App Tour, 3–4 min)

**Release:** v1.6 · slots into **Slides 7–10** of `presentation.tex`
**Windows:** ① mirrored Android phone (scrcpy/Vysor) · ② the same app in Chrome (web build)
**Audience:** mixed committee, **not deeply technical** — no jargon in the spoken lines
**Cadence:** 150 wpm → 30s ≈ 75 words · 45s ≈ 112 words
**Driver:** written speaker-neutral. Per `role-assignment.md` this is Jedsarit's section, but it works solo.

> This script extends the original 5-beat demo (Slide 7) into a whole-app tour. The original
> beats survive — cross-platform, auth, a11y (one-liner), and the canned intervention — plus
> Garden, History, Patterns, Skin Shop, and Settings. **Offline-first is one spoken sentence,
> not a live airplane-mode toggle** (deliberately de-risked; the claim stays, the gamble goes).
> The deck itself is **not** changed; a paste-ready Slide 7 snippet is at the bottom.

---

## The flow at a glance

| # | Time | Beat | Window | What happens on screen |
|---|------|------|--------|------------------------|
| 0 | 0:00–0:15 | Stage set | both | Both windows visible side by side |
| 1 | 0:15–0:35 | Unlock (auth) | ① phone | Cold open → Privacy Lock → biometric/PIN → Garden home |
| 2 | 0:35–1:15 | Log a mood (core loop) | ① phone | `+` tab → mood + intensity slider → short text → AI pill → Save → garden responds |
| 3 | 1:15–1:35 | Sync to web (+ offline line) | ① → ② | Pivot to Chrome — the entry just logged is already there; one sentence on offline-first |
| 4 | 1:35–2:15 | Garden & History | ② web | Plant tiers + weather → History tab → browse a harvested week → open an entry |
| 5 | 2:15–3:00 | Patterns & care | ② web (+video) | Patterns tab + disclaimer banner → canned Tier-1 banner → breathing screen |
| 6 | 3:00–3:30 | Shop & Settings close | ① phone | Customize → Skin Shop (tokens) → Settings → dark mode → close line |

**Total: ~3:30.** Compression to 3:00 — see "If you only have 3 minutes" below.

---

## Pre-show checklist (do this tonight, re-verify 30 min before)

**Account & data**
- [ ] One **seeded demo account**, signed in on **both** windows (same account — Beat 3's sync glance depends on it).
- [ ] At least **3 weeks of entries** so History shows harvested weeks and Patterns shows insight cards.
- [ ] Keep today's entries mildly positive in seeding, so the live log moves the garden visibly.
- [ ] Do **not** plan a live intervention trigger — the cooldown guard blocks it (that's the feature). Tier-1 is canned.
- [ ] Do **not** demo airplane mode live — offline-first is covered by one spoken line in Beat 3.
      (Verify sync works on venue Wi-Fi once before the talk: log a throwaway-positive mood on the
      phone, confirm it reaches Chrome, edit it into your seed story or leave it — never remove it on stage.)
- [ ] Make that throwaway mood a **text** entry (12+ characters) and wait for the AI pill — this
      pre-warms the Gemini function. Cold-start measured at ~5s for the first call after idle vs
      ~1.4s warm; warming it 5–10 min before the talk keeps Beat 2's AI moment snappy.
- [ ] AI pill needs the network: in airplane mode (or mid-reconnect) it shows "Couldn't analyze —
      pick manually or retry." That's by design, not a bug — verified 2026-06-05: zero server-side
      failures, all errors were device-offline moments.

**Phone (window ①)**
- [ ] Release APK installed; app opens to **Privacy Lock** (lock enabled, biometric enrolled, PIN known by heart).
- [ ] Mirror via scrcpy/Vysor; portrait; brightness max; **Do Not Disturb on**; ringer muted; battery > 50%.

**Web (window ②)**
- [ ] `./scripts/run_web.ps1` (pins port 5173) **or** the hosted release build; already signed in.
- [ ] Window pre-sized; browser zoom ~125% so the projector can read it; sitting on the **History** tab (so Beat 3's new entry lands visibly).
- [ ] Optional Beat 5 live variant rehearsed once (see Beat 5).

**Fallbacks**
- [ ] Backup videos queued in a third (hidden) window: Tier-1 walkthrough clip, a11y clip.
      (Keep the offline-sync clip queued too — not for the demo, but as a Q&A receipt if the
      committee asks "does it really work offline?")
- [ ] Slide 8 (screenshots) and Slide 10 (banner + breathing stills) are your zero-tech fallbacks — the deck already carries them.
- [ ] Venue Wi-Fi tested; phone hotspot as backup network for the sync moment.

---

## Verbatim script

### Beat 0 · Stage set · 0:00–0:15 · both windows (~38 words)

**[DO: both windows already side by side — phone mirror left, Chrome right.]**

> "Two windows. On the left, a real Android phone. On the right, the very same app
> running in Chrome. One codebase, built by one small team — phone, tablet, and web.
> Let's use it the way Lin would, every day."

### Beat 1 · Unlock · 0:15–0:35 · phone (~50 words)

**[DO: open the app cold → Privacy Lock appears → unlock with fingerprint (PIN as backup).]**

> "First thing: this is a private journal, so it opens locked. Fingerprint — or a PIN —
> and on the web it's a passkey. [unlock] And we arrive in the garden. Every plant here
> is a real week of someone's life. We'll come back to it in a moment."

**[FALLBACK: biometric fails twice → type the PIN without comment and keep talking.]**

### Beat 2 · Log a mood — the core loop · 0:35–1:15 · phone (~100 words)

**[DO: tap the highlighted `+` tab. Pick a mood chip. Drag the intensity slider. Type one short
line, e.g. "Presenting our project today — nervous but excited." Wait a beat for the AI pill.]**

> "The heart of the app: logging takes under thirty seconds. I pick how I feel, and —
> this matters — how *strongly*, one to five. A nervous-but-okay day and an overwhelming
> day are different days, and the garden should know.
>
> I can write a line if I want — and notice the app gently suggests a mood from my own
> words. It suggests; I decide. [DO: accept or keep your pick, tap Save.]
>
> Saved — instantly. [DO: back on Home.] And the garden has already taken today in:
> the weather above the plants is today's mood."

**[FALLBACK: AI pill doesn't appear → "and if the suggestion service is off, I simply pick
by hand — the app never depends on AI to work." Keep moving.]**

### Beat 3 · Sync to web + offline line · 1:15–1:35 · phone → web (~50 words)

**[DO: gesture from the phone to the Chrome window — the entry saved in Beat 2 is already
sitting in the History list. Point at it. Nothing to toggle, nothing to wait for.]**

> "Now look at the right-hand window. The entry I logged on the phone seconds ago is
> already here in Chrome — same account, same garden. And because every entry is written
> to the phone first and the cloud catches up after, logging works even with no signal
> at all. Your journal never asks you to wait."

**[FALLBACK: entry hasn't appeared yet → don't wait, don't refresh-mash. Say "it'll be
there by the time we get back to this window" and go straight into Beat 4 — you're about
to use the web window anyway, and it will have arrived by then.]**

### Beat 4 · Garden & History · 1:35–2:15 · web (~100 words)

**[DO: in Chrome, go Home. Point at plants and sky. Then the History tab; open one past week;
tap one entry to raise the detail sheet.]**

> "The garden is the story your moods tell. Five states, from Flourishing down to Storm
> Season — and here's our core promise: **every state is alive**. Hard weeks don't show a
> punished garden; the plants shelter, and the caption says it best: *storms pass, the
> roots hold.*
>
> Each week, the garden is harvested into History — a new week starts fresh, and nothing
> is taken from you. [DO: open a past week, then an entry.] Today's entry I can still
> edit; after that, it becomes part of the record — a story, not a redo."

### Beat 5 · Patterns & care · 2:15–3:00 · web + canned clip (~112 words)

**[DO: open the Patterns tab. Point at the insight cards, then the inline disclaimer banner.]**

> "Patterns. Five statistical checks run quietly on the phone with every entry — no mood
> text ever leaves for analysis. And before any insight, this banner — read it with me:
> *MoodBloom is not a medical device. It cannot diagnose. Consult a professional.* That
> sentence appears five places in the app, on purpose.
>
> [DO: play the 20s Tier-1 clip — banner slides up → 'Open' → breathing screen.]
>
> When the checks notice a rough stretch, the app offers — never orders: a two-minute
> breathing exercise, or a journaling prompt. For the most serious pattern, it shows
> real crisis resources and the 1323 hotline — in fixed, human-written wording. No AI
> there, ever, by design. And at most one gentle nudge per day."

**[FALLBACK: clip won't play → flip the deck to Slide 10 and narrate the two stills left-to-right.]**

**[OPTIONAL live variant — only if rehearsed: in Chrome, navigate to
`/home/intervention/breathing` and let the breathing animation run live for ~5s instead of
the clip. Fall back to the clip if the route misbehaves under the projector's nerves.]**

### Beat 6 · Shop & Settings close · 3:00–3:30 · phone (~75 words)

**[DO: on the phone — Home → "Customize" pill → Skin Shop. Then Settings tab → toggle dark mode.]**

> "Last stop. Logging earns tokens — for showing up, not for feeling better: a sad day
> earns exactly what a joyful day earns. Tokens buy flower skins. That's all they buy —
> care is never behind a price.
>
> And Settings: dark mode, large-text support, the same disclaimer, and your data is
> yours to export or erase. [DO: toggle dark mode — garden re-renders.]
>
> That's MoodBloom — a garden that never punishes you for being human."

**[Hand back to the deck — Slide 11.]**

---

## If you only have 3:00 (cut in this order)

1. Merge Beat 0 into Beat 1 — open on the lock screen and say the two-windows line while unlocking (−10s).
2. Beat 4: show the garden + one harvested week, skip opening the entry detail sheet (−15s).
3. Beat 6: skip the dark-mode toggle, keep the tokens line + close line (−10s).
4. Never cut Beats 2, 3, or 5 — core loop, the sync glance, and the safety story are the demo.
   (Beat 3 is already only 20s — it has no further fat to trim.)

## Recovery matrix (one line each — keep calm, keep narrating)

| Failure | Response |
|---|---|
| Phone mirror freezes | Switch fully to Chrome — every beat except biometric works on web. |
| Web build down | Phone-only; cover sync verbally + Slide 8 screenshots. |
| Wi-Fi dead | Phone hotspot. If that fails too: skip the Beat 3 glance, run Beats 4–5 on the phone instead of Chrome, and keep the offline-first sentence — it's the one claim that needs *no* network to be true. |
| Sync slow in Beat 3 | Don't wait or refresh — "it'll be there in a moment," move into Beat 4 on the web window; it arrives while you talk. |
| AI pill missing | Scripted fallback line in Beat 2 — it's the rollback design, say so. |
| Anything else | "Here's that flow captured this morning" → video → keep talking. Promise from Slide 7 stands. |

---

## Offline — what's actually true (for Q&A, verified 2026-06-05)

| | Android (phone) | Web (Chrome) |
|---|---|---|
| Write path | Drift (SQLite) first → background sync queue → Firestore | Firestore SDK directly — no local queue (ADR-0004: Drift is native-only) |
| Log with no signal | Works; saved on device, drains on reconnect | Works while the tab stays open (SDK buffers in memory) |
| Offline + app/tab closed before reconnect | Entry is safe — survives restart (Drift + Firestore disk cache, `main.dart:45`) | Pending entry does not survive a tab close/refresh (no web persistence) |
| Verified by | 96/96 sync-engine tests (enqueue, reconnect drain, retry/backoff, conflict LWW, no cross-user replay) | Code-level review; web UI flows can't be auto-tested (Drift FFI doesn't compile to web — documented, deck A8) |

**If asked "does offline work on the web too?"** — honest answer: *"On web, entries go straight to the cloud; brief connection drops are buffered by the browser SDK. The full offline-first guarantee — log with no signal, close the app, sync later — is the native Android path, which is where people actually log offline."*

## How this maps to the deck (deck unchanged)

- **Slide 7 (agenda)** — verbally present the new tour: *"a three-and-a-half-minute tour of the
  whole app: unlock, log a mood and watch it sync, the garden and its history, patterns and
  care, and the shop."* Then leave the deck for the windows.
- **Slides 8–9** — superseded by live Beats 0–3; keep them as fallback imagery. Slide 9's
  offline-first card backs the spoken offline line in Beat 3 — if someone asks, the answer is
  "happy to show the captured clip in Q&A" (it's queued), not a live toggle.
- **Slide 10** — your Beat 5 fallback stills; return to the deck here if the clip fails.
- Re-enter the deck at **Slide 11** for the hand-off ("That safety system is really an
  AI-orchestration story…").

### Paste-ready Slide 7 agenda (optional, NOT applied)

```latex
\begin{enumerate}
  \item \textbf{Unlock} --- private by default: biometric / PIN / passkey \hfill {\footnotesize($\sim$20s)}
  \item \textbf{Log a mood} --- intensity slider + AI suggestion, under 30s \hfill {\footnotesize($\sim$40s)}
  \item \textbf{Cross-platform sync} --- the phone entry appears on Web in seconds (offline-first by design) \hfill {\footnotesize($\sim$20s)}
  \item \textbf{Garden \& History} --- five living tiers, weekly harvest \hfill {\footnotesize($\sim$40s)}
  \item \textbf{Patterns \& care} --- disclaimer + Tier-1 walkthrough (canned) \hfill {\footnotesize($\sim$45s)}
  \item \textbf{Tokens \& Settings} --- cosmetic-only shop, dark mode \hfill {\footnotesize($\sim$30s)}
\end{enumerate}
```

---

## Copy-rule self-check (spoken lines audited)

- No "delete / reset / lost / wilted / dead / dying" — harvest, fresh, sheltered used instead. ✓
- No clinical labels for the user; "bipolar" only inside the verbatim disclaimer quote. ✓
- No streak language; tokens framed as "for showing up." ✓
- Offers, never orders: "offers — never orders," "I can," "if I want." ✓
- Hotline 1323 mentioned once, inside the Tier-3 sentence, never as a CTA. ✓
